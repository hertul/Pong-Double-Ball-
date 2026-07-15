// pong.js
const readline = require('readline');
const { stdin, stdout } = process;

const W = 40;
const H = 20;

class Ball {
    constructor(x, y, dx, dy, char = 'O') {
        this.x = x;
        this.y = y;
        this.dx = dx;
        this.dy = dy;
        this.char = char;
        this.speed = 0.8 + Math.random() * 0.4;
    }
}

class Pong {
    constructor() {
        this.paddleH = 4;
        this.playerY = Math.floor(H/2) - Math.floor(this.paddleH/2);
        this.aiY = Math.floor(H/2) - Math.floor(this.paddleH/2);
        this.scorePlayer = 0;
        this.scoreAI = 0;
        this.winScore = 5;
        this.gameOver = false;
        this.running = true;
        this.paddleSpeed = 1;
        this.balls = [];
        this.initBalls();
        this.setupInput();
        this.gameLoop();
    }

    initBalls() {
        this.balls = [
            new Ball(W/2, H/2, -1, -0.5, 'O'),
            new Ball(W/2, H/2, 1, 0.5, 'o')
        ];
    }

    drawBorder() {
        for (let x = 0; x < W; x++) {
            process.stdout.write(`\x1b[0;${x}H#`);
            process.stdout.write(`\x1b[${H-1};${x}H#`);
        }
        for (let y = 0; y < H; y++) {
            process.stdout.write(`\x1b[${y};0H#`);
            process.stdout.write(`\x1b[${y};${W-1}H#`);
        }
        for (let y = 1; y < H-1; y++) {
            process.stdout.write(`\x1b[${y};${Math.floor(W/2)}H|`);
        }
    }

    drawPaddles() {
        for (let i = 0; i < this.paddleH; i++) {
            process.stdout.write(`\x1b[${this.playerY+i};2H]`);
            process.stdout.write(`\x1b[${this.aiY+i};${W-3}H[`);
        }
    }

    drawBalls() {
        for (const b of this.balls) {
            if (b.x > 0 && b.x < W-1 && b.y > 0 && b.y < H-1) {
                process.stdout.write(`\x1b[${Math.floor(b.y)};${Math.floor(b.x)}H${b.char}`);
            }
        }
    }

    drawScore() {
        process.stdout.write(`\x1b[1;${Math.floor(W/2)-2}H${this.scorePlayer} : ${this.scoreAI}`);
        if (this.gameOver) {
            const winner = this.scorePlayer >= this.winScore ? 'Player' : 'AI';
            process.stdout.write(`\x1b[${Math.floor(H/2)};${Math.floor(W/2)-Math.floor(winner.length/2)}H${winner} WINS!`);
            process.stdout.write(`\x1b[${Math.floor(H/2)+1};${Math.floor(W/2)-8}HPress R to restart`);
        }
    }

    resetBall(idx, dir) {
        const b = this.balls[idx];
        b.x = W/2;
        b.y = H/2;
        b.dx = dir * (0.5 + Math.random() * 0.5);
        b.dy = (Math.random() - 0.5) * 0.8;
        b.speed = 0.8 + Math.random() * 0.4;
        if (b.dy === 0) b.dy = 0.3 * (Math.random() > 0.5 ? 1 : -1);
    }

    updateBalls() {
        if (this.gameOver) return;
        for (const b of this.balls) {
            b.x += b.dx * b.speed;
            b.y += b.dy * b.speed;
            if (b.y <= 1 || b.y >= H-2) b.dy *= -1;
            if (b.x <= 3 && Math.floor(b.y) >= this.playerY && Math.floor(b.y) < this.playerY + this.paddleH) {
                b.dx *= -1;
                b.x = 4;
                b.speed = Math.min(2.0, b.speed * 1.05);
            }
            if (b.x >= W-4 && Math.floor(b.y) >= this.aiY && Math.floor(b.y) < this.aiY + this.paddleH) {
                b.dx *= -1;
                b.x = W-5;
                b.speed = Math.min(2.0, b.speed * 1.05);
            }
            if (b.x <= 0) {
                this.scoreAI++;
                this.resetBall(this.balls.indexOf(b), 1);
                if (this.scoreAI >= this.winScore) this.gameOver = true;
            } else if (b.x >= W-1) {
                this.scorePlayer++;
                this.resetBall(this.balls.indexOf(b), -1);
                if (this.scorePlayer >= this.winScore) this.gameOver = true;
            }
        }
    }

    updateAI() {
        let targetY = H/2;
        for (const b of this.balls) {
            if (b.dx > 0 && b.x > W/2) {
                targetY = b.y;
                break;
            }
        }
        if (targetY > this.aiY + this.paddleH/2 + 1) this.aiY += this.paddleSpeed;
        else if (targetY < this.aiY + this.paddleH/2 - 1) this.aiY -= this.paddleSpeed;
        this.aiY = Math.max(1, Math.min(H - this.paddleH - 1, this.aiY));
    }

    movePlayer(dy) {
        if (this.gameOver) return;
        const newY = this.playerY + dy;
        if (newY >= 1 && newY <= H - this.paddleH - 1) this.playerY = newY;
    }

    restart() {
        this.playerY = Math.floor(H/2) - Math.floor(this.paddleH/2);
        this.aiY = Math.floor(H/2) - Math.floor(this.paddleH/2);
        this.scorePlayer = 0;
        this.scoreAI = 0;
        this.gameOver = false;
        this.initBalls();
    }

    setupInput() {
        readline.emitKeypressEvents(process.stdin);
        process.stdin.setRawMode(true);
        process.stdin.on('keypress', (str, key) => {
            if (key.ctrl && key.name === 'c') process.exit();
            if (key.name === 'q') process.exit();
            if (key.name === 'r' && this.gameOver) this.restart();
            if (key.name === 'w' || key.name === 'up') this.movePlayer(-1);
            if (key.name === 's' || key.name === 'down') this.movePlayer(1);
        });
    }

    render() {
        process.stdout.write('\x1b[2J');
        this.drawBorder();
        this.drawPaddles();
        this.drawBalls();
        this.drawScore();
    }

    gameLoop() {
        if (!this.running) return;
        this.updateAI();
        this.updateBalls();
        this.render();
        setTimeout(() => this.gameLoop(), 16);
    }
}

new Pong();
