
using System;
using System.Collections.Generic;
using System.Linq;

using System.IO;
using System.Security.Cryptography;
using TorchSharp;
using static TorchSharp.torch;
using static TorchSharp.torch.nn;
using CreeperAI;

public class DQNAgent
{
	// Input dimensionality for state-action scoring.
	private const int StateSize = 86;
	private const int MoveFeatureSize = 10;
	private const int StateActionInputSize = StateSize + MoveFeatureSize;
	private readonly Random rng = new Random();
	private readonly DQN policyNet;
	private readonly DQN targetNet;

	// Epsilon-greedy exploration parameters.
	private float epsilon = 1.0f;

	// Restored from optional metadata sidecar.
	private int trainingStep = 0;

	// Initialize policy/target networks and start with identical weights.
	public DQNAgent()
	{
		policyNet = new DQN(StateActionInputSize, 1);
		targetNet = new DQN(StateActionInputSize, 1);
		targetNet.load_state_dict(policyNet.state_dict());
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

	// Load checkpoint for inference with optional checksum and metadata.
	public void Load(string path)
	{
		if (!File.Exists(path))
		{
			Console.WriteLine($"Checkpoint not found at {path}");
			return;
		}

		var shaPath = path + ".sha256";
		if (File.Exists(shaPath))
		{
			var expected = File.ReadAllText(shaPath).Trim();
			using var fs = File.OpenRead(path);
			using var sha = SHA256.Create();
			var actualBytes = sha.ComputeHash(fs);
			var actual = BitConverter.ToString(actualBytes).Replace("-", "").ToLowerInvariant();
			if (expected != actual)
				throw new InvalidDataException("Checkpoint checksum mismatch.");
		}

		policyNet.load(path);
		targetNet.load_state_dict(policyNet.state_dict());

		var metaPath = path + ".meta";
		if (File.Exists(metaPath))
		{
			var lines = File.ReadAllLines(metaPath);
			if (lines.Length > 0 && float.TryParse(lines[0], out var e)) epsilon = e;
			if (lines.Length > 1 && int.TryParse(lines[1], out var s)) trainingStep = s;
		}

		Console.WriteLine($"Loaded checkpoint from {path}. Step: {trainingStep}, Epsilon: {epsilon:F4}");
	}

	// Select a legal move index from the policy output.
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

}
