#ifndef TWENTY48_BIT_SET_WRITER_HPP

#include <fstream>

#include "twenty48.hpp"

namespace twenty48 {

/**
 * Write a bitset --- one bit per candidate member to indicate membership.
 */
struct bit_set_writer_t {
  bit_set_writer_t(const char *pathname);
  ~bit_set_writer_t();
  void write(bool member);
  void flush();
  void close();
private:
  std::ofstream os;
  uint8_t data;
  int offset;
};

}

#define TWENTY48_BIT_SET_WRITER_HPP
#endif
