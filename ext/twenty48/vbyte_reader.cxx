#include <fstream>

#include "vbyte_reader.hpp"
#include "vbyte.h"

namespace twenty48 {

vbyte_reader_t::vbyte_reader_t(
  const char *pathname, size_t byte_offset, uint64_t previous,
  size_t max_states) :
  is(pathname, std::ios::in | std::ios::binary),
  previous(previous), states_read(0), max_states(max_states),
  buffer_length(0), eof(false) {
    is.seekg(byte_offset);
  }

uint64_t vbyte_reader_t::read() {
  if (states_read >= max_states) return 0;

  if (!eof) {
    is.read(reinterpret_cast<char *>(buffer + buffer_length),
      BUFFER_SIZE - buffer_length);
    buffer_length += is.gcount();
    if (!is) eof = true;
  }

  if (buffer_length == 0) return 0;

  uint64_t value;
  size_t bytes_in = vbyte_uncompress_sorted64(buffer, &value, previous, 1);

  // Shift the bytes we just read out of the buffer.
  for (size_t i = 0; i + bytes_in < BUFFER_SIZE; ++i) {
    buffer[i] = buffer[i + bytes_in];
  }

  buffer_length -= bytes_in;
  states_read += 1;
  previous = value;

  return value;
}

}
