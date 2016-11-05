#ifndef TWENTY48_STATE_HPP

#include <iostream>
#include <iomanip>
#include <vector>

#include "twenty48.hpp"
#include "line.hpp"

namespace twenty48 {

template <int size> struct state_t {
  typedef uint64_t nybbles_t;

  state_t(nybbles_t initial_nybbles = 0) {
    nybbles = initial_nybbles;
  }

  nybbles_t get_nybbles() const {
    return nybbles;
  }

  bool any_at_least(uint8_t top) const {
    for (size_t i = 0; i < size * size; ++i) {
      if ((*this)[i] >= top) return true;
    }
    return false;
  }

  bool no_cells_available() const {
    for (size_t i = 0; i < size * size; ++i) {
      if ((*this)[i] == 0) return false;
    }
    return true;
  }

  uint8_t max_value() const {
    uint8_t result = 0;
    for (size_t i = 0; i < size * size; ++i) {
      if ((*this)[i] > result) result = (*this)[i];
    }
    return result;
  }

  size_t cells_available() const {
    size_t result = 0;
    for (size_t i = 0; i < size * size; ++i) {
      if ((*this)[i] == 0) ++result;
    }
    return result;
  }

  uint8_t operator[](size_t i) const {
    if (i >= size * size) {
      throw std::invalid_argument("state index out of range");
    }
    return (nybbles >> 4 * (size * size - i - 1)) & 0xf;
  }

  void set_nybble(size_t i, uint8_t value) {
    if (i >= size * size) {
      throw std::invalid_argument("state index out of range");
    }
    size_t shift = 4 * (size * size - i - 1);
    nybbles &= ~(0xf << shift);
    nybbles |= ~(value & 0xf << shift);
  }

  static const nybbles_t ROW_MASK = 0xffff >> (4 * (4 - size));

  /**
   * Number of bits to right shift in order to get the nybbles for the given
   * row into the rightmost nybbles.
   *
   * @param i from 0, which is the topmost row
   */
  size_t get_row_shift(size_t i) const {
    if (i >= size) throw std::invalid_argument("row index out of range");
    return 4 * size * (size - i - 1);
  }

  /**
   * Number of bits to right shift in order to get the nybble for position
   * (i, j) into the rightmost nybble.
   *
   * @param i from 0, which is the topmost cell
   * @param j from 0, which is the leftmost cell
   */
  size_t get_shift(size_t i, size_t j) const {
    if (i >= size) throw std::invalid_argument("row index out of range");
    if (j >= size) throw std::invalid_argument("col index out of range");
    return 4 * (size * (size - i) - j - 1);
  }

  line_t<size> get_row(size_t i) const {
    uint16_t row_nybbles = (nybbles >> get_row_shift(i)) & ROW_MASK;
    return line_t<size>(row_nybbles);
  }

  line_t<size> get_col(size_t j) const {
    uint16_t col_nybbles = 0;
    for (int i = 0; i < size; ++i) {
      col_nybbles |= ((nybbles >> get_shift(i, j)) & 0xf) << 4 * (size - i - 1);
    }
    return line_t<size>(col_nybbles);
  }

  // It would be better (and more consistent with line_t) to use a
  // std::array<uint8_t, size * size> here, but swig (v3.0.10) cannot handle
  // the 'size * size' part.
  std::vector<uint8_t> to_a() const {
    std::vector<uint8_t> result(size * size);
    for (size_t i = 0; i < size * size; ++i) result[i] = (*this)[i];
    return result;
  }

  state_t move (twenty48::direction_t direction) {
    switch(direction) {
      case DIRECTION_LEFT:  return move(0, 1, size);
      case DIRECTION_RIGHT: return move(size, -1, 0);
      case DIRECTION_UP:    return move(0, size, size * size);
      case DIRECTION_DOWN:  return move(size * size, -size, 0);
    }
    throw std::invalid_argument("bad direction");
  }

  nybbles_t set_row(nybbles_t state_nybbles, size_t i, uint16_t row_nybbles) {
    int shift = get_row_shift(i);
    return (state_nybbles & ~(ROW_MASK << shift)) | (row_nybbles << shift);
  }

  nybbles_t set_col(nybbles_t state_nybbles, size_t j, uint16_t col_nybbles) {
    if (j >= size) throw std::invalid_argument("col index out of range");
    for (int i = 0; i < size; ++i) {
      size_t shift = get_shift(i, j);
      state_nybbles &= ~(0xf << shift);
      state_nybbles |= ((col_nybbles >> 4 * (size - i - 1)) & 0xf) << shift;
    }
    return state_nybbles;
  }

private:
  nybbles_t nybbles;

  state_t move(size_t begin, size_t step, size_t end) {
    size_t offset = size - 1;
    uint16_t line_nybble = 0;
    for (size_t i = begin; i != end; i += step, --offset) {
      line_nybble |= (*this)[i] << 4 * offset;
    }
    line_t<size> line = line_t<size>(line_t<size>::lookup_move(line_nybble));

    offset = 0;
    nybbles_t result = nybbles;
    // for (size_t i = begin; i != end; i += step, ++offset) {
    //   result = set_nybble(i, get_nybble(offset, line_nybble));
    // }
    return state_t(result);
  }
};

template <int size>
std::ostream &operator << (std::ostream &os, const state_t<size> &state) {
  os << "(0x" << std::hex << state.get_nybbles() << std::dec << ')';
  return os;
}

}
#define TWENTY48_STATE_HPP
#endif
