#ifndef TWENTY48_LAYER_STORAGE_HPP

#include <fstream>
#include <iomanip>
#include <sstream>
#include <string>
#include <sys/stat.h>
#include <vector>

#include "twenty48.hpp"
#include "state.hpp"
#include "vbyte_reader.hpp"
#include "vbyte_writer.hpp"

namespace twenty48 {
  std::string make_layer_pathname(const std::string &data_path, int sum,
    const std::string &extension);

  /**
   * Read a list of 64bit integers in binary format and write them out
   * in hexadecimal format.
   */
  void convert_bin_layer_to_hex(
    const char *in_pathname,
    const char *out_pathname);

  /**
   * Read a list of 64bit integers in hexadecimal format and write them out
   * in binary format.
   */
  void convert_hex_layer_to_bin(
    const char *in_pathname,
    const char *out_pathname);

  /**
   * Convert a layer in binary format to compressed vbyte format.
   * @param in_pathname bin file
   * @param out_pathname vbyte file
   */
  void convert_bin_layer_to_vbyte(
    const char *in_pathname, const char *out_pathname);

  /**
   * Read states in sorted compressed vbyte format.
   */
  template <int size>
  std::vector<state_t<size> > read_states_vbyte(const char *pathname) {
    vbyte_reader_t vbyte_reader(pathname);
    std::vector<state_t<size> > result;
    for (;;) {
      uint64_t nybbles = vbyte_reader.read();
      if (nybbles == 0) break;
      result.push_back(state_t<size>(nybbles));
    }
    return result;
  }

  /**
   * Write states in sorted compressed vbyte format.
   */
  template <int size>
  void write_states_vbyte(const std::vector<state_t<size> > &states,
    const char *pathname) {
    vbyte_writer_t vbyte_writer(pathname);
    for (typename std::vector<state_t<size> >::const_iterator it =
      states.begin(); it != states.end(); ++it) {
      vbyte_writer.write(it->get_nybbles());
    }
  }

  /**
   * Write states in order in binary format.
   */
  template <int size>
  void write_states_bin(const std::vector<state_t<size> > &states,
    const char *pathname) {
    std::ofstream os(pathname, std::ios::out | std::ios::binary);
    for (typename std::vector<state_t<size> >::const_iterator it =
      states.begin(); it != states.end(); ++it) {
      it->write_bin(os);
    }
    os.close();
  }

  /**
   * Write states in order in hex format.
   */
  template <int size>
  void write_states_hex(const std::vector<state_t<size> > &states,
    const char *pathname) {
    std::ofstream os(pathname);
    os << std::hex << std::setfill('0');
    for (typename std::vector<state_t<size> >::const_iterator it =
      states.begin(); it != states.end(); ++it) {
      os << std::setw(16) << it->get_nybbles() << std::endl;
    }
    os.close();
  }

  /**
   * Count records in a fixed-size file.
   */
  size_t count_records_in_file(const char *pathname, size_t record_size);
}

#define TWENTY48_LAYER_STORAGE_HPP
#endif
