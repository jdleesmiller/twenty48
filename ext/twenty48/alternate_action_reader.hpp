#ifndef TWENTY48_ALTERNATE_ACTION_READER_HPP

#include <fstream>

#include "twenty48.hpp"

namespace twenty48 {

/**
 * Read bitmasks written by `alternate_action_writer_t`.
 *
 * Note: There is no way for the reader to reliably detect when it is done
 * reading, so you have to know how many states to read. If you try to read
 * too many more, reading will throw.
 */
struct alternate_action_reader_t {
  alternate_action_reader_t(const char *pathname);
  void skip(size_t num_states);
  void read(direction_t action, bool alternate_actions[4]);

  // Swig can't wrap the array parameter, so provide an alternative form.
  void read(direction_t action, bool &left, bool &right, bool &up, bool &down);

private:
  std::ifstream is;
  uint64_t data;
  int offset;
};

}

#define TWENTY48_ALTERNATE_ACTION_READER_HPP
#endif
