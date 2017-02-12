#ifndef TWENTY48_POLICY_WRITER_HPP

#include <fstream>

#include "twenty48.hpp"

namespace twenty48 {

/**
 * We only need two bits per action (since there are only 4 possible actions).
 * This helper writes the policy two bits at a time.
 */
struct policy_writer_t {
  policy_writer_t(const char *pathname);
  ~policy_writer_t();
  void write(direction_t direction);
  void flush();
  void close();
private:
  std::ofstream os;
  uint8_t data;
  size_t offset;
};

}

#define TWENTY48_POLICY_WRITER_HPP
#endif
