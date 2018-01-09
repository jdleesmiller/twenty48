#ifndef TWENTY48_STATE_VALUE_HPP

#include "layer_files.hpp"

namespace twenty48 {

struct state_value_t {
  bool operator <(uint64_t other_state) const;

  uint64_t state;
  double value;
};

}

#define TWENTY48_STATE_VALUE_HPP
#endif
