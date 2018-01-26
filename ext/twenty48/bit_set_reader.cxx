#include <iostream>

#include "bit_set_reader.hpp"

namespace twenty48 {

const int BLOCK_BITS = 8;

bit_set_reader_t::bit_set_reader_t(const char *pathname)
  : is(pathname, std::ios::in | std::ios::binary), data(0), offset(0)
{ }

void bit_set_reader_t::skip(size_t num_members) {
  size_t byte_offset = num_members / BLOCK_BITS;
  is.seekg(byte_offset);
  for (size_t i = 0; i < num_members % BLOCK_BITS; ++i) {
    read();
  }
}

bool bit_set_reader_t::read() {
  if (offset % BLOCK_BITS == 0) {
    is.read(reinterpret_cast<char *>(&data), 1);
    if (!is) {
      throw std::runtime_error("bit_set_reader_t: read failed");
    }
    offset = 0;
  }
  bool result = (data >> offset) & 0x1ULL;
  offset += 1;
  return result;
}

}
