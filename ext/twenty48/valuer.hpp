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
      double result = inner_value(state, max_depth);
      if (result >= 0) return result;
      return nan("");
    }

  private:
    int max_exponent;
    int max_depth;
    double discount;

    double inner_value(const state_t<size> &state, int depth) const
    {
      // std::cout << std::setw(4*(max_depth - depth)) << depth << ": inner_value: " << state << " delta: " << max_exponent - state.max_value() << " avail: " << state.cells_available() << std::endl;

      // If we've won, we're done.
      int delta = max_exponent - state.max_value();
      if (delta <= 0) return 1.0;

      // If we can't search any deeper, and we haven't won or lost, we need an
      // upper bound on the value of the state. We can do this by assuming that
      // we win in the minimum number of moves, which is delta.
      if (depth <= 0) {
        if (state.lose()) return 0.0;
        return -pow(discount, delta);
      }

      // If there is no value close enough to the max exponent, we can't win,
      // because the maximum value can increase by at most one per move.
      // We also can't win if the sum is too low, because we can only count on
      // the sum increasing by 2 per move.
      // TODO: it seems a bit odd to check this for every state. If we
      // established that we could not win, nothing we do after that is going
      // to make it possible to win. The converse is not true, however: I think
      // it is useful to continue checking these bounds if we were once able
      // to win but now can't.
      int sum_delta = (1 << max_exponent) - state.sum();
      bool can_win = depth >= delta && 2 * depth >= sum_delta;

      // If there are too many available cells, then we can't lose, because we
      // can't add more than one new tile per move. If we can't win or lose,
      // we can't value the state, so give up.
      if (!can_win) {
        int available = (int)state.cells_available();
        bool can_lose = depth >= available;
        if (!can_lose) return -pow(discount, delta);
      }

      // Don't bother doing a big search if there are an adjacent pair of tiles
      // that we can merge for the win; this is quite easy to check. We could
      // alternatively check this after moving but before doing transitions, in
      // the action loop below. Not sure which one would be faster.
      if (can_win && delta == 1) {
        if (state.has_adjacent_pair(max_exponent - 1, false)) {
          return discount * 1.0;
        }
      }

      bool any_possible_moves = false;
      double best_known = nan("");
      double best_unknown = nan("");
      for (size_t i = 0; i < 4; ++i) {
        direction_t direction = (direction_t)i;
        state_t<size> moved_state = state.move(direction);
        if (moved_state == state) continue;
        any_possible_moves = true;

        // std::cout << std::setw(4*(max_depth - depth)) << depth << ": inner_value: moving: " << direction << " new state: " << moved_state << std::endl;
        double moved_value = value_moved_state(moved_state, depth);
        // std::cout << std::setw(4*(max_depth - depth)) << depth << ": inner_value: moved: " << direction << " new state: " << moved_state << " value: " << moved_value << std::endl;
        if (moved_value >= 0) {
          // Value is known.
          if (std::isnan(best_known) || moved_value > best_known) {
            best_known = moved_value;
          }
        } else {
          // Value is not known.
          if (std::isnan(best_unknown) || -moved_value > best_unknown) {
            best_unknown = -moved_value;
          }
        }
      }

      if (!any_possible_moves) return 0.0;
      if (!std::isnan(best_known) && !std::isnan(best_unknown)) {
        if (best_known > best_unknown) return best_known;
        return -best_unknown;
      }
      if (!std::isnan(best_known)) {
        return best_known;
      }
      if (!std::isnan(best_unknown)) {
        return -best_unknown;
      }
      throw std::logic_error("no known or unknown values");
    }

    double value_moved_state(const state_t<size> &moved_state, int depth) const
    {
      double sign = 1.0;
      double result = 0.0;
      transitions_t transitions = moved_state.random_transitions();
      for (typename transitions_t::const_iterator it = transitions.begin();
        it != transitions.end(); ++it)
      {
        double probability = it->second;
        // std::cout << std::setw(4*(max_depth - depth)) << depth << ": value_moved_state: " << moved_state << " -> " << it->first << " pr:" << probability << std::endl;
        double successor_value = inner_value(it->first, depth - 1);
        // std::cout << std::setw(4*(max_depth - depth)) << depth << ": value_moved_state: succ val: " << it->first << " = " << successor_value << std::endl;
        if (successor_value < 0) {
          sign = -1.0;
          successor_value *= -1;
        }
        result += probability * discount * successor_value;
      }
      return sign * result;
    }
  };

}

#define TWENTY48_VALUER_HPP
#endif
