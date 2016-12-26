#ifndef TWENTY48_RESOLVER_HPP

#include <algorithm>
#include <iostream>
#include <iomanip>
#include <vector>

#include "twenty48.hpp"
#include "state.hpp"
#include "start_states.hpp"
#include "state_hash_set.hpp"

namespace twenty48 {
  template <int size>
  struct resolver_t {
    typedef typename state_t<size>::transitions_t transitions_t;
    typedef std::vector<state_t<size> > state_vector_t;

    resolver_t(int max_exponent, int max_lose_depth,
      const state_vector_t &resolved_win_states) :
      max_exponent(max_exponent),
      max_lose_depth(max_lose_depth),
      resolved_win_states(resolved_win_states),
      lose_state(0) {
      if (resolved_win_states.size() < 1) {
        throw std::invalid_argument("bad resolved win states size");
      }
    }

    bool lose_within(const state_t<size> &state, size_t moves) const {
      if (state.cells_available() > moves) return false;
      if (state.lose()) return true;
      if (moves == 0) return false;
      return
        lose_within_after_move(state, moves - 1, DIRECTION_UP) &&
        lose_within_after_move(state, moves - 1, DIRECTION_DOWN) &&
        lose_within_after_move(state, moves - 1, DIRECTION_LEFT) &&
        lose_within_after_move(state, moves - 1, DIRECTION_RIGHT);
    }

    int get_max_exponent() const {
      return max_exponent;
    }

    int max_win_depth() const {
      return (int)resolved_win_states.size() - 1;
    }

    size_t moves_to_win(const state_t<size> &state) const {
      return inner_moves_to_win(state, max_win_depth(), false);
    }

    static const size_t UNKNOWN_MOVES_TO_WIN = (size_t)(-1);

    state_t<size> resolve(const state_t<size> &state) const {
      size_t win_in = moves_to_win(state);
      if (win_in != UNKNOWN_MOVES_TO_WIN) {
        return resolved_win_states[win_in];
      }
      if (lose_within(state, max_lose_depth)) return lose_state;
      return state;
    }

  private:
    int max_exponent;
    int max_lose_depth;
    state_vector_t resolved_win_states;
    state_t<size> lose_state;

    bool lose_within_after_move(const state_t<size> &state, size_t moves,
      direction_t direction) const {

      state_t<size> moved_state = state.move(direction);
      if (moved_state == state) return true; // Cannot move in this direction.

      transitions_t transitions = moved_state.random_transitions();
      for (typename transitions_t::const_iterator it = transitions.begin();
        it != transitions.end(); ++it) {
        if (!lose_within(it->first, moves)) return false;
      }
      return true;
    }

    size_t inner_moves_to_win(
      const state_t<size> &state, int max_depth, bool zeros_unknown) const {
      // If there is no value close enough to the max exponent, we can skip this
      // check, because the maximum value can increase by at most one per move.
      int delta = max_exponent - state.max_value();
      if (delta > max_depth) return UNKNOWN_MOVES_TO_WIN;

      if (delta == 0) {
        return 0;
      }

      if (delta == 1 &&
        state.has_adjacent_pair(max_exponent - 1, zeros_unknown)) {
        return 1;
      }

      state_t<size> state_up = state.move(DIRECTION_UP, zeros_unknown);
      size_t moves_up = inner_moves_to_win(state_up, max_depth - 1, true);

      state_t<size> state_down = state.move(DIRECTION_DOWN, zeros_unknown);
      size_t moves_down = inner_moves_to_win(state_down, max_depth - 1, true);

      state_t<size> state_left = state.move(DIRECTION_LEFT, zeros_unknown);
      size_t moves_left = inner_moves_to_win(state_left, max_depth - 1, true);

      state_t<size> state_right = state.move(DIRECTION_RIGHT, zeros_unknown);
      size_t moves_right = inner_moves_to_win(state_right, max_depth - 1, true);

      size_t moves = std::min(
        std::min(moves_up, moves_down),
        std::min(moves_left, moves_right));

      if (moves != UNKNOWN_MOVES_TO_WIN) moves += 1;
      return moves;
    }
  };

}
#define TWENTY48_RESOLVER_HPP
#endif
