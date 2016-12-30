#ifndef TWENTY48_LAYER_STORAGE_HPP

#include <iomanip>
#include <sstream>
#include <string>
#include <sys/stat.h>

#include "twenty48.hpp"

namespace twenty48 {
  std::string make_layer_pathname(const std::string &data_path, int sum) {
    std::stringstream path;
    path << data_path << '/' << std::setfill('0') << std::setw(4) << sum <<
      ".bin";
    return path.str();
  }

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

#define TWENTY48_LAYER_STORAGE_HPP
#endif
