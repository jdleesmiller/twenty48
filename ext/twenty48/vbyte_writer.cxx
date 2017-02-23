#include <fstream>
#include <sstream>
#include <string.h>

#include "vbyte_writer.hpp"
#include "vbyte.h"

namespace twenty48 {

vbyte_writer_t::vbyte_writer_t(const char *pathname) :
  os(pathname, std::ios::out | std::ios::binary),
  bytes_written(0), previous(0) { }

void vbyte_writer_t::write(uint64_t value) {
  size_t bytes_out = vbyte_append_sorted64(buffer, previous, value);
  os.write(reinterpret_cast<const char*>(buffer), bytes_out);
  if (!os) {
    std::ostringstream oss;
    oss << "vbyte_writer: write failed: " << errno << " " << strerror(errno);
    throw std::runtime_error(oss.str());
  }
  bytes_written += bytes_out;
  previous = value;
}

void vbyte_writer_t::close() {
  os.close();
}

}
