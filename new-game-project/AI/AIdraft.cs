using System.Runtime.InteropServices;

namespace CreeperAI;

public enum PlayerColor
{
    Dark = -1,
    Light = 1
}

public record PinMove(int FromR, int FromC, int ToR, int ToC);

// class for the board state and utility functions
public class Board
{
    private int[,] _pins;
    private int[,] _discs;

    public int[,] Pins => _pins;
    public int[,] Discs => _discs;

    // Store references to the live pin and disc grids used by the game.
    public Board(int[,] pins, int[,] discs)
    {
        _pins = pins;
        _discs = discs;
    }

    // Scan the 7x7 pin grid and return all coordinates occupied by the requested player.
    public List<(int R, int C)> GetPins(PlayerColor player)
    {
        var result = new List<(int, int)>();
        for (int r = 0; r < 7; r++)
            for (int c = 0; c < 7; c++)
                if (_pins[r, c] == (int)player)
                    result.Add((r, c));
        return result;
    }

    // String has 86 characters: 49 for pins (7x7), 36 for discs (6x6) and 1 for current player
    //     'x' = Light pin/disc, 'o' = Dark pin/disc, '.' = Empty pin/disc grid
    //     Example (initial state): ".oo.xx.o.....xo.....x.......x.....ox.....o.xx.oo.o....x........................x....ox"
    public void ConvertStringToBoard(string boardString)
    {
        // Validate the serialized state length before reading indices.
        if (boardString.Length != 86)
            throw new ArgumentException("Board string must be exactly 86 characters long.");

        // Parse the first 49 characters into the 7x7 pin grid.
        for (int i = 0; i < 49; i++)
        {
            char ch = boardString[i];
            int r = i / 7;
            int c = i % 7;

            _pins[r, c] = ch switch
            {
                'x' => 1,
                'o' => -1,
                '.' => 0,
                _ => throw new ArgumentException($"Invalid character '{ch}' in board string.")
            };
        }

        // Parse the next 36 characters into the 6x6 disc grid.
        for (int i = 49; i < 85; i++)
        {
            char ch = boardString[i];
            int idx = i - 49;
            int r = idx / 6;
            int c = idx % 6;

            _discs[r, c] = ch switch
            {
                'x' => 1,
                'o' => -1,
                '.' => 0,
                _ => throw new ArgumentException($"Invalid character '{ch}' in board string.")
            };
        }
    }

    public void ConvertBoardToString(char[] boardString, PlayerColor currentPlayer)
    {
        if (boardString == null || boardString.Length != 86)
            throw new ArgumentException("Board string buffer must be exactly 86 chars.");

        // Convert the 7x7 pin grid into the first 49 characters of the string.
        for (int r = 0; r < 7; r++)
            for (int c = 0; c < 7; c++)
            {
                char ch = _pins[r, c] switch
                {
                    1 => 'x',
                    -1 => 'o',
                    0 => '.',
                    _ => throw new InvalidOperationException($"Invalid pin value {_pins[r, c]} at ({r},{c}).")
                };
                boardString[r * 7 + c] = ch;
            }

        // Convert the 6x6 disc grid into the next 36 characters of the string.
        for (int r = 0; r < 6; r++)
            for (int c = 0; c < 6; c++)
            {
                char ch = _discs[r, c] switch
                {
                    1 => 'x',
                    -1 => 'o',
                    0 => '.',
                    _ => throw new InvalidOperationException($"Invalid disc value {_discs[r, c]} at ({r},{c}).")
                };
                boardString[49 + r * 6 + c] = ch;
            }

        // Set the final character (index 85) to represent the current player.
        boardString[85] = currentPlayer == PlayerColor.Light ? 'x' : 'o';
    }

    public bool IsEmptyPG(int r, int c) => _pins[r, c] == 0;

    // Check bounds first, then confirm the target pin belongs to the opposing player.
    public bool HasOpponentPin(int r, int c, PlayerColor player)
    {
        if (r < 0 || r > 6 || c < 0 || c > 6) return false;
        return _pins[r, c] == -(int)player;
    }
}

// class for game logic
public static class Game
{
    // -1 = Dark disc, 0 = Empty, +1 = Light disc
    private static readonly int[,] _discs = new int[6, 6];
    // -1 = Dark pin, 0 = Empty, +1 = Light pin
    private static readonly int[,] _pins = new int[7, 7];

    // Single owned board instance for game state access.
    public static Board CurrentBoard { get; } = new Board(_pins, _discs);

    private static int[,] Discs => CurrentBoard.Discs;
    private static int[,] Pins => CurrentBoard.Pins;

    // Holds the current player's turn
    public static PlayerColor CurrentPlayer { get; set; }

    // Direction vectors for legal move generation
    private static readonly (int, int)[] OrthogonalOffsets = { (1, 0), (-1, 0), (0, 1), (0, -1) };
    private static readonly (int, int)[] DiagonalOffsets = { (1, 1), (1, -1), (-1, 1), (-1, -1) };
    private static readonly (int, int)[] CaptureOffsets = { (2, 0), (-2, 0), (0, 2), (0, -2) };

    // Rebuild game state from an encoded board string.
    public static void InitializeFromString(string boardString)
    {
        // Clear current state before loading serialized data.
        Array.Clear(Discs, 0, Discs.Length);
        Array.Clear(Pins, 0, Pins.Length);

        // Reuse Board parsing logic so conversion stays in one place.
        CurrentBoard.ConvertStringToBoard(boardString);
    }

