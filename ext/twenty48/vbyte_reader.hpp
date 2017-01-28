#ifndef TWENTY48_VBYTE_READER_HPP

#include <fstream>

namespace twenty48 {

/**
 * Read 64-bit integers one at a time using vbyte compression. 
 */
struct vbyte_reader_t {
  explicit vbyte_reader_t(const char *pathname);
  ~vbyte_reader_t();

  uint64_t read();

private:
  const static int BUFFER_SIZE = 2 * sizeof(uint64_t);
  std::ifstream is;
  uint64_t previous;
  uint8_t buffer[BUFFER_SIZE];
  size_t buffer_length;
  bool eof;
};

}

#define TWENTY48_VBYTE_READER_HPP
#endif
