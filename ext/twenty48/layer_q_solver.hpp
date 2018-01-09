#ifndef TWENTY48_LAYER_Q_SOLVER_HPP

#include <cmath>
#include <fstream>
#include <memory>

#include "twenty48.hpp"
#include "mmap_value_reader.hpp"
#include "policy_writer.hpp"
#include "solution_writer.hpp"
#include "state.hpp"
#include "valuer.hpp"
#include "vbyte_reader.hpp"

namespace twenty48 {
  /**
   * This solver reads in a single layer and outputs the value function and
   * optimal policy for that layer. In order to do so, it must have already read
   * in the value functions for up to two subsequent layers.
   */
  template <int size> struct layer_q_solver_t {
    layer_q_solver_t(
      const valuer_t<size> &valuer,
      int sum, uint8_t max_value,
      const char *values_pathname)
      : valuer(valuer), sum(sum), max_value(max_value) {
      if (values_pathname != NULL) {
        value_reader.reset(new mmap_value_reader_t(values_pathname));
      }
    }

    double get_discount() const {
      return valuer.get_discount();
    }

    void solve(twenty48::vbyte_reader_t &vbyte_reader, const char *q_pathname) {
      std::fstream q_s(q_pathname,
        std::fstream::in | std::fstream::out | std::fstream::binary);

      for (;;) {
        uint64_t nybbles = vbyte_reader.read();
        if (nybbles == 0) break;
        const state_t<size> state(nybbles);

        q_values_t q;
        q_s.read(reinterpret_cast<char *>(&q), sizeof(q));
        if (!q_s) {
          throw std::runtime_error("layer_q_solver_t: solve: q read failed");
        }

        bool changed = false;
        changed = backup(
          state, DIRECTION_LEFT, q.values[DIRECTION_LEFT]) || changed;
        changed = backup(
          state, DIRECTION_RIGHT, q.values[DIRECTION_RIGHT]) || changed;
        changed = backup(
          state, DIRECTION_UP, q.values[DIRECTION_UP]) || changed;
        changed = backup(
          state, DIRECTION_DOWN, q.values[DIRECTION_DOWN]) || changed;

        if (changed) {
          std::fstream::pos_type q_s_g = q_s.tellg();
          q_s.seekp(q_s_g - (std::fstream::pos_type)sizeof(q));
          q_s.write(reinterpret_cast<const char *>(&q), sizeof(q));
          q_s.seekg(q_s_g);
          if (!q_s) {
            throw std::runtime_error("layer_q_solver_t: q rewrite failed");
          }
        }
      }
    }

    static void finish(twenty48::vbyte_reader_t &vbyte_reader,
      const char *q_pathname,
      twenty48::solution_writer_t &solution_writer,
      const char *all_values_pathname)
    {
      std::ifstream q_is(q_pathname, std::fstream::binary);
      std::ofstream all_values_os;

      if (all_values_pathname) {
        all_values_os.open(all_values_pathname);
        all_values_os.precision(std::numeric_limits<double>::max_digits10);
      }

      for (;;) {
        uint64_t nybbles = vbyte_reader.read();
        if (nybbles == 0) break;
        const state_t<size> state(nybbles);

        q_values_t q;
        q_is.read(reinterpret_cast<char *>(&q), sizeof(q));
        if (!q_is) {
          throw std::runtime_error("layer_q_solver_t: finish: q read failed");
        }

        if (all_values_pathname) {
          all_values_os << std::hex << nybbles << std::dec;
          for (size_t i = 0; i < 4; ++i) {
            all_values_os << ',' << q.values[i];
          }
          all_values_os << std::endl;
        }

        solution_writer.choose(nybbles, q.values);
      }

      solution_writer.flush();
    }

  private:
    typedef typename state_t<size>::transitions_t transitions_t;

    struct q_values_t {
      double values[4];
    };

    const valuer_t<size> &valuer;
    int sum;
    uint8_t max_value;
    std::unique_ptr<mmap_value_reader_t> value_reader;

    bool backup(const state_t<size> &state, direction_t direction,
      double &q_value)
    {
      // Action already determined to be infeasible; can stop early.
      if (q_value < 0) return false;

      state_t<size> move_state = state.move(direction);
      if (move_state == state) {
        // Cannot move in this direction.
        q_value += -std::numeric_limits<double>::infinity();
        return true;
      }

      bool changed = false;
      transitions_t transitions = move_state.random_transitions();
      for (typename transitions_t::const_iterator it = transitions.begin();
        it != transitions.end(); ++it)
      {
        double value;
        if (lookup_value(it->first, value)) {
          changed = true;
          q_value += it->second * get_discount() * value;
        }
      }
      return changed;
    }

    bool lookup_value(const state_t<size> &state, double &value) const
    {
      int state_sum = state.sum();
      uint8_t state_max_value = state.max_value();
      if (state_sum == sum && state_max_value == max_value) {
        value = valuer.value(state);
        if (!std::isnan(value)) return true;

        if (!value_reader) {
          std::cerr << "missing state: " << state << std::endl;
          throw std::runtime_error("layer_q_solver_t: lookup_value: missing");
        }

        value = value_reader->get_value(state.get_nybbles());
        return true;
      }
      return false;
    }
  };
}

#define TWENTY48_LAYER_Q_SOLVER_HPP
#endif