    // Generates a list of legal moves for the given player based on the current board state
    public static List<PinMove> GetLegalMoves(Board board, PlayerColor player)
    {
        var moves = new List<PinMove>();

        // For every player pin, generate all move categories from that origin.
        foreach (var (r, c) in board.GetPins(player))
        {
            // Orthogonal moves
            foreach (var (dr, dc) in OrthogonalOffsets)
            {
                TryAddMove(board, r, c, r + dr, c + dc, moves);
            }

            // Diagonal DG jumps
            foreach (var (dr, dc) in DiagonalOffsets)
            {
                TryAddMove(board, r, c, r + dr, c + dc, moves);
            }

            // Capture jumps
            foreach (var (dr, dc) in CaptureOffsets)
            {
                TryAddCaptureMove(board, r, c, r + dr, c + dc, moves, player);
            }
        }

        return moves;
    }

    // Convert the move to the correct format
    //     Example: "0,3 -> 1,4" to c1d2
    //     Note: need to switch from 0-indexed row + column to alphabetic column + 1 indexed row
    public static string MoveToString(PinMove move)
    {
        // Convert numeric columns into chess-style letters.
        char fromCol = (char)('a' + move.FromC);
        char toCol = (char)('a' + move.ToC);

        // Convert 0-based rows into 1-based display indices.
        int fromRow = move.FromR + 1;
        int toRow = move.ToR + 1;

        // Return compact 4-character move notation.
        return $"{fromCol}{fromRow}{toCol}{toRow}";
    }

    public static string GetBoardString()
    {
        char[] serialized = new char[86];
        CurrentBoard.ConvertBoardToString(serialized, CurrentPlayer);
        return new string(serialized);
    }

    // Applies the given move to the game state, updating pins, discs, and switching turns
    public static void ApplyMove(PinMove move)
    {
        // Snapshot the active player so move resolution is consistent through this method.
        int player = (int)CurrentPlayer;

        // Relocate the pin from source to destination.
        Pins[move.FromR, move.FromC] = 0;
        Pins[move.ToR, move.ToC] = player;

        // Compute move vector to classify move type.
        int dr = move.ToR - move.FromR;
        int dc = move.ToC - move.FromC;

        // Capture logic
        if ((Math.Abs(dr) == 2 && dc == 0) || (Math.Abs(dc) == 2 && dr == 0))
        {
            int midR = (move.FromR + move.ToR) / 2;
            int midC = (move.FromC + move.ToC) / 2;
            Pins[midR, midC] = 0; // remove captured pin
        }

        // Diagonal DG interaction
        if (Math.Abs(dr) == 1 && Math.Abs(dc) == 1)
        {
            // Map the diagonal pin movement to its corresponding disc-grid cell.
            int dgR = Math.Min(move.FromR, move.ToR);
            int dgC = Math.Min(move.FromC, move.ToC);

            // Ignore home/goal bases (corners) so they never change color
            if (dgR >= 0 && dgR < 6 && dgC >= 0 && dgC < 6 && !IsBaseSquare(dgR, dgC))
            {
                // Claim neutral disc or convert opponent disc to current player.
                if (Discs[dgR, dgC] == 0)
                    Discs[dgR, dgC] = player;
                else if (Discs[dgR, dgC] == -player)
                    Discs[dgR, dgC] = player;
            }
        }

        // Switch turn
        CurrentPlayer = (CurrentPlayer == PlayerColor.Light)
            ? PlayerColor.Dark
            : PlayerColor.Light;
    }

    private static bool IsBaseSquare(int r, int c)
    {
        // Base discs are fixed and cannot be recolored by diagonal interactions.
        return (r == 0 && c == 0) || (r == 0 && c == 5) || (r == 5 && c == 0) || (r == 5 && c == 5);
    }

    // Checks if the given position is a valid pin grid location (not out of bounds or a corner)
    private static bool IsValidPG(int r, int c)
    {
        if (r < 0 || r > 6 || c < 0 || c > 6) return false;
        if ((r == 0 || r == 6) && (c == 0 || c == 6)) return false;
        return true;
    }

    // Validates if a capture move is legal by checking for an opponent's pin in the middle and an empty target position
    private static bool IsValidCapture(Board board, int fromR, int fromC, int toR, int toC, PlayerColor player)
    {
        // Capture requires jumping over a single opponent pin.
        int midR = (fromR + toR) / 2;
        int midC = (fromC + toC) / 2;

        // Destination must be empty and the midpoint must contain an opponent pin.
        return board.HasOpponentPin(midR, midC, player)
            && board.IsEmptyPG(toR, toC);
    }

    // Helper function to attempt adding a normal move to the list of legal moves if it's valid
    private static void TryAddMove(Board board, int fromR, int fromC, int toR, int toC, List<PinMove> moves)
    {
        if (IsValidPG(toR, toC) && board.IsEmptyPG(toR, toC))
        {
            moves.Add(new PinMove(fromR, fromC, toR, toC));
        }
    }

    // Helper function to attempt adding a capture move to the list of legal moves if it's valid
    private static void TryAddCaptureMove(Board board, int fromR, int fromC, int toR, int toC, List<PinMove> moves, PlayerColor player)
    {
        if (IsValidPG(toR, toC) && IsValidCapture(board, fromR, fromC, toR, toC, player))
        {
            moves.Add(new PinMove(fromR, fromC, toR, toC));
        }
    }
}