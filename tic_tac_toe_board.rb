class TicTacToeBoard
  attr_reader :size, :board, :current_player, :current_move,
              :turn, :game_over, :flags, :parent

  PIECES=['X', 'O']

  # There are three ways to initialize a TicTacToeBoard:
  #
  # Empty 3x3 board:
  # tttb = TicTacToeBoard.new(size: 3)
  #
  # Existing board with a move applied:
  # tttb = TicTacToeBoard.new(board: other_tttb, move: 5)
  #
  # New board based on an array:
  # tttb = TicTacToeBoard.new(array: [[nil,nil,nil],[nil,nil,nil],[nil,nil,nil]])
  def initialize(params)
    if params[:size]
      # Initialize an empty board
      @size = params[:size].to_i
      raise "Invalid size" if @size < 3 || @size > 5
      @board = @size.times.map { Array.new(@size) }
      @current_player = nil
      @current_move = nil
      @turn = 0

    elsif params[:board]
      # Initialize from another TicTacToeBoard
      raise StandardError, "Cannot continue finished game" if params[:board].game_over
      @parent = params[:board]
      @size = @parent.size
      @board = @parent.board.map(&:dup)
      @current_player = @parent.next_player
      @turn = @parent.turn + 1

    elsif params[:array]
      # Initialize from an array
      @size = params[:array].size
      # Ensure that the size is 3, 4, or 5
      raise "Invalid size" if @size < 3 || @size > 5
      # Ensure that the board has only valid values
      values = params[:array].flatten
      raise StandardError, "Board must contain only nil, 0, or 1 in all positions" unless values.all? { |v| [nil,0,1].include?(v) }
      # Ensure that board is properly dimensioned
      raise StandardError, "Board is not square" unless params[:array].all? { |col| col.count == params[:array].count }
      # Ensure that the player's moves are balanced
      @board = params[:array].map(&:dup)
      moves = [0, 0]
      moves[0] = values.select { |v| v == 0 }.count
      moves[1] = values.select { |v| v == 1 }.count
      raise StandardError, "Moves are not balanced" unless moves[0] == moves[1] || moves[0] == moves[1] + 1
      @turn = moves[0] + moves[1]
      if @turn == 0
        @current_player = nil
      else
        @current_player = (@turn.odd? ? 0 : 1)
      end
      # No way to know which move was the last one
      @current_move = nil
    end

    if params[:move]
      x_y = position_to_x_y(params[:move])
      raise StandardError, "Position unavailable" if @board[x_y.first][x_y.last]
      @board[x_y.first][x_y.last] = @current_player
      @current_move = x_y
    end

    # This is where it becomes immutable
    @board.map(&:freeze)
    @board.freeze
    @current_player.freeze
    @current_move.freeze

    set_flags
  end

  # Determine who the next player will be
  def next_player
    @current_player ? (1 - @current_player) : 0
  end

  # Do the next move, return a new TTTB
  def apply_move(next_move)
    self.class.new(board: self, move: next_move)
  end

  # Display the board.  If passed "true", show a compact board.
  def display(compact=false)
    low_int_on = "\e[2m"
    bold_on = "\e[1m"
    reverse_on = "\e[7m"
    char_attr_off = "\e[0m"
    width = (@size == 3 ? 3 : 4)
    width -= 2 if compact
    fmt = (@size == 3 ? ' %1s ' : ' %2s ')
    fmt = fmt.strip if compact
    hsep = '+' + (('-' * width) + '+') * @size
    hblank = '|' + ((' ' * width) + '|') * @size
    0.upto(@size-1) do |y|
      puts hsep
      puts hblank unless compact
      hline = '|'
      0.upto(@size-1) do |x|
        position = x_y_to_position(x, y)
        if @board[x][y]
          if @flags[:winner] && @flags[:win_positions].include?([x,y])
            hline += sprintf("%s%s#{fmt}%s|", reverse_on, bold_on, PIECES[@board[x][y]], char_attr_off)
          else
            hline += sprintf("%s#{fmt}%s|", bold_on, PIECES[@board[x][y]], char_attr_off)
          end
        else
          hline += sprintf("%s#{fmt}%s|", low_int_on, position, char_attr_off)
        end
      end
      puts hline
      puts hblank unless compact
    end
    puts hsep
  end

  # Display the entire game
  def display_entire_game(compact=false)
    if @parent
      @parent.display_entire_game(compact)
      puts unless compact
    end
    if @turn == 0
      puts "Start"
    else
      puts "Turn #{@turn}"
    end
    display(compact)
  end

  def ==(other_tic_tac_toe_board)
    @size == other_tic_tac_toe_board.size && @board == other_tic_tac_toe_board.board
  end

  protected

    # The flags are as follows:
    #
    # empty            No moves have been made yet
    # full             All positions filled
    # stalemate        Nobody won
    # winner           Player # of winner
    # win_type         :row, :col, or :diagonal
    # win_desc         row #, col #, or "nw_se" / "sw_ne"
    # win_positions    Set of x,y coordinates of winning pieces
    def set_flags
      # Initialize flags
      @flags = { empty: false, full: false, stalemate: false, winner: false }
      pieces_count = 0
      0.upto(@size-1) do |y|
        0.upto(@size-1) do |x|
          pieces_count += 1 if @board[x][y]
        end
      end

      flags[:empty] = true if pieces_count == 0
      flags[:full] = true if pieces_count == @size * @size

      # For a win to occur, there must be at least @size partial turns.
      # For example, on a 3x3 board, the first player must have put 3
      # pieces, and the second player at least 2.
      if pieces_count >= @size * 2 - 1
        # Check for wins.  First, check rows.
        @flags[:win_positions] = []
        0.upto(@size-1) do |y|
          row_vals = 0.upto(@size-1).map { |x| @board[x][y] }
          if row_vals.first && row_vals.all? { |v| v == row_vals.first }
            @flags[:winner] = row_vals.first
            @flags[:win_type] = :row
            @flags[:win_desc] = y
            @flags[:win_positions] += 0.upto(@size-1).map { |x| [x,y] }
            break
          end
        end
        # Check columns
        0.upto(@size-1) do |x|
          col_vals = @board[x]
          if col_vals.first && col_vals.all? { |v| v == col_vals.first }
            @flags[:winner] = col_vals.first
            @flags[:win_type] = :col
            @flags[:win_desc] = x
            @flags[:win_positions] += 0.upto(@size-1).map { |y| [x,y] }
            break
          end
        end
        # Try diagonals, NW -> SE
        diag_vals_nw_se = 0.upto(@size-1).map { |xy| @board[xy][xy] }
        if diag_vals_nw_se.first && diag_vals_nw_se.all? { |v| v == diag_vals_nw_se.first }
          @flags[:winner] = diag_vals_nw_se.first
          @flags[:win_type] = :diagonal
          @flags[:win_desc] = :nw_se
          @flags[:win_positions] += 0.upto(@size-1).map { |xy| [xy,xy] }
        end
        # Try diagonals, SW -> NE
        diag_vals_sw_ne = 0.upto(@size-1).map { |x| @board[x][@size - x - 1] }
        if diag_vals_sw_ne.first && diag_vals_sw_ne.all? { |v| v == diag_vals_sw_ne.first }
          @flags[:winner] = diag_vals_sw_ne.first
          @flags[:win_type] = :diagonal
          @flags[:win_desc] = :sw_ne
          @flags[:win_positions] += 0.upto(@size-1).map { |x| [x,@size - x - 1] }
        end
        # Get rid of duplicates
        @flags[:win_positions] = @flags[:win_positions].uniq
      end
      # It's a stalemate if the board is full without a winner
      if @flags[:full] && !@flags[:winner]
        @flags[:stalemate] = true
      end
      @flags.freeze

      # Set game_over, making it a pure boolean
      @game_over = (@flags[:full] || @flags[:winner] != false)
    end

    # The position is 1 - 9, so a 3x3 board:
    #
    #    1 2 3
    #    4 5 6
    #    7 8 9
    #
    # This will turn the position # into x,y coordinates, 0 based.
    # For instance, position 4 is 0,1.  Position 1, 0,0 is upper left.
    def position_to_x_y(position)
      x = (position - 1) % @size
      y = (position - 1) / @size
      [x, y]
    end

    # Given an x,y coordinate, return the integer position
    def x_y_to_position(x, y)
      y.to_i * @size + x.to_i + 1
    end
end
