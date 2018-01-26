#ifndef TWENTY48_BINARY_WRITER_HPP

#include <fstream>

#include "twenty48.hpp"

namespace twenty48 {

/**
 * Write binary values of a given type to a file.
 */
template <typename T> struct binary_writer_t {
  binary_writer_t(const char *pathname)
    : os(pathname, std::ios::out | std::ios::binary) { }

  void write(const T &t) {
    os.write(reinterpret_cast<const char *>(&t), sizeof(t));
    if (!os) {
      throw std::runtime_error("binary write failed");
    }
  }
private:
  std::ofstream os;
};

}

#define TWENTY48_BINARY_WRITER_HPP
#endif
