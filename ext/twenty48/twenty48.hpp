#ifndef TWENTY48_TWENTY48_HPP

#include <cstddef>
#include <cstdint>
#include <stdexcept>

namespace twenty48 {
  typedef enum DIRECTION {
    DIRECTION_LEFT = 'l',
    DIRECTION_RIGHT = 'r',
    DIRECTION_UP = 'u',
    DIRECTION_DOWN = 'd'
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
   * significant byte.
   */
  template <typename Data>
  Data set_nybble(Data data, uint8_t value, size_t i, size_t length) {
    if (i >= length) throw std::invalid_argument("nybble index out of range");
    size_t shift = 4 * (length - i - 1);
    data &= ~(0xf << shift);
    data |= ~(value & 0xf << shift);
    return data;
  }
}

#define TWENTY48_TWENTY48_HPP
#endif
