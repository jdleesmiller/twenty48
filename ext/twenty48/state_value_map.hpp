#ifndef TWENTY48_STATE_VALUE_MAP_HPP

#include <fstream>
#include <vector>
#include <algorithm>

#include "twenty48.hpp"
#include "layer_storage.hpp"
#include "state.hpp"

namespace twenty48 {

/**
 * Store values for states. Since we have some leftover bits, we also store the
 * optimal action for each state (i.e. the optimal policy) in the same map, to
 * reduce space requirements.
 *
 * The packing scheme is to represent the board in base 12 (MAX_MAX_EXPONENT).
 * That allows 12^16 states, which is less than 2^58. So, we have 6 bits to
 * play with after packing, and we only need 2 bits, because there are 2^2 = 4
 * possible actions.
 */
template <int board_size>
struct state_value_map_t {
  /**
   * Append a state and its value to the map. It is assumed that we process
   * states in order, so we only need to append states.
   */
  void push_back(const state_t<board_size> &state, direction_t optimal_action,
    double value) {
    data.push_back(record_t(state, optimal_action, value));
  }

  double get_value(const state_t<board_size> &state) const {
    return find(state)->get_value();
  }

  state_t<board_size> get_state(size_t index) const {
    return data.at(index).get_state();
  }

  size_t size() const {
    return data.size();
  }

  direction_t get_action(const state_t<board_size> &state) const {
    return find(state)->get_action();
  }

  void reserve(size_t num_states) {
    data.reserve(num_states);
  }

  void read(const char *pathname) {
    reserve(count_records_in_file(pathname, sizeof(record_t)));

    std::ifstream is(pathname, std::ios::in | std::ios::binary);
    while (is) {
      data.push_back(record_t::read(is));
    }
    is.close();
  }

  void write(const char *pathname) {
    std::ofstream os(pathname, std::ios::out | std::ios::binary);

    for (typename std::vector<record_t>::const_iterator it =
      data.begin(); it != data.end(); ++it) {
      // std::cout << "writing" << it->get_state() << " sz " << sizeof(record_t) << std::endl;
      it->write(os);
    }
    os.close();
  }

  static const int MAX_MAX_EXPONENT = 12;

private:
  struct record_t {
    record_t() {}

    record_t(const state_t<board_size> &state, direction_t action, double value)
      : packed_state(pack(state)), action(action), value(value) { }

    state_t<board_size> get_state() const {
      return unpack(packed_state);
    }

    direction_t get_action() const {
      return action;
    }

    double get_value() const {
      return value;
    }

    static record_t read(std::istream &is) {
      record_t result;
      std::cout << "V record size" << sizeof(result) << std::endl;
      is.read(reinterpret_cast<char *>(&result), sizeof(result));
      return result;
    }

    void write(std::ostream &os) const {
      os.write(reinterpret_cast<const char *>(this), sizeof(*this));
    }

    static uint64_t pack(const state_t<board_size> &state) {
      uint64_t packed_value = 0;
      size_t exponent = 1;
      for (size_t i = 0; i < board_size * board_size; ++i) {
        packed_value += state[i] * exponent;
        exponent *= MAX_MAX_EXPONENT;
      }
      return packed_value;
    }

    static state_t<board_size> unpack(uint64_t packed_value) {
      uint64_t nybbles = 0;
      for (size_t i = 0; i < board_size * board_size; ++i) {
        uint8_t value = packed_value % MAX_MAX_EXPONENT;
        nybbles = set_nybble(nybbles, i, value, board_size * board_size);
        packed_value = packed_value / MAX_MAX_EXPONENT;
      }
      return state_t<board_size>(nybbles);
    }

    bool operator<(const state_t<board_size> &other_state) const {
      return get_state() < other_state;
    }

  private:
    uint64_t packed_state:62;
    direction_t action:2;
    double value;
  };

  typename std::vector<record_t>::const_iterator find(
    const state_t<board_size> &state) const {
    typename std::vector<record_t>::const_iterator it = std::lower_bound(
      data.begin(), data.end(), state);
    if (it == data.end()) {
      std::cout << "STATE NOT FOUND: " << state << std::endl;
      for (it = data.begin(); it != data.end(); ++it) {
        std::cout << "STATE: " << it->get_state() << std::endl;
      }
      throw std::invalid_argument("get_value: state not found");
    }
    return it;
  }

  std::vector<record_t> data;
};

}

#define TWENTY48_STATE_VALUE_MAP_HPP
#endif
