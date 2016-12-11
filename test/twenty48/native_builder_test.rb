# frozen_string_literal: true

require_relative 'helper'

class NativeBuilderTest < Twenty48NativeTest
  include Twenty48

  def test_build_2x2_to_4
    builder = make_builder(2, 2)
    builder.build
    closed_states = builder.closed_states
    assert_equal 5, closed_states.size
    assert_equal 5, builder.count_closed_states

    lose = make_state([
      0, 0,
      0, 0
    ])
    win = make_state([
      0, 0,
      0, 2
    ])
    side = make_state([
      0, 0,
      1, 1
    ])
    corner = make_state([
      0, 1,
      1, 1
    ])
    diag = make_state([
      0, 1,
      1, 0
    ])

    assert closed_states.member?(side)
    assert closed_states.member?(corner)
    assert closed_states.member?(diag)
    assert closed_states.member?(win)
    assert closed_states.member?(lose)
  end

  def test_build_hash_model_3x3_to_4
    builder = make_builder(3, 2)
    builder.build
    closed_states = builder.closed_states

    assert_equal 24, closed_states.size
    assert_equal 24, builder.count_closed_states

    lose = make_state([
      0, 0, 0,
      0, 0, 0,
      0, 0, 0
    ])
    win = make_state([
      0, 0, 0,
      0, 0, 0,
      0, 0, 2
    ])
    side = make_state([
      0, 0, 0,
      0, 0, 0,
      0, 1, 1
    ])

    assert closed_states.member?(lose)
    assert closed_states.member?(win)
    assert closed_states.member?(side)

    # Check that all successors of `side` if we go `up` are closed.
    assert closed_states.member?(make_state([ # flipped vertically
      0, 0, 0,
      0, 0, 0,
      1, 1, 1
    ]))

    assert closed_states.member?(make_state([ # flipped vertically
      0, 0, 0,
      0, 0, 1,
      0, 1, 1
    ]))

    assert closed_states.member?(make_state([ # rotated 90
      0, 0, 0,
      0, 0, 1,
      1, 0, 1
    ]))

    assert closed_states.member?(make_state([ # rotated 180
      0, 0, 0,
      0, 0, 1,
      1, 1, 0
    ]))

    assert closed_states.member?(make_state([ # flipped vertically
      0, 0, 0,
      0, 1, 0,
      0, 1, 1
    ]))

    assert closed_states.member?(make_state([ # rotated 90
      0, 0, 0,
      1, 0, 1,
      0, 0, 1
    ]))

    assert closed_states.member?(make_state([ # rotated 180
      0, 0, 1,
      0, 0, 0,
      1, 1, 0
    ]))
  end
end
