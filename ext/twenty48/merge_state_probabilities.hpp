#ifndef TWENTY48_MERGE_STATE_PROBABILITIES_HPP

#include <string>
#include <vector>

namespace twenty48 {

size_t merge_state_probabilities(
  const std::vector<std::string> &input_pathnames,
  const char *output_pathname);

}

#define TWENTY48_MERGE_STATE_PROBABILITIES_HPP
#endif
