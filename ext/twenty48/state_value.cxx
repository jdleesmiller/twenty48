#include "state_value.hpp"

namespace twenty48 {

bool state_value_t::operator <(uint64_t other_state) const {
  return state < other_state;
}

}
