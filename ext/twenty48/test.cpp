#include <fstream>
#include <iostream>
#include <vector>

#include "vbyte.h"

int compress() {
  std::ifstream is(
    "../../data/layer_states/board_size-3.max_exponent-10.max_depth-0/1438.bin",
    std::ios::in | std::ios::binary);
  std::vector<uint64_t> values;
  std::vector<uint8_t> out;
  for (;;) {
    uint64_t value;
    is.read(reinterpret_cast<char *>(&value), sizeof(value));
    if (!is) break;
    values.push_back(value);
  }

  size_t num_values = values.size();
  std::cout << num_values << std::endl;

  std::cout << "comp 0" << std::endl;
  out.resize(num_values * sizeof(uint64_t));
  std::cout << "comp 1" << std::endl;
  size_t num_bytes_out = vbyte_compress_sorted64(
    values.data(), out.data(), 0, num_values);

  std::ofstream os(
    "../../data/layer_states/board_size-3.max_exponent-10.max_depth-0/1438.vbyte",
    std::ios::out | std::ios::binary);

  std::cout << "comp 2" << std::endl;
  os.write(reinterpret_cast<const char*>(&num_values), sizeof(num_values));

  std::cout << "comp 3" << std::endl;
  for (size_t i = 0; i < num_bytes_out; ++i) {
    os.write(reinterpret_cast<const char*>(out.data() + i), 1);
    if (!os) return 1;
  }
  return 0;
}

int decompress() {
  std::cout << "decomp" << std::endl;
  std::ifstream is(
    "../../data/layer_states/board_size-3.max_exponent-10.max_depth-0/1438.vbyte",
    std::ios::in | std::ios::binary);
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

  std::ofstream os(
    "../../data/layer_states/board_size-3.max_exponent-10.max_depth-0/1438.vbyte.bin",
    std::ios::out | std::ios::binary);

  for (size_t i = 0; i < num_values; ++i) {
    os.write(reinterpret_cast<const char*>(values.data() + i), sizeof(uint64_t));
    if (!os) return 1;
  }
  return 0;
}

int main() {
  return compress() || decompress();
}
