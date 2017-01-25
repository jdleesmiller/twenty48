#ifndef TWENTY48_LAYER_BUILDER_HPP

#include <iostream>

#include "btree_set.h"

#include "twenty48.hpp"
#include "layer_storage.hpp"
#include "state.hpp"
#include "valuer.hpp"

namespace twenty48 {
  /**
   * Idea: having realised that the state space is not recurrent, we can
   * decompose into layers by sum. If you are in a state with sum N, you can
   * only progress to a state with sum N + 2 or N + 4 (or you can lose). That
   * means that we should never actually have to load the whole state space
   * at once. We only have to load two layers. (And we could potentially load
   * only one layer, if we generated all of the N + 2 successors in one pass,
   * and then all of the N + 4 successors in a second pass.)
   *
   * The '2' transitions correspond to transitions to the next layer. The '4'
   * transitions skip the next layer for the one after.
   *
   * This also helps us when we want to solve: if each layer is a Q function,
   * we can work backwards through the layers to update the Q. No update in
   * a lower-sum Q layer can affect a higher-sum Q layer, so we should be able
   * to solve in a single backward induction pass.
   *
   * Previously I've regenerated the lower layers for each max_exponent, but I
   * think that, if we don't use win resolution, which isn't very effective in
   * the lower layers anyway, we should just be able to do this once for each
   * board size.
   *
   * How to get started? The start states can have sum 2, 6 or 8, so probably
   * the best thing to do is to build this so that the layer builder can load
   * an existing layer and add to it. We can then pre-populate the first 3
   * layers.
   *
   * Should we just store states or jump straight to storing Q's? We may want
   * to have a separate Q build step that reads in the states, sorts them and
   * outputs the Q. In principle, we only need to store the Q for three layers
   * at a time, and then for later layers we can just store the policy. If we
   * pack the state into 7 bytes, the remaining byte could store the optimal
   * action, so that's only slightly more than what we'd need to store the state
   * list itself.
   */
  template <int size> struct layer_builder_t {
    typedef typename state_t<size>::transitions_t transitions_t;
    typedef std::vector<state_t<size> > state_vector_t;
    typedef btree::btree_set<state_t<size> > state_set_t;

    layer_builder_t(const valuer_t<size> &valuer) : valuer(valuer) { }

    void build_layer(const char *input_layer_pathname,
      const char *output_layer_pathname, int step,
      size_t offset, int count) const
    {
      std::ifstream is(input_layer_pathname, std::ios::in | std::ios::binary);
      is.seekg(offset * sizeof(state_t<size>));

      state_set_t output_layer;
      for (; count > 0; --count) {
        state_t<size> state = state_t<size>::read_bin(is);
        if (!is) break;
        expand(state, step, output_layer);
      }

      is.close();
      write_states(output_layer_pathname, output_layer);
    }

    void merge_files(const std::vector<std::string> &input_pathnames,
      const char *output_pathname) const
    {
      const size_t n = input_pathnames.size();
      const state_t<size> inf_state = state_t<size>(
        std::numeric_limits<uint64_t>::max());
      typedef std::vector<std::unique_ptr<std::ifstream> > stream_vector_t;

      std::ofstream os(output_pathname, std::ios::out | std::ios::binary);

      // Open input files.
      stream_vector_t inputs;
      for (typename std::vector<std::string>::const_iterator it =
        input_pathnames.begin(); it != input_pathnames.end(); ++it) {
        inputs.emplace_back(
          new std::ifstream(*it, std::ios::in | std::ios::binary));
      }

      // Read first value from each file.
      state_vector_t heads;
      for (typename stream_vector_t::iterator it = inputs.begin();
        it != inputs.end(); ++it) {
        state_t<size> state = state_t<size>::read_bin(**it);
        if (**it) {
          heads.push_back(state);
        } else {
          heads.push_back(inf_state);
        }
      }

      std::vector<size_t> min_indexes;
      for (;;) {
        // Find the smallest state among the current heads.
        state_t<size> min_state(inf_state);
        for (size_t i = 0; i < n; ++i) {
          if (heads[i] < min_state) {
            min_state = heads[i];
            min_indexes.clear();
            min_indexes.push_back(i);
          } else if (heads[i] == min_state) {
            min_indexes.push_back(i);
          }
        }

        // If all heads are infinite, we're done.
        if (min_state == inf_state) {
          for (typename stream_vector_t::iterator it = inputs.begin();
            it != inputs.end(); ++it) {
            (*it)->close();
          }
          os.close();
          return;
        }

        // Write the min state.
        min_state.write_bin(os);

        // Pop the head states that matched the min state we just wrote.
        for (typename std::vector<size_t>::const_iterator it =
          min_indexes.begin(); it != min_indexes.end(); ++it) {
          state_t<size> next_state = state_t<size>::read_bin(*inputs[*it]);
          if (*inputs[*it]) {
            heads[*it] = next_state;
          } else {
            heads[*it] = inf_state;
          }
        }

        min_indexes.clear();
      }
    }

  private:
    valuer_t<size> valuer;

    void expand(const state_t<size> &state, int step,
      state_set_t &successors) const {
      move(state, step, DIRECTION_UP, successors);
      move(state, step, DIRECTION_DOWN, successors);
      move(state, step, DIRECTION_LEFT, successors);
      move(state, step, DIRECTION_RIGHT, successors);
    }

    void move(const state_t<size> &state, int step,
      direction_t direction, state_set_t &successors) const {
      state_t<size> moved_state = state.move(direction);
      if (moved_state == state) return; // Cannot move in this direction.

      for (size_t i = 0; i < size * size; ++i) {
        if (moved_state[i] != 0) continue;
        if (step == 0 || step == 1) {
          state_t<size> successor =
            moved_state.new_state_with_tile(i, 1).canonicalize();
          if (std::isnan(valuer.value(successor))) {
            successors.insert(successor);
          }
        }
        if (step == 0 || step == 2) {
          state_t<size> successor =
            moved_state.new_state_with_tile(i, 2).canonicalize();
          if (std::isnan(valuer.value(successor))) {
            successors.insert(successor);
          }
        }
      }
    }

    void write_states(const char *pathname, const state_set_t &layer) const {
      std::ofstream os(pathname, std::ios::out | std::ios::binary);
      for (typename state_set_t::const_iterator it = layer.begin();
        it != layer.end(); ++it) {
        it->write_bin(os);
      }
      os.close();
    }
  };
}

#define TWENTY48_LAYER_BUILDER_HPP
#endif
