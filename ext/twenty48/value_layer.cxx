#include <algorithm>
#include <iostream>
#include <sstream>

#include "value_layer.hpp"
#include "vbyte.h"

namespace twenty48 {

value_layer_t::value_layer_t(
  const char *states_pathname, const char *values_pathname)
  : states(states_pathname), values(values_pathname)
{
  page_size = get_index_page_size();
  build_index();
}

size_t value_layer_t::lookup(uint64_t state) const {
  // lower_bound will give us the bucket after the one we want (that is, the
  // first indexed state greater than or equal to the target state)
  index_t::const_iterator it = std::lower_bound(
    index.begin(), index.end(), state);

  // If we hit the state in the index, we're done.
  if (it->state == state) return it->state_offset;

  // Otherwise, rewind one to get the previous bucket.
  --it;

  uint64_t previous = it->state;
  size_t offset = it->state_offset;
  uint8_t *data_start = (uint8_t *)states.get_data();
  uint8_t *data = data_start + it->byte_offset;
  uint8_t *data_end = data_start + states.get_byte_size();

  while (data < data_end) {
    offset += 1;
    uint64_t value;
    size_t bytes_in = vbyte_uncompress_sorted64(data, &value, previous, 1);
    // std::cout << "lookup val " << std::hex << value << std::endl;
    if (value == state) {
      return offset;
    }
    data += bytes_in;
    previous = value;
  }

  std::ostringstream os;
  os << "value_layer_t: state not found: " << std::hex << state;
  throw std::invalid_argument(os.str());
}

value_layer_t::value_t value_layer_t::get_value(uint64_t state) const {
  const value_t *value_data = (value_t *)values.get_data();
  return *(value_data + lookup(state));
}

// Use the system page size as the granularity of the index, so we can find
// which page the target state is on.
size_t value_layer_t::get_index_page_size() {
  int pagesize = getpagesize();
  if (pagesize > 4096) {
    return (size_t)(pagesize);
  } else {
    return 4096;
  }
}

value_layer_t::index_entry_t::index_entry_t(
  uint64_t state, size_t byte_offset, size_t state_offset)
  : state(state), byte_offset(byte_offset), state_offset(state_offset) { }

bool value_layer_t::index_entry_t::operator <(uint64_t other_state) const {
  return state < other_state;
}

void value_layer_t::build_index() {
  uint8_t *data = (uint8_t *)states.get_data();
  size_t total_bytes = states.get_byte_size();
  size_t page_bytes = get_index_page_size();

  if (total_bytes == 0) {
    throw std::invalid_argument("value_layer_t: empty states file");
  }

  // Add a sentinel at the start.
  index.push_back(index_entry_t(0, 0, std::numeric_limits<size_t>::max()));

  uint64_t previous = 0;
  size_t total_bytes_in = 0;
  size_t page_bytes_in = 0;
  size_t offset = 0;

  while (total_bytes_in < total_bytes) {
    uint64_t value;
    size_t bytes_in = vbyte_uncompress_sorted64(data, &value, previous, 1);

    total_bytes_in += bytes_in;
    page_bytes_in += bytes_in;
    if (page_bytes_in >= page_bytes) {
      std::cout << "index " << std::hex << value << " " << std::dec << total_bytes_in << " " << offset << std::endl;
      index.push_back(index_entry_t(value, total_bytes_in, offset));
      page_bytes_in -= page_bytes;
    }

    data += bytes_in;
    offset += 1;
    previous = value;
  }

  // Add a sentinel at the end.
  std::cout << "index done" << std::hex << previous << " " << std::dec << total_bytes_in << " " << offset << std::endl;
  index.push_back(index_entry_t(
    std::numeric_limits<uint64_t>::max(),
    total_bytes,
    std::numeric_limits<size_t>::max()
  ));
}

}
