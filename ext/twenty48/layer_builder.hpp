#ifndef TWENTY48_LAYER_BUILDER_HPP

#include <iostream>
#include <sstream>
#include <string>

#include "twenty48.hpp"
#include "builder.hpp"
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
    typedef std::vector<state_t<size> > state_vector_t;

    layer_builder_t(const char *data_path) : data_path(data_path) {
    }

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
        layer_states.dump_binary(layer_path(layer_sum).c_str());
      }
    }

    std::string layer_path(int sum) const {
      std::stringstream path;
      path << data_path << '/' << std::setfill('0') << std::setw(4) << sum <<
        ".bin";
      return path.str();
    }

    void build_layer(int sum) const {
      // TODO
    }

  private:
    const std::string data_path;

    const int MAX_EXPONENT = 11;
  };
}

#define TWENTY48_LAYER_BUILDER_HPP
#endif
