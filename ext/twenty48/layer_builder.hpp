#ifndef TWENTY48_LAYER_BUILDER_HPP

#include <iostream>

#include "twenty48.hpp"
#include "builder.hpp"
#include "layer_storage.hpp"
#include "state.hpp"
#include "state_hash_set.hpp"

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

    layer_builder_t(const char *data_path, const resolver_t<size> &resolver)
      : data_path(data_path), resolver(resolver) { }

    void build_start_state_layers() const {
      const size_t max_layer_start_states = 1024;
      state_vector_t start_states(twenty48::generate_start_states<size>());
      for (int layer_sum = 4; layer_sum <= 8; layer_sum += 2) {
        state_hash_set_t<size> layer_states(max_layer_start_states);
        for (typename state_vector_t::const_iterator it = start_states.begin();
          it != start_states.end(); ++it) {
          if (it->sum() == layer_sum) {
            layer_states.insert(*it);
          }
        }
        layer_states.dump_binary(make_layer_pathname(layer_sum).c_str());
      }
    }

    std::string make_layer_pathname(int sum) const {
      return twenty48::make_layer_pathname(data_path, sum);
    }

    void build_layer(int sum, int step, size_t max_states) const {
      std::string input_layer_pathname = make_layer_pathname(sum);
      std::string output_layer_pathname = make_layer_pathname(sum + 2 * step);
      state_hash_set_t<size> output_layer(max_states);

      output_layer.load_binary(output_layer_pathname.c_str());
      size_t start_size = output_layer.size();

      std::ifstream is(input_layer_pathname, std::ios::in | std::ios::binary);
      while (is) {
        state_t<size> state = state_t<size>::read_bin(is);
        expand(state, step, output_layer);
      }
      is.close();

      size_t end_size = output_layer.size();
      if (end_size > start_size) {
        output_layer.dump_binary(output_layer_pathname.c_str());
      }
    }

  private:
    const std::string data_path;
    resolver_t<size> resolver;

    static void call_build_layer(
      const layer_builder_t<size> &builder,
      int sum, int step, size_t max_states) {
      builder.build_layer(sum, step, max_states);
    }

    void expand(const state_t<size> &state, int step,
      state_hash_set_t<size> &successors) const {
      move(state, step, DIRECTION_UP, successors);
      move(state, step, DIRECTION_DOWN, successors);
      move(state, step, DIRECTION_LEFT, successors);
      move(state, step, DIRECTION_RIGHT, successors);
    }

    void move(const state_t<size> &state, int step,
      direction_t direction, state_hash_set_t<size> &successors) const {
      state_t<size> moved_state = state.move(direction);
      if (moved_state == state) return; // Cannot move in this direction.

      transitions_t transitions = moved_state.random_transitions(step);
      for (typename transitions_t::const_iterator it = transitions.begin();
        it != transitions.end(); ++it) {
        successors.insert(resolver.resolve(it->first));
      }
    }
  };
}

#define TWENTY48_LAYER_BUILDER_HPP
#endif
