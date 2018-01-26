#ifndef TWENTY48_LAYER_TRANCHE_BUILDER_HPP

#include <iostream>

#include "btree_map.h"

#include "twenty48.hpp"
#include "state.hpp"
#include "valuer.hpp"
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
    layer_tranche_builder_t(uint8_t max_exponent, double threshold)
    : max_exponent(max_exponent), threshold(threshold)
    { }

    void add_start_state_probabilities() {
      state_t<size> empty_state(0ULL);
      transitions_t empty_transitions = empty_state.random_transitions();
      for (typename transitions_t::const_iterator it0 =
        empty_transitions.begin(); it0 != empty_transitions.end(); ++it0)
      {
        transitions_t one_tile_transitions = it0->first.random_transitions();
        for (typename transitions_t::const_iterator it1 =
          one_tile_transitions.begin();
          it1 != one_tile_transitions.end(); ++it1)
        {
          add_pr(it1->first, it0->second * it1->second);
        }
      }
    }

    void run(int sum, uint8_t max_value,
      const char *states_pathname, const char *policy_pathname,
      const char *bitset_pathname, const char *transient_pr_pathname
    ) {
      part_t part(sum, max_value);
      const state_probability_map_t &transient_map = transients[part];

      vbyte_reader_t vbyte_reader(states_pathname);
      policy_reader_t policy_reader(policy_pathname);
      bit_set_writer_t bit_set_writer(bitset_pathname);
      binary_writer_t<double> transient_pr_writer(transient_pr_pathname);
      for (;;) {
        uint64_t nybbles = vbyte_reader.read();
        if (nybbles == 0) break;

        state_t<size> state(nybbles);
        direction_t direction = policy_reader.read();

        // If we have never seen this state, it's not reachable.
        typename state_probability_map_t::const_iterator state_it =
          transient_map.find(state);
        if (state_it == transient_map.end()) {
          bit_set_writer.write(false);
          continue;
        }

        // Write out
        double state_pr = state_it->second;
        if (state_pr >= threshold) {
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
      transients.erase(part);
    }

    bool have_losses(int sum, uint8_t max_value) const {
      part_t part(sum, max_value);
      typename probability_map_t::const_iterator it = losses.find(part);
      if (it == losses.end()) return false;
      return it->second.size() > 0;
    }

    void finish_losses(int sum, uint8_t max_value, const char *losses_pathname)
    {
      part_t part(sum, max_value);
      typename probability_map_t::const_iterator it = losses.find(part);
      if (it == losses.end()) return;

      write_state_probability_map(it->second, losses_pathname);
      losses.erase(it);
    }

    bool have_wins(int sum) const {
      part_t part(sum, max_exponent);
      typename probability_map_t::const_iterator it = wins.find(part);
      if (it == wins.end()) return false;
      return it->second.size() > 0;
    }

    void finish_wins(int sum, const char *wins_pathname)
    {
      part_t part(sum, max_exponent);
      typename probability_map_t::const_iterator it = wins.find(part);
      if (it == wins.end()) return;

      write_state_probability_map(it->second, wins_pathname);
      wins.erase(it);
    }

  private:
    typedef btree::btree_map<state_t<size>, double> state_probability_map_t;
    typedef std::pair<int, uint8_t> part_t;
    typedef std::map<part_t, state_probability_map_t> probability_map_t;
    typedef typename state_t<size>::transitions_t transitions_t;

    typedef std::pair<uint64_t, double> state_pr_t;

    void add_pr(const state_t<size> &state, double probability) {
      int state_sum = state.sum();
      uint8_t state_max_value = state.max_value();
      part_t state_part(state_sum, state_max_value);

      if (state_max_value >= max_exponent) {
        add_pr(wins[state_part], state, probability);
      } else if (state.lose()) {
        add_pr(losses[state_part], state, probability);
      } else {
        add_pr(transients[state_part], state, probability);
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
      const state_probability_map_t &map, const char *pathname)
    {
      if (pathname == NULL) return;
      if (map.size() == 0) return;

      binary_writer_t<state_pr_t> writer(pathname);
      for (typename state_probability_map_t::const_iterator it = map.begin();
        it != map.end(); ++it)
      {
        state_pr_t pair(it->first.get_nybbles(), it->second);
        if (it->second >= threshold) writer.write(pair);
      }
    }

    uint8_t max_exponent;
    double threshold;
    probability_map_t transients;
    probability_map_t wins;
    probability_map_t losses;
  };
}

#define TWENTY48_LAYER_TRANCHE_BUILDER_HPP
#endif
