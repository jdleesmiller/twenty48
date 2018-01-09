#ifndef TWENTY48_MMAP_VALUE_READER_HPP

#include "layer_files.hpp"
#include "state_value.hpp"

namespace twenty48 {

/**
 * Get values from a file that is a list of (state, value) pairs, ordered
 * by state.
 */
struct mmap_value_reader_t {
  explicit mmap_value_reader_t(const char *pathname);

  double get_value(uint64_t state) const;

private:
  mmapped_layer_file_t input;
  state_value_t *input_data;
  state_value_t *input_end;
};

}

#define TWENTY48_MMAP_VALUE_READER_HPP
#endif
