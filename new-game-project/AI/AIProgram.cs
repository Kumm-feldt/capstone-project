using System;
using CreeperAI;
using Godot;

public partial class AIProgram : Node
{
	internal const string ModelPath = "trained_AI.pt";

	public string GetMove(string boardString)
	{
		var agent = CreateAgent();
		InitializeGameFromBoardString(boardString);
		var board = Game.CurrentBoard;
		
		// Ask game rules for all legal moves in this position.
		var legalMoves = Game.GetLegalMoves(board, Game.CurrentPlayer);

		// Build the 86-length state vector expected by DQNAgent.
		float[] state = BuildStateVectorFromCurrentGame();

		// Greedy action selection returns index into legalMoves.
		int bestMoveIndex = agent.SelectAction(state, legalMoves, greedy: true);
		var bestMove = legalMoves[bestMoveIndex];

		// Convert internal move coordinates into external move notation.
		string moveString = Game.MoveToString(bestMove);
		return moveString;
	}


	public string GetNewBoardString(string boardString)
	{
		var agent = CreateAgent();
		InitializeGameFromBoardString(boardString);
		var board = Game.CurrentBoard;

		// Ask game rules for all legal moves in this position.
		var legalMoves = Game.GetLegalMoves(board, Game.CurrentPlayer);

		// Build the 86-length state vector expected by DQNAgent.
		float[] state = BuildStateVectorFromCurrentGame();

		// Greedy action selection returns index into legalMoves.
		int bestMoveIndex = agent.SelectAction(state, legalMoves, greedy: true);
		var bestMove = legalMoves[bestMoveIndex];
		Game.ApplyMove(bestMove);

		// Convert internal move coordinates into external move notation.
		string newBoardString = Game.GetBoardString();
		return newBoardString;
	}

	private static DQNAgent CreateAgent()
	{
		var agent = new DQNAgent();
		agent.Load(ModelPath);
		return agent;
	}

	private static void InitializeGameFromBoardString(string boardString)
	{
		Game.InitializeFromString(boardString);
		Game.CurrentPlayer = boardString[85] == 'x' ? PlayerColor.Light : PlayerColor.Dark;
	}

	// Encodes current game arrays into model input format:
	// discs (6x6), pins (7x7), then current player.
	internal static float[] BuildStateVectorFromCurrentGame()
	{
		float[] state = new float[86];
		int idx = 0;
		var board = Game.CurrentBoard;

		// Discs occupy indices 0..35.
		for (int r = 0; r < 6; r++)
			for (int c = 0; c < 6; c++)
				state[idx++] = board.Discs[r, c];

		// Pins occupy indices 36..84.
		for (int r = 0; r < 7; r++)
			for (int c = 0; c < 7; c++)
				state[idx++] = board.Pins[r, c];

		// Final slot (index 85) stores side-to-move.
		state[idx] = (int)Game.CurrentPlayer;
		return state;
	}
}
