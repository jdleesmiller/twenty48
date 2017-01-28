#include <fstream>

#include "vbyte_writer.hpp"
#include "vbyte.h"

namespace twenty48 {

vbyte_writer_t::vbyte_writer_t(const char *pathname) :
  os(pathname, std::ios::out | std::ios::binary), previous(0) { }

vbyte_writer_t::~vbyte_writer_t() {
  os.close();
}

void vbyte_writer_t::write(uint64_t value) {
  size_t bytes_out = vbyte_append_sorted64(buffer, previous, value);
  os.write(reinterpret_cast<const char*>(buffer), bytes_out);
  if (!os) {
    throw std::runtime_error("vbyte_writer: write failed");
  }
  previous = value;
}

}
