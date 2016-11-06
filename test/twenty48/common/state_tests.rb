# frozen_string_literal: true

module Twenty48
  module CommonStateTests
    def test_inspect_2x2
      assert_equal '[0, 0, 0, 0]', make_state([0, 0, 0, 0]).inspect
      assert_equal '[0, 0, 0, 1]', make_state([0, 0, 0, 1]).inspect
      assert_equal '[1, 0, 0, 0]', make_state([1, 0, 0, 0]).inspect
    end

    def test_eql?
      state0 = make_state([0, 0, 0, 0])
      state1 = make_state([0, 0, 0, 0])
      state2 = make_state([0, 0, 0, 1])

      assert state0.eql?(state0)
      assert state0.eql?(state1)
      refute state0.eql?(state2)
    end

    def test_pretty_print_2x2
      state = make_state([0, 0, 0, 0])
      assert_equal "   .    .\n   .    .", state.pretty_print

      state = make_state([1, 0, 0, 0])
      assert_equal "   2    .\n   .    .", state.pretty_print

      state = make_state([1, 2, 0, 0])
      assert_equal "   2    4\n   .    .", state.pretty_print

      state = make_state([1, 1, 2, 0])
      assert_equal "   2    2\n   4    .", state.pretty_print

      state = make_state([1, 1, 1, 2])
      assert_equal "   2    2\n   2    4", state.pretty_print
    end
  end
end
