# pong.rb
require 'io/console'
require 'timeout'

W = 40
H = 20

class Ball
  attr_accessor :x, :y, :dx, :dy, :speed, :char
  def initialize(x, y, dx, dy, char)
    @x, @y, @dx, @dy, @char = x, y, dx, dy, char
    @speed = 0.8 + rand * 0.4
  end
end

class Pong
  def initialize
    @paddle_h = 4
    @player_y = H/2 - @paddle_h/2
    @ai_y = H/2 - @paddle_h/2
    @score_player = 0
    @score_ai = 0
    @win_score = 5
    @game_over = false
    @running = true
    @paddle_speed = 1
    @balls = []
    init_balls
    Thread.new { input_loop }
    game_loop
  end

  def init_balls
    @balls = [
      Ball.new(W/2, H/2, -1, -0.5, 'O'),
      Ball.new(W/2, H/2, 1, 0.5, 'o')
    ]
  end

  def draw_border
    (0...W).each { |x| print "\e[0;#{x}H#" }
    (0...W).each { |x| print "\e[#{H-1};#{x}H#" }
    (0...H).each { |y| print "\e[#{y};0H#" }
    (0...H).each { |y| print "\e[#{y};#{W-1}H#" }
    (1...H-1).each { |y| print "\e[#{y};#{W/2}H|" }
  end

  def draw_paddles
    (0...@paddle_h).each do |i|
      print "\e[#{@player_y+i};2H]"
      print "\e[#{@ai_y+i};#{W-3}H["
    end
  end

  def draw_balls
    @balls.each do |b|
      if b.x > 0 && b.x < W-1 && b.y > 0 && b.y < H-1
        print "\e[#{b.y.to_i};#{b.x.to_i}H#{b.char}"
      end
    end
  end

  def draw_score
    print "\e[1;#{W/2-2}H#{@score_player} : #{@score_ai}"
    if @game_over
      winner = @score_player >= @win_score ? "Player" : "AI"
      print "\e[#{H/2};#{W/2-winner.length/2}H#{winner} WINS!"
      print "\e[#{H/2+1};#{W/2-8}HPress R to restart"
    end
  end

  def reset_ball(idx, dir)
    b = @balls[idx]
    b.x = W/2
    b.y = H/2
    b.dx = dir * (0.5 + rand * 0.5)
    b.dy = (rand - 0.5) * 0.8
    b.speed = 0.8 + rand * 0.4
    b.dy = 0.3 * (rand > 0.5 ? 1 : -1) if b.dy == 0
  end

  def update_balls
    return if @game_over
    @balls.each_with_index do |b, i|
      b.x += b.dx * b.speed
      b.y += b.dy * b.speed
      b.dy *= -1 if b.y <= 1 || b.y >= H-2
      if b.x <= 3 && b.y.to_i >= @player_y && b.y.to_i < @player_y + @paddle_h
        b.dx *= -1
        b.x = 4
        b.speed = [2.0, b.speed * 1.05].min
      end
      if b.x >= W-4 && b.y.to_i >= @ai_y && b.y.to_i < @ai_y + @paddle_h
        b.dx *= -1
        b.x = W-5
        b.speed = [2.0, b.speed * 1.05].min
      end
      if b.x <= 0
        @score_ai += 1
        reset_ball(i, 1)
        @game_over = true if @score_ai >= @win_score
      elsif b.x >= W-1
        @score_player += 1
        reset_ball(i, -1)
        @game_over = true if @score_player >= @win_score
      end
    end
  end

  def update_ai
    target_y = H/2
    @balls.each { |b| target_y = b.y if b.dx > 0 && b.x > W/2 }
    if target_y > @ai_y + @paddle_h/2 + 1
      @ai_y += @paddle_speed
    elsif target_y < @ai_y + @paddle_h/2 - 1
      @ai_y -= @paddle_speed
    end
    @ai_y = [1, [H - @paddle_h - 1, @ai_y].min].max
  end

  def move_player(dy)
    return if @game_over
    new_y = @player_y + dy
    @player_y = new_y if new_y >= 1 && new_y <= H - @paddle_h - 1
  end

  def restart
    @player_y = H/2 - @paddle_h/2
    @ai_y = H/2 - @paddle_h/2
    @score_player = 0
    @score_ai = 0
    @game_over = false
    init_balls
  end

  def input_loop
    while @running
      char = STDIN.getch
      case char
      when 'q', 'Q' then @running = false
      when 'r', 'R'
        restart if @game_over
      when 'w', 'W' then move_player(-1)
      when 's', 'S' then move_player(1)
      when "\e"
        c = STDIN.read_nonblock(2) rescue nil
        if c == '[A' then move_player(-1)
        elsif c == '[B' then move_player(1)
        end
      end
    end
  end

  def render
    system('clear') || system('cls')
    draw_border
    draw_paddles
    draw_balls
    draw_score
  end

  def game_loop
    while @running
      update_ai
      update_balls
      render
      sleep 0.016
    end
  end
end

Pong.new
