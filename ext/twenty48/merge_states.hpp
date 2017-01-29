#ifndef TWENTY48_MERGE_STATES_HPP

#include <string>
#include <vector>

#include "vbyte_index.hpp"

namespace twenty48 {

size_t merge_states(
  const std::vector<std::string> &input_pathnames,
  const char *output_pathname,
  size_t index_stride, twenty48::vbyte_index_t &vbyte_index);

}

#define TWENTY48_MERGE_STATES_HPP
#endif
