#ifndef TWENTY48_LAYER_STORAGE_HPP

#include <iomanip>
#include <sstream>
#include <string>

namespace twenty48 {
  std::string make_layer_pathname(const std::string &data_path, int sum) {
    std::stringstream path;
    path << data_path << '/' << std::setfill('0') << std::setw(4) << sum <<
      ".bin";
    return path.str();
  }
}

#define TWENTY48_LAYER_STORAGE_HPP
#endif
