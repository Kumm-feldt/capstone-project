using System;
using System.IO;
using System.Security.Cryptography;
using System.Text;
using TorchSharp;
using static TorchSharp.torch;
using static TorchSharp.torch.optim;
using static TorchSharp.torch.nn;
using CreeperAI;

public class DQNAgent
{
    // Input dimensionality for state-action scoring.
    private const int StateSize = 86;
    private const int MoveFeatureSize = 10;
    private const int StateActionInputSize = StateSize + MoveFeatureSize;
    private Random rng = new Random();
    private DQN policyNet;
    private DQN targetNet;
    private Optimizer optimizer;

    // Epsilon-greedy exploration parameters.
    private float epsilon = 1.0f;
    private float epsilonMin = 0.05f;
    private float epsilonDecay = 0.9990f;

    // Target-network synchronization cadence.
    private int trainingStep = 0;
    private int targetUpdateFrequency = 1000;

    // Discount factor for Bellman target computation.
    private float gamma = 0.99f;

    // Expose current exploration rate for logging/monitoring.
    public float Epsilon => epsilon;

    // Initialize policy/target networks and start with identical weights.
    public DQNAgent()
    {
        policyNet = new DQN(StateActionInputSize, 1);
        targetNet = new DQN(StateActionInputSize, 1);
        targetNet.load_state_dict(policyNet.state_dict());

        optimizer = Adam(policyNet.parameters(), 0.001);
    }

    // Configure epsilon schedule (used by training modes with custom exploration policy).
    public void ConfigureExploration(float startEpsilon, float minEpsilon, float decay)
    {
        epsilon = startEpsilon;
        epsilonMin = minEpsilon;
        epsilonDecay = decay;
    }

    // Copy source policy weights into this agent's policy and target networks.
    public void CopyWeightsFrom(DQNAgent source)
    {
        policyNet.load_state_dict(source.policyNet.state_dict());
        targetNet.load_state_dict(source.policyNet.state_dict());
    }

    // Build normalized features for a move on the 7x7 pin grid.
    public static float[] BuildMoveFeatures(PinMove move)
    {
        float fromRow = move.FromR / 6f;
        float fromCol = move.FromC / 6f;
        float toRow = move.ToR / 6f;
        float toCol = move.ToC / 6f;
        int deltaRowRaw = move.ToR - move.FromR;
        int deltaColRaw = move.ToC - move.FromC;
        float deltaRow = deltaRowRaw / 6f;
        float deltaCol = deltaColRaw / 6f;
        float isDiagonal = (Math.Abs(deltaRowRaw) == 1 && Math.Abs(deltaColRaw) == 1) ? 1f : 0f;
        float isOrthogonalStep = ((Math.Abs(deltaRowRaw) == 1 && deltaColRaw == 0) || (Math.Abs(deltaColRaw) == 1 && deltaRowRaw == 0)) ? 1f : 0f;
        float isCaptureJump = ((Math.Abs(deltaRowRaw) == 2 && deltaColRaw == 0) || (Math.Abs(deltaColRaw) == 2 && deltaRowRaw == 0)) ? 1f : 0f;
        float manhattanDistance = (Math.Abs(deltaRowRaw) + Math.Abs(deltaColRaw)) / 12f;

        return new float[]
        {
            fromRow,
            fromCol,
            toRow,
            toCol,
            deltaRow,
            deltaCol,
            isDiagonal,
            isOrthogonalStep,
            isCaptureJump,
            manhattanDistance
        };
    }

    // Standard epsilon-greedy action selection over legal moves.
    public int SelectAction(float[] state, List<PinMove> legalMoves)
    {
        if (rng.NextDouble() < epsilon)
        {
            return rng.Next(legalMoves.Count);
        }

        return SelectBestLegalMoveIndex(state, legalMoves, policyNet);
    }

