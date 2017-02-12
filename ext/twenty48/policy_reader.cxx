#include "policy_reader.hpp"

namespace twenty48 {

policy_reader_t::policy_reader_t(const char *pathname)
  : is(pathname, std::ios::in | std::ios::binary), data(0), offset(0)
{ }

direction_t policy_reader_t::read() {
  if (offset % 4 == 0) {
    is.read(reinterpret_cast<char *>(&data), sizeof(data));
    if (!is) {
      throw std::runtime_error("policy_reader_t: read failed");
    }
    offset = 1;
  } else {
    offset += 1;
  }
  int shift = 2 * (4 - offset);
  return (direction_t)((data >> shift) & 0x3);
}

}
