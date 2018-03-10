#ifndef TWENTY48_STATE_ACTION_VALUE_HPP

#include <vector>

#include "twenty48.hpp"

namespace twenty48 {

/**
 * Combined state, action, value and alternate action data, usually for a small
 * subset of states.
 */
struct state_action_value_t {
  uint64_t state;
  direction_t action;
  double value;
  bool left;
  bool right;
  bool up;
  bool down;

  state_action_value_t() :
    state(0), action(DIRECTION_LEFT), value(0.0),
    left(0), right(0), up(0), down(0) { }

  /**
   * Write out a policy and values for only the states that are present in another
   * list of states, according to the bitset.
   */
  static std::vector<twenty48::state_action_value_t> subset(
    const char* bit_set_pathname,
    const char* states_pathname,
    const char* policy_pathname,
    const char* alternate_actions_pathname,
    const char* values_pathname);
};

}

#define TWENTY48_STATE_ACTION_VALUE_HPP
#endif
