#include <string.h>
#include <sstream>

#include "bit_set_writer.hpp"

namespace twenty48 {

const int BLOCK_BITS = 8;

bit_set_writer_t::bit_set_writer_t(const char *pathname)
  : os(pathname, std::ios::out | std::ios::binary), data(0), offset(0)
{ }

bit_set_writer_t::~bit_set_writer_t() {
  flush();
}

void bit_set_writer_t::write(bool member)
{
  if (member) data |= 0x1ULL << offset;
  offset += 1;
  if (offset % BLOCK_BITS == 0) flush();
}

void bit_set_writer_t::flush() {
  if (offset == 0) return;
  os.write(reinterpret_cast<const char *>(&data), 1);
  if (!os) {
    std::ostringstream oss;
    oss << "bit_set_writer_t: write failed: " <<
      errno << " " << strerror(errno);
    throw std::runtime_error(oss.str());
  }
  data = 0;
  offset = 0;
}

void bit_set_writer_t::close() {
  os.close();
}

}
