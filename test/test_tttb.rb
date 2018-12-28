#--
# Copyright 2018 Michael Chaney Consulting Corporation
#
# Released under the terms of the MIT License or the GNU
# General Public License, v. 2
#++

require 'minitest/autorun'
require_relative '../tic_tac_toe_board'

class TTTBTest < Minitest::Test
  def setup
    @options = {}
  end

  def teardown
  end

  def test_has_expected_methods
    tttb = TicTacToeBoard.new(size: 3)

    assert_respond_to tttb, :next_player
    assert_respond_to tttb, :apply_move
    assert_respond_to tttb, :display
    assert_respond_to tttb, :display_entire_game
    assert_respond_to tttb, :==

    # attributes
    assert_respond_to tttb, :size
    assert_respond_to tttb, :board
    assert_respond_to tttb, :current_player
    assert_respond_to tttb, :current_move
    assert_respond_to tttb, :turn
    assert_respond_to tttb, :game_over
    assert_respond_to tttb, :flags
    assert_respond_to tttb, :parent
  end

  def test_simple_game
    # No winner
    move_list = [5,1,2,8,4,6,9,3,7]
    tttb = TicTacToeBoard.new(size: 3)
    assert tttb.flags[:empty]
    assert_equal 0, tttb.turn
    move_list.each { |move| tttb = tttb.apply_move(move) }
    assert tttb.game_over
    assert_equal 9, tttb.turn
    assert tttb.flags[:full]
    assert tttb.flags[:stalemate]
    refute tttb.flags[:winner]
    refute tttb.flags[:empty]
  end

  def test_game_with_winner
    move_list = [5,2,3,7,9,6,1]
    tttb = TicTacToeBoard.new(size: 3)
    move_list.each { |move| tttb = tttb.apply_move(move) }
    assert tttb.game_over
    assert_equal 7, tttb.turn
    refute tttb.flags[:full]
    refute tttb.flags[:stalemate]
    assert_equal 0, tttb.flags[:winner]
  end

  def test_game_with_double_win
    move_list = [1,2,3,6,9,8,7,4,5]
    tttb = TicTacToeBoard.new(size: 3)
    move_list.each { |move| tttb = tttb.apply_move(move) }
    assert tttb.game_over
    assert_equal 9, tttb.turn
    assert tttb.flags[:full]
    refute tttb.flags[:stalemate]
    assert_equal 0, tttb.flags[:winner]
  end

  def test_game_can_be_four_by_four
    move_list = [1,2,3,6,9,8,7,4,5,10,13]
    tttb = TicTacToeBoard.new(size: 4)
    move_list.each { |move| tttb = tttb.apply_move(move) }
    assert tttb.game_over
    assert_equal 11, tttb.turn
    refute tttb.flags[:full]
    refute tttb.flags[:stalemate]
    assert_equal 0, tttb.flags[:winner]
  end

  def test_game_can_be_five_by_five
    move_list = [1,2,3,6,9,8,7,4,5,10,13,14,19,20,25]
    tttb = TicTacToeBoard.new(size: 5)
    move_list.each { |move| tttb = tttb.apply_move(move) }
    assert tttb.game_over
    assert_equal 15, tttb.turn
    refute tttb.flags[:full]
    refute tttb.flags[:stalemate]
    assert_equal 0, tttb.flags[:winner]
  end

  def test_game_cannot_be_smaller_than_three
    assert_raises(StandardError) { TicTacToeBoard.new(size: 2) }
  end

  def test_game_cannot_be_larger_than_five
    assert_raises(StandardError) { TicTacToeBoard.new(size: 6) }
  end

  def test_cannot_continue_a_finished_game
    move_list = [5,2,3,7,9,6,1]
    tttb = TicTacToeBoard.new(size: 3)
    move_list.each { |move| tttb = tttb.apply_move(move) }
    assert tttb.game_over
    assert_raises(StandardError) { tttb.apply_move(8) }
  end

  def test_cannot_move_on_occupied_position
    move_list = [5,2,3,7,9,6]
    tttb = TicTacToeBoard.new(size: 3)
    move_list.each { |move| tttb = tttb.apply_move(move) }
    assert_raises(StandardError) { tttb.apply_move(6) }
  end

  def test_can_create_tttb_from_array
    tttb = TicTacToeBoard.new(array: [[nil,nil,nil],[nil,nil,nil],[nil,nil,nil]])
    assert tttb.is_a?(TicTacToeBoard)
  end

  def test_create_from_array_must_be_correct_size
    assert_raises(StandardError) {
      TicTacToeBoard.new(array: [[nil, nil], [nil, nil]])
    }
  end

  def test_create_from_array_must_have_valid_values
    assert_raises(StandardError) {
      TicTacToeBoard.new(array: [[nil,nil,nil],[nil,2,nil],[nil,nil,nil]])
    }
  end

  def test_create_from_array_must_be_square
    assert_raises(StandardError) {
      TicTacToeBoard.new(array: [[nil,nil],[nil,0,nil],[nil,nil,nil]])
    }
  end

  def test_create_from_array_must_have_balanced_moves
    assert_raises(StandardError) {
      TicTacToeBoard.new(array: [[nil,1,1],[nil,0,nil],[nil,nil,nil]])
    }
    assert_raises(StandardError) {
      TicTacToeBoard.new(array: [[nil,0,0],[0,1,nil],[nil,nil,nil]])
    }
  end

  def test_create_from_array_works_with_game_in_progress
    board = [[nil,0,0],[1,1,nil],[nil,nil,nil]]
    tttb = TicTacToeBoard.new(array: board)
    assert_equal 4, tttb.turn
    assert_equal 1, tttb.current_player
    assert_nil tttb.current_move
    assert_equal board, tttb.board
  end

  def test_move_is_applied_properly
    tttb = TicTacToeBoard.new(size: 3)
    tttb = tttb.apply_move(5)
    assert_equal 0, tttb.board[1][1]
  end
end
