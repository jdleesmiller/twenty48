#ifndef TWENTY48_RESOLVER_HPP

#include <algorithm>
#include <cmath>
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

    int get_max_lose_depth() const {
      return max_lose_depth;
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

    double value(const state_t<size> &state, double discount) const {
      return inner_value(state, discount, max_win_depth());
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

    double inner_value(const state_t<size> &state, double discount,
      int depth) const
    {
      // std::cout << std::setw(4*(max_win_depth() - depth)) << depth << ": inner_value: " << state << " delta: " << delta << "avail: " << state.cells_available() << std::endl;
        // std::cout << std::setw(4*(max_win_depth() - depth)) << depth << ": inner_value: moved: " << direction << " new state: " << moved_state << std::endl;

      // If we've won, we're done.
      int delta = max_exponent - state.max_value();
      if (delta <= 0) return 1.0;

      // If there is no value close enough to the max exponent, we can't win,
      // because the maximum value can increase by at most one per move.
      bool can_win = depth >= delta;

      // If there are too many available cells, then we can't lose, because we
      // can't add more than one new tile per move.
      int available = (int)state.cells_available();
      bool can_lose = depth >= available;

      if (!(can_win || can_lose)) return nan("");

      // We also can't win if the sum is too low, because the sum can increase
      // by at most 4 per move.
      if (!can_lose) {
        int sum_delta = (1 << max_exponent) - state.sum();
        if (sum_delta > 4 * depth) return nan("");
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

        double moved_value = value_moved_state(moved_state, discount, depth);
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

    double value_moved_state(const state_t<size> &moved_state,
      double discount, int depth) const
    {
      double result = 0.0;
      transitions_t transitions = moved_state.random_transitions();
      for (typename transitions_t::const_iterator it = transitions.begin();
        it != transitions.end(); ++it)
      {
        double probability = it->second;
        std::cout << std::setw(4*(max_win_depth() - depth)) << depth << ": value_moved_state: " << moved_state << " -> " << it->first << " pr:" << probability << std::endl;
        double successor_value = inner_value(it->first, discount, depth - 1);
        std::cout << std::setw(4*(max_win_depth() - depth)) << depth << ": value_moved_state: succ val: " << it->first << " = " << successor_value << std::endl;
        if (isnan(successor_value)) return nan("");
        result += probability * discount * successor_value;
      }
      if (result < 1e-12) {
        std::cout << std::setw(4*(max_win_depth() - depth)) << depth << ": value_moved_state: zero value: " << moved_state << std::endl;
      }
      return result;
    }
  };

}
#define TWENTY48_RESOLVER_HPP
#endif
