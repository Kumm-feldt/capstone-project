using System;
using System.Collections.Generic;
using System.Linq;
using CreeperAI;

public static class AlphaBetaAgent
{
    private const int WinScore = 100000;
    private const int Infinity = 1_000_000_000;
    private const int DrawPenalty = 20;

    public static PinMove ChooseMove(int[,] pins, int[,] discs, PlayerColor currentPlayer, int depth, List<PinMove> legalMoves = null)
    {
        var legal = legalMoves ?? Game.GetLegalMoves(new Board(pins, discs), currentPlayer);
        if (legal.Count == 0)
            throw new InvalidOperationException("No legal moves available for alpha-beta selection.");

        int bestScore = int.MinValue;
        int alpha = -Infinity;
        int beta = Infinity;
        PinMove bestMove = legal[0];

        var orderedMoves = OrderMoves(legal, pins, discs, currentPlayer);
        foreach (var move in orderedMoves)
        {
            var pinsNext = (int[,])pins.Clone();
            var discsNext = (int[,])discs.Clone();
            var nextPlayer = ApplyMoveToCopies(pinsNext, discsNext, currentPlayer, move);

            int score = -Negamax(pinsNext, discsNext, nextPlayer, depth - 1, -beta, -alpha);
            if (score > bestScore)
            {
                bestScore = score;
                bestMove = move;
            }

            if (score > alpha)
                alpha = score;
        }

        return bestMove;
    }

    private static int Negamax(int[,] pins, int[,] discs, PlayerColor playerToMove, int depth, int alpha, int beta)
    {
        int winner = WinnerFromDiscs(discs);
        if (winner != 0)
        {
            if (winner == (int)playerToMove)
                return WinScore + depth;
            return -WinScore - depth;
        }

        if (depth <= 0)
            return Evaluate(discs, pins, playerToMove);

        var legal = Game.GetLegalMoves(new Board(pins, discs), playerToMove);
        if (legal.Count == 0)
            return -DrawPenalty;

        var orderedMoves = OrderMoves(legal, pins, discs, playerToMove);

        int best = -Infinity;
        foreach (var move in orderedMoves)
        {
            var pinsNext = (int[,])pins.Clone();
            var discsNext = (int[,])discs.Clone();
            var nextPlayer = ApplyMoveToCopies(pinsNext, discsNext, playerToMove, move);

            int score = -Negamax(pinsNext, discsNext, nextPlayer, depth - 1, -beta, -alpha);
            if (score > best)
                best = score;

            if (score > alpha)
                alpha = score;

            if (alpha >= beta)
                break;
        }

        return best;
    }

    private static int Evaluate(int[,] discs, int[,] pins, PlayerColor playerToMove)
    {
        int player = (int)playerToMove;
        int opponent = -player;

        int discDiff = CountCells(discs, player) - CountCells(discs, opponent);
        int pinDiff = CountCells(pins, player) - CountCells(pins, opponent);

        int rootCost = ConnectionCost(discs, player);
        int oppCost = ConnectionCost(discs, opponent);

        int pathScore = PathCostToScore(oppCost) - PathCostToScore(rootCost);
        int progressPressure = Math.Clamp(oppCost - rootCost, -8, 8);

        int mobilitySelf = Game.GetLegalMoves(new Board(pins, discs), playerToMove).Count;
        var opponentColor = playerToMove == PlayerColor.Light ? PlayerColor.Dark : PlayerColor.Light;
        int mobilityOpp = Game.GetLegalMoves(new Board(pins, discs), opponentColor).Count;
        int mobilityDiff = mobilitySelf - mobilityOpp;

        int noProgressPenalty = 0;
        if (rootCost >= oppCost)
            noProgressPenalty += 12;
        if (rootCost >= 1_000_000)
            noProgressPenalty += 12;

        return (discDiff * 10) + (pinDiff * 3) + (pathScore * 36) + (progressPressure * 12) + (mobilityDiff * 2) - noProgressPenalty - DrawPenalty;
    }

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

                if (isCapture)
                    score += 60;
                if (isDiagonal)
                {
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

                if (nextCost < currentCost)
                    score += Math.Min(40, (currentCost - nextCost) * 8);

                return (move, score);
            })
            .OrderByDescending(x => x.score)
            .Select(x => x.move)
            .ToList();
    }

    private static int PathCostToScore(int cost)
    {
        const int inf = 1_000_000;
        if (cost >= inf)
            return -12;

        return Math.Max(-12, 12 - cost);
    }

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

    private static PlayerColor ApplyMoveToCopies(int[,] pins, int[,] discs, PlayerColor currentPlayer, PinMove move)
    {
        int player = (int)currentPlayer;

        pins[move.FromR, move.FromC] = 0;
        pins[move.ToR, move.ToC] = player;

        int dr = move.ToR - move.FromR;
        int dc = move.ToC - move.FromC;

        if ((Math.Abs(dr) == 2 && dc == 0) || (Math.Abs(dc) == 2 && dr == 0))
        {
            int midR = (move.FromR + move.ToR) / 2;
            int midC = (move.FromC + move.ToC) / 2;
            pins[midR, midC] = 0;
        }

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

    private static bool IsBaseSquare(int r, int c)
    {
        return (r == 0 && c == 0) || (r == 0 && c == 5) || (r == 5 && c == 0) || (r == 5 && c == 5);
    }

    private static int WinnerFromDiscs(int[,] discs)
    {
        if (HasWinningPath(discs, PlayerColor.Light))
            return 1;
        if (HasWinningPath(discs, PlayerColor.Dark))
            return -1;
        return 0;
    }

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

    private static int ConnectionCost(int[,] discs, int player)
    {
        const int inf = 1_000_000;
        (int r, int c) start = player == 1 ? (0, 5) : (0, 0);
        (int r, int c) goal = player == 1 ? (5, 0) : (5, 5);

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
