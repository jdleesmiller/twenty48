#include "state_action_value.hpp"

#include "alternate_action_reader.hpp"
#include "binary_reader.hpp"
#include "binary_writer.hpp"
#include "bit_set_reader.hpp"
#include "state_value.hpp"
#include "policy_reader.hpp"
#include "vbyte_reader.hpp"

namespace twenty48 {

std::vector<twenty48::state_action_value_t> state_action_value_t::subset(
  const char* bit_set_pathname,
  const char* states_pathname,
  const char* policy_pathname,
  const char* alternate_action_pathname,
  const char* values_pathname) {
  std::vector<twenty48::state_action_value_t> output;
  bit_set_reader_t bit_set_reader(bit_set_pathname);
  vbyte_reader_t vbyte_reader(states_pathname);
  policy_reader_t policy_reader(policy_pathname);
  std::unique_ptr<alternate_action_reader_t> alternate_action_reader;
  if (alternate_action_pathname) {
    alternate_action_reader.reset(
      new alternate_action_reader_t(alternate_action_pathname));
  }
  std::unique_ptr<binary_reader_t<state_value_t> > values_reader;
  if (values_pathname) {
    values_reader.reset(new binary_reader_t<state_value_t>(values_pathname));
  }

  for (;;) {
    state_action_value_t state_action_value;
    state_action_value.state = vbyte_reader.read();
    if (state_action_value.state == 0) break;

    state_action_value.action = policy_reader.read();

    if (alternate_action_pathname) {
      alternate_action_reader->read(state_action_value.action,
        state_action_value.left, state_action_value.right,
        state_action_value.up, state_action_value.down);
    }

    if (values_pathname) {
      state_action_value.value = values_reader->read().value;
    }

    if (bit_set_reader.read()) {
      output.push_back(state_action_value);
    }
  }

  return output;
}

}
