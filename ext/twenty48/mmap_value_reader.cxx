#include <algorithm>

#include "mmap_value_reader.hpp"

namespace twenty48 {

mmap_value_reader_t::mmap_value_reader_t(const char *pathname) : input(pathname)
{
  input_data = (state_value_t *)input.get_data();
  input_end = input_data + input.get_byte_size() / sizeof(state_value_t);
}

double mmap_value_reader_t::get_value(uint64_t state) const {
  state_value_t *record = std::lower_bound(input_data, input_end, state);
  if (record == input_end || record->state != state) {
    throw std::runtime_error("state not found");
  }
  return record->value;
}

bool state_value_t::operator <(uint64_t other_state) const {
  return state < other_state;
}

}
