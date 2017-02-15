#ifndef TWENTY48_LAYER_SOLVER_HPP

#include <cmath>
#include <iostream>
#include <memory>

#include "twenty48.hpp"
#include "layer_storage.hpp"
#include "policy_writer.hpp"
#include "state.hpp"
#include "state_value_map.hpp"
#include "value_layer.hpp"
#include "valuer.hpp"
#include "vbyte_reader.hpp"

namespace twenty48 {
  /**
   * This solver reads in a single layer and outputs the value function and
   * optimal policy for that layer. In order to do so, it must have already read
   * in the value functions for up to two subsequent layers.
   */
  template <int size> struct layer_solver_t {
    layer_solver_t(
      const valuer_t<size> &valuer, int end_layer_sum, double end_value)
        : valuer(valuer), sum(end_layer_sum), end_value(end_value) { }

    double get_discount() const {
      return valuer.get_discount();
    }

    int get_sum() const {
      return sum;
    }

    void prepare_lower_layer(
      const char *states_pathname, const char *values_pathname) {

      sum -= 2;
      value_layers[1].swap(value_layers[0]);

      if (states_pathname == NULL && values_pathname == NULL) {
        // The layer does not exist; skip it.
        value_layers[0].release();
      } else {
        value_layers[0].reset(
          new value_layer_t(states_pathname, values_pathname));
      }
    }

    void solve(twenty48::vbyte_reader_t &vbyte_reader,
      const char *output_values_pathname, const char *output_policy_pathname)
    {
      std::ofstream values_os(output_values_pathname,
        std::ios::out | std::ios::binary);
      policy_writer_t policy_writer(output_policy_pathname);

      for (;;) {
        uint64_t nybbles = vbyte_reader.read();
        if (nybbles == 0) break;

        direction_t direction;
        double value;
        backup_state(state_t<size>(nybbles), direction, value);

        values_os.write(reinterpret_cast<const char *>(&value), sizeof(value));
        if (!values_os) {
          throw std::runtime_error("layer_solver_t: value write failed");
        }
        policy_writer.write(direction);
      }

      policy_writer.flush();
    }

  private:
    typedef double value_t;
    typedef typename state_t<size>::transitions_t transitions_t;

    valuer_t<size> valuer;
    int sum;
    double end_value;

    std::unique_ptr<value_layer_t> value_layers[2];

    void backup_state(const state_t<size> &state,
      direction_t &action, double &value)
    {
      double action_value;
      // std::cout << "backup " << state << std::endl;

      action = DIRECTION_LEFT;
      value = backup_state_action(state, DIRECTION_LEFT);

      action_value = backup_state_action(state, DIRECTION_RIGHT);
      if (action_value > value) {
        action = DIRECTION_RIGHT;
        value = action_value;
      }

      action_value = backup_state_action(state, DIRECTION_UP);
      if (action_value > value) {
        action = DIRECTION_UP;
        value = action_value;
      }

      action_value = backup_state_action(state, DIRECTION_DOWN);
      if (action_value > value) {
        action = DIRECTION_DOWN;
        value = action_value;
      }
    }

    double backup_state_action(const state_t<size> &state,
      direction_t direction) {
      state_t<size> moved_state = state.move(direction);
      if (moved_state == state) return 0; // Cannot move in this direction.

      double state_action_value = 0;
      transitions_t transitions = moved_state.random_transitions();
      for (typename transitions_t::const_iterator it = transitions.begin();
        it != transitions.end(); ++it)
      {
        double value = lookup_value(it->first);
        // std::cout << "lookup " << it->first << ": " << value << std::endl;
        state_action_value += it->second * get_discount() * value;
      }
      return state_action_value;
    }

    double lookup_value(const state_t<size> &state) const {
      double value = valuer.value(state);
      if (!std::isnan(value)) return value;

      if (state.sum() == sum + 2) {
        if (value_layers[0]) {
          // std::cout << "lookup " << state << " in L+2" << std::endl;
          return value_layers[0]->get_value(state.get_nybbles());
        }
        return end_value;
      }

      if (state.sum() == sum + 4) {
        if (value_layers[1]) {
          // std::cout << "lookup " << state << " in L+4" << std::endl;
          return value_layers[1]->get_value(state.get_nybbles());
        }
        return end_value;
      }

      throw std::invalid_argument("lookup_value: bad state sum");
    }
  };

}

#define TWENTY48_LAYER_SOLVER_HPP
#endif
