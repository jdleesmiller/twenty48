#ifndef TWENTY48_LAYER_SOLVER_HPP

#include <cmath>
#include <iostream>
#include <memory>

#include "twenty48.hpp"
#include "layer_storage.hpp"
#include "state.hpp"
#include "state_value_map.hpp"
#include "valuer.hpp"

namespace twenty48 {
  /**
   * The input states layer from the LayerBuilder must be sorted by
   * `bin/layer_sort` first.
   *
   * This solver reads in a single layer and outputs the value function and
   * optimal policy for that layer. In order to do so, it may have to read in
   * the value functions for up to two subsequent layers.
   */
  template <int size> struct layer_solver_t {
    typedef typename state_t<size>::transitions_t transitions_t;
    typedef std::vector<state_t<size> > state_vector_t;

    layer_solver_t(const char *states_path, const char *values_path, int sum,
      const valuer_t<size> &valuer) :
        states_path(states_path), values_path(values_path),
        sum(sum), valuer(valuer),
        values(new state_value_map_t<size>()),
        values_2(new state_value_map_t<size>()),
        values_4(new state_value_map_t<size>()) {
      values_2->read(make_values_pathname(sum + 2).c_str());
      values_4->read(make_values_pathname(sum + 4).c_str());
    }

    std::string make_states_pathname(int layer_sum) const {
      return twenty48::make_layer_pathname(states_path, layer_sum);
    }

    std::string make_values_pathname(int layer_sum) const {
      return twenty48::make_layer_pathname(values_path, layer_sum);
    }

    int get_sum() const {
      return sum;
    }

    double get_discount() const {
      return valuer.get_discount();
    }

    void solve() {
      std::string states_pathname = make_states_pathname(sum);
      values->reserve(count_records_in_file(
        states_pathname.c_str(), sizeof(state_t<size>)));
      // std::cout << states_pathname << std::endl;

      std::ifstream is(states_pathname, std::ios::in | std::ios::binary);
      for (;;) {
        state_t<size> state = state_t<size>::read_bin(is);
        if (!is) break;
        // std::cout << "SOLVE:" << state << " " << values->size() << std::endl;
        backup_state(state);
      }
      is.close();

      // std::cout << make_values_pathname(sum) << std::endl;

      values->write(make_values_pathname(sum).c_str());
    }

    bool move_to_lower_layer() {
      if (sum < 6) return false;
      sum -= 2;
      values_4.swap(values_2);
      values_2.swap(values);
      values.reset(new state_value_map_t<size>());
      return true;
    }

  private:
    const std::string states_path;
    const std::string values_path;
    int sum;
    valuer_t<size> valuer;
    std::unique_ptr<state_value_map_t<size> > values;
    std::unique_ptr<state_value_map_t<size> > values_2;
    std::unique_ptr<state_value_map_t<size> > values_4;

    void backup_state(const state_t<size> &state) {
      double action_values[4];
      action_values[DIRECTION_LEFT] =
        backup_state_action(state, DIRECTION_LEFT);
      action_values[DIRECTION_RIGHT] =
        backup_state_action(state, DIRECTION_RIGHT);
      action_values[DIRECTION_UP] =
        backup_state_action(state, DIRECTION_UP);
      action_values[DIRECTION_DOWN] =
        backup_state_action(state, DIRECTION_DOWN);

      size_t max_action = 0;
      double max_value = action_values[0];
      for (size_t i = 1; i < 4; ++i) {
        if (action_values[i] > max_value) {
          max_value = action_values[i];
          max_action = i;
        }
      }
      values->push_back(state, (direction_t)max_action, max_value);
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
        double value = valuer.value(it->first);
        if (std::isnan(value)) {
          value = lookup_value(it->first);
        }
        state_action_value += it->second * get_discount() * value;
      }
      return state_action_value;
    }

    double lookup_value(const state_t<size> &state) const {
      if (state.sum() == sum + 2) return values_2->get_value(state);
      if (state.sum() == sum + 4) return values_4->get_value(state);
      throw std::invalid_argument("lookup_value: bad state sum");
    }
  };
}

#define TWENTY48_LAYER_SOLVER_HPP
#endif
