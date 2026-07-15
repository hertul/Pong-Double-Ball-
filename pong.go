// pong.go
package main

import (
	"fmt"
	"math/rand"
	"os"
	"os/exec"
	"time"
)

const (
	width  = 40
	height = 20
)

type Ball struct {
	x, y      float64
	dx, dy    float64
	speed     float64
	char      rune
}

type Game struct {
	balls       []Ball
	playerY     int
	aiY         int
	paddleH     int
	scorePlayer int
	scoreAI     int
	winScore    int
	gameOver    bool
	running     bool
	paddleSpeed int
}

func NewGame() *Game {
	g := &Game{
		paddleH:     4,
		winScore:    5,
		running:     true,
		paddleSpeed: 1,
	}
	g.playerY = height/2 - g.paddleH/2
	g.aiY = height/2 - g.paddleH/2
	g.initBalls()
	return g
}

func (g *Game) initBalls() {
	g.balls = []Ball{
		{float64(width / 2), float64(height / 2), -1, -0.5, 0.8, 'O'},
		{float64(width / 2), float64(height / 2), 1, 0.5, 0.9, 'o'},
	}
}

func clearScreen() {
	cmd := exec.Command("clear")
	cmd.Stdout = os.Stdout
	cmd.Run()
}

func (g *Game) drawBorder() {
	for x := 0; x < width; x++ {
		fmt.Printf("\033[%d;%dH#", 0, x)
		fmt.Printf("\033[%d;%dH#", height-1, x)
	}
	for y := 0; y < height; y++ {
		fmt.Printf("\033[%d;%dH#", y, 0)
		fmt.Printf("\033[%d;%dH#", y, width-1)
	}
	// centre line
	for y := 1; y < height-1; y++ {
		fmt.Printf("\033[%d;%dH|", y, width/2)
	}
}

func (g *Game) drawPaddles() {
	for i := 0; i < g.paddleH; i++ {
		fmt.Printf("\033[%d;%dH]", g.playerY+i, 2)
		fmt.Printf("\033[%d;%dH[", g.aiY+i, width-3)
	}
}

func (g *Game) drawBalls() {
	for _, b := range g.balls {
		if b.x > 0 && b.x < float64(width-1) && b.y > 0 && b.y < float64(height-1) {
			fmt.Printf("\033[%d;%dH%c", int(b.y), int(b.x), b.char)
		}
	}
}

func (g *Game) drawScore() {
	fmt.Printf("\033[%d;%dH%d : %d", 1, width/2-2, g.scorePlayer, g.scoreAI)
	if g.gameOver {
		winner := "Player"
		if g.scoreAI >= g.winScore {
			winner = "AI"
		}
		fmt.Printf("\033[%d;%dH%s WINS!", height/2, width/2-len(winner)/2, winner)
		fmt.Printf("\033[%d;%dHPress R to restart", height/2+1, width/2-8)
	}
}

func (g *Game) updateBalls() {
	if g.gameOver {
		return
	}
	for i := range g.balls {
		b := &g.balls[i]
		b.x += b.dx * b.speed
		b.y += b.dy * b.speed
		// top/bottom
		if b.y <= 1 || b.y >= float64(height-2) {
			b.dy *= -1
		}
		// left paddle
		if b.x <= 3 && int(b.y) >= g.playerY && int(b.y) < g.playerY+g.paddleH {
			b.dx *= -1
			b.x = 4
			b.speed *= 1.05
			if b.speed > 2.0 {
				b.speed = 2.0
			}
		}
		// right paddle
		if b.x >= float64(width-4) && int(b.y) >= g.aiY && int(b.y) < g.aiY+g.paddleH {
			b.dx *= -1
			b.x = float64(width - 5)
			b.speed *= 1.05
			if b.speed > 2.0 {
				b.speed = 2.0
			}
		}
		// scoring
		if b.x <= 0 {
			g.scoreAI++
			g.resetBall(i, 1)
			if g.scoreAI >= g.winScore {
				g.gameOver = true
			}
		} else if b.x >= float64(width-1) {
			g.scorePlayer++
			g.resetBall(i, -1)
			if g.scorePlayer >= g.winScore {
				g.gameOver = true
			}
		}
	}
}

func (g *Game) resetBall(idx int, dir int) {
	b := &g.balls[idx]
	b.x = float64(width / 2)
	b.y = float64(height / 2)
	b.dx = float64(dir) * (0.5 + rand.Float64()*0.5)
	b.dy = (rand.Float64() - 0.5) * 0.8
	b.speed = 0.8 + rand.Float64()*0.4
	if b.dy == 0 {
		b.dy = 0.3
		if rand.Float64() > 0.5 {
			b.dy = -0.3
		}
	}
}

func (g *Game) updateAI() {
	targetY := height / 2
	for _, b := range g.balls {
		if b.dx > 0 && b.x > float64(width/2) {
			targetY = int(b.y)
			break
		}
	}
	if targetY > g.aiY+g.paddleH/2+1 {
		g.aiY += g.paddleSpeed
	} else if targetY < g.aiY+g.paddleH/2-1 {
		g.aiY -= g.paddleSpeed
	}
	if g.aiY < 1 {
		g.aiY = 1
	}
	if g.aiY > height-g.paddleH-1 {
		g.aiY = height - g.paddleH - 1
	}
}

func (g *Game) movePlayer(dy int) {
	if g.gameOver {
		return
	}
	newY := g.playerY + dy
	if newY >= 1 && newY <= height-g.paddleH-1 {
		g.playerY = newY
	}
}

func (g *Game) restart() {
	g.playerY = height/2 - g.paddleH/2
	g.aiY = height/2 - g.paddleH/2
	g.scorePlayer = 0
	g.scoreAI = 0
	g.gameOver = false
	g.initBalls()
}

func (g *Game) render() {
	clearScreen()
	g.drawBorder()
	g.drawPaddles()
	g.drawBalls()
	g.drawScore()
}

func (g *Game) run() {
	go func() {
		for g.running {
			var b [1]byte
			os.Stdin.Read(b[:])
			switch b[0] {
			case 'q', 'Q':
				g.running = false
			case 'r', 'R':
				if g.gameOver {
					g.restart()
				}
			case 'w', 'W':
				g.movePlayer(-1)
			case 's', 'S':
				g.movePlayer(1)
			}
		}
	}()
	for g.running {
		g.updateAI()
		g.updateBalls()
		g.render()
		time.Sleep(16 * time.Millisecond)
	}
}

func main() {
	rand.Seed(time.Now().UnixNano())
	fmt.Print("\033[?25l")
	game := NewGame()
	game.run()
}
