#ifndef TWENTY48_VALUE_LAYER_HPP

#include <cstdint>
#include <unistd.h>

#include "layer_files.hpp"
#include "vbyte_index.hpp"

namespace twenty48 {

/**
 * Manage the reading of the value function for a layer of states. The approach
 * is to use the layer's states file as an index into its values file. To do
 * this:
 *
 * 1. Keep an in-memory index on the states file so we can jump directly to the
 *    page that contains the requested state in order to find its offset.
 *    (The states are vbyte-compressed, so we can't compute offsets into the
 *    vbyte file directly.)
 * 2. Use mmap for both the states and values, since we only need read only
 *    access, and we'll be using the data from several forked child processes.
 *    Hopefully this will reduce overhead compared to using file seeks directly.
 *
 * TODO We may want use madvise to tell the OS that we'll have an essentially
 * random access pattern, but it needs profiling.
 */
struct value_layer_t {
  typedef double value_t;

  value_layer_t(const char *states_pathname, const char *values_pathname);

  size_t lookup(uint64_t state) const;

  value_t get_value(uint64_t state) const;

private:
  mmapped_layer_file_t states;
  mmapped_layer_file_t values;
  size_t page_size;

  struct index_entry_t {
    index_entry_t(uint64_t state, size_t byte_offset, size_t state_offset);

    bool operator <(uint64_t other_state) const;

    uint64_t state;
    size_t byte_offset;
    size_t state_offset;
  };

  typedef std::vector<index_entry_t> index_t;
  index_t index;

  size_t get_index_page_size();
  void build_index();
};

}

#define TWENTY48_VALUE_LAYER_HPP
#endif
