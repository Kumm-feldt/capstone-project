using System;
using CreeperAI;

class Program
{
    static void Main()
    {
        // Path to the trained checkpoint requested for inference.
        const string modelPath = "trained_agent_A.pt";

        // Build the agent and load trained weights from disk.
        var agent = new DQNAgent();
        try
        {
            agent.Load(modelPath);
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error loading model '{modelPath}': {ex.Message}");
            Console.WriteLine("The checkpoint appears unreadable by TorchSharp (not native .pt and not custom CREEPERCHKv1).");
            return;
        }

        // Read the serialized board state from stdin.
        Console.WriteLine("Enter board state string (86 chars):");
        string boardState = (Console.ReadLine() ?? string.Empty).Trim();

        // The board encoding is fixed-size: 49 pins + 36 discs + 1 current-player marker.
        if (boardState.Length != 86)
        {
            Console.WriteLine("Error: board state must be exactly 86 characters.");
            return;
        }

        // Start from a clean board, then overwrite with provided encoded state.
        Game.InitializeFromString(boardState);

        // Convert the incoming string into live pin/disc arrays.
        var board = new Board(Game.pins, Game.discs);
        board.ConvertStringToBoard(boardState);

        // Last character indicates side-to-move; map it to Game.CurrentPlayer.
        if (!TrySetCurrentPlayerFromBoardString(boardState, out string playerError))
        {
            Console.WriteLine($"Error: {playerError}");
            return;
        }

        // Ask game rules for all legal moves in this position.
        var legalMoves = Game.GetLegalMoves(board, Game.CurrentPlayer);
        if (legalMoves.Count == 0)
        {
            Console.WriteLine("No legal moves available.");
            return;
        }

        // Build the 86-length state vector expected by DQNAgent.
        float[] state = BuildStateVectorFromCurrentGame();

        // Greedy action selection returns index into legalMoves.
        int bestMoveIndex = agent.SelectAction(state, legalMoves, greedy: true);
        var bestMove = legalMoves[bestMoveIndex];

        // Convert internal move coordinates into external move notation.
        string moveString = Game.MoveToString(bestMove);
        Console.WriteLine($"Best move: {moveString}");
    }

    // Encodes current game arrays into model input format:
    // discs (6x6), pins (7x7), then current player.
    private static float[] BuildStateVectorFromCurrentGame()
    {
        float[] state = new float[86];
        int idx = 0;

        // Discs occupy indices 0..35.
        for (int r = 0; r < 6; r++)
            for (int c = 0; c < 6; c++)
                state[idx++] = Game.discs[r, c];

        // Pins occupy indices 36..84.
        for (int r = 0; r < 7; r++)
            for (int c = 0; c < 7; c++)
                state[idx++] = Game.pins[r, c];

        // Final slot (index 85) stores side-to-move.
        state[idx] = (int)Game.CurrentPlayer;
        return state;
    }

    // Interprets the board-string current-player marker and updates Game.CurrentPlayer.
    private static bool TrySetCurrentPlayerFromBoardString(string boardState, out string error)
    {
        // Encoding convention: index 85 carries side-to-move marker.
        char currentPlayerChar = boardState[85];

        switch (char.ToLowerInvariant(currentPlayerChar))
        {
            case 'x':
                Game.CurrentPlayer = PlayerColor.Light;
                error = string.Empty;
                return true;

            case 'o':
                Game.CurrentPlayer = PlayerColor.Dark;
                error = string.Empty;
                return true;

            default:
                error = "unsupported current-player marker at index 85. Use x for Light or o for Dark.";
                return false;
        }
    }
}
