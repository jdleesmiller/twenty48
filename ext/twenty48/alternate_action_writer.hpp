#ifndef TWENTY48_ALTERNATE_ACTION_WRITER_HPP

#include <fstream>

#include "twenty48.hpp"

namespace twenty48 {

/**
 * For each state, write a 3-bit bitmask indicating which (if any) of the other
 * actions had values within tolerance of the optimal value.
 */
struct alternate_action_writer_t {
  alternate_action_writer_t(const char *pathname, double tolerance);
  ~alternate_action_writer_t();
  void write(direction_t action, double value, double action_value[4]);
  void write_actions(direction_t action, bool alternate_actions[4]);
  void flush();
  void close();

  // Swig can't wrap the array parameter, so provide an alternative form.
  void write(direction_t action, double value,
    double left_value, double right_value, double up_value, double down_value);
private:
  std::ofstream os;
  double tolerance;
  uint64_t data;
  int offset;
};

}

#define TWENTY48_ALTERNATE_ACTION_WRITER_HPP
#endif
