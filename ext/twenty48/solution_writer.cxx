#include <string.h>
#include <sstream>

#include "solution_writer.hpp"
#include "state_value.hpp"

namespace twenty48 {

solution_writer_t::solution_writer_t(
  const char *policy_pathname,
  const char *values_pathname,
  const char *alternate_action_pathname,
  double alternate_action_tolerance)
  : policy_writer(policy_pathname),
    values_os(values_pathname, std::ios::out | std::ios::binary)
{
  if (alternate_action_pathname) {
    alternate_action_writer.reset(
      new alternate_action_writer_t(
        alternate_action_pathname, alternate_action_tolerance));
  }
}

void solution_writer_t::choose(uint64_t state_nybbles, double action_value[4])
{
  direction_t action = DIRECTION_LEFT;
  double value = action_value[0];
  for (size_t i = 1; i < 4; ++i) {
    if (action_value[i] > value) {
      action = (direction_t)i;
      value = action_value[i];
    }
  }

  if (value < 0) {
    throw std::runtime_error("layer_solver_t: no feasible action");
  }

  policy_writer.write(action);

  if (alternate_action_writer) {
    alternate_action_writer->write(action, value, action_value);
  }

  state_value_t record;
  record.state = state_nybbles;
  record.value = value;
  values_os.write(
    reinterpret_cast<const char *>(&record), sizeof(record));
  if (!values_os) {
    throw std::runtime_error("layer_solver_t: value write failed");
  }
}

void solution_writer_t::flush() {
  policy_writer.flush();
  if (alternate_action_writer) {
    alternate_action_writer->flush();
  }
}

void solution_writer_t::close() {
  policy_writer.close();
  if (alternate_action_writer) {
    alternate_action_writer->close();
  }
  values_os.close();
}

}
