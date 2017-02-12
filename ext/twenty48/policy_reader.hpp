#ifndef TWENTY48_POLICY_READER_HPP

#include <fstream>

#include "twenty48.hpp"

namespace twenty48 {

/**
 * Read a policy written by `policy_writer_t`.
 *
 * Note: There is no way for the reader to reliably detect when it is done
 * reading, so you have to know how many states to read. If you try to read
 * too many more (more than one byte past the end), reading will throw.
 */
struct policy_reader_t {
  policy_reader_t(const char *pathname);
  direction_t read();
private:
  std::ifstream is;
  uint8_t data;
  size_t offset;
};

}

#define TWENTY48_POLICY_READER_HPP
#endif
