module TicTacToe
  CARDINALS =
      %w[
        nw n ne
        w  c  e
        sw s se
      ]

  WINS = [
      %w[nw n ne], # top row
      %w[w  c  e], # middle row
      %w[sw s se], # bottom row
      %w[nw w sw], # left column
      %w[ne e se], # right column
      %w[n  c  s], # middle column
      %w[nw c se], # diagonal
      %w[sw c ne], # diagonal
  ]

  class Game
    attr_writer :won
    def initialize
      @state = 'in progress'
      @board = Board.new
      @replay_answer = nil
    end

    def play
      [:human_turn, :program_turn].cycle do |turn|
        system('clear')
        board.draw
        check_for_win_or_draw
        break if state == 'ended'
        self.send(turn)
      end
      announce_result
      confirm_replay
      quit_or_restart
    end

    private
    attr_reader :board
    attr_accessor :state, :replay_answer, :winner

    def human_turn
      puts "Make your move"
      location = ''
      until board.available_positions.include?(location)
        location = gets.chomp
        respond_to_nonvalid_input if !board.available_positions.include?(location)
      end
      board.position_at(location).set_mark('x')
    end

    def respond_to_nonvalid_input
      system('clear')
      board.draw
      puts "Try one of these: #{board.available_positions.join(', ')}"
    end

    def program_turn
      ProgramReaction.new(:board => board).react
    end

    def check_for_win_or_draw
      check_win
      check_draw if state != 'ended'
    end

    def check_win
      WINS.each do |win|
        ['x', 'o'].each do |player|
          if win.all?{ |p| board.send(player + '_marks').include?(p) }
            self.state = 'ended'
            self.winner = player
          end
        end
      end
    end

    def check_draw
      self.state = 'ended' if board.available_positions.empty?
    end

    def announce_result
      if winner
        puts "#{winner} wins!"
      else
        puts 'draw!'
      end
    end

    def confirm_replay
      puts "Play again? (y/n)"
      until ['y', 'n'].include?(replay_answer)
        self.replay_answer = gets.chomp
      end
    end

    def quit_or_restart
      if replay_answer == 'y'
        Game.new.play
      else
        puts "Goodbye!"
      end
    end
  end

  class ProgramReaction
    def initialize(args)
      @board = args[:board]
    end

    def react
      humanize
      if first_program_turn?
        react_to_opening_move
      elsif program_can_win?
        take_win
      elsif win_must_be_prevented?
        prevent_win
      else
        play_random
      end
    end

    private
    attr_reader :board

    def play_random
      random_location = board.available_positions.sample
      board.position_at(random_location).set_mark('o')
    end

    def win_possibilities_for(player)
      target_marks = player == 'x' ? board.x_marks : board.o_marks
      WINS.collect do |win|
        difference = win - target_marks
        if difference.count == 1 && board.position_at(difference.first).mark == ' '
          win
        end
      end.compact
    end

    def win_must_be_prevented?
      win_possibilities_for('x').any?
    end

    def program_can_win?
      win_possibilities_for('o').any?
    end

    def prevent_or_take_win(opt)
      target_marks = opt == 'prevent' ? board.x_marks : board.o_marks
      WINS.each do |win|
        difference = win - target_marks
        if difference.count == 1 && board.position_at(difference.first).mark == ' '
          board.position_at(difference[0]).set_mark('o')
          return
        end
      end
    end

    def prevent_win
      prevent_or_take_win('prevent')
    end

    def take_win
      prevent_or_take_win('take')
    end

    def humanize
      sleep [0.2, 0.3, 0.4, 0.5, 0.6].sample
    end

    def first_program_turn?
      board.o_marks.none?
    end

    def react_to_opening_move
      play_center if human_opened_with_corner?
      play_corner if human_opened_with_center?
      play_center if human_opened_with_edge?
    end

    def human_opened_with_corner?
      board.x_marks.count == 1 and %w[nw sw ne se].include?(board.x_marks.first)
    end

    def human_opened_with_edge?
      board.x_marks.count == 1 and %w[n s e w].include?(board.x_marks.first)
    end

    def human_opened_with_center?
      board.x_marks == ['c']
    end

    def play_center
      board.position_at('c').set_mark('o')
    end

    def play_corner
      corner = %w[nw sw ne se].sample
      board.position_at(corner).set_mark('o')
    end
  end

  module BlankBoardWriter
    def self.write
      CARDINALS.collect do |cardinal|
        Position.new(:location => cardinal)
      end
    end
  end

  class Board
    attr_reader :positions

    def initialize(args={})
      @positions = args[:positions] || BlankBoardWriter.write
    end

    def draw
      rows.each do |row|
        output = ['|']
        row.each do |position|
          output << position.mark
          output << '|'
        end
        puts output.join
      end
    end

    def position_at(location)
      positions.select{ |p| p.location == location }.first
    end

    def x_marks
      positions.collect { |p| p.location if p.mark == 'x' }.compact
    end

    def o_marks
      positions.collect { |p| p.location if p.mark == 'o' }.compact
    end

    def available_positions
      positions.collect { |p| p.location if p.mark == ' ' }.compact
    end

    private
    def top_row
      positions.select{ |p| p.location.include?('n') }
    end

    def middle_row
      positions.select{ |p| %w[w c e].include?(p.location) }
    end

    def bottom_row
      positions.select{ |p| p.location.include?('s') }
    end

    def rows
      [top_row, middle_row, bottom_row]
    end
  end

  class Position
    attr_reader :mark, :location
    def initialize(args)
      @mark = ' '
      @location = args[:location]
    end

    def set_mark(mark)
      self.mark = mark
    end

    private
    attr_writer :mark
  end
end
