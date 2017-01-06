#ifndef TWENTY48_LAYER_STORAGE_HPP

#include <fstream>
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

  /**
   * Read a list of 64bit integers in hexadecimal format and write them out
   * in binary format.
   */
  void convert_hex_layer_to_bin(
    const char *in_pathname,
    const char *out_pathname) {
    std::ifstream is(in_pathname);
    std::ofstream os(out_pathname, std::ios::out | std::ios::binary);

    is >> std::hex;

    for (;;) {
      uint64_t data;
      is >> data;
      if (!is) break;
      os.write(reinterpret_cast<const char *>(&data), sizeof(data));
      if (!os) {
        throw std::runtime_error("convert_hex_layer_to_bin: write failed");
      };
    }

    is.close();
    os.close();
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
