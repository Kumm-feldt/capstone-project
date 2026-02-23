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
    public static int[,] discs = new int[6, 6];
    // -1 = Dark pin, 0 = Empty, +1 = Light pin
    public static int[,] pins = new int[7, 7];
    public static string? BoardString { get; set; }
    public static string? MoveString { get; set; }

    // Holds the current player's turn
    public static PlayerColor CurrentPlayer { get; set; }

    // Direction vectors for legal move generation
    private static readonly (int, int)[] OrthogonalOffsets = { (1, 0), (-1, 0), (0, 1), (0, -1) };
    private static readonly (int, int)[] DiagonalOffsets = { (1, 1), (1, -1), (-1, 1), (-1, -1) };
    private static readonly (int, int)[] CaptureOffsets = { (2, 0), (-2, 0), (0, 2), (0, -2) };

    // Initializes the game state with starting positions and sets the current player to Light
    public static void Initialize(bool test = false, int testScenario = 0)
    {
        // Reset both boards to an empty state.
        Array.Clear(discs, 0, discs.Length);
        Array.Clear(pins, 0, pins.Length);

        // Seed immutable base discs in the four corners.
        discs[0, 5] = 1; // Light home base disc
        discs[5, 0] = 1; // Light goal base disc
        discs[0, 0] = -1; // Dark home base disc
        discs[5, 5] = -1; // Dark goal base disc

        // Fill pins using standard setup or a requested test scenario.
        PlaceInitialPins(test, testScenario);

        // Light always starts.
        CurrentPlayer = PlayerColor.Light;
    }

    // Rebuild game state from an encoded board string.
    public static void InitializeFromString(string boardString)
    {
        // Clear current state before loading serialized data.
        Array.Clear(discs, 0, discs.Length);
        Array.Clear(pins, 0, pins.Length);

        // Reuse Board parsing logic so conversion stays in one place.
        var tempBoard = new Board(pins, discs);
        tempBoard.ConvertStringToBoard(boardString);
    }

    // Function to place initial pins based on standard setup or for testing specific scenarios
    private static void PlaceInitialPins(bool test = false, int testScenario = 0)
    {
        int light = (int)PlayerColor.Light;
        int dark = (int)PlayerColor.Dark;

        // Normal game opening with 8 pins per player.
        if (!test)
        {
            // Dark pins
            pins[0, 1] = dark;
            pins[0, 2] = dark;
            pins[1, 0] = dark;
            pins[2, 0] = dark;
            pins[4, 6] = dark;
            pins[5, 6] = dark;
            pins[6, 4] = dark;
            pins[6, 5] = dark;
            // White pins
            pins[0, 4] = light;
            pins[0, 5] = light;
            pins[1, 6] = light;
            pins[2, 6] = light;
            pins[4, 0] = light;
            pins[5, 0] = light;
            pins[6, 1] = light;
            pins[6, 2] = light;
        }
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

    // Placeholder for AI move selection logic. Currently selects a random legal move
    public static PinMove? GetBestMove(Board board, PlayerColor player)
    {
        // Gather all legal actions for the current position.
        var legalMoves = GetLegalMoves(board, player);
        if (legalMoves.Count == 0) return null;

        // Temporary policy: pick uniformly at random.
        var rand = new Random();
        return legalMoves[rand.Next(legalMoves.Count)];
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

    // Applies the given move to the game state, updating pins, discs, and switching turns
    public static void ApplyMove(PinMove move)
    {
        // Snapshot the active player so move resolution is consistent through this method.
        int player = (int)CurrentPlayer;

        // Relocate the pin from source to destination.
        pins[move.FromR, move.FromC] = 0;
        pins[move.ToR, move.ToC] = player;

        // Compute move vector to classify move type.
        int dr = move.ToR - move.FromR;
        int dc = move.ToC - move.FromC;

        // Capture logic
        if ((Math.Abs(dr) == 2 && dc == 0) || (Math.Abs(dc) == 2 && dr == 0))
        {
            int midR = (move.FromR + move.ToR) / 2;
            int midC = (move.FromC + move.ToC) / 2;
            pins[midR, midC] = 0; // remove captured pin
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
                if (discs[dgR, dgC] == 0)
                    discs[dgR, dgC] = player;
                else if (discs[dgR, dgC] == -player)
                    discs[dgR, dgC] = player;
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

    // Checks if the game has reached a terminal state (win/loss/draw) and identifies the winner if applicable
    public static bool IsTerminal(out int winner)
    {
        // Default to no winner, then check each player for a completed path.
        winner = 0;

        if (HasWinningPath(PlayerColor.Light))
            winner = (int)PlayerColor.Light;
        else if (HasWinningPath(PlayerColor.Dark))
            winner = (int)PlayerColor.Dark;
        // TODO: implement draw condition

        return winner != 0;
    }

    // Uses BFS to check if the given player has a connected path of discs from their home base to the opposite side
    private static bool HasWinningPath(PlayerColor player)
    {
        // Standard BFS over the 6x6 disc grid, restricted to the player's disc color.
        int color = (int)player;
        var visited = new bool[6,6];
        var queue = new Queue<(int r, int c)>();

        // Define home bases
        (int r, int c) start = player == PlayerColor.Light ? (0,5) : (0,0);
        (int r, int c) goal  = player == PlayerColor.Light ? (5,0) : (5,5);

        // Start if adjacent disc matches
        if (discs[start.r, start.c] != color)
            return false;

        // Seed BFS from the player's home base disc.
        queue.Enqueue(start);
        visited[start.r, start.c] = true;

        int[] dr = { -1, 1, 0, 0 };
        int[] dc = { 0, 0, -1, 1 };

        while (queue.Count > 0)
        {
            var (r, c) = queue.Dequeue();

            // Reaching the goal base means the player has a winning connection.
            if (r == goal.r && c == goal.c)
                return true;

            for (int i = 0; i < 4; i++)
            {
                int nr = r + dr[i];
                int nc = c + dc[i];

                if (!InDG(nr, nc)) continue;
                if (visited[nr, nc]) continue;
                if (discs[nr, nc] != color) continue;

                // Visit each matching orthogonal neighbor once.
                visited[nr, nc] = true;
                queue.Enqueue((nr, nc));
            }
        }

        return false;
    }

    // Prints a text representation of both boards with pins integrated into disc grid borders
    public static void PrintBoard()
    {
        // Glyphs used to draw dark and light discs in console output.
        char darkDisc = '\u2591';
        char lightDisc = '\u2588';

        Console.WriteLine();
        
        // Column numbers header
        Console.Write("    ");
        for (int c = 0; c < 7; c++) 
        {
            Console.Write($"{c}   ");
        }
        Console.WriteLine();
        
        for (int r = 0; r < 7; r++)
        {
            // Border line with pins integrated (only for pin grid columns 0-6)
            Console.Write($"  {r} ");
            for (int c = 0; c < 6; c++)
            {
                if (pins[r, c] == 1)
                    Console.Write("L---");
                else if (pins[r, c] == -1)
                    Console.Write("D---");
                else
                    Console.Write("+---");
            }
            if (pins[r, 6] == 1)
                Console.Write("L");
            else if (pins[r, 6] == -1)
                Console.Write("D");
            else
                Console.Write("+");
            Console.WriteLine();
            
            // Disc row (if applicable)
            if (r < 6)
            {
                // Print the 6x6 disc row between pin-border rows.
                Console.Write("    ");
                Console.Write("|");
                for (int c = 0; c < 6; c++)
                {
                    if (discs[r, c] == 1)
                        Console.Write($" {lightDisc} |");
                    else if (discs[r, c] == -1)
                        Console.Write($" {darkDisc} |");
                    else
                        Console.Write("   |");
                }
                Console.WriteLine();
            }
        }
        
        Console.WriteLine();
    }

    // Utility functions for move validation and generation
    private static bool InDG(int r, int c)
    {
        // Disc grid is valid for row/col indices [0..5].
        return r >= 0 && r < 6 && c >= 0 && c < 6;
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
