#ifndef TWENTY48_LAYER_SOLVER_HPP

#include <cmath>
#include <iostream>
#include <memory>

#include "twenty48.hpp"
#include "layer_storage.hpp"
#include "mmap_value_reader.hpp"
#include "policy_writer.hpp"
#include "state.hpp"
#include "state_value_map.hpp"
#include "valuer.hpp"
#include "vbyte_reader.hpp"

namespace twenty48 {
  /**
   * This solver reads in a single layer and outputs the value function and
   * optimal policy for that layer. In order to do so, it must have already read
   * in the value functions for up to two subsequent layers.
   */
  template <int size> struct layer_solver_t {
    layer_solver_t(const valuer_t<size> &valuer) : valuer(valuer) { }

    double get_discount() const {
      return valuer.get_discount();
    }

    //
    // for end layer sum N
    // no load needed in that layer; all states must resolve
    // for layer N-2 with max value M_{N-2}, need to load:
    //   (N, M_{N-2}), (N, M_{N-2} + 1)
    // then for (N-2, M_{N-2} - 1), need
    //   (N, M_{N-2} - 1), (N, M_{N-2})
    // then for (N-2, M_{N-2} - 2), need
    //   (N, M_{N-2} - 2), (N, M_{N-2} - 1)
    // down to (N-2, m_{N-2}), for which we need
    //   (N, m_{N-2}), (N, m_{N-2} + 1)
    //
    // for layer N-4 with max value M_{N-4}, need to load:
    //   (N-2, M_{N-4}), (N-2, M_{N-4} + 1)
    //   (N, M_{N-4}), (N, M_{N-4} + 1)
    // then for (N-4, M_{N-4} - 1), need
    //   (N-2, M_{N-4} - 1), (N-2, M_{N-4})
    //   (N, M_{N-4} - 1), (N, M_{N-4})
    // then for (N-4, M_{N-4} - 2), need
    //   (N-2, M_{N-4} - 2), (N-2, M_{N-4} - 1)
    //   (N, M_{N-4} - 2), (N, M_{N-4} - 1)
    // down to (N-4, m_{N-4}), for which we need
    //   (N-2, m_{N-4}), (N-2, m_{N-4} + 1)
    //   (N, m_{N-4}), (N, m_{N-4} + 1)
    //
    // When we are procesing layer N-4, we'll need a slice of the value
    // functions in both layer N-2 and N in order to run. It's only from layer
    // N that we can permanently remove a part. The parts in layer N-2 will
    // be needed again when we process N-6.
    //
    // So.. if we visualised it in a matrix, we'd have to retain one full column
    // (though some of the cells have zero states) for N-2, but as we add states
    // to layer N-4, we can remove them from layer N.
    //
    // I guess 'loading' is actually very cheap, if we are exploding the value
    // functions. Basically it's just a call to mmap.
    //
    // When we finish a value function for a part, we need to munmap it and then
    // remove the value file data.
    //
    // So... we might still want to be able to carry some state over if we are
    // parallelising the solve. But ultimately there's no point in keeping
    // the value function parts mmapped while we do the solve. By the time
    // we get to the layer down, we'll have evicted everything anyway. Might
    // as well reduce the amount of book keeping and just prepare by mmapping
    // the required value function parts.
    //
    // Actually, there might be some benefit in keeping the [i][1] entries ---
    // just moving that up to the [i][0] entry might be worthwhile.
    //
    // So... the ruby layer will know M_k and m_k.
    //
    void load(
      const char *values_pathname_1_0, const char *values_pathname_1_1,
      const char *values_pathname_2_0, const char *values_pathname_2_1)
    {
      if (values_pathname_1_0 == NULL) {
        value_readers[0][0].reset(NULL);
      } else {
        value_readers[0][0].reset(new mmap_value_reader_t(values_pathname_1_0));
      }
      if (values_pathname_1_1 == NULL) {
        value_readers[0][1].reset(NULL);
      } else {
        value_readers[0][1].reset(new mmap_value_reader_t(values_pathname_1_1));
      }
      if (values_pathname_2_0 == NULL) {
        value_readers[1][0].reset(NULL);
      } else {
        value_readers[1][0].reset(new mmap_value_reader_t(values_pathname_2_0));
      }
      if (values_pathname_2_1 == NULL) {
        value_readers[1][1].reset(NULL);
      } else {
        value_readers[1][1].reset(new mmap_value_reader_t(values_pathname_2_1));
      }
    }

    void solve(twenty48::vbyte_reader_t &vbyte_reader,
      int sum, uint8_t max_value,
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
        backup_state(state_t<size>(nybbles), sum, max_value, direction, value);

        state_value_t record;
        record.state = nybbles;
        record.value = value;
        values_os.write(
          reinterpret_cast<const char *>(&record), sizeof(record));
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
    uint8_t max_value;

    std::unique_ptr<mmap_value_reader_t> value_readers[2][2];

    void backup_state(const state_t<size> &state, int sum, uint8_t max_value,
      direction_t &action, double &value)
    {
      double action_value;
      // std::cout << "backup " << state << std::endl;

      action = DIRECTION_LEFT;
      value = backup_state_action(state, sum, max_value, DIRECTION_LEFT);

      action_value = backup_state_action(
        state, sum, max_value, DIRECTION_RIGHT);
      if (action_value > value) {
        action = DIRECTION_RIGHT;
        value = action_value;
      }

      action_value = backup_state_action(
        state, sum, max_value, DIRECTION_UP);
      if (action_value > value) {
        action = DIRECTION_UP;
        value = action_value;
      }

      action_value = backup_state_action(
        state, sum, max_value, DIRECTION_DOWN);
      if (action_value > value) {
        action = DIRECTION_DOWN;
        value = action_value;
      }
    }

    double backup_state_action(const state_t<size> &state,
      int sum, uint8_t max_value, direction_t direction) {
      state_t<size> moved_state = state.move(direction);
      if (moved_state == state) return 0; // Cannot move in this direction.

      double state_action_value = 0;
      transitions_t transitions = moved_state.random_transitions();
      for (typename transitions_t::const_iterator it = transitions.begin();
        it != transitions.end(); ++it)
      {
        double value = lookup_value(it->first, sum, max_value);
        // std::cout << "lookup " << it->first << ": " << value << std::endl;
        state_action_value += it->second * get_discount() * value;
      }
      return state_action_value;
    }

    double lookup_value(const state_t<size> &state,
      int sum, uint8_t max_value) const
    {
      double value = valuer.value(state);
      if (!std::isnan(value)) return value;

      int state_sum = state.sum();
      uint8_t state_max_value = state.max_value();
      size_t i;
      size_t j;

      if (state_sum == sum + 2) i = 0;
      if (state_sum == sum + 4) i = 1;

      if (state_max_value == max_value) j = 0;
      if (state_max_value == max_value + 1) j = 1;

      if (value_readers[i][j]) {
        return value_readers[i][j]->get_value(state.get_nybbles());
      }

      throw std::invalid_argument("lookup_value: bad state sum / max_value");
    }
  };

}

#define TWENTY48_LAYER_SOLVER_HPP
#endif
