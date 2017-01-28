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

int uncompress() {
  std::ifstream is(VBYTE_FILE, std::ios::in | std::ios::binary);
  std::ofstream os(BIN_OUT_FILE, std::ios::out | std::ios::binary);

  size_t num_values;
  is.read(reinterpret_cast<char *>(&num_values), sizeof(num_values));
  std::cout << "num values " << num_values << std::endl;

  uint64_t previous = 0;
  const size_t buf_size = 16;
  uint8_t buf[buf_size];
  size_t buf_length = 0;
  bool eof = false;
  do {
    if (!eof) {
      is.read(reinterpret_cast<char *>(buf + buf_length), buf_size - buf_length);
      buf_length += is.gcount();
      if (!is) eof = true;
    }

    uint64_t value;
    size_t bytes_in = vbyte_uncompress_sorted64(buf, &value, previous, 1);

    os.write(reinterpret_cast<const char*>(&value), sizeof(value));
    if (!os) {
      std::cout << "uncompress: write failed" << std::endl;
      return 1;
    }
    previous = value;

    // Shift the bytes we've already read out of the buffer and replace them
    // with bytes we've already read from the file (if any).
    // std::cout << "bytes_in=" << bytes_in << " buf_length=" << buf_length << std::endl;
    if (bytes_in > buf_length) {
      std::cout << "uncompress: bytes_in too large" << std::endl;
      return 1;
    }
    for (size_t i = 0; i + bytes_in < buf_size; ++i) {
      buf[i] = buf[i + bytes_in];
    }
    buf_length -= bytes_in;
  } while (buf_length > 0);
  return 0;
}

int main() {
  return uncompress();
  // return compress() || uncompress();
}
