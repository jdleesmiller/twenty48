#ifndef TWENTY48_SOLUTION_WRITER_HPP

#include <fstream>

#include "twenty48.hpp"
#include "alternate_action_writer.hpp"
#include "policy_writer.hpp"

namespace twenty48 {

/**
 * Write the value function and policy and, optionally, which alternate actions
 * were within a specified tolerance of the optimal action.
 *
 * This handles some logic that's common to the V and Q solvers.
 */
struct solution_writer_t {
  solution_writer_t(
    const char *policy_pathname,
    const char *values_pathname,
    const char *alternate_action_pathname,
    double alternate_action_tolerance);
  void choose(uint64_t state_nybbles, double action_value[4]);
  void flush();
  void close();
private:
  policy_writer_t policy_writer;
  std::ofstream values_os;
  std::unique_ptr<alternate_action_writer_t> alternate_action_writer;
};

}

#define TWENTY48_SOLUTION_WRITER_HPP
#endif
