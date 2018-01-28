#include <cerrno>
#include <fcntl.h>
#include <iostream>
#include <sys/mman.h>
#include <sstream>
#include <string.h>
#include <unistd.h>

#include "layer_files.hpp"

namespace twenty48 {

layer_file_t::layer_file_t(const char *pathname) : pathname(pathname) {
  fd = open(pathname, O_RDONLY);
  if (fd == -1) {
    throw std::invalid_argument("layer_file_t: failed to open");
  }
}

layer_file_t::~layer_file_t() {
  int rc = close(fd);
  if (rc != 0) {
    std::cerr << "layer_file_t: failed close" << std::endl;
    std::terminate();
  }
}

size_t layer_file_t::get_size() const {
  struct stat stat_buf;
  int rc = fstat(fd, &stat_buf);
  if (rc != 0) return 0;
  return stat_buf.st_size;
}

mmapped_layer_file_t::mmapped_layer_file_t(const char *pathname)
  : file(pathname), byte_size(file.get_size())
{
  if (byte_size == 0) {
    data = NULL; // cannot mmap an empty file
    return;
  }
  data = mmap(NULL, byte_size, PROT_READ, MAP_PRIVATE, file.fd, 0);
  if (data == MAP_FAILED) {
    std::ostringstream os;
    os << "mmapped_layer_file_t: mmap failed: errno " << errno <<
      ": " << strerror(errno);
    throw std::runtime_error(os.str());
  }
  // std::cout << "mmap " << file.pathname << " " << byte_size << "B" << std::hex << " @ " << (size_t)data << std::endl;
}

mmapped_layer_file_t::~mmapped_layer_file_t() {
  if (data == NULL) return;
  int rc = munmap(data, file.get_size());
  if (rc != 0) {
    std::cerr << "mmapped_layer_file_t: munmap failed" << std::endl;
    std::terminate();
  }
}

}
