# frozen_string_literal: true

require_relative 'helper'

class BuilderTest < Twenty48Test
  def test_build_2x2_to_4
    builder = Twenty48::Builder.new(2, 2)
    resolver = Twenty48::UnknownZerosResolver.new(builder, 0)
    hash = build_hash_model(builder, resolver)

    assert_equal 5, hash.size
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

    check_lose_state(builder, hash)

    check_win_state(hash, win)

    assert hash.key?(side)
    assert_equal 2, hash[side].size
    assert_close 0.9, hash[side][:up][corner][0]
    assert_equal 0, hash[side][:up][corner][1]
    assert_close 0.1, hash[side][:up][win][0]
    assert_equal 0, hash[side][:up][win][1]
    assert_close 1, hash[side][:right][win][0]
    assert_equal 0, hash[side][:right][win][1]

    assert hash.key?(corner)
    assert_equal 1, hash[corner].size
    assert_close 1, hash[corner][:up][win][0]

    assert hash.key?(diag)
    assert_equal 1, hash[diag].size
    assert_close 0.9, hash[diag][:up][corner][0]
    assert_close 0.1, hash[diag][:up][win][0]
  end

  def test_build_model_2x2_to_4_resolve_1
    builder = Twenty48::Builder.new(2, 2)
    resolver = Twenty48::UnknownZerosResolver.new(builder, 1)
    hash = build_hash_model(builder, resolver)

    #
    # With one-step resolution, we lose the 'corner' state, because it has
    # adjacent 2's, just like the side state.
    #
    assert_equal 4, hash.size
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

    check_lose_state(builder, hash)

    check_win_state(hash, win)

    assert hash.key?(side)
    assert_equal 2, hash[side].size
    assert_close 0.9, hash[side][:up][side][0] # resolved
    assert_equal 0, hash[side][:up][side][1]
    assert_close 0.1, hash[side][:up][win][0]
    assert_equal 0, hash[side][:up][win][1]
    assert_close 1, hash[side][:right][win][0]
    assert_equal 0, hash[side][:right][win][1]

    assert hash.key?(diag)
    assert_equal 1, hash[diag].size
    assert_close 0.9, hash[diag][:up][side][0] # resolved
    assert_close 0.1, hash[diag][:up][win][0]
  end

  def test_build_hash_model_3x3_to_4
    builder = Twenty48::Builder.new(3, 2)
    resolver = Twenty48::UnknownZerosResolver.new(builder, 0)
    hash = build_hash_model(builder, resolver)

    assert_equal 24, hash.size

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

    check_lose_state(builder, hash)

    check_win_state(hash, win)

    assert hash.key?(side)
    assert_equal 2, hash[side].size
    up = hash[side][:up]
    assert_equal 8, up.size
    assert_close 0.1, up[win][0]
    assert_close 0.9 / 7, up[
      Twenty48::State.new([
        0, 0, 0,
        0, 0, 0,
        1, 1, 1
      ])][0] # flipped vertically
    assert_close 0.9 / 7, up[
      Twenty48::State.new([
        0, 0, 0,
        0, 0, 1,
        0, 1, 1
      ])][0] # flipped vertically
    assert_close 0.9 / 7, up[
      Twenty48::State.new([
        0, 0, 0,
        0, 0, 1,
        1, 0, 1
      ])][0] # rotated 90
    assert_close 0.9 / 7, up[
      Twenty48::State.new([
        0, 0, 0,
        0, 0, 1,
        1, 1, 0
      ])][0] # rotated 180
    assert_close 0.9 / 7, up[
      Twenty48::State.new([
        0, 0, 0,
        0, 1, 0,
        0, 1, 1
      ])][0] # flipped vertically
    assert_close 0.9 / 7, up[
      Twenty48::State.new([
        0, 0, 0,
        1, 0, 1,
        0, 0, 1
      ])][0] # rotated 90
    assert_close 0.9 / 7, up[
      Twenty48::State.new([
        0, 0, 1,
        0, 0, 0,
        1, 1, 0
      ])][0] # rotated 180
    assert_close 1, hash[side][:right][win][0]
  end

  def test_build_hash_model_3x3_to_4_resolve_1
    builder = Twenty48::Builder.new(3, 2)
    resolver = Twenty48::UnknownZerosResolver.new(builder, 1)
    hash = build_hash_model(builder, resolver)

    assert_equal 7, hash.size

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

    check_lose_state(builder, hash)

    check_win_state(hash, win)

    assert hash.key?(win)
    assert_equal 1, hash[win].size
    assert_close 1, hash[win][:up][win][0]
    assert_equal 1, hash[win][:up][win][1]

    assert hash.key?(side)
    assert_equal 2, hash[side].size
    assert_close 0.9, hash[side][:up][side][0] # pre-win state
    assert_close 0.1, hash[side][:up][win][0]
    assert_close 1, hash[side][:right][win][0]

    assert hash.key?(diag_t)
    assert_equal 1, hash[diag_t].size
    assert_close 0.9, hash[diag_t][:up][side][0] # pre-win state
    assert_close 0.1, hash[diag_t][:up][win][0]

    assert hash.key?(skew)
    assert_equal 1, hash[skew].size
    assert_close 0.9, hash[diag_t][:up][side][0] # pre-win state
    assert_close 0.1, hash[diag_t][:up][win][0]

    assert hash.key?(diag)
    assert_equal 1, hash[diag].size
    assert_close 0.9, hash[diag][:up][side][0] # pre-win state
    assert_close 0.1, hash[diag][:up][win][0]

    assert hash.key?(corners)
    assert_equal 1, hash[corners].size
    assert_close 0.9, hash[corners][:up][side][0] # pre-win state
    assert_close 0.1, hash[corners][:up][win][0]
  end

  def check_win_state(hash, win)
    assert hash.key?(win)
    assert_equal 1, hash[win].size
    assert_close 1, hash[win][:up][win][0]
    assert_equal 1, hash[win][:up][win][1]
  end

  def check_lose_state(builder, hash)
    lose = Twenty48::State.new([0] * builder.board_size**2)
    assert hash.key?(lose)
    assert_equal 1, hash[lose].size
    assert_close 1, hash[lose][:down][lose][0]
    assert_equal 0, hash[lose][:down][lose][1]
  end
end
