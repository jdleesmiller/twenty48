#include "mmap_vbyte_reader.hpp"
#include "vbyte.h"

namespace twenty48 {

mmap_vbyte_reader_t::mmap_vbyte_reader_t(const char *pathname,
  size_t byte_offset, uint64_t previous)
  : input(pathname), previous(previous)
{
  input_data = (uint8_t *)input.get_data();
  input_end = input_data + input.get_byte_size();
}

uint64_t mmap_vbyte_reader_t::read() {
  if (input_data == input_end) return 0;
  uint64_t value;
  input_data += vbyte_uncompress_sorted64(input_data, &value, previous, 1);
  previous = value;
  return value;
}

}