    // Perform one DQN optimization step from replay memory when enough samples exist.
    public void Train(ReplayBuffer buffer)
    {
        if (buffer.Count < 64) return;

        var batch = buffer.Sample(64);
        optimizer.zero_grad();

        // Compute Bellman loss per sampled transition and accumulate gradients.
        foreach (var transition in batch)
        {
            float[] state = transition.Item1;
            float[] actionFeatures = transition.Item2;
            float reward = transition.Item3;
            float[] nextState = transition.Item4;
            List<float[]> nextLegalActionFeatures = transition.Item5;
            bool done = transition.Item6;

            using var stateActionTensor = tensor(ConcatenateStateAction(state, actionFeatures), dtype: ScalarType.Float32).unsqueeze(0);
            using var currentQ = policyNet.forward(stateActionTensor).squeeze();

            float maxNextQ = 0f;
            if (!done && nextLegalActionFeatures.Count > 0)
            {
                maxNextQ = EvaluateMaxQ(targetNet, nextState, nextLegalActionFeatures, noGrad: true);
            }

            float targetValue = reward + (done ? 0f : gamma * maxNextQ);
            using var targetQ = tensor(targetValue, dtype: ScalarType.Float32);
            using var loss = functional.smooth_l1_loss(currentQ, targetQ);
            using var scaledLoss = loss / batch.Count;
            scaledLoss.backward();
        }

        torch.nn.utils.clip_grad_norm_(policyNet.parameters(), 1.0);
        optimizer.step();

        // Periodically refresh target network weights.
        trainingStep++;
        if (trainingStep % targetUpdateFrequency == 0)
            targetNet.load_state_dict(policyNet.state_dict());
    }

    // Decay epsilon after each training episode, bounded by epsilonMin.
    public void EndEpisode()
    {
        if (epsilon > epsilonMin)
            epsilon *= epsilonDecay;
    }

    // Save checkpoint with robust fallbacks and sidecar integrity metadata.
    public void Save(string path)
    {
        // Ensure destination directory exists.
        var dir = Path.GetDirectoryName(path);
        if (!string.IsNullOrEmpty(dir)) Directory.CreateDirectory(dir);

        // Preferred save path: module-native serializer.
        try
        {
            policyNet.save(path);
        }
        catch
        {
            // Fallback 1: invoke potential torch.save(object, string) overload via reflection.
            var stateDict = policyNet.state_dict();
            var torchType = typeof(torch);
            var saveMethod = torchType.GetMethod(
                "save",
                System.Reflection.BindingFlags.Public | System.Reflection.BindingFlags.Static,
                null,
                new Type[] { typeof(object), typeof(string) },
                null
            );

            if (saveMethod != null)
            {
                saveMethod.Invoke(null, new object[] { stateDict, path });
            }
            else
            {
                // Fallback 2: custom binary format for broad compatibility.
                using var stream = File.Create(path);
                using var writer = new BinaryWriter(stream);

                writer.Write("CREEPERCHKv1");
                var metadata = new Dictionary<string, string>
                {
                    { "epsilon", epsilon.ToString() },
                    { "trainingStep", trainingStep.ToString() }
                };

                foreach (var kvp in metadata)
                {
                    writer.Write(kvp.Key);
                    writer.Write(kvp.Value);
                }

                writer.Write("END_METADATA");
                writer.Write(stateDict.Count);

                foreach (var kvp in stateDict)
                {
                    writer.Write(kvp.Key);
                    var shape = kvp.Value.shape;
                    writer.Write(shape.Length);
                    for (int i = 0; i < shape.Length; i++) writer.Write((int)shape[i]);

                    var tensorBytes = kvp.Value.bytes;
                    writer.Write(tensorBytes.Length);
                    writer.Write(tensorBytes);
                }
            }
        }

        // Write SHA256 sidecar for integrity checks during load.
        try
        {
            using var fs = File.OpenRead(path);
            using var sha = SHA256.Create();
            var hash = sha.ComputeHash(fs);
            var hex = BitConverter.ToString(hash).Replace("-", "").ToLowerInvariant();
            File.WriteAllText(path + ".sha256", hex);
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Warning: failed to write checksum: {ex.Message}");
        }

        // Write minimal training metadata sidecar.
        try
        {
            var metaPath = path + ".meta";
            File.WriteAllLines(metaPath, new[] { epsilon.ToString("R"), trainingStep.ToString() });
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Warning: failed to write metadata: {ex.Message}");
        }
    }

