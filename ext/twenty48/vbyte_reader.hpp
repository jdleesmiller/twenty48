#ifndef TWENTY48_VBYTE_READER_HPP

#include <fstream>
#include <limits>

namespace twenty48 {

/**
 * Read 64-bit integers one at a time using vbyte compression.
 */
struct vbyte_reader_t {
  explicit vbyte_reader_t(const char *pathname,
    size_t byte_offset = 0, uint64_t previous = 0,
    size_t max_states = std::numeric_limits<size_t>::max());
  ~vbyte_reader_t();

  uint64_t read();

private:
  static const int BUFFER_SIZE = 2 * sizeof(uint64_t);
  std::ifstream is;
  uint64_t previous;
  size_t states_read;
  size_t max_states;
  uint8_t buffer[BUFFER_SIZE];
  size_t buffer_length;
  bool eof;
};

}

#define TWENTY48_VBYTE_READER_HPP
#endif
