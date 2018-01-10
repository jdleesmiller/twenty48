#include <string.h>
#include <sstream>

#include "alternate_action_writer.hpp"

namespace twenty48 {

const int BLOCK_BYTES = 6;
const int BLOCK_BITS = BLOCK_BYTES * 8;

alternate_action_writer_t::alternate_action_writer_t(
  const char *pathname, double tolerance)
  : os(pathname, std::ios::out | std::ios::binary),
    tolerance(tolerance), data(0), offset(0)
{ }

alternate_action_writer_t::~alternate_action_writer_t() {
  flush();
}

void alternate_action_writer_t::write(
  direction_t action, double value, double action_value[4])
{
  for (size_t i = 0; i < 4; ++i) {
    if (i == action) continue;
    // std::cout << "i=" << i << " av=" << action_value[i]
    //   << " v-t=" << (value - tolerance)
    //   << " offset=" << offset
    //   << " data=" << std::hex << data << std::dec;
    if (action_value[i] > value - tolerance) data |= 0x1ULL << offset;
    // std::cout << " -> data=" << std::hex << data << std::dec << std::endl;

    offset += 1;
    if (offset % BLOCK_BITS == 0) flush();
  }
}

void alternate_action_writer_t::write(
  direction_t action, double value,
  double left_value, double right_value, double up_value, double down_value) {
  double action_value[4];
  action_value[0] = left_value;
  action_value[1] = right_value;
  action_value[2] = up_value;
  action_value[3] = down_value;
  write(action, value, action_value);
}

void alternate_action_writer_t::flush() {
  if (offset == 0) return;
  os.write(reinterpret_cast<const char *>(&data), BLOCK_BYTES);
  if (!os) {
    std::ostringstream oss;
    oss << "alternate_action_writer_t: write failed: " <<
      errno << " " << strerror(errno);
    throw std::runtime_error(oss.str());
  }
  data = 0;
  offset = 0;
}

void alternate_action_writer_t::close() {
  os.close();
}

}
