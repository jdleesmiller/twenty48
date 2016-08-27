# frozen_string_literal: true

require 'minitest/autorun'

require_relative '../../lib/twenty_48'

class ModelTest < Minitest::Test
  def assert_close(x, y)
    assert_in_delta x, y, 1e-6
  end

  def test_random_tile_successors_hash_2x2
    model = Twenty48::Model.new(2, 3)

    hash = model.random_tile_successors_hash(Twenty48::State.new([
      0, 0,
      0, 1
    ]))

    assert_close hash[Twenty48::State.new([
      0, 0,
      1, 1
    ])], 0.6
    assert_close hash[Twenty48::State.new([
      0, 1,
      1, 0
    ])], 0.3
    assert_close hash[Twenty48::State.new([
      0, 0,
      1, 2
    ])], 2 * 0.1 / 3
    assert_close hash[Twenty48::State.new([
      0, 1,
      2, 0
    ])], 1 * 0.1 / 3
  end

  def test_start_states_2x2
    model = Twenty48::Model.new(2, 2)
    assert_equal [
      [0, 0,
       0, 2], # canonicalized to winning state
      [0, 0,
       1, 1],
      [0, 1,
       1, 0]
    ].map { |state_array| Twenty48::State.new(state_array) }, model.start_states

    model = Twenty48::Model.new(2, 3)
    assert_equal [
      [0, 0,
       1, 1],
      [0, 0,
       1, 2],
      [0, 0,
       2, 2],
      [0, 1,
       1, 0],
      [0, 1,
       2, 0],
      [0, 2,
       2, 0]
    ].map { |state_array| Twenty48::State.new(state_array) }, model.start_states
  end

  def test_start_states_2x2_with_pre_win
    model = Twenty48::Model.new(2, 2, true)
    assert_equal [
      [0, 0,
       0, 2], # canonicalized to winning state
      [0, 0,
       1, 1], # actually the pre-win state
      [0, 1,
       1, 0]
    ].map { |state_array| Twenty48::State.new(state_array) }, model.start_states

    model = Twenty48::Model.new(2, 3, true)
    assert_equal [
      [0, 0,
       1, 1],
      [0, 0,
       1, 2],
      [0, 0,
       2, 2], # actually the pre-win state
      [0, 1,
       1, 0],
      [0, 1,
       2, 0],
      [0, 2,
       2, 0]
    ].map { |state_array| Twenty48::State.new(state_array) }, model.start_states
  end

  def test_build_hash_model_2x2_game_of_4
    model = Twenty48::Model.new(2, 2)
    hash = model.build_hash_model

    assert_equal 4, hash.size
    win = Twenty48::State.new([
      0, 0,
      0, 2
    ])
    side = Twenty48::State.new([
      0, 0,
      1, 1
    ])
    corner = Twenty48::State.new([
      0, 1,
      1, 1
    ])
    diag = Twenty48::State.new([
      0, 1,
      1, 0
    ])

    assert hash.key?(win)
    assert_equal 4, hash[win].size
    assert_close 1, hash[win][:up][win]
    assert_close 1, hash[win][:right][win]
    assert_close 1, hash[win][:down][win]
    assert_close 1, hash[win][:left][win]

    assert hash.key?(side)
    assert_equal 4, hash[side].size
    assert_close 0.9, hash[side][:up][corner]
    assert_close 0.1, hash[side][:up][win]
    assert_close 1, hash[side][:right][win]
    assert_close 1, hash[side][:down][side]
    assert_close 1, hash[side][:left][win]

    assert hash.key?(corner)
    assert_equal 4, hash[corner].size
    assert_close 1, hash[corner][:up][win]
    assert_close 1, hash[corner][:right][win]
    assert_close 1, hash[corner][:down][win]
    assert_close 1, hash[corner][:left][win]

    assert hash.key?(diag)
    assert_equal 4, hash[diag].size
    assert_close 0.9, hash[diag][:up][corner]
    assert_close 0.1, hash[diag][:up][win]
    assert_close 0.9, hash[diag][:right][corner]
    assert_close 0.1, hash[diag][:right][win]
    assert_close 0.9, hash[diag][:down][corner]
    assert_close 0.1, hash[diag][:down][win]
    assert_close 0.9, hash[diag][:left][corner]
    assert_close 0.1, hash[diag][:left][win]
  end

  def test_build_hash_model_2x2_game_of_4_pre_win
    model = Twenty48::Model.new(2, 2, true)
    hash = model.build_hash_model

    #
    # With pre-win, we lose the 'corner' state, because it has adjacent 2's,
    # which we consider a pre-win state.
    #
    assert_equal 3, hash.size
    win = Twenty48::State.new([
      0, 0,
      0, 2
    ])
    side = Twenty48::State.new([
      0, 0,
      1, 1
    ])
    diag = Twenty48::State.new([
      0, 1,
      1, 0
    ])

    assert hash.key?(win)
    assert_equal 4, hash[win].size
    assert_close 1, hash[win][:up][win]
    assert_close 1, hash[win][:right][win]
    assert_close 1, hash[win][:down][win]
    assert_close 1, hash[win][:left][win]

    assert hash.key?(side)
    assert_equal 4, hash[side].size
    assert_close 0.9, hash[side][:up][side] # pre-win state
    assert_close 0.1, hash[side][:up][win]
    assert_close 1, hash[side][:right][win]
    assert_close 1, hash[side][:down][side]
    assert_close 1, hash[side][:left][win]

    assert hash.key?(diag)
    assert_equal 4, hash[diag].size
    assert_close 0.9, hash[diag][:up][side] # pre-win state
    assert_close 0.1, hash[diag][:up][win]
    assert_close 0.9, hash[diag][:right][side] # pre-win state
    assert_close 0.1, hash[diag][:right][win]
    assert_close 0.9, hash[diag][:down][side] # pre-win state
    assert_close 0.1, hash[diag][:down][win]
    assert_close 0.9, hash[diag][:left][side] # pre-win state
    assert_close 0.1, hash[diag][:left][win]
  end

  def test_build_hash_model_3x3_game_of_4
    model = Twenty48::Model.new(3, 2)
    hash = model.build_hash_model

    assert_equal 23, hash.size

    win = Twenty48::State.new([
      0, 0, 0,
      0, 0, 0,
      0, 0, 2
    ])
    side = Twenty48::State.new([
      0, 0, 0,
      0, 0, 0,
      0, 1, 1
    ])

    assert hash.key?(win)
    assert_equal 4, hash[win].size
    assert_close 1, hash[win][:up][win]
    assert_close 1, hash[win][:right][win]
    assert_close 1, hash[win][:down][win]
    assert_close 1, hash[win][:left][win]

    assert hash.key?(side)
    assert_equal 4, hash[side].size
    up = hash[side][:up]
    assert_equal 8, up.size
    assert_close 0.1, up[win]
    assert_close 0.9 / 7, up[
      Twenty48::State.new([
        0, 0, 0,
        0, 0, 0,
        1, 1, 1
      ])] # flipped vertically
    assert_close 0.9 / 7, up[
      Twenty48::State.new([
        0, 0, 0,
        0, 0, 1,
        0, 1, 1
      ])] # flipped vertically
    assert_close 0.9 / 7, up[
      Twenty48::State.new([
        0, 0, 0,
        0, 0, 1,
        1, 0, 1
      ])] # rotated 90
    assert_close 0.9 / 7, up[
      Twenty48::State.new([
        0, 0, 0,
        0, 0, 1,
        1, 1, 0
      ])] # rotated 180
    assert_close 0.9 / 7, up[
      Twenty48::State.new([
        0, 0, 0,
        0, 1, 0,
        0, 1, 1
      ])] # flipped vertically
    assert_close 0.9 / 7, up[
      Twenty48::State.new([
        0, 0, 0,
        1, 0, 1,
        0, 0, 1
      ])] # rotated 90
    assert_close 0.9 / 7, up[
      Twenty48::State.new([
        0, 0, 1,
        0, 0, 0,
        1, 1, 0
      ])] # rotated 180
    assert_close 1, hash[side][:right][win]
    assert_close 1, hash[side][:down][side]
    assert_close 1, hash[side][:left][win]

    # puts
    # puts model.pretty_print_hash_model(hash)
  end

  def test_build_hash_model_3x3_game_of_4_with_pre_win
    model = Twenty48::Model.new(3, 2, true)
    hash = model.build_hash_model

    assert_equal 6, hash.size

    win = Twenty48::State.new([
      0, 0, 0,
      0, 0, 0,
      0, 0, 2
    ])
    side = Twenty48::State.new([
      0, 0, 0,
      0, 0, 0,
      0, 1, 1
    ])
    diag_t = Twenty48::State.new([
      0, 0, 0,
      0, 0, 1,
      0, 1, 0
    ])
    skew = Twenty48::State.new([
      0, 0, 0,
      0, 0, 1,
      1, 0, 0
    ])
    diag = Twenty48::State.new([
      0, 0, 0,
      0, 1, 0,
      0, 0, 1
    ])
    corners = Twenty48::State.new([
      0, 0, 1,
      0, 0, 0,
      1, 0, 0
    ])

    assert hash.key?(win)
    assert_equal 4, hash[win].size
    assert_close 1, hash[win][:up][win]
    assert_close 1, hash[win][:right][win]
    assert_close 1, hash[win][:down][win]
    assert_close 1, hash[win][:left][win]

    assert hash.key?(side)
    assert_equal 4, hash[side].size
    assert_close 0.9, hash[side][:up][side] # pre-win state
    assert_close 0.1, hash[side][:up][win]
    assert_close 1, hash[side][:right][win]
    assert_close 1, hash[side][:down][side]
    assert_close 1, hash[side][:left][win]

    assert hash.key?(diag_t)
    assert_equal 4, hash[diag_t].size
    assert_close 0.9, hash[diag_t][:up][side] # pre-win state
    assert_close 0.1, hash[diag_t][:up][win]
    assert_close 0.9, hash[diag_t][:right][side] # pre-win state
    assert_close 0.1, hash[diag_t][:right][win]
    assert_close 0.9, hash[diag_t][:down][side] # pre-win state
    assert_close 0.1, hash[diag_t][:down][win]
    assert_close 0.9, hash[diag_t][:left][side] # pre-win state
    assert_close 0.1, hash[diag_t][:left][win]

    assert hash.key?(skew)
    assert_equal 4, hash[skew].size
    assert_close 0.9, hash[diag_t][:up][side] # pre-win state
    assert_close 0.1, hash[diag_t][:up][win]
    assert_close 0.9, hash[diag_t][:right][side] # pre-win state
    assert_close 0.1, hash[diag_t][:right][win]
    assert_close 0.9, hash[diag_t][:down][side] # pre-win state
    assert_close 0.1, hash[diag_t][:down][win]
    assert_close 0.9, hash[diag_t][:left][side] # pre-win state
    assert_close 0.1, hash[diag_t][:left][win]

    assert hash.key?(diag)
    assert_equal 4, hash[diag].size
    assert_close 0.9, hash[diag][:up][side] # pre-win state
    assert_close 0.1, hash[diag][:up][win]
    assert_close 0.9, hash[diag][:right][side] # pre-win state
    assert_close 0.1, hash[diag][:right][win]
    assert_close 0.9, hash[diag][:down][side] # pre-win state
    assert_close 0.1, hash[diag][:down][win]
    assert_close 0.9, hash[diag][:left][side] # pre-win state
    assert_close 0.1, hash[diag][:left][win]

    assert hash.key?(corners)
    assert_equal 4, hash[corners].size
    assert_close 0.9, hash[corners][:up][side] # pre-win state
    assert_close 0.1, hash[corners][:up][win]
    assert_close 0.9, hash[corners][:right][side] # pre-win state
    assert_close 0.1, hash[corners][:right][win]
    assert_close 0.9, hash[corners][:down][side] # pre-win state
    assert_close 0.1, hash[corners][:down][win]
    assert_close 0.9, hash[corners][:left][side] # pre-win state
    assert_close 0.1, hash[corners][:left][win]
  end

  def test_add_rewards_to_hash_2x2
    model = Twenty48::Model.new(2, 2, true)
    hash = model.build_hash_model
    model.add_rewards_to_hash(hash)

    assert_equal 3, hash.size
    win = Twenty48::State.new([
      0, 0,
      0, 2
    ])
    side = Twenty48::State.new([
      0, 0,
      1, 1
    ])

    assert hash.key?(win)
    assert_equal 4, hash[win].size
    assert_close 1, hash[win][:up][win][0]
    assert_close 1, hash[win][:up][win][1]
    assert_close 1, hash[win][:right][win][0]
    assert_close 1, hash[win][:right][win][1]
    assert_close 1, hash[win][:down][win][0]
    assert_close 1, hash[win][:down][win][1]
    assert_close 1, hash[win][:left][win][0]
    assert_close 1, hash[win][:left][win][1]

    assert hash.key?(side)
    assert_equal 4, hash[side].size
    assert_close 0.9, hash[side][:up][side][0] # pre-win state
    assert_close 0, hash[side][:up][side][1]
    assert_close 0.1, hash[side][:up][win][0]
    assert_close 1, hash[side][:up][win][1]
    assert_close 1, hash[side][:right][win][0]
    assert_close 1, hash[side][:right][win][1]
    assert_close 1, hash[side][:down][side][0]
    assert_close 0, hash[side][:down][side][1]
    assert_close 1, hash[side][:left][win][0]
    assert_close 1, hash[side][:left][win][1]
  end
end
