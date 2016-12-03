#ifndef TWENTY48_STATE_HPP

#include <iostream>
#include <iomanip>
#include <vector>
#include <map>

#include "twenty48.hpp"
#include "line.hpp"

namespace twenty48 {

/**
 * Board state.
 *
 * There are several places where it would be better (and more consistent with
 * line_t) to use a std::array<uint8_t, size * size> here, but swig (v3.0.10)
 * cannot handle the 'size * size' part, so we just use vectors.
 */
template <int size> struct state_t {
  typedef uint64_t nybbles_t;
  typedef std::map<state_t<size>, double> transitions_t;

  state_t(nybbles_t initial_nybbles = 0) {
    nybbles = initial_nybbles;
  }

  explicit state_t(const std::vector<uint8_t> &array) {
    nybbles = 0;
    if (array.size() != size * size) {
      throw std::invalid_argument("bad state array size");
    }
    for (size_t i = 0; i < size * size; ++i) {
      set_nybble(i, array[i]);
    }
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

  state_t<size> reflect_horizontally() const {
    return transform(transform_reflect_horizontally);
  }

  state_t<size> reflect_vertically() const {
    return transform(transform_reflect_vertically);
  }

  state_t<size> transpose() const {
    return transform(transform_transpose);
  }

  state_t<size> canonicalize() const {
    state_t<size> horizontal_reflection = reflect_horizontally();
    state_t<size> vertical_reflection = reflect_vertically();
    state_t<size> transposition = transpose();

    state_t<size> rotated_90 = transposition.reflect_horizontally();
    state_t<size> rotated_180 = horizontal_reflection.reflect_vertically();
    state_t<size> rotated_270 = transposition.reflect_vertically();

    // transpose rotated 180
    state_t<size> anti_transposition = rotated_90.reflect_vertically();

    return std::min(*this,
      std::min(horizontal_reflection,
        std::min(vertical_reflection,
          std::min(transposition,
            std::min(anti_transposition,
              std::min(rotated_90,
                std::min(rotated_180, rotated_270)))))));
  }

  /**
   * Generate a 2 tile, with probability 0.9, or a 4 tile, with probability 0.1,
   * in each empty cell. The states are canonicalized and the probabilities are
   * normalized.
   *
   * @param transitions assumed to be empty (passed to avoid an allocation)
   */
  void generate_random_transitions(transitions_t &transitions) const {
    for (size_t i = 0; i < size * size; ++i) {
      if ((*this)[i] != 0) continue;
      transitions[new_state_with_tile(i, 1).canonicalize()] +=
        0.9 / (size * size);
      transitions[new_state_with_tile(i, 2).canonicalize()] +=
        0.1 / (size * size);
    }
  }

  transitions_t random_transitions() const {
    transitions_t transitions;
    generate_random_transitions(transitions);
    return transitions;
  }

  bool operator==(const state_t<size> &other) const {
    return nybbles == other.nybbles;
  }

  bool operator<(const state_t<size> &other) const {
    return nybbles < other.nybbles;
  }

private:
  nybbles_t nybbles;

  static nybbles_t set_nybble(nybbles_t data, size_t i, uint8_t value) {
    return twenty48::set_nybble(data, i, value, size * size);
  }

  void set_nybble(size_t i, uint8_t value) {
    nybbles = set_nybble(nybbles, i, value);
  }

  state_t new_state_with_tile(size_t i, uint8_t value) const {
    return state_t(set_nybble(nybbles, i, value));
  }

  //
  // Transformer is a function from an (x, y) coordinate to the index of the
  // cell whose value we want to put into cell (x, y) in the result.
  //
  template <typename Transformer> state_t<size> transform(Transformer t) const {
    nybbles_t new_nybbles = 0;
    for (size_t i = 0; i < size * size; ++i) {
      size_t x = i % size;
      size_t y = i / size;
      uint8_t value = (*this)[t(x, y)];
      new_nybbles = set_nybble(new_nybbles, i, value);
    }
    return state_t<size>(new_nybbles);
  }

  //
  // Reflections
  //
  // i = n * y + x
  // x = i % n
  // y = i / n
  //
  // x' = n - x - 1, y' = y =>
  //   i' = n*y + n - 1 - x = n*(y + 1) - (x + 1)
  //
  static size_t transform_reflect_horizontally(size_t x, size_t y) {
    return size * (y + 1) - (x + 1);
  }

  //
  // y' = n - y - 1, x' = x => i' = n*(n - y - 1) + x
  //
  static size_t transform_reflect_vertically(size_t x, size_t y) {
    return size * (size - y - 1) + x;
  }

  //
  // x' = y, y' = x => i' = n*x + y
  //
  static size_t transform_transpose(size_t x, size_t y) {
    return size * x + y;
  }

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
