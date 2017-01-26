#include <fstream>
#include <iostream>
#include <sys/stat.h>
#include <vector>

#include "vbyte.h"

#define BIN_IN_FILE  "0222.bin"
#define VBYTE_FILE   "0222.vbyte"
#define BIN_OUT_FILE "0222.vbyte.bin"

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

int compress() {
  std::ifstream is(BIN_IN_FILE, std::ios::in | std::ios::binary);
  std::ofstream os(VBYTE_FILE, std::ios::out | std::ios::binary);
  uint8_t buf[16];
  uint64_t previous = 0;

  size_t num_values = count_records_in_file(BIN_IN_FILE, 8);
  os.write(reinterpret_cast<const char*>(&num_values), sizeof(num_values));

  for (;;) {
    uint64_t value;
    is.read(reinterpret_cast<char *>(&value), sizeof(value));
    if (!is) break;

    size_t bytes_out = vbyte_append_sorted64(buf, previous, value);
    os.write(reinterpret_cast<const char*>(buf), bytes_out);
    if (!os) {
      std::cout << "compress: write failed" << std::endl;
      return 1;
    }

    previous = value;
  }
  return 0;
}

int decompress() {
  std::cout << "decomp" << std::endl;
  std::ifstream is(VBYTE_FILE, std::ios::in | std::ios::binary);
  std::vector<uint8_t> in;
  std::vector<uint64_t> values;

  size_t num_values;
  is.read(reinterpret_cast<char *>(&num_values), sizeof(num_values));
  std::cout << num_values << std::endl;

  std::cout << "decomp 1" << std::endl;
  for (;;) {
    uint8_t value;
    is.read(reinterpret_cast<char *>(&value), sizeof(value));
    if (!is) break;
    in.push_back(value);
  }

  std::cout << "decomp 2" << std::endl;
  values.resize(num_values * sizeof(uint64_t));
  size_t num_bytes_in = vbyte_uncompress_sorted64(
    in.data(), values.data(), 0, num_values);

  std::cout << "processed " << num_bytes_in << std::endl;

  std::ofstream os(BIN_OUT_FILE, std::ios::out | std::ios::binary);
  for (size_t i = 0; i < num_values; ++i) {
    os.write(reinterpret_cast<const char*>(values.data() + i), sizeof(uint64_t));
    if (!os) return 1;
  }
  return 0;
}

int main() {
  return compress();
  // return compress() || decompress();
}
