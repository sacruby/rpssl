#!/usr/bin/env ruby
#---
# Excerpted from "Best of Ruby Quiz"
# We make no guarantees that this code is fit for any purpose.
# Visit http://www.pragmaticprogrammer.com/titles/fr_quiz for more book information.
# Additions: http://www.samkass.com/theories/RPSSL.html
#---

class Player
  @@players = [ ]

  def self.inherited( player )
    @@players << player
  end

  def self.each_pair
    (0...(@@players.size - 1)).each do |i|
      ((i + 1)...@@players.size).each do |j|
        yield @@players[i], @@players[j]
      end
    end
  end

  def initialize( opponent_name )
    @opponent_name = opponent_name
  end

  def choose
    raise NoMethodError, "Player subclasses must override choose()."
  end

  def result( your_choice, opponents_choice, win_lose_or_draw )
    # do nothing--subclasses can override as needed
  end
end

class PlayerPipe
  attr_reader :read, :write, :pid, :player_class

  def initialize(player_class, opponent)
    @player_class = player_class
    @read, write = IO.pipe
    read, @write = IO.pipe
    @pid = fork do
      player = player_class.new(opponent)
      trap(:HUP){write.puts(player.choose)}
      write.puts("ready")
      while line = read.readline.chomp
        exit(0) if line == "kill"
        player.result(*line.split(" ").map(&:to_sym))
      end
    end
    raise "Bad player" unless @read.readline.chomp == "ready"
  end

  def choose
    Process.kill(:HUP, pid)
    read.readline.chomp.to_sym
  end

  def result(*a)
    write.puts(a.join(" "))
  end

  def kill
    write.puts("kill")
    Process.wait(pid)
  end
end

class Game
  def initialize( player1, player2 )
    @player1_name = player1.to_s
    @player2_name = player2.to_s
    @player1      = PlayerPipe.new(player1, @player2_name)
    @player2      = PlayerPipe.new(player2, @player1_name)

    @score1 = 0
    @score2 = 0
  end

  def play( num_matches )
    num_matches.times do
      hand1 = @player1.choose
      hand2 = @player2.choose

      [[@player1_name, hand1], [@player2_name, hand2]].each do |player, hand|
        unless [:rock, :paper, :scissors, :lizard, :spock].include? hand
          raise "Invalid choice by #{player}."
        end
      end

      hands   = {hand1.to_s => @player1, hand2.to_s => @player2}
      choices = hands.keys.sort
      if choices.size == 1
        draw hand1, hand2
      elsif choices == %w{paper rock}
        win hands["paper"], hand1, hand2
      elsif choices == %w{rock scissors}
        win hands["rock"], hand1, hand2
      elsif choices == %w{paper scissors}
        win hands["scissors"], hand1, hand2
      elsif choices == %w{paper spock}
        win hands["paper"], hand1, hand2
      elsif choices == %w{lizard paper}
        win hands["lizard"], hand1, hand2
      elsif choices == %w{lizard rock}
        win hands["rock"], hand1, hand2
      elsif choices == %w{rock spock}
        win hands["spock"], hand1, hand2
      elsif choices == %w{scissors spock}
        win hands["spock"], hand1, hand2
      elsif choices == %w{lizard scissors}
        win hands["scissors"], hand1, hand2
      elsif choices == %w{lizard spock}
        win hands["lizard"], hand1, hand2
      else
        raise "Bad: #{hands.inspect}"
      end
    end
  end

  def results
    @player1.kill
    @player2.kill
    match = "#{@player1_name} vs. #{@player2_name}\n" +
          "\t#{@player1_name}: #{@score1}\n" +
          "\t#{@player2_name}: #{@score2}\n"
    if @score1 == @score2
      match + "\tDraw\n"
    elsif @score1 > @score2
      match + "\t#{@player1_name} Wins\n"
    else
      match + "\t#{@player2_name} Wins\n"
    end
  end

  private

  def draw( hand1, hand2 )
    @score1 += 0.5
    @score2 += 0.5
    @player1.result(hand1, hand2, :draw)
    @player2.result(hand2, hand1, :draw)
  end

  def win( winner, hand1, hand2 )
    if winner == @player1
      @score1 += 1
      @player1.result(hand1, hand2, :win)
      @player2.result(hand2, hand1, :lose)
    elsif winner == @player2
      @score2 += 1
      @player1.result(hand1, hand2, :lose)
      @player2.result(hand2, hand1, :win)
    else
      raise "Bad result: #{winner.inspect} #{hand1.inspect} #{hand2.inspect}"
    end
  end
end

match_game_count = 1000
if ARGV.size > 2 and ARGV[0] == "-m" and ARGV[1] =~ /^[1-9]\d*$/
  ARGV.shift
  match_game_count = ARGV.shift.to_i
end

ARGV.each do |p|
  if test(?d, p)
    Dir.foreach(p) do |file|
      next if file =~ /^\./
      next unless file =~ /\.rb$/
      require_relative File.join(p, file)
    end
  else
    require_relative p
  end
end

Player.each_pair do |one, two|
  game = Game.new one, two
  game.play match_game_count
  puts game.results
end
