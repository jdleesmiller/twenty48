#include "policy_reader.hpp"

namespace twenty48 {

policy_reader_t::policy_reader_t(const char *pathname)
  : is(pathname, std::ios::in | std::ios::binary), data(0), offset(0)
{ }

void policy_reader_t::skip(size_t num_states) {
  size_t byte_offset = num_states / 4;
  is.seekg(byte_offset);
  for (size_t i = 0; i < num_states % 4; ++i) {
    read();
  }
}

direction_t policy_reader_t::read() {
  if (offset % 4 == 0) {
    is.read(reinterpret_cast<char *>(&data), sizeof(data));
    if (!is) {
      throw std::runtime_error("policy_reader_t: read failed");
    }
    offset = 1;
  } else {
    offset += 1;
  }
  int shift = 2 * (4 - offset);
  return (direction_t)((data >> shift) & 0x3);
}

}
