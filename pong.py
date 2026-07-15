# pong.py
import curses
import random
import time

class Ball:
    def __init__(self, x, y, dx, dy, char='O'):
        self.x = x
        self.y = y
        self.dx = dx
        self.dy = dy
        self.char = char
        self.speed = 1.0

    def move(self):
        self.x += self.dx * self.speed
        self.y += self.dy * self.speed

    def bounce_x(self):
        self.dx *= -1

    def bounce_y(self):
        self.dy *= -1

    def speed_up(self, factor=1.05):
        self.speed = min(2.0, self.speed * factor)

class Pong:
    def __init__(self, stdscr):
        self.stdscr = stdscr
        curses.curs_set(0)
        self.stdscr.nodelay(1)
        self.stdscr.timeout(16)
        self.height, self.width = self.stdscr.getmaxyx()
        self.height = min(self.height, 24)
        self.width = min(self.width, 80)
        self.paddle_h = 4
        self.player_y = self.height // 2 - self.paddle_h // 2
        self.ai_y = self.height // 2 - self.paddle_h // 2
        self.score_player = 0
        self.score_ai = 0
        self.win_score = 5
        self.game_over = False
        self.paused = False
        self.running = True
        self.balls = []
        self.init_balls()
        self.paddle_speed = 1

    def init_balls(self):
        cx = self.width // 2
        cy = self.height // 2
        angles = [(-1, -0.5), (1, 0.5)]
        for i, (dx, dy) in enumerate(angles):
            b = Ball(cx, cy, dx, dy, 'O' if i == 0 else 'o')
            b.speed = 0.8 + random.random() * 0.4
            self.balls.append(b)

    def draw_border(self):
        for y in range(self.height):
            self.stdscr.addch(y, 0, '#')
            self.stdscr.addch(y, self.width-1, '#')
        for x in range(self.width):
            self.stdscr.addch(0, x, '#')
            self.stdscr.addch(self.height-1, x, '#')
        # center line
        for y in range(1, self.height-1):
            self.stdscr.addch(y, self.width//2, '|')

    def draw_paddles(self):
        for i in range(self.paddle_h):
            self.stdscr.addch(self.player_y + i, 2, ']')
            self.stdscr.addch(self.ai_y + i, self.width-3, '[')

    def draw_balls(self):
        for b in self.balls:
            if 0 < b.x < self.width-1 and 0 < b.y < self.height-1:
                self.stdscr.addch(int(b.y), int(b.x), b.char)

    def draw_score(self):
        self.stdscr.addstr(1, self.width//2 - 5, f"{self.score_player} : {self.score_ai}")
        if self.game_over:
            winner = "Player" if self.score_player >= self.win_score else "AI"
            self.stdscr.addstr(self.height//2, self.width//2 - len(winner)//2, f"{winner} WINS!")
            self.stdscr.addstr(self.height//2 + 1, self.width//2 - 8, "Press R to restart")

    def update_balls(self):
        if self.game_over or self.paused:
            return
        for b in self.balls:
            b.move()
            # top/bottom walls
            if b.y <= 1 or b.y >= self.height-2:
                b.bounce_y()
            # left paddle
            if b.x <= 3 and self.player_y <= b.y < self.player_y + self.paddle_h:
                b.bounce_x()
                b.x = 4
                b.speed_up()
            # right paddle
            if b.x >= self.width-4 and self.ai_y <= b.y < self.ai_y + self.paddle_h:
                b.bounce_x()
                b.x = self.width-5
                b.speed_up()
            # scoring
            if b.x <= 0:
                self.score_ai += 1
                self.reset_ball(b, 1)
                if self.score_ai >= self.win_score:
                    self.game_over = True
            elif b.x >= self.width-1:
                self.score_player += 1
                self.reset_ball(b, -1)
                if self.score_player >= self.win_score:
                    self.game_over = True

    def reset_ball(self, ball, direction):
        ball.x = self.width // 2
        ball.y = self.height // 2
        ball.dx = direction * (0.5 + random.random() * 0.5)
        ball.dy = (random.random() - 0.5) * 0.8
        ball.speed = 0.8 + random.random() * 0.4
        if ball.dy == 0:
            ball.dy = 0.3 if random.random() > 0.5 else -0.3

    def update_ai(self):
        # Simple AI: follow the ball that's closest to its side
        target_y = self.height // 2
        for b in self.balls:
            if b.dx > 0 and b.x > self.width // 2:
                target_y = b.y
                break
        if target_y > self.ai_y + self.paddle_h // 2 + 1:
            self.ai_y += self.paddle_speed
        elif target_y < self.ai_y + self.paddle_h // 2 - 1:
            self.ai_y -= self.paddle_speed
        self.ai_y = max(1, min(self.height - self.paddle_h - 1, self.ai_y))

    def move_player(self, dy):
        if self.game_over:
            return
        new_y = self.player_y + dy
        if 1 <= new_y <= self.height - self.paddle_h - 1:
            self.player_y = new_y

    def restart(self):
        self.player_y = self.height // 2 - self.paddle_h // 2
        self.ai_y = self.height // 2 - self.paddle_h // 2
        self.score_player = 0
        self.score_ai = 0
        self.game_over = False
        self.balls = []
        self.init_balls()

    def render(self):
        self.stdscr.clear()
        self.draw_border()
        self.draw_paddles()
        self.draw_balls()
        self.draw_score()
        self.stdscr.refresh()

    def run(self):
        while self.running:
            key = self.stdscr.getch()
            if key == ord('q') or key == ord('Q'):
                break
            if key == ord('r') or key == ord('R'):
                self.restart()
            if key == ord('w') or key == ord('W') or key == curses.KEY_UP:
                self.move_player(-1)
            elif key == ord('s') or key == ord('S') or key == curses.KEY_DOWN:
                self.move_player(1)
            self.update_ai()
            self.update_balls()
            self.render()
            time.sleep(0.016)

def main(stdscr):
    game = Pong(stdscr)
    game.run()

if __name__ == "__main__":
    curses.wrapper(main)
