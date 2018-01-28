#ifndef TWENTY48_BINARY_READER_HPP

#include <fstream>

#include "twenty48.hpp"

namespace twenty48 {

/**
 * Read binary objects of a given type from a file.
 */
template <typename T> struct binary_reader_t {
  binary_reader_t(const char *pathname)
    : is(pathname, std::ios::in | std::ios::binary), num_records_read(0)
  {
    std::ifstream test(pathname, std::ios::ate | std::ios::binary);
    num_records = test.tellg() / sizeof(T);
  }

  bool done() const {
    return num_records_read >= num_records;
  }

  T read() {
    T t;
    is.read(reinterpret_cast<char *>(&t), sizeof(T));
    if (!is) {
      throw std::runtime_error("binary read failed");
    }
    num_records_read += 1;
    return t;
  }
private:
  std::ifstream is;
  size_t num_records_read;
  size_t num_records;
};

}

#define TWENTY48_BINARY_READER_HPP
#endif
