#include <sys/stat.h>

#include "layer_storage.hpp"

namespace twenty48 {

size_t count_records_in_file(const char *pathname, size_t record_size) {
  struct stat stat_buf;
  int rc = stat(pathname, &stat_buf);
  if (rc != 0) return 0;

  off_t file_size = stat_buf.st_size;
  if (file_size % record_size != 0) {
    throw std::invalid_argument("file / record size mismatch");
  }

  return file_size / record_size;
}

}
