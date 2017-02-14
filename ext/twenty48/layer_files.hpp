#ifndef TWENTY48_LAYER_FILES_HPP

#include <string>
#include <sys/stat.h>

#include "twenty48.hpp"

namespace twenty48 {

/**
 * Mostly just a wrapper around a file descriptor from `open(2)` (RAII).
 */
struct layer_file_t {
  layer_file_t(const char *pathname);
  ~layer_file_t();

  size_t get_size() const;

  std::string pathname;
  int fd;
};

/**
 * Wrapper around an `mmap`ped file (RAII).
 */
struct mmapped_layer_file_t {
  mmapped_layer_file_t(const char *pathname);

  ~mmapped_layer_file_t();

  size_t get_byte_size() const { return byte_size; }

  void *get_data() const { return data; }
private:
  layer_file_t file;
  size_t byte_size;
  void *data;
};

}

#define TWENTY48_LAYER_FILES_HPP
#endif
