#ifndef TWENTY48_VBYTE_WRITER_HPP

#include <fstream>

namespace twenty48 {

/**
 * Write 64-bit integers one at a time using vbyte compression.
 */
struct vbyte_writer_t {
  explicit vbyte_writer_t(const char *pathname);
  ~vbyte_writer_t();

  void write(uint64_t value);

private:
  const static int BUFFER_SIZE = 2 * sizeof(uint64_t);
  std::ofstream os;
  uint64_t previous;
  uint8_t buffer[BUFFER_SIZE];
};

}

#define TWENTY48_VBYTE_WRITER_HPP
#endif
