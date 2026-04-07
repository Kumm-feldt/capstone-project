using System;
using CreeperAI;
using Godot;

public partial class AIProgram : Node
{
	internal const int DefaultAlphaBetaDepth = 4;
	internal const int MidgameAlphaBetaDepth = 5;
	internal const int EndgameAlphaBetaDepth = 6;

	public string GetMoveHard(string boardString)
	{
		InitializeGameFromBoardString(boardString);
		var board = new Board(Game.CurrentBoard.Pins, Game.CurrentBoard.Discs);
		var legalMoves = Game.GetLegalMoves(board, Game.CurrentPlayer);
		legalMoves = FilterOutLastPinCaptureMoves(legalMoves, Game.CurrentBoard.Pins, Game.CurrentPlayer);
		if (legalMoves.Count == 0)
			return string.Empty;

		int pinCount = CountPinsForPlayer(Game.CurrentBoard.Pins, Game.CurrentPlayer);
		int searchDepth = ChooseSearchDepth(pinCount);

		var bestMove = AlphaBetaAgent.ChooseMove(Game.CurrentBoard.Pins, Game.CurrentBoard.Discs, Game.CurrentPlayer, searchDepth, legalMoves);

		// Convert internal move coordinates into external move notation.
		string moveString = Game.MoveToString(bestMove);
		return moveString;
	}

	public string GetMoveEasy(string boardString)
	{
		InitializeGameFromBoardString(boardString);
		var board = new Board(Game.CurrentBoard.Pins, Game.CurrentBoard.Discs);
		var legalMoves = Game.GetLegalMoves(board, Game.CurrentPlayer);
		legalMoves = FilterOutLastPinCaptureMoves(legalMoves, Game.CurrentBoard.Pins, Game.CurrentPlayer);
		if (legalMoves.Count == 0)
			return string.Empty;

		int searchDepth = 2;

		var bestMove = AlphaBetaAgent.ChooseMove(Game.CurrentBoard.Pins, Game.CurrentBoard.Discs, Game.CurrentPlayer, searchDepth, legalMoves);

		// Convert internal move coordinates into external move notation.
		string moveString = Game.MoveToString(bestMove);
		return moveString;
	}


	public string GetNewBoardString(string boardString)
	{
		InitializeGameFromBoardString(boardString);
		var board = new Board(Game.CurrentBoard.Pins, Game.CurrentBoard.Discs);
		var legalMoves = Game.GetLegalMoves(board, Game.CurrentPlayer);
		legalMoves = FilterOutLastPinCaptureMoves(legalMoves, Game.CurrentBoard.Pins, Game.CurrentPlayer);
		if (legalMoves.Count == 0)
			return BuildBoardStringFromCurrentGame();

		int pinCount = CountPinsForPlayer(Game.CurrentBoard.Pins, Game.CurrentPlayer);
		int searchDepth = ChooseSearchDepth(pinCount);

		var bestMove = AlphaBetaAgent.ChooseMove(Game.CurrentBoard.Pins, Game.CurrentBoard.Discs, Game.CurrentPlayer, searchDepth, legalMoves);
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

	private static int ChooseSearchDepth(int totalPinsLeft)
	{
		// Increase depth as the active player runs low on remaining pins.
		if (totalPinsLeft <= 3)
			return EndgameAlphaBetaDepth;
		if (totalPinsLeft <= 5)
			return MidgameAlphaBetaDepth;

		return DefaultAlphaBetaDepth;
	}

	private static System.Collections.Generic.List<PinMove> FilterOutLastPinCaptureMoves(System.Collections.Generic.List<PinMove> legalMoves, int[,] pins, PlayerColor currentPlayer)
	{
		var opponent = currentPlayer == PlayerColor.Light ? PlayerColor.Dark : PlayerColor.Light;
		if (CountPinsForPlayer(pins, opponent) != 1)
			return legalMoves;

		var filtered = new System.Collections.Generic.List<PinMove>(legalMoves.Count);
		foreach (var move in legalMoves)
		{
			if (!IsCaptureMove(move) || !DoesCaptureOpponentPin(move, pins, opponent))
				filtered.Add(move);
		}

		return filtered;
	}

	private static int CountPinsForPlayer(int[,] pins, PlayerColor player)
	{
		int value = (int)player;
		int total = 0;
		for (int r = 0; r < 7; r++)
		{
			for (int c = 0; c < 7; c++)
			{
				if (pins[r, c] == value)
					total++;
			}
		}

		return total;
	}

	private static bool IsCaptureMove(PinMove move)
	{
		int dr = move.ToR - move.FromR;
		int dc = move.ToC - move.FromC;
		return (Math.Abs(dr) == 2 && dc == 0) || (Math.Abs(dc) == 2 && dr == 0);
	}

	private static bool DoesCaptureOpponentPin(PinMove move, int[,] pins, PlayerColor opponent)
	{
		int midR = (move.FromR + move.ToR) / 2;
		int midC = (move.FromC + move.ToC) / 2;
		return pins[midR, midC] == (int)opponent;
	}
}
