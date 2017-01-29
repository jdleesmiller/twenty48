#ifndef TWENTY48_VBYTE_INDEX_HPP

#include <vector>

namespace twenty48 {

/**
 * In order to read a specific location in a vbyte-encoded file, we need to
 * know the byte offset and the previous value in order to resume decompressing.
 */
struct vbyte_index_entry_t {
  vbyte_index_entry_t() : vbyte_index_entry_t(0, 0) { } 
  vbyte_index_entry_t(size_t byte_offset, uint64_t previous) :
    byte_offset(byte_offset), previous(previous) { }
  size_t byte_offset;
  uint64_t previous;
};

typedef std::vector<vbyte_index_entry_t> vbyte_index_t;

}

#define TWENTY48_VBYTE_INDEX_HPP
#endif
