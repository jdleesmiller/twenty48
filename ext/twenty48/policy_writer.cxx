#include <string.h>
#include <sstream>

#include "policy_writer.hpp"

namespace twenty48 {

policy_writer_t::policy_writer_t(const char *pathname)
  : os(pathname, std::ios::out | std::ios::binary), data(0), offset(0)
{ }

policy_writer_t::~policy_writer_t() {
  flush();
}

void policy_writer_t::write(direction_t direction) {
  int shift = 2 * (3 - offset);
  data |= (direction & 0x3) << shift;
  offset += 1;
  if (offset % 4 == 0) flush();
}

void policy_writer_t::flush() {
  if (offset == 0) return;
  os.write(reinterpret_cast<const char *>(&data), sizeof(data));
  if (!os) {
    std::ostringstream oss;
    oss << "policy_writer_t: write failed: " << errno << " " << strerror(errno);
    throw std::runtime_error(oss.str());
  }
  data = 0;
  offset = 0;
}

void policy_writer_t::close() {
  os.close();
}

}
