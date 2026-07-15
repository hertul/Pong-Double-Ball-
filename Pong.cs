// Pong.cs
using System;
using System.Collections.Generic;
using System.Threading;

class Ball
{
    public double X, Y, DX, DY, Speed;
    public char Char;
    public Ball(double x, double y, double dx, double dy, char ch)
    {
        X = x; Y = y; DX = dx; DY = dy; Char = ch; Speed = 0.8 + new Random().NextDouble() * 0.4;
    }
}

class Pong
{
    const int W = 40, H = 20;
    List<Ball> balls = new List<Ball>();
    int paddleH = 4;
    int playerY, aiY;
    int scorePlayer = 0, scoreAI = 0;
    int winScore = 5;
    bool gameOver = false;
    bool running = true;
    int paddleSpeed = 1;
    Random rand = new Random();

    public Pong()
    {
        playerY = H / 2 - paddleH / 2;
        aiY = H / 2 - paddleH / 2;
        InitBalls();
        Thread inputThread = new Thread(InputLoop);
        inputThread.IsBackground = true;
        inputThread.Start();
        while (running)
        {
            UpdateAI();
            UpdateBalls();
            Render();
            Thread.Sleep(16);
        }
    }

    void InitBalls()
    {
        balls.Clear();
        balls.Add(new Ball(W/2, H/2, -1, -0.5, 'O'));
        balls.Add(new Ball(W/2, H/2, 1, 0.5, 'o'));
    }

    void DrawBorder()
    {
        for (int x = 0; x < W; x++)
        {
            Console.SetCursorPosition(x, 0);
            Console.Write('#');
            Console.SetCursorPosition(x, H - 1);
            Console.Write('#');
        }
        for (int y = 0; y < H; y++)
        {
            Console.SetCursorPosition(0, y);
            Console.Write('#');
            Console.SetCursorPosition(W - 1, y);
            Console.Write('#');
        }
        for (int y = 1; y < H - 1; y++)
        {
            Console.SetCursorPosition(W / 2, y);
            Console.Write('|');
        }
    }

    void DrawPaddles()
    {
        for (int i = 0; i < paddleH; i++)
        {
            Console.SetCursorPosition(2, playerY + i);
            Console.Write(']');
            Console.SetCursorPosition(W - 3, aiY + i);
            Console.Write('[');
        }
    }

    void DrawBalls()
    {
        foreach (var b in balls)
        {
            if (b.X > 0 && b.X < W - 1 && b.Y > 0 && b.Y < H - 1)
            {
                Console.SetCursorPosition((int)b.X, (int)b.Y);
                Console.Write(b.Char);
            }
        }
    }

    void DrawScore()
    {
        Console.SetCursorPosition(W / 2 - 2, 1);
        Console.Write($"{scorePlayer} : {scoreAI}");
        if (gameOver)
        {
            string winner = scorePlayer >= winScore ? "Player" : "AI";
            Console.SetCursorPosition(W / 2 - winner.Length / 2, H / 2);
            Console.Write($"{winner} WINS!");
            Console.SetCursorPosition(W / 2 - 8, H / 2 + 1);
            Console.Write("Press R to restart");
        }
    }

    void ResetBall(int idx, int dir)
    {
        var b = balls[idx];
        b.X = W / 2;
        b.Y = H / 2;
        b.DX = dir * (0.5 + rand.NextDouble() * 0.5);
        b.DY = (rand.NextDouble() - 0.5) * 0.8;
        b.Speed = 0.8 + rand.NextDouble() * 0.4;
        if (b.DY == 0) b.DY = 0.3 * (rand.Next(2) == 0 ? 1 : -1);
    }

    void UpdateBalls()
    {
        if (gameOver) return;
        for (int i = 0; i < balls.Count; i++)
        {
            var b = balls[i];
            b.X += b.DX * b.Speed;
            b.Y += b.DY * b.Speed;
            if (b.Y <= 1 || b.Y >= H - 2) b.DY *= -1;
            if (b.X <= 3 && (int)b.Y >= playerY && (int)b.Y < playerY + paddleH)
            {
                b.DX *= -1;
                b.X = 4;
                b.Speed = Math.Min(2.0, b.Speed * 1.05);
            }
            if (b.X >= W - 4 && (int)b.Y >= aiY && (int)b.Y < aiY + paddleH)
            {
                b.DX *= -1;
                b.X = W - 5;
                b.Speed = Math.Min(2.0, b.Speed * 1.05);
            }
            if (b.X <= 0)
            {
                scoreAI++;
                ResetBall(i, 1);
                if (scoreAI >= winScore) gameOver = true;
            }
            else if (b.X >= W - 1)
            {
                scorePlayer++;
                ResetBall(i, -1);
                if (scorePlayer >= winScore) gameOver = true;
            }
        }
    }

    void UpdateAI()
    {
        double targetY = H / 2;
        foreach (var b in balls)
            if (b.DX > 0 && b.X > W / 2) { targetY = b.Y; break; }
        if (targetY > aiY + paddleH / 2 + 1) aiY += paddleSpeed;
        else if (targetY < aiY + paddleH / 2 - 1) aiY -= paddleSpeed;
        aiY = Math.Max(1, Math.Min(H - paddleH - 1, aiY));
    }

    void MovePlayer(int dy)
    {
        if (gameOver) return;
        int newY = playerY + dy;
        if (newY >= 1 && newY <= H - paddleH - 1) playerY = newY;
    }

    void Restart()
    {
        playerY = H / 2 - paddleH / 2;
        aiY = H / 2 - paddleH / 2;
        scorePlayer = 0;
        scoreAI = 0;
        gameOver = false;
        InitBalls();
    }

    void InputLoop()
    {
        while (running)
        {
            var key = Console.ReadKey(true);
            switch (key.Key)
            {
                case ConsoleKey.R:
                    if (gameOver) Restart();
                    break;
                case ConsoleKey.W:
                    MovePlayer(-1);
                    break;
                case ConsoleKey.S:
                    MovePlayer(1);
                    break;
                case ConsoleKey.UpArrow:
                    MovePlayer(-1);
                    break;
                case ConsoleKey.DownArrow:
                    MovePlayer(1);
                    break;
                case ConsoleKey.Q:
                    running = false;
                    return;
            }
        }
    }

    void Render()
    {
        Console.Clear();
        DrawBorder();
        DrawPaddles();
        DrawBalls();
        DrawScore();
    }

    static void Main()
    {
        Console.CursorVisible = false;
        new Pong();
    }
}
