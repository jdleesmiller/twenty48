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

  twenty48::state_value_t *maybe_find(uint64_t state) const;

  double get_value(uint64_t state) const;

  void get_value_and_offset(
    uint64_t state, double &value, size_t &offset) const;

private:
  mmapped_layer_file_t input;
  state_value_t *input_data;
  state_value_t *input_end;

  state_value_t *find(uint64_t state) const;
};

}

#define TWENTY48_MMAP_VALUE_READER_HPP
#endif
