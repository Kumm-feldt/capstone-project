using TorchSharp;
using TorchSharp.Modules;
using static TorchSharp.torch;
using static TorchSharp.torch.nn;

public class DQN : Module
{
    // Three-layer fully connected network used to approximate Q-values.
    private Linear fc1;
    private Linear fc2;
    private Linear fc3;

    // Build the MLP: input -> 128 -> 128 -> action-space output.
    public DQN(int inputSize, int outputSize) : base("dqn")
    {
        fc1 = Linear(inputSize, 128);
        fc2 = Linear(128, 128);
        fc3 = Linear(128, outputSize);

        RegisterComponents();
    }

    // Forward pass that maps state features to per-action Q-values.
    public Tensor forward(Tensor input)
    {
        // First hidden layer with ReLU activation.
        input = fc1.forward(input);
        input = functional.relu(input);

        // Second hidden layer with ReLU activation.
        input = fc2.forward(input);
        input = functional.relu(input);

        // Output layer returns raw Q-values (no activation).
        input = fc3.forward(input);

        return input;
    }
}
