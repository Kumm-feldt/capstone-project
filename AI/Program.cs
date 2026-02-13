using System;
//using TorchSharp;
//using static TorchSharp.torch;
using CreeperAI;

class Program
{
    static void Main()
    {
        /* RAMDOM AI FOR INTEGRATING WITH THE GODOT PROJECT */
        // Change this to get the current board state from Godot instead of hardcoding
        Game.BoardString = ".oo.xx.o.....xo.....x.......x.....ox.....o.xx.oo.o....x........................x....ox";
        Game.InitializeFromString(Game.BoardString); // Initializes the Game state based on the provided board string
        var board = new Board(Game.pins, Game.discs); // Create a Board object from the current Game state
        var move = Game.GetBestMove(board, Game.CurrentPlayer); // Gets a rendom legal move for the current player
        if (move != null) { // If a legal move exists
            Game.MoveString = Game.MoveToString(move); // Turn it into the string format for Godot. This is a field you can read from.
            Console.WriteLine($"Random AI selects move: {Game.MoveString}"); // Not sure if this will print to Godot's console...
        }
        else
        {
            Console.WriteLine("No legal moves available for Random AI.");
        }

        /* SIMPLE TORCHSHARP TEST
        var t = randn(3, 3);
        Console.WriteLine(t);
        */

        /* SIMULATE RANDOM GAMES FOR TESTING CREEPERENVIRONMENT
        CreeperEnvironment env = new CreeperEnvironment();
        Random random = new Random();
        bool done = false;
        float rewardTotal = 0f;
        int numGames = 0;
        char winner = 'd'; // d for draw, L for light, D for dark
        float gameReward = 0f;
        while (numGames < 10000)
        {
            env.Reset();
            done = false;
            while (!done)
            {
                var legal = env.GetLegalMoves();
                if (legal.Count == 0)
                {
                    done = true;
                    gameReward = -0.5f;  // No legal moves = draw
                    winner = 'd';
                    break;
                }

                var move = legal[random.Next(legal.Count)];
                (float reward, bool done, int winner) result = env.Step(move);
                done = result.done;
                // Track from Light's perspective: +1 if Light wins, -1 if Dark wins, -0.5 if draw
                if (done)
                    gameReward = result.winner == 1 ? 1f : (result.winner == -1 ? -1f : -0.5f);
                winner = result.winner == 1 ? 'L' : (result.winner == -1 ? 'D' : 'd');
            }
            numGames++;
            rewardTotal += gameReward;
        }
            Console.WriteLine($"Game {numGames}: Reward = {gameReward:+0.0;-0.0}, Winner = {winner}, Total = {rewardTotal}");
        */

        /* TESTS
        Game.Initialize(test: true, testScenario: 3);
        var testBoard = new Board(Game.pins, Game.discs);
        var testMoves = Game.GetLegalMoves(testBoard, Game.CurrentPlayer);
        Console.WriteLine($"Current player: {Game.CurrentPlayer}");
        Console.WriteLine($"Legal moves: {testMoves.Count}");
        foreach (var m in testMoves) Console.WriteLine($"{m.FromR},{m.FromC} -> {m.ToR},{m.ToC}");
        */

        /* FOR WATCHING AI PLAY
        Game.Initialize();
        var board = new Board(Game.pins, Game.discs);
        Game.PrintBoard();
        var winner = 0;
        var continueGame = true;
        do {
            var move = Game.GetBestMove(board, Game.CurrentPlayer);
            if (move == null)
            {
                Console.WriteLine($"{Game.CurrentPlayer} has no legal moves. Game over.");
                break;
            }
            Console.WriteLine($"{Game.CurrentPlayer} plays: {move.FromR},{move.FromC} -> {move.ToR},{move.ToC}");
            Game.ApplyMove(move);
            Game.PrintBoard();

        } while (!Game.IsTerminal(out winner) && (continueGame = Console.ReadLine() != "q"));
        if (winner != 0) {
            Console.WriteLine($"Game over! Winner: {(PlayerColor)winner}");
        }
        else {
            Console.WriteLine($"Game over! Draw.");
        }
        */
    }
}