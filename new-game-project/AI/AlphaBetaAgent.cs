using System;
using System.Collections.Generic;
using System.Linq;
using CreeperAI;

public static class AlphaBetaAgent
{
    // Large terminal value used to strongly prefer forced wins/losses.
    private const int WinScore = 100000;
    // Practical infinity for alpha-beta bounds.
    private const int Infinity = 1_000_000_000;
    // Small penalty to discourage lines that stall into no-progress states.
    private const int DrawPenalty = 20;

    // Entry point: pick the best move for currentPlayer using depth-limited negamax.
    public static PinMove ChooseMove(int[,] pins, int[,] discs, PlayerColor currentPlayer, int depth, List<PinMove> legalMoves = null)
    {
        // Reuse caller-provided legal moves when available to avoid recomputation.
        var legal = legalMoves ?? Game.GetLegalMoves(new Board(pins, discs), currentPlayer);
        legal = FilterOutLastPinCaptureMovesForAI(legal, pins, currentPlayer, currentPlayer);
        if (legal.Count == 0)
            throw new InvalidOperationException("No legal moves available for alpha-beta selection.");

        int bestScore = int.MinValue;
        int alpha = -Infinity;
        int beta = Infinity;
        PinMove bestMove = legal[0];

        var orderedMoves = OrderMoves(legal, pins, discs, currentPlayer);
        foreach (var move in orderedMoves)
        {
            // Search on cloned boards so each branch is isolated.
            var pinsNext = (int[,])pins.Clone();
            var discsNext = (int[,])discs.Clone();
            var nextPlayer = ApplyMoveToCopies(pinsNext, discsNext, currentPlayer, move);

            // Negamax flips perspective each ply, so child score is negated.
            int score = -Negamax(pinsNext, discsNext, nextPlayer, depth - 1, -beta, -alpha, currentPlayer);
            if (score > bestScore)
            {
                bestScore = score;
                bestMove = move;
            }

            // Track the best lower bound seen at root.
            if (score > alpha)
                alpha = score;
        }

        return bestMove;
    }

    // Core alpha-beta negamax recursion from the perspective of playerToMove.
    private static int Negamax(int[,] pins, int[,] discs, PlayerColor playerToMove, int depth, int alpha, int beta, PlayerColor aiPlayer)
    {
        // Immediate terminal check based on completed disc paths.
        int winner = WinnerFromDiscs(discs);
        if (winner != 0)
        {
            // Depth bonus prefers faster wins and slower losses.
            if (winner == (int)playerToMove)
                return WinScore + depth;
            return -WinScore - depth;
        }

        // At horizon, fall back to static board evaluation.
        if (depth <= 0)
            return Evaluate(discs, pins, playerToMove, aiPlayer);

        var legal = Game.GetLegalMoves(new Board(pins, discs), playerToMove);
        legal = FilterOutLastPinCaptureMovesForAI(legal, pins, playerToMove, aiPlayer);
        if (legal.Count == 0)
            return -DrawPenalty;

        var orderedMoves = OrderMoves(legal, pins, discs, playerToMove);

        int best = -Infinity;
        foreach (var move in orderedMoves)
        {
            var pinsNext = (int[,])pins.Clone();
            var discsNext = (int[,])discs.Clone();
            var nextPlayer = ApplyMoveToCopies(pinsNext, discsNext, playerToMove, move);

            int score = -Negamax(pinsNext, discsNext, nextPlayer, depth - 1, -beta, -alpha, aiPlayer);
            if (score > best)
                best = score;

            if (score > alpha)
                alpha = score;

            // Standard alpha-beta cutoff: remaining siblings cannot improve result.
            if (alpha >= beta)
                break;
        }

        return best;
    }

    // Heuristic evaluation for material, connectivity pressure, and mobility.
    private static int Evaluate(int[,] discs, int[,] pins, PlayerColor playerToMove, PlayerColor aiPlayer)
    {
        int player = (int)playerToMove;
        int opponent = -player;
        var opponentColor = playerToMove == PlayerColor.Light ? PlayerColor.Dark : PlayerColor.Light;

        // Material signals: owned discs matter most, pins matter less.
        int discDiff = CountCells(discs, player) - CountCells(discs, opponent);
        int pinDiff = CountCells(pins, player) - CountCells(pins, opponent);

        // Connection cost is lower when a player is closer to a completed path.
        int rootCost = ConnectionCost(discs, player);
        int oppCost = ConnectionCost(discs, opponent);

        int pathScore = PathCostToScore(oppCost) - PathCostToScore(rootCost);
        int progressPressure = Math.Clamp(oppCost - rootCost, -8, 8);

        // Mobility discourages positions that self-trap while enabling the opponent.
        int mobilitySelf = Game.GetLegalMoves(new Board(pins, discs), playerToMove).Count;
        int mobilityOpp = Game.GetLegalMoves(new Board(pins, discs), opponentColor).Count;
        int mobilityDiff = mobilitySelf - mobilityOpp;

        // Compare immediate tactical safety: threatened own pins vs threatened opponent pins.
        int threatenedSelf = CountImmediateCaptureTargets(pins, discs, opponentColor, aiPlayer);
        int threatenedOpp = CountImmediateCaptureTargets(pins, discs, playerToMove, aiPlayer);
        int safetyDiff = threatenedOpp - threatenedSelf;

        // Penalize stagnant positions where the side to move is not improving path cost.
        int noProgressPenalty = 0;
        if (rootCost >= oppCost)
            noProgressPenalty += 16;
        if (rootCost >= 1_000_000)
            noProgressPenalty += 16;

        return (discDiff * 10) + (pinDiff * 1) + (pathScore * 42) + (progressPressure * 12) + (mobilityDiff * 4) + (safetyDiff * 8) - noProgressPenalty - DrawPenalty;
    }

    // Lightweight move ordering to improve alpha-beta cutoffs.
    private static List<PinMove> OrderMoves(List<PinMove> legalMoves, int[,] pins, int[,] discs, PlayerColor playerToMove)
    {
        int player = (int)playerToMove;
        int currentCost = ConnectionCost(discs, player);

        return legalMoves
            .Select(move =>
            {
                int score = 0;

                int dr = move.ToR - move.FromR;
                int dc = move.ToC - move.FromC;
                bool isCapture = (Math.Abs(dr) == 2 && dc == 0) || (Math.Abs(dc) == 2 && dr == 0);
                bool isDiagonal = Math.Abs(dr) == 1 && Math.Abs(dc) == 1;

                // Prioritize tactical captures.
                if (isCapture)
                    score += 24;
                if (isDiagonal)
                {
                    // Prefer diagonal moves, especially those that can claim/flip a disc.
                    score += 12;
                    int dgR = Math.Min(move.FromR, move.ToR);
                    int dgC = Math.Min(move.FromC, move.ToC);
                    if (dgR >= 0 && dgR < 6 && dgC >= 0 && dgC < 6 && !IsBaseSquare(dgR, dgC) && discs[dgR, dgC] != player)
                        score += 30;
                }

                var pinsNext = (int[,])pins.Clone();
                var discsNext = (int[,])discs.Clone();
                ApplyMoveToCopies(pinsNext, discsNext, playerToMove, move);
                int nextCost = ConnectionCost(discsNext, player);

                // Reward moves that reduce the mover's path cost to goal.
                if (nextCost < currentCost)
                    score += Math.Min(40, (currentCost - nextCost) * 8);

                return (move, score);
            })
            .OrderByDescending(x => x.score)
            .Select(x => x.move)
            .ToList();
    }

    // Count unique defender pins that can be captured immediately by attacker.
    private static int CountImmediateCaptureTargets(int[,] pins, int[,] discs, PlayerColor attacker, PlayerColor aiPlayer)
    {
        var legal = Game.GetLegalMoves(new Board(pins, discs), attacker);
        legal = FilterOutLastPinCaptureMovesForAI(legal, pins, attacker, aiPlayer);
        var threatenedPins = new HashSet<(int r, int c)>();

        foreach (var move in legal)
        {
            int dr = move.ToR - move.FromR;
            int dc = move.ToC - move.FromC;
            bool isCapture = (Math.Abs(dr) == 2 && dc == 0) || (Math.Abs(dc) == 2 && dr == 0);
            if (!isCapture)
                continue;

            int midR = (move.FromR + move.ToR) / 2;
            int midC = (move.FromC + move.ToC) / 2;
            threatenedPins.Add((midR, midC));
        }

        return threatenedPins.Count;
    }

    // Enforce the house rule: the AI may not capture the opponent's final remaining pin.
    private static List<PinMove> FilterOutLastPinCaptureMovesForAI(List<PinMove> legalMoves, int[,] pins, PlayerColor playerToMove, PlayerColor aiPlayer)
    {
        if (playerToMove != aiPlayer)
            return legalMoves;

        var opponent = aiPlayer == PlayerColor.Light ? PlayerColor.Dark : PlayerColor.Light;
        if (CountPinsForPlayer(pins, opponent) != 1)
            return legalMoves;

        var filtered = new List<PinMove>(legalMoves.Count);
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
            for (int c = 0; c < 7; c++)
                if (pins[r, c] == value)
                    total++;

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

    // Convert path cost into a bounded score contribution for evaluation blending.
    private static int PathCostToScore(int cost)
    {
        const int inf = 1_000_000;
        if (cost >= inf)
            return -12;

        return Math.Max(-12, 12 - cost);
    }

    // Count how many cells in a grid belong to a given side/value.
    private static int CountCells(int[,] grid, int value)
    {
        int rows = grid.GetLength(0);
        int cols = grid.GetLength(1);
        int total = 0;

        for (int r = 0; r < rows; r++)
            for (int c = 0; c < cols; c++)
                if (grid[r, c] == value)
                    total++;

        return total;
    }

    // Apply a move to temporary board copies and return the next side to move.
    private static PlayerColor ApplyMoveToCopies(int[,] pins, int[,] discs, PlayerColor currentPlayer, PinMove move)
    {
        int player = (int)currentPlayer;

        pins[move.FromR, move.FromC] = 0;
        pins[move.ToR, move.ToC] = player;

        int dr = move.ToR - move.FromR;
        int dc = move.ToC - move.FromC;

        // Capture jumps remove the jumped pin in the midpoint.
        if ((Math.Abs(dr) == 2 && dc == 0) || (Math.Abs(dc) == 2 && dr == 0))
        {
            int midR = (move.FromR + move.ToR) / 2;
            int midC = (move.FromC + move.ToC) / 2;
            pins[midR, midC] = 0;
        }

        // Diagonal moves may claim/flip the mapped disc cell (except fixed corners).
        if (Math.Abs(dr) == 1 && Math.Abs(dc) == 1)
        {
            int dgR = Math.Min(move.FromR, move.ToR);
            int dgC = Math.Min(move.FromC, move.ToC);

            if (dgR >= 0 && dgR < 6 && dgC >= 0 && dgC < 6 && !IsBaseSquare(dgR, dgC))
            {
                if (discs[dgR, dgC] == 0 || discs[dgR, dgC] == -player)
                    discs[dgR, dgC] = player;
            }
        }

        return currentPlayer == PlayerColor.Light ? PlayerColor.Dark : PlayerColor.Light;
    }

    // Corner/base discs are immutable and excluded from conversion logic.
    private static bool IsBaseSquare(int r, int c)
    {
        return (r == 0 && c == 0) || (r == 0 && c == 5) || (r == 5 && c == 0) || (r == 5 && c == 5);
    }

    // Winner detection from discs only: completed path for either side.
    private static int WinnerFromDiscs(int[,] discs)
    {
        if (HasWinningPath(discs, PlayerColor.Light))
            return 1;
        if (HasWinningPath(discs, PlayerColor.Dark))
            return -1;
        return 0;
    }

    // Breadth-first search over same-color orthogonal adjacency.
    private static bool HasWinningPath(int[,] discs, PlayerColor player)
    {
        int color = (int)player;
        var visited = new bool[6, 6];
        var queue = new Queue<(int r, int c)>();

        (int r, int c) start = player == PlayerColor.Light ? (0, 5) : (0, 0);
        (int r, int c) goal = player == PlayerColor.Light ? (5, 0) : (5, 5);

        if (discs[start.r, start.c] != color)
            return false;

        queue.Enqueue(start);
        visited[start.r, start.c] = true;

        int[] dr = { -1, 1, 0, 0 };
        int[] dc = { 0, 0, -1, 1 };

        while (queue.Count > 0)
        {
            var (r, c) = queue.Dequeue();
            if (r == goal.r && c == goal.c)
                return true;

            for (int i = 0; i < 4; i++)
            {
                int nr = r + dr[i];
                int nc = c + dc[i];

                if (nr < 0 || nr >= 6 || nc < 0 || nc >= 6)
                    continue;
                if (visited[nr, nc])
                    continue;
                if (discs[nr, nc] != color)
                    continue;

                visited[nr, nc] = true;
                queue.Enqueue((nr, nc));
            }
        }

        return false;
    }

    // Dijkstra-style shortest connection cost where own discs cost 0 and neutral discs cost 1.
    private static int ConnectionCost(int[,] discs, int player)
    {
        const int inf = 1_000_000;
        (int r, int c) start = player == 1 ? (0, 5) : (0, 0);
        (int r, int c) goal = player == 1 ? (5, 0) : (5, 5);

        // If the start base is not owned, no path is currently possible.
        if (discs[start.r, start.c] != player)
            return inf;

        var dist = new int[6, 6];
        for (int r = 0; r < 6; r++)
            for (int c = 0; c < 6; c++)
                dist[r, c] = inf;

        var pq = new PriorityQueue<(int r, int c), int>();
        dist[start.r, start.c] = 0;
        pq.Enqueue(start, 0);

        int[] dr = { -1, 1, 0, 0 };
        int[] dc = { 0, 0, -1, 1 };

        while (pq.Count > 0)
        {
            var current = pq.Dequeue();
            int curDist = dist[current.r, current.c];

            if (current == goal)
                return curDist;

            for (int i = 0; i < 4; i++)
            {
                int nr = current.r + dr[i];
                int nc = current.c + dc[i];
                if (nr < 0 || nr >= 6 || nc < 0 || nc >= 6)
                    continue;

                if (discs[nr, nc] == -player)
                    continue;

                // Moving through own discs is free; neutral discs cost one conversion step.
                int stepCost = discs[nr, nc] == player ? 0 : 1;
                int nd = curDist + stepCost;

                if (nd < dist[nr, nc])
                {
                    dist[nr, nc] = nd;
                    pq.Enqueue((nr, nc), nd);
                }
            }
        }

        return inf;
    }
}
