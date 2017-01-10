#ifndef TWENTY48_VALUER_HPP

#include <cmath>
#include <iostream>
#include <iomanip>

#include "twenty48.hpp"
#include "state.hpp"

namespace twenty48 {
  template <int size>
  struct valuer_t {
    typedef typename state_t<size>::transitions_t transitions_t;

    valuer_t(int max_exponent, int max_depth, double discount) :
      max_exponent(max_exponent), max_depth(max_depth), discount(discount) {
      if (max_depth < 0 || max_depth > 1) {
        throw new std::invalid_argument("bad max_depth");
      }
    }

    int get_max_exponent() const {
      return max_exponent;
    }

    int get_max_depth() const {
      return max_depth;
    }

    double get_discount() const {
      return discount;
    }

    double value(const state_t<size> &state) const {
      int win_delta = max_exponent - state.max_value();

      // We have already won.
      if (win_delta <= 0) return 1.0;

      // If we're searching one move ahead, see whether we're about to win.
      if (win_delta == 1 && max_depth > 0) {
        if (state.has_adjacent_pair(max_exponent - 1)) return discount;
      }

      // We can't lose unless the board is full, and the number of available
      // cells can decrease by at most one per move, so if we have more cells
      // available than moves within search depth, we can't lose.
      if (state.cells_available() > max_depth) return nan("");

      // Check for a loss.
      if (lose_within(state, max_depth)) return 0.0;

      // Otherwise, we don't know.
      return nan("");
    }

  private:
    int max_exponent;
    int max_depth;
    double discount;

    bool lose_within(const state_t<size> &state, int moves) const {
      return
        lose_within_after_move(state, moves, DIRECTION_UP) &&
        lose_within_after_move(state, moves, DIRECTION_DOWN) &&
        lose_within_after_move(state, moves, DIRECTION_LEFT) &&
        lose_within_after_move(state, moves, DIRECTION_RIGHT);
    }

    bool lose_within_after_move(const state_t<size> &state, int moves,
      direction_t direction) const {
      // If we cannot move in this direction, we may have lost.
      state_t<size> moved_state = state.move(direction);
      if (moved_state == state) return true;

      // If we can move in this direction and we've reached our search depth,
      // we have not lost.
      if (moves == 0) return false;

      transitions_t transitions = moved_state.random_transitions();
      for (typename transitions_t::const_iterator it = transitions.begin();
        it != transitions.end(); ++it) {
        if (!lose_within(it->first, moves - 1)) return false;
      }
      return true;
    }
  };
}

#define TWENTY48_VALUER_HPP
#endif
