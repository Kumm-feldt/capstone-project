public class ReplayBuffer
{
    // Random source used for uniform batch sampling.
    private readonly Random rng = new Random();

    // Experience tuples: (state, actionFeatures, reward, nextState, nextLegalActionFeatures, done).
    private List<(float[] state, float[] actionFeatures, float reward, float[] nextState, List<float[]> nextLegalActionFeatures, bool done)> memory
        = new();

    // Maximum number of transitions retained in replay memory.
    private int capacity = 10000;

    // Add one transition; evict oldest item when at capacity (FIFO behavior).
    public void Add(float[] state, float[] actionFeatures, float reward, float[] nextState, List<float[]> nextLegalActionFeatures, bool done)
    {
        if (memory.Count >= capacity)
            memory.RemoveAt(0);

        memory.Add((state, actionFeatures, reward, nextState, nextLegalActionFeatures, done));
    }

    // Sample unique random indices to form a mini-batch up to requested size.
    public List<(float[], float[], float, float[], List<float[]>, bool)> Sample(int batchSize)
    {
        var count = Math.Min(batchSize, memory.Count);
        var indices = new HashSet<int>();
        while (indices.Count < count)
        {
            indices.Add(rng.Next(memory.Count));
        }

        var sample = new List<(float[], float[], float, float[], List<float[]>, bool)>(count);
        foreach (var index in indices)
        {
            sample.Add(memory[index]);
        }

        return sample;
    }

    // Current number of stored transitions.
    public int Count => memory.Count;
}
