#ifndef TWENTY48_VBYTE_WRITER_HPP

#include <fstream>

namespace twenty48 {

/**
 * Write 64-bit integers one at a time using vbyte compression.
 */
struct vbyte_writer_t {
  explicit vbyte_writer_t(const char *pathname);

  uint64_t get_bytes_written() const { return bytes_written; }
  uint64_t get_previous() const { return previous; }

  void write(uint64_t value);
  void close();

private:
  static const int BUFFER_SIZE = 2 * sizeof(uint64_t);
  std::ofstream os;
  size_t bytes_written;
  uint64_t previous;
  uint8_t buffer[BUFFER_SIZE];
};

}

#define TWENTY48_VBYTE_WRITER_HPP
#endif
