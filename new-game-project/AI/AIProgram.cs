using System;
using CreeperAI;
using Godot;

public partial class AIProgram : Node
{
	internal const int DefaultAlphaBetaDepth = 3;

	public string GetMove(string boardString)
	{
		InitializeGameFromBoardString(boardString);
		var board = new Board(Game.CurrentBoard.Pins, Game.CurrentBoard.Discs);
		var legalMoves = Game.GetLegalMoves(board, Game.CurrentPlayer);
		if (legalMoves.Count == 0)
			return string.Empty;

		var bestMove = AlphaBetaAgent.ChooseMove(Game.CurrentBoard.Pins, Game.CurrentBoard.Discs, Game.CurrentPlayer, DefaultAlphaBetaDepth, legalMoves);

		// Convert internal move coordinates into external move notation.
		string moveString = Game.MoveToString(bestMove);
		return moveString;
	}


	public string GetNewBoardString(string boardString)
	{
		InitializeGameFromBoardString(boardString);
		var board = new Board(Game.CurrentBoard.Pins, Game.CurrentBoard.Discs);
		var legalMoves = Game.GetLegalMoves(board, Game.CurrentPlayer);
		if (legalMoves.Count == 0)
			return BuildBoardStringFromCurrentGame();

		var bestMove = AlphaBetaAgent.ChooseMove(Game.CurrentBoard.Pins, Game.CurrentBoard.Discs, Game.CurrentPlayer, DefaultAlphaBetaDepth, legalMoves);
		Game.ApplyMove(bestMove);

		// Return serialized board after applying the selected move.
		string newBoardString = BuildBoardStringFromCurrentGame();
		return newBoardString;
	}

	private static void InitializeGameFromBoardString(string boardString)
	{
		if (string.IsNullOrEmpty(boardString) || boardString.Length != 86)
			throw new ArgumentException("Board string must be exactly 86 characters long.", nameof(boardString));

		Game.InitializeFromString(boardString);
		Game.CurrentPlayer = boardString[85] == 'x' ? PlayerColor.Light : PlayerColor.Dark;
	}

	// Serialize board using the same 86-char layout expected by InitializeFromString.
	internal static string BuildBoardStringFromCurrentGame()
	{
		char[] state = new char[86];
		int idx = 0;

		// Pins occupy indices 0..48.
		for (int r = 0; r < 7; r++)
			for (int c = 0; c < 7; c++)
				state[idx++] = CellToChar(Game.CurrentBoard.Pins[r, c]);

		// Discs occupy indices 49..84.
		for (int r = 0; r < 6; r++)
			for (int c = 0; c < 6; c++)
				state[idx++] = CellToChar(Game.CurrentBoard.Discs[r, c]);

		// Final slot (index 85) stores side-to-move.
		state[idx] = Game.CurrentPlayer == PlayerColor.Light ? 'x' : 'o';
		return new string(state);
	}

	private static char CellToChar(int value)
	{
		return value switch
		{
			1 => 'x',
			-1 => 'o',
			_ => '.'
		};
	}
}
