#ifndef TWENTY48_LAYER_BUILDER_HPP

#include <iostream>

#include "btree_set.h"

#include "twenty48.hpp"
#include "state.hpp"
#include "valuer.hpp"
#include "vbyte_reader.hpp"
#include "vbyte_writer.hpp"

namespace twenty48 {
  /**
   * Idea: having realised that the state space is not recurrent, we can
   * decompose into layers by sum. If you are in a state with sum N, you can
   * only progress to a state with sum N + 2 or N + 4 (or you can lose). That
   * means that we should never actually have to load the whole state space
   * at once.
   */
  template <int size> struct layer_builder_t {
    typedef std::vector<state_t<size> > state_vector_t;
    typedef btree::btree_set<state_t<size> > state_set_t;

    layer_builder_t(
      uint8_t input_max_value,
      const char *pathname_1_0, const char *pathname_1_1,
      const char *pathname_2_0, const char *pathname_2_1,
      const valuer_t<size> &valuer) :
      input_max_value(input_max_value),
      pathname_1_0(pathname_1_0), pathname_1_1(pathname_1_1),
      pathname_2_0(pathname_2_0), pathname_2_1(pathname_2_1),
      valuer(valuer) { }

    void expand_all(twenty48::vbyte_reader_t &vbyte_reader) {
      for (;;) {
        uint64_t nybbles = vbyte_reader.read();
        if (nybbles == 0) break;
        expand(state_t<size>(nybbles));
      }
      write_all_states();
    }

    void expand_with_policy(twenty48::vbyte_reader_t &vbyte_reader) {
      // TODO
    }

  private:
    uint8_t input_max_value;
    std::string pathname_1_0;
    std::string pathname_1_1;
    std::string pathname_2_0;
    std::string pathname_2_1;
    valuer_t<size> valuer;
    state_set_t output_1_0;
    state_set_t output_1_1;
    state_set_t output_2_0;
    state_set_t output_2_1;

    void expand(const state_t<size> &state) {
      move(state, DIRECTION_UP);
      move(state, DIRECTION_DOWN);
      move(state, DIRECTION_LEFT);
      move(state, DIRECTION_RIGHT);
    }

    void move(const state_t<size> &state, direction_t direction)
    {
      state_t<size> moved_state = state.move(direction);
      if (moved_state == state) return; // Cannot move in this direction.

      for (size_t i = 0; i < size * size; ++i) {
        if (moved_state[i] != 0) continue;
        add_successor(moved_state, i, 1);
        add_successor(moved_state, i, 2);
      }
    }

    void add_successor(const state_t<size> &moved_state, size_t i, int step)
    {
      state_t<size> successor =
        moved_state.new_state_with_tile(i, step).canonicalize();
      if (!std::isnan(valuer.value(successor))) return;

      uint8_t new_max_value = successor.max_value();
      if (step == 1) {
        if (input_max_value == new_max_value) {
          output_1_0.insert(successor);
        } else {
          output_1_1.insert(successor);
        }
      } else if (step == 2) {
        if (input_max_value == new_max_value) {
          output_2_0.insert(successor);
        } else {
          output_2_1.insert(successor);
        }
      }
    }

    void write_all_states() {
      write_states(pathname_1_0.c_str(), output_1_0);
      output_1_0.clear();
      write_states(pathname_1_1.c_str(), output_1_1);
      output_1_1.clear();
      write_states(pathname_2_0.c_str(), output_2_0);
      output_2_0.clear();
      write_states(pathname_2_1.c_str(), output_2_1);
      output_2_1.clear();
    }

    void write_states(const char *pathname, const state_set_t &layer) const {
      vbyte_writer_t vbyte_writer(pathname);
      for (typename state_set_t::const_iterator it = layer.begin();
        it != layer.end(); ++it) {
        vbyte_writer.write(it->get_nybbles());
      }
    }
  };
}

#define TWENTY48_LAYER_BUILDER_HPP
#endif
