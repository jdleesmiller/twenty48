#ifndef TWENTY48_MERGE_STATES_HPP

#include <string>
#include <vector>

namespace twenty48 {

size_t merge_states(
  const std::vector<std::string> &input_pathnames,
  const char *output_pathname);

}

#define TWENTY48_MERGE_STATES_HPP
#endif
