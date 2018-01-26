#ifndef TWENTY48_BIT_SET_READER_HPP

#include <fstream>

#include "twenty48.hpp"

namespace twenty48 {

/**
 * Read a bitset --- one bit per candidate member to indicate membership.
 */
struct bit_set_reader_t {
  bit_set_reader_t(const char *pathname);
  void skip(size_t num_members);
  bool read();
private:
  std::ifstream is;
  uint8_t data;
  int offset;
};

}

#define TWENTY48_BIT_SET_READER_HPP
#endif
