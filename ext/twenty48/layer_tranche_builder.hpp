#ifndef TWENTY48_LAYER_TRANCHE_BUILDER_HPP

#include <iostream>

#include "btree_map.h"

#include "twenty48.hpp"
#include "state.hpp"
#include "valuer.hpp"
#include "mmap_value_reader.hpp"
#include "vbyte_reader.hpp"
#include "vbyte_writer.hpp"
#include "policy_reader.hpp"
#include "alternate_action_reader.hpp"
#include "binary_writer.hpp"
#include "bit_set_writer.hpp"

namespace twenty48 {
  /**
   * Calculate the transient and absorbing probabilities of states when
   * following a given policy.
   */
  template <int size> struct layer_tranche_builder_t {
    layer_tranche_builder_t(
      uint8_t max_exponent, double threshold,
      int start_sum, uint8_t start_max_value,
      const char *transient_pathname)
    : max_exponent(max_exponent), threshold(threshold),
      start_sum(start_sum), start_max_value(start_max_value),
      transient(transient_pathname)
    { }

    void build(
      twenty48::vbyte_reader_t &vbyte_reader,
      twenty48::policy_reader_t &policy_reader,
      const char *bitset_pathname, const char *transient_pr_pathname
    ) {
      bit_set_writer_t bit_set_writer(bitset_pathname);
      binary_writer_t<double> transient_pr_writer(transient_pr_pathname);

      for (;;) {
        uint64_t nybbles = vbyte_reader.read();
        if (nybbles == 0) break;

        state_t<size> state(nybbles);
        direction_t direction = policy_reader.read();

        // If we have never seen this state, it's not reachable.
        state_value_t *transient_state_pr = transient.maybe_find(nybbles);
        if (transient_state_pr == NULL) {
          bit_set_writer.write(false);
          continue;
        }

        // Write out
        double state_pr = transient_state_pr->value;
        if (state_pr > threshold) {
          bit_set_writer.write(true);
          transient_pr_writer.write(state_pr);
        } else {
          bit_set_writer.write(false);
        }

        state_t<size> move_state = state.move(direction);
        transitions_t transitions = move_state.random_transitions();
        for (typename transitions_t::const_iterator it = transitions.begin();
          it != transitions.end(); ++it)
        {
          add_pr(it->first, state_pr * it->second);
        }
      }
    }

    void write(
      const char *transient_pathname_1_0, const char *transient_pathname_1_1,
      const char *transient_pathname_2_0, const char *transient_pathname_2_1,
      const char *loss_pathname_1_0, const char *loss_pathname_1_1,
      const char *loss_pathname_2_0, const char *loss_pathname_2_1,
      const char *win_pathname_1, const char *win_pathname_2)
    {
      write_state_probability_map(transient_1_0, transient_pathname_1_0, true);
      write_state_probability_map(transient_1_1, transient_pathname_1_1, true);
      write_state_probability_map(transient_2_0, transient_pathname_2_0, true);
      write_state_probability_map(transient_2_1, transient_pathname_2_1, true);
      write_state_probability_map(loss_1_0, loss_pathname_1_0, false);
      write_state_probability_map(loss_1_1, loss_pathname_1_1, false);
      write_state_probability_map(loss_2_0, loss_pathname_2_0, false);
      write_state_probability_map(loss_2_1, loss_pathname_2_1, false);
      write_state_probability_map(win_1, win_pathname_1, false);
      write_state_probability_map(win_2, win_pathname_2, false);
    }

  private:
    typedef btree::btree_map<state_t<size>, double> state_probability_map_t;
    typedef typename state_t<size>::transitions_t transitions_t;

    typedef std::pair<uint64_t, double> state_pr_t;

    void add_pr(const state_t<size> &state, double probability) {
      int state_sum = state.sum();
      uint8_t state_max_value = state.max_value();

      int sum_delta = state_sum - start_sum;
      assert(sum_delta == 2 || sum_delta == 4);

      uint8_t value_delta = state_max_value - start_max_value;
      assert(value_delta == 0 || value_delta == 1);

      if (state_max_value >= max_exponent) {
        if (sum_delta == 2) {
          add_pr(win_1, state, probability);
        } else {
          add_pr(win_2, state, probability);
        }
      } else if (state.lose()) {
        if (sum_delta == 2) {
          if (value_delta == 0) {
            add_pr(loss_1_0, state, probability);
          } else {
            add_pr(loss_1_1, state, probability);
          }
        } else {
          if (value_delta == 0) {
            add_pr(loss_2_0, state, probability);
          } else {
            add_pr(loss_2_1, state, probability);
          }
        }
      } else {
        if (sum_delta == 2) {
          if (value_delta == 0) {
            add_pr(transient_1_0, state, probability);
          } else {
            add_pr(transient_1_1, state, probability);
          }
        } else {
          if (value_delta == 0) {
            add_pr(transient_2_0, state, probability);
          } else {
            add_pr(transient_2_1, state, probability);
          }
        }
      }
    }

    void add_pr(state_probability_map_t &map,
      const state_t<size> &state, double probability)
    {
      typename state_probability_map_t::const_iterator it = map.find(state);
      if (it == map.end()) {
        map[state] = probability;
      } else {
        map[state] = it->second + probability;
      }
    }

    void write_state_probability_map(
      state_probability_map_t &map, const char *pathname, bool all_states)
    {
      if (pathname == NULL) return;
      if (map.size() == 0) return;

      binary_writer_t<state_pr_t> writer(pathname);
      for (typename state_probability_map_t::const_iterator it = map.begin();
        it != map.end(); ++it)
      {
        state_pr_t pair(it->first.get_nybbles(), it->second);
        if (all_states || it->second > threshold) writer.write(pair);
      }
      map.clear();
    }

    uint8_t max_exponent;
    double threshold;
    int start_sum;
    uint8_t start_max_value;
    mmap_value_reader_t transient;
    state_probability_map_t transient_1_0;
    state_probability_map_t transient_1_1;
    state_probability_map_t transient_2_0;
    state_probability_map_t transient_2_1;
    state_probability_map_t win_1;
    state_probability_map_t win_2;
    state_probability_map_t loss_1_0;
    state_probability_map_t loss_1_1;
    state_probability_map_t loss_2_0;
    state_probability_map_t loss_2_1;
  };
}

#define TWENTY48_LAYER_TRANCHE_BUILDER_HPP
#endif
