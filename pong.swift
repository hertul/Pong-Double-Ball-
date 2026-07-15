// pong.swift
import Foundation

let W = 40
let H = 20

struct Ball {
    var x, y, dx, dy, speed: Double
    let char: Character
}

class Pong {
    var balls: [Ball] = []
    let paddleH = 4
    var playerY = H/2 - 2
    var aiY = H/2 - 2
    var scorePlayer = 0
    var scoreAI = 0
    let winScore = 5
    var gameOver = false
    var running = true
    let paddleSpeed = 1

    init() {
        initBalls()
        DispatchQueue.global().async {
            self.inputLoop()
        }
        gameLoop()
    }

    func initBalls() {
        balls = [
            Ball(x: Double(W/2), y: Double(H/2), dx: -1, dy: -0.5, speed: 0.8 + Double.random(in: 0...0.4), char: "O"),
            Ball(x: Double(W/2), y: Double(H/2), dx: 1, dy: 0.5, speed: 0.8 + Double.random(in: 0...0.4), char: "o")
        ]
    }

    func drawBorder() {
        for x in 0..<W {
            print("\u{001B}[0;\(x)H#", terminator: "")
            print("\u{001B}[\(H-1);\(x)H#", terminator: "")
        }
        for y in 0..<H {
            print("\u{001B}[\(y);0H#", terminator: "")
            print("\u{001B}[\(y);\(W-1)H#", terminator: "")
        }
        for y in 1..<H-1 {
            print("\u{001B}[\(y);\(W/2)H|", terminator: "")
        }
    }

    func drawPaddles() {
        for i in 0..<paddleH {
            print("\u{001B}[\(playerY+i);2H]", terminator: "")
            print("\u{001B}[\(aiY+i);\(W-3)H[", terminator: "")
        }
    }

    func drawBalls() {
        for b in balls {
            if b.x > 0 && b.x < Double(W-1) && b.y > 0 && b.y < Double(H-1) {
                print("\u{001B}[\(Int(b.y));\(Int(b.x))H\(b.char)", terminator: "")
            }
        }
    }

    func drawScore() {
        print("\u{001B}[1;\(W/2-2)H\(scorePlayer) : \(scoreAI)", terminator: "")
        if gameOver {
            let winner = scorePlayer >= winScore ? "Player" : "AI"
            print("\u{001B}[\(H/2);\(W/2-winner.count/2)H\(winner) WINS!", terminator: "")
            print("\u{001B}[\(H/2+1);\(W/2-8)HPress R to restart", terminator: "")
        }
    }

    func resetBall(_ idx: Int, _ dir: Int) {
        var b = balls[idx]
        b.x = Double(W/2)
        b.y = Double(H/2)
        b.dx = Double(dir) * (0.5 + Double.random(in: 0...0.5))
        b.dy = (Double.random(in: 0...1) - 0.5) * 0.8
        b.speed = 0.8 + Double.random(in: 0...0.4)
        if b.dy == 0 { b.dy = 0.3 * (Double.random(in: 0...1) > 0.5 ? 1 : -1) }
        balls[idx] = b
    }

    func updateBalls() {
        if gameOver { return }
        for i in 0..<balls.count {
            var b = balls[i]
            b.x += b.dx * b.speed
            b.y += b.dy * b.speed
            if b.y <= 1 || b.y >= Double(H-2) { b.dy *= -1 }
            if b.x <= 3 && Int(b.y) >= playerY && Int(b.y) < playerY + paddleH {
                b.dx *= -1
                b.x = 4
                b.speed = min(2.0, b.speed * 1.05)
            }
            if b.x >= Double(W-4) && Int(b.y) >= aiY && Int(b.y) < aiY + paddleH {
                b.dx *= -1
                b.x = Double(W-5)
                b.speed = min(2.0, b.speed * 1.05)
            }
            if b.x <= 0 {
                scoreAI += 1
                resetBall(i, 1)
                if scoreAI >= winScore { gameOver = true }
            } else if b.x >= Double(W-1) {
                scorePlayer += 1
                resetBall(i, -1)
                if scorePlayer >= winScore { gameOver = true }
            }
            balls[i] = b
        }
    }

    func updateAI() {
        var targetY = Double(H/2)
        for b in balls {
            if b.dx > 0 && b.x > Double(W/2) {
                targetY = b.y
                break
            }
        }
        if targetY > Double(aiY + paddleH/2 + 1) { aiY += paddleSpeed }
        else if targetY < Double(aiY + paddleH/2 - 1) { aiY -= paddleSpeed }
        aiY = max(1, min(H - paddleH - 1, aiY))
    }

    func movePlayer(_ dy: Int) {
        if gameOver { return }
        let newY = playerY + dy
        if newY >= 1 && newY <= H - paddleH - 1 {
            playerY = newY
        }
    }

    func restart() {
        playerY = H/2 - paddleH/2
        aiY = H/2 - paddleH/2
        scorePlayer = 0
        scoreAI = 0
        gameOver = false
        initBalls()
    }

    func inputLoop() {
        while running {
            let input = readLine(strippingNewline: false) ?? ""
            let chars = Array(input)
            if chars.isEmpty { continue }
            let ch = chars[0]
            switch ch {
            case "q", "Q": running = false
            case "r", "R":
                if gameOver { restart() }
            case "w", "W": movePlayer(-1)
            case "s", "S": movePlayer(1)
            default: break
            }
        }
    }

    func render() {
        print("\u{001B}[2J", terminator: "")
        drawBorder()
        drawPaddles()
        drawBalls()
        drawScore()
    }

    func gameLoop() {
        while running {
            updateAI()
            updateBalls()
            render()
            Thread.sleep(forTimeInterval: 0.016)
        }
    }
}

let game = Pong()
