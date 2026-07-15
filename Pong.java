// Pong.java
import java.awt.*;
import java.awt.event.*;
import javax.swing.*;
import java.util.*;

class Ball {
    double x, y, dx, dy, speed;
    char ch;
    Ball(double x, double y, double dx, double dy, char ch) {
        this.x=x; this.y=y; this.dx=dx; this.dy=dy; this.ch=ch;
        speed = 0.8 + Math.random() * 0.4;
    }
}

public class Pong extends JPanel implements ActionListener, KeyListener {
    static final int W = 40, H = 20, CELL = 20;
    java.util.List<Ball> balls = new ArrayList<>();
    int paddleH = 4;
    int playerY, aiY;
    int scorePlayer = 0, scoreAI = 0;
    int winScore = 5;
    boolean gameOver = false;
    Timer timer;
    Random rand = new Random();

    public Pong() {
        setPreferredSize(new Dimension(W*CELL + 50, H*CELL));
        setBackground(Color.BLACK);
        setFocusable(true);
        addKeyListener(this);
        playerY = H/2 - paddleH/2;
        aiY = H/2 - paddleH/2;
        initBalls();
        timer = new Timer(16, this);
        timer.start();
    }

    void initBalls() {
        balls.clear();
        balls.add(new Ball(W/2, H/2, -1, -0.5, 'O'));
        balls.add(new Ball(W/2, H/2, 1, 0.5, 'o'));
    }

    @Override
    public void actionPerformed(ActionEvent e) {
        updateAI();
        updateBalls();
        repaint();
    }

    void updateBalls() {
        if (gameOver) return;
        for (int i = 0; i < balls.size(); i++) {
            Ball b = balls.get(i);
            b.x += b.dx * b.speed;
            b.y += b.dy * b.speed;
            if (b.y <= 1 || b.y >= H-2) b.dy *= -1;
            if (b.x <= 3 && (int)b.y >= playerY && (int)b.y < playerY + paddleH) {
                b.dx *= -1;
                b.x = 4;
                b.speed = Math.min(2.0, b.speed * 1.05);
            }
            if (b.x >= W-4 && (int)b.y >= aiY && (int)b.y < aiY + paddleH) {
                b.dx *= -1;
                b.x = W-5;
                b.speed = Math.min(2.0, b.speed * 1.05);
            }
            if (b.x <= 0) {
                scoreAI++;
                resetBall(i, 1);
                if (scoreAI >= winScore) gameOver = true;
            } else if (b.x >= W-1) {
                scorePlayer++;
                resetBall(i, -1);
                if (scorePlayer >= winScore) gameOver = true;
            }
        }
    }

    void resetBall(int idx, int dir) {
        Ball b = balls.get(idx);
        b.x = W/2;
        b.y = H/2;
        b.dx = dir * (0.5 + rand.nextDouble() * 0.5);
        b.dy = (rand.nextDouble() - 0.5) * 0.8;
        b.speed = 0.8 + rand.nextDouble() * 0.4;
        if (b.dy == 0) b.dy = 0.3 * (rand.nextBoolean() ? 1 : -1);
    }

    void updateAI() {
        double targetY = H/2;
        for (Ball b : balls)
            if (b.dx > 0 && b.x > W/2) { targetY = b.y; break; }
        if (targetY > aiY + paddleH/2 + 1) aiY++;
        else if (targetY < aiY + paddleH/2 - 1) aiY--;
        aiY = Math.max(1, Math.min(H - paddleH - 1, aiY));
    }

    void movePlayer(int dy) {
        if (gameOver) return;
        int newY = playerY + dy;
        if (newY >= 1 && newY <= H - paddleH - 1) playerY = newY;
    }

    void restart() {
        playerY = H/2 - paddleH/2;
        aiY = H/2 - paddleH/2;
        scorePlayer = 0;
        scoreAI = 0;
        gameOver = false;
        initBalls();
    }

    @Override
    public void paintComponent(Graphics g) {
        super.paintComponent(g);
        g.setColor(Color.WHITE);
        // border
        for (int x = 0; x < W; x++) {
            g.drawRect(x*CELL, 0, CELL, CELL);
            g.drawRect(x*CELL, (H-1)*CELL, CELL, CELL);
        }
        for (int y = 0; y < H; y++) {
            g.drawRect(0, y*CELL, CELL, CELL);
            g.drawRect((W-1)*CELL, y*CELL, CELL, CELL);
        }
        // centre
        for (int y = 1; y < H-1; y++) {
            g.drawString("|", W/2*CELL, y*CELL + CELL/2);
        }
        // paddles
        g.setColor(Color.BLUE);
        for (int i = 0; i < paddleH; i++) {
            g.drawString("]", 2*CELL, (playerY+i)*CELL + CELL/2);
            g.drawString("[", (W-3)*CELL, (aiY+i)*CELL + CELL/2);
        }
        // balls
        g.setColor(Color.YELLOW);
        for (Ball b : balls) {
            if (b.x > 0 && b.x < W-1 && b.y > 0 && b.y < H-1) {
                g.drawString(String.valueOf(b.ch), (int)b.x*CELL, (int)b.y*CELL + CELL/2);
            }
        }
        // score
        g.setColor(Color.WHITE);
        g.drawString(scorePlayer + " : " + scoreAI, W/2*CELL - 20, 20);
        if (gameOver) {
            String winner = scorePlayer >= winScore ? "Player" : "AI";
            g.setColor(Color.RED);
            g.setFont(new Font("Arial", Font.BOLD, 20));
            g.drawString(winner + " WINS!", W/2*CELL - 50, H/2*CELL);
            g.setFont(new Font("Arial", Font.PLAIN, 14));
            g.drawString("Press R to restart", W/2*CELL - 60, H/2*CELL + 30);
        }
    }

    @Override
    public void keyPressed(KeyEvent e) {
        int key = e.getKeyCode();
        if (key == KeyEvent.VK_R && gameOver) restart();
        if (key == KeyEvent.VK_W || key == KeyEvent.VK_UP) movePlayer(-1);
        if (key == KeyEvent.VK_S || key == KeyEvent.VK_DOWN) movePlayer(1);
        if (key == KeyEvent.VK_Q) System.exit(0);
    }
    @Override public void keyReleased(KeyEvent e) {}
    @Override public void keyTyped(KeyEvent e) {}

    public static void main(String[] args) {
        JFrame frame = new JFrame("Double Ball Pong");
        frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        frame.setResizable(false);
        frame.add(new Pong());
        frame.pack();
        frame.setLocationRelativeTo(null);
        frame.setVisible(true);
    }
}
