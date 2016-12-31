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
      max_exponent(max_exponent), max_depth(max_depth), discount(discount) { }

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
      return inner_value(state, max_depth);
    }

  private:
    int max_exponent;
    int max_depth;
    double discount;

    double inner_value(const state_t<size> &state, int depth) const
    {
      // std::cout << std::setw(4*(max_win_depth() - depth)) << depth << ": inner_value: " << state << " delta: " << delta << "avail: " << state.cells_available() << std::endl;
        // std::cout << std::setw(4*(max_win_depth() - depth)) << depth << ": inner_value: moved: " << direction << " new state: " << moved_state << std::endl;

      // If we've won, we're done.
      int delta = max_exponent - state.max_value();
      if (delta <= 0) return 1.0;

      // If there is no value close enough to the max exponent, we can't win,
      // because the maximum value can increase by at most one per move.
      // We also can't win if the sum is too low, because we can only count on
      // the sum increasing by 2 per move.
      int sum_delta = (1 << max_exponent) - state.sum();
      bool can_win = depth >= delta && 2 * depth >= sum_delta;

      // If there are too many available cells, then we can't lose, because we
      // can't add more than one new tile per move. If we can't win or lose,
      // we can't value the state, so give up.
      if (!can_win) {
        int available = (int)state.cells_available();
        bool can_lose = depth >= available;
        if (!can_lose) return nan("");
      }

      // Don't bother doing a big search if there are an adjacent pair of tiles
      // that we can merge for the win; this is quite easy to check.
      if (can_win && delta == 1) {
        if (state.has_adjacent_pair(max_exponent - 1, false)) {
          return discount * 1.0;
        }
      }

      bool any_possible_moves = false;
      bool any_unknown = false;
      double best_value = nan("");
      for (size_t i = 0; i < 4; ++i) {
        direction_t direction = (direction_t)i;
        state_t<size> moved_state = state.move(direction);
        if (moved_state == state) continue;
        any_possible_moves = true;

        // At this point, we've established that we have not lost, so if we are
        // out of depth, we can't expand any more states; we have to give up.
        if (depth <= 0) return nan("");

        double moved_value = value_moved_state(moved_state, depth);
        if (isnan(moved_value)) {
          // If we are looking for a definite loss, a NaN value for one of the
          // actions means this is not a definite loss, so we can stop early.
          if (!can_win) return nan("");
          any_unknown = true;
          continue;
        }

        if (isnan(best_value)) {
          best_value = moved_value;
        } else {
          if (moved_value > best_value) {
            best_value = moved_value;
          }
        }
      }

      // If we can't move, we've lost, and we can stop.
      if (!any_possible_moves) return 0.0;

      // If all actions resulted in a loss, best_value will be zero and there
      // will not be any unknowns, so we can return 0. However, if there were
      // any unknowns, this is not a definite loss.
      if (best_value == 0 && any_unknown) return nan("");

      return best_value;
    }

    double value_moved_state(const state_t<size> &moved_state, int depth) const
    {
        // std::cout << std::setw(4*(max_depth - depth)) << depth << ": value_moved_state: " << moved_state << " -> " << it->first << " pr:" << probability << std::endl;
        // std::cout << std::setw(4*(max_depth - depth)) << depth << ": value_moved_state: succ val: " << it->first << " = " << successor_value << std::endl;
      double result = 0.0;
      transitions_t transitions = moved_state.random_transitions();
      for (typename transitions_t::const_iterator it = transitions.begin();
        it != transitions.end(); ++it)
      {
        double probability = it->second;
        double successor_value = inner_value(it->first, depth - 1);
        if (isnan(successor_value)) return nan("");
        result += probability * discount * successor_value;
      }
      // if (result < 1e-12) {
      //   std::cout << std::setw(4*(max_depth - depth)) << depth << ": value_moved_state: zero value: " << moved_state << std::endl;
      // }
      return result;
    }
  };

}

#define TWENTY48_VALUER_HPP
#endif
