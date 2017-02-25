#ifndef TWENTY48_LAYER_STORAGE_HPP

#include "twenty48.hpp"

namespace twenty48 {
  /**
   * Count records in a fixed-size file.
   */
  size_t count_records_in_file(const char *pathname, size_t record_size);
}

#define TWENTY48_LAYER_STORAGE_HPP
#endif
