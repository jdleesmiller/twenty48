#ifndef TWENTY48_TWENTY48_HPP

#include <cstddef>
#include <cstdint>
#include <stdexcept>

namespace twenty48 {
  typedef enum DIRECTION {
    DIRECTION_LEFT = 0,
    DIRECTION_RIGHT = 1,
    DIRECTION_UP = 2,
    DIRECTION_DOWN = 3
  } direction_t;

  /**
   * Get the value of the ith nybble (half byte), where i = 0 is the most
   * significant byte.
   */
  template <typename Data>
  uint8_t get_nybble(Data data, size_t i, size_t length) {
    if (i >= length) throw std::invalid_argument("nybble index out of range");
    return (data >> 4 * (length - i - 1)) & 0xf;
  }

  /**
   * Set the value of the ith nybble (half byte), where i = 0 is the most
   * significant byte. This overwrites the existing nybble, regardless of its
   * value.
   */
  template <typename Data>
  Data set_nybble(Data data, size_t i, uint8_t value, size_t length) {
    if (i >= length) throw std::invalid_argument("nybble index out of range");
    size_t shift = 4 * (length - i - 1);
    data &= ~((Data)0xf << shift);
    data |= (value & (Data)0xf) << shift;
    return data;
  }
}

#define TWENTY48_TWENTY48_HPP
#endif
