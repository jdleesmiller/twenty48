#include <iostream>

#include "alternate_action_reader.hpp"

namespace twenty48 {

const int BLOCK_BYTES = 6;
const int BLOCK_BITS = BLOCK_BYTES * 8;
const int BLOCK_STATES = BLOCK_BITS / 3;

alternate_action_reader_t::alternate_action_reader_t(const char *pathname)
  : is(pathname, std::ios::in | std::ios::binary), data(0), offset(0)
{ }

void alternate_action_reader_t::skip(size_t num_states) {
  bool discarded[4];
  size_t byte_offset = BLOCK_BYTES * (num_states / BLOCK_STATES);
  is.seekg(byte_offset);
  for (size_t i = 0; i < num_states % BLOCK_STATES; ++i) {
    read(DIRECTION_LEFT, discarded);
  }
}

void alternate_action_reader_t::read(
  direction_t action, bool alternate_actions[4])
{
  if (offset % BLOCK_BITS == 0) {
    is.read(reinterpret_cast<char *>(&data), BLOCK_BYTES);
    if (!is) {
      throw std::runtime_error("alternate_action_reader_t: read failed");
    }
    offset = 0;
  }
  for (size_t i = 0; i < 4; ++i) {
    // std::cout << "i=" << i << " a=" << action
    //   << " offset=" << offset
    //   << " data=" << std::hex << data << std::dec;
    if (action == i) {
      alternate_actions[i] = true;
      // std::cout << std::endl;
      continue;
    }
    // std::cout << "result=" << ((data >> offset) & 0x1ULL) << std::endl;
    alternate_actions[i] = (data >> offset) & 0x1ULL;
    offset += 1;
  }
}

void alternate_action_reader_t::read(
  direction_t action, bool &left, bool &right, bool &up, bool &down)
{
  bool alternate_actions[4];
  read(action, alternate_actions);
  left = alternate_actions[0];
  right = alternate_actions[1];
  up = alternate_actions[2];
  down = alternate_actions[3];
}

}
