#ifndef TWENTY48_MMAP_VBYTE_READER_HPP

#include "layer_files.hpp"

namespace twenty48 {

/**
 * Read 64-bit integers one at a time from an mmaped file using vbyte
 * compression.
 */
struct mmap_vbyte_reader_t {
  explicit mmap_vbyte_reader_t(
    const char *pathname, size_t byte_offset = 0, uint64_t previous = 0);

  uint64_t read();

private:
  mmapped_layer_file_t input;
  uint64_t previous;
  uint8_t *input_data;
  uint8_t *input_end;
};

}

#define TWENTY48_MMAP_VBYTE_READER_HPP
#endif