    // Load checkpoint with checksum validation and layered format fallbacks.
    public void Load(string path)
    {
        if (!File.Exists(path))
        {
            Console.WriteLine($"Checkpoint not found at {path}");
            return;
        }

        // Validate checksum if sidecar exists.
        try
        {
            var shaPath = path + ".sha256";
            if (File.Exists(shaPath))
            {
                var expected = File.ReadAllText(shaPath).Trim();
                using var fs = File.OpenRead(path);
                using var sha = SHA256.Create();
                var actualBytes = sha.ComputeHash(fs);
                var actual = BitConverter.ToString(actualBytes).Replace("-", "").ToLowerInvariant();
                if (expected != actual)
                    throw new Exception("Checksum mismatch: file may be corrupted or truncated");
            }
        }
        catch (Exception ex)
        {
            throw new Exception($"Checkpoint integrity check failed: {ex.Message}");
        }

        // Preferred load path: module-native loader.
        try
        {
            policyNet.load(path);
            targetNet.load_state_dict(policyNet.state_dict());

            var metaPath2 = path + ".meta";
            if (File.Exists(metaPath2))
            {
                var lines2 = File.ReadAllLines(metaPath2);
                if (lines2.Length > 0 && float.TryParse(lines2[0], out var e2)) epsilon = e2;
                if (lines2.Length > 1 && int.TryParse(lines2[1], out var s2)) trainingStep = s2;
            }

            Console.WriteLine($"Loaded module checkpoint from {path}. Step: {trainingStep}, Epsilon: {epsilon:F4}");
            return;
        }
        catch
        {
            // Fall through to state-dict loader paths.
        }

        // Fallback load path: torch.load state dictionary.
        Dictionary<string, Tensor>? stateDict = null;
        try
        {
            var loaded = torch.load(path);
            if (loaded is System.Collections.IDictionary dict)
            {
                stateDict = new Dictionary<string, Tensor>();
                foreach (System.Collections.DictionaryEntry entry in dict)
                {
                    if (entry.Key is string k && entry.Value is Tensor t)
                        stateDict[k] = t;
                }
            }
            else
            {
                throw new Exception("Unexpected checkpoint format");
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Native load failed: {ex.Message}");

            // Final fallback: custom binary checkpoint format.
            try
            {
                stateDict = ReadCustomCheckpoint(path);
                Console.WriteLine("Loaded checkpoint using custom binary fallback.");
            }
            catch (Exception ex2)
            {
                throw new Exception($"Failed to load checkpoint (native and fallback): {ex.Message} | {ex2.Message}");
            }
        }

        if (stateDict == null || stateDict.Count == 0)
            throw new Exception("Loaded checkpoint contains no tensors");

        policyNet.load_state_dict(stateDict);
        targetNet.load_state_dict(policyNet.state_dict());

        // Restore metadata when available.
        try
        {
            var metaPath = path + ".meta";
            if (File.Exists(metaPath))
            {
                var lines = File.ReadAllLines(metaPath);
                if (lines.Length > 0 && float.TryParse(lines[0], out var e)) epsilon = e;
                if (lines.Length > 1 && int.TryParse(lines[1], out var s)) trainingStep = s;
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Warning: failed to read metadata: {ex.Message}");
        }

        Console.WriteLine($"Loaded checkpoint from {path}. Step: {trainingStep}, Epsilon: {epsilon:F4}");
    }

    // Parse legacy custom binary checkpoint format into a TorchSharp-compatible state dict.
    private Dictionary<string, Tensor> ReadCustomCheckpoint(string path)
    {
        using var stream = File.OpenRead(path);
        using var reader = new BinaryReader(stream);

        var header = reader.ReadString();
        if (header != "CREEPERCHKv1")
            throw new Exception("Not a custom checkpoint (header mismatch)");

        // Skip metadata key-value pairs until sentinel marker.
        while (true)
        {
            var key = reader.ReadString();
            if (key == "END_METADATA") break;
            _ = reader.ReadString();
        }

        int entries = reader.ReadInt32();
        var dict = new Dictionary<string, Tensor>();
        for (int i = 0; i < entries; i++)
        {
            var k = reader.ReadString();
            int shapeLen = reader.ReadInt32();
            var shape = new long[shapeLen];
            for (int s = 0; s < shapeLen; s++) shape[s] = reader.ReadInt32();

            int byteLen = reader.ReadInt32();
            var bytes = reader.ReadBytes(byteLen);

            if (byteLen % 4 != 0)
                throw new Exception("Tensor byte length not divisible by 4 for float32 assumption");

            int count = byteLen / 4;
            var floats = new float[count];
            Buffer.BlockCopy(bytes, 0, floats, 0, byteLen);
            var t = tensor(floats, dtype: ScalarType.Float32).reshape(shape);
            dict[k] = t;
        }

        return dict;
    }

    // Greedy/eval action selection with optional tiny stochasticity and tie randomization.
    public int SelectAction(float[] state, List<PinMove> legalMoves, bool greedy)
    {
        // In non-greedy mode, use normal epsilon-greedy exploration.
        if (!greedy && rng.NextDouble() < epsilon)
        {
            return rng.Next(legalMoves.Count);
        }

        // Small randomization during eval to avoid strict deterministic loops.
        const double evalEpsilon = 0.01;
        if (greedy && rng.NextDouble() < evalEpsilon)
        {
            return rng.Next(legalMoves.Count);
        }

        return SelectBestLegalMoveIndex(state, legalMoves, policyNet);
    }

    private int SelectBestLegalMoveIndex(float[] state, List<PinMove> legalMoves, DQN network)
    {
        var moveFeaturesBatch = legalMoves.Select(BuildMoveFeatures).ToList();
        using var noGrad = torch.no_grad();
        var qValues = EvaluateQBatch(network, state, moveFeaturesBatch);

        float bestValue = float.MinValue;
        var candidates = new List<int>();
        const float tieTolerance = 1e-5f;

        for (int index = 0; index < qValues.Length; index++)
        {
            float value = qValues[index];
            if (value > bestValue + tieTolerance)
            {
                bestValue = value;
                candidates.Clear();
                candidates.Add(index);
            }
            else if (Math.Abs(value - bestValue) <= tieTolerance)
            {
                candidates.Add(index);
            }
        }

        if (candidates.Count == 0)
            return 0;

        return candidates[rng.Next(candidates.Count)];
    }

    private static float EvaluateQ(DQN network, float[] state, float[] moveFeatures)
    {
        using var stateActionTensor = tensor(ConcatenateStateAction(state, moveFeatures), dtype: ScalarType.Float32).unsqueeze(0);
        using var qValue = network.forward(stateActionTensor).squeeze();
        return qValue.ToSingle();
    }

    private static float EvaluateMaxQ(DQN network, float[] state, List<float[]> nextLegalActionFeatures, bool noGrad)
    {
        if (nextLegalActionFeatures.Count == 0)
            return 0f;

        if (noGrad)
        {
            using var ng = torch.no_grad();
            var qValues = EvaluateQBatch(network, state, nextLegalActionFeatures);
            return qValues.Length == 0 ? 0f : qValues.Max();
        }

        var qValuesWithoutNoGrad = EvaluateQBatch(network, state, nextLegalActionFeatures);
        return qValuesWithoutNoGrad.Length == 0 ? 0f : qValuesWithoutNoGrad.Max();
    }

    private static float[] EvaluateQBatch(DQN network, float[] state, List<float[]> moveFeaturesBatch)
    {
        if (moveFeaturesBatch.Count == 0)
            return Array.Empty<float>();

        int batchSize = moveFeaturesBatch.Count;
        var flattened = new float[batchSize * StateActionInputSize];

        for (int row = 0; row < batchSize; row++)
        {
            int offset = row * StateActionInputSize;
            Array.Copy(state, 0, flattened, offset, StateSize);
            Array.Copy(moveFeaturesBatch[row], 0, flattened, offset + StateSize, MoveFeatureSize);
        }

        using var input = tensor(flattened, dtype: ScalarType.Float32).reshape(batchSize, StateActionInputSize);
        using var output = network.forward(input).squeeze();

        var values = new float[batchSize];
        for (int i = 0; i < batchSize; i++)
        {
            values[i] = output[i].ToSingle();
        }

        return values;
    }

    private static float[] ConcatenateStateAction(float[] state, float[] moveFeatures)
    {
        var combined = new float[StateActionInputSize];
        Array.Copy(state, combined, StateSize);
        Array.Copy(moveFeatures, 0, combined, StateSize, MoveFeatureSize);
        return combined;
    }
}