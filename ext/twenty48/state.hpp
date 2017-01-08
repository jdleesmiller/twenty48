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
 *
 * The bit twiddling techniques used here are largely based on
 * https://github.com/nneonneo/2048-ai
 * and
 * https://github.com/kcwu/2048-c/blob/master/micro_optimize.cc
 * with some help from
 * http://graphics.stanford.edu/~seander/bithacks.html
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

  bool lose() const {
    return
      move(DIRECTION_LEFT) == *this &&
      move(DIRECTION_RIGHT) == *this &&
      move(DIRECTION_UP) == *this &&
      move(DIRECTION_DOWN) == *this;
  }

  uint8_t max_value() const {
    uint8_t result = 0;
    nybbles_t temp = nybbles;
    while (temp) {
      uint8_t value = uint8_t(temp & 0xF);
      if (value > result) result = value;
      temp >>= 4;
    }
    return result;
  }

  size_t cells_available() const {
    nybbles_t v = nybbles;
    // Make each nybble 1 if it was non-zero or 0 if it was zero.
    v |= (v >> 2);
    v |= (v >> 1);
    v &= 0x1111111111111111ULL;
    // Count the number of bits set. The multiplication has the effect of adding
    // together all of the possible whole-nybble left shifts
    // (v + (v << 4) + (v << 8) + ... + (v << 60)); this means that the highest-
    // order nybble is the sum of c nybbles, each with value 1, where c is the
    // number of nonzero nibbles in v. However, if there are no available cells,
    // the count will overflow 1 nybble, so we have to trap that case.
    nybbles_t c = ((v * 0x1111111111111111ULL) >> 60);
    if (c == 0 && v != 0) return 0;
    return size * size - c;
  }

  uint8_t operator[](size_t i) const {
    return get_nybble(nybbles, i);
  }

  int sum() const {
    int result = 0;
    nybbles_t temp = nybbles;
    while (temp) {
      uint8_t value = uint8_t(temp & 0xF);
      if (value != 0) result += 1 << value;
      temp >>= 4;
    }
    return result;
  }

  std::vector<uint8_t> to_a() const {
    std::vector<uint8_t> result(size * size);
    for (size_t i = 0; i < size * size; ++i) result[i] = (*this)[i];
    return result;
  }

  /**
   * Return a new state that is the result of moving this one in the given
   * direction.
   *
   * At present, all of these are implemented in terms of moving left. There
   * may be some efficiency improvements possible.
   */
  state_t move (twenty48::direction_t direction,
    bool zeros_unknown = false) const {
    switch(direction) {
      case DIRECTION_LEFT:
        return move_left(zeros_unknown);
      case DIRECTION_RIGHT:
        return reflect_horizontally().
          move(DIRECTION_LEFT, zeros_unknown).
          reflect_horizontally();
      case DIRECTION_UP:
        return transpose().move(DIRECTION_LEFT, zeros_unknown).transpose();
      case DIRECTION_DOWN:
        return transpose().move(DIRECTION_RIGHT, zeros_unknown).transpose();
    }
    throw std::invalid_argument("bad direction");
  }

  state_t<size> reflect_horizontally() const {
    nybbles_t c1, c2, c3, c4;
    switch(size) {
      case 2:
        c1 = nybbles & 0x000000000000F0F0ULL;
        c2 = nybbles & 0x0000000000000F0FULL;
        return state_t<size>((c1 >> 4) | (c2 << 4));
      case 3:
        c1 = nybbles & 0x0000000F00F00F00ULL;
        c2 = nybbles & 0x00000000F00F00F0ULL; // stays
        c3 = nybbles & 0x000000000F00F00FULL;
        return state_t<size>((c1 >> 8) | c2 | (c3 << 8));
      case 4:
        c1 = nybbles & 0xF000F000F000F000ULL;
        c2 = nybbles & 0x0F000F000F000F00ULL;
        c3 = nybbles & 0x00F000F000F000F0ULL;
        c4 = nybbles & 0x000F000F000F000FULL;
        return state_t<size>((c1 >> 12) | (c2 >> 4) | (c3 << 4) | (c4 << 12));
      default:
        throw std::invalid_argument("reflect_horizontally: bad size");
    }
  }

  state_t<size> reflect_vertically() const {
    nybbles_t r1, r2, r3, r4;
    switch(size) {
      case 2:
        r1 = nybbles & 0x000000000000FF00ULL;
        r2 = nybbles & 0x00000000000000FFULL;
        return state_t<size>((r1 >> 8) | (r2 << 8));
      case 3:
        r1 = nybbles & 0x0000000FFF000000ULL;
        r2 = nybbles & 0x0000000000FFF000ULL; // stays
        r3 = nybbles & 0x0000000000000FFFULL;
        return state_t<size>((r1 >> 24) | r2 | (r3 << 24));
      case 4:
        r1 = nybbles & 0xFFFF000000000000ULL;
        r2 = nybbles & 0x0000FFFF00000000ULL;
        r3 = nybbles & 0x00000000FFFF0000ULL;
        r4 = nybbles & 0x000000000000FFFFULL;
        return state_t<size>((r1 >> 48) | (r2 >> 16) | (r3 << 16) | (r4 << 48));
      default:
        throw std::invalid_argument("reflect_vertically: bad size");
    }
  }

  state_t<size> transpose() const {
    nybbles_t a1, a2, a3, b1, b2, b3, a;
    switch(size) {
      case 2:
        a1 = nybbles & 0x000000000000F00FULL; // diagonal
        a2 = nybbles & 0x0000000000000F00ULL; // move 1 right
        a3 = nybbles & 0x00000000000000F0ULL; // move 1 left
        return state_t<size>(a1 | (a2 >> 4) | (a3 << 4));
      case 3:
        a1 = nybbles & 0x0000000F000F000FULL; // diagonal
        a2 = nybbles & 0x00000000F000F000ULL; // move 2 right
        a3 = nybbles & 0x000000000F000000ULL; // move 4 right
        b1 = nybbles & 0x0000000000F000F0ULL; // move 2 left
        b2 = nybbles & 0x0000000000000F00ULL; // move 4 left
        return state_t<size>(
          a1 | (a2 >> 8) | (a3 >> 16) | (b1 << 8) | (b2 << 16));
      case 4:
        a1 = nybbles & 0xF0F00F0FF0F00F0FULL; // diagonal
        a2 = nybbles & 0x0000F0F00000F0F0ULL; // move 3 left
        a3 = nybbles & 0x0F0F00000F0F0000ULL; // move 3 right
        a = a1 | (a2 << 12) | (a3 >> 12);
        b1 = a & 0xFF00FF0000FF00FFULL;
        b2 = a & 0x00FF00FF00000000ULL;
        b3 = a & 0x00000000FF00FF00ULL;
        return state_t<size>(b1 | (b2 >> 24) | (b3 << 24));
      default:
        throw std::invalid_argument("transpose: bad size");
    }
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
   */
  transitions_t random_transitions(int step = 0) const {
    transitions_t transitions;
    size_t denominator = cells_available();
    for (size_t i = 0; i < size * size; ++i) {
      if ((*this)[i] != 0) continue;
      if (step == 0 || step == 1) {
        transitions[new_state_with_tile(i, 1).canonicalize()] +=
          0.9 / denominator;
      }
      if (step == 0 || step == 2) {
        transitions[new_state_with_tile(i, 2).canonicalize()] +=
          0.1 / denominator;
      }
    }
    return transitions;
  }

  //
  // Does the state contain a pair of cells, both with value `value`, separated
  // only by zero or more (known) zeros? If so, we can always swipe to get a
  // `value + 1` tile.
  //
  bool has_adjacent_pair(uint8_t value, bool zeros_unknown) const {
    return any_row_or_col(adjacent_pair_t(value, zeros_unknown));
  }

  bool operator==(const state_t<size> &other) const {
    return nybbles == other.nybbles;
  }

  bool operator<(const state_t<size> &other) const {
    return nybbles < other.nybbles;
  }

  static state_t<size> read_bin(std::istream &is) {
    nybbles_t nybbles;
    is.read(reinterpret_cast<char *>(&nybbles), sizeof(nybbles));
    return nybbles;
  }

  void write_bin(std::ostream &os) const {
    os.write(reinterpret_cast<const char *>(&nybbles), sizeof(nybbles));
  }

private:
  nybbles_t nybbles;

  static uint8_t get_nybble(nybbles_t data, size_t i) {
    return twenty48::get_nybble(data, i, size * size);
  }

  static uint8_t get_grid_nybble(nybbles_t data, size_t x, size_t y) {
    return get_nybble(data, y * size + x);
  }

  static nybbles_t set_nybble(nybbles_t data, size_t i, uint8_t value) {
    return twenty48::set_nybble(data, i, value, size * size);
  }

  static nybbles_t set_grid_nybble(nybbles_t data, size_t x, size_t y,
    uint8_t value) {
    return set_nybble(data, y * size + x, value);
  }

  void set_nybble(size_t i, uint8_t value) {
    nybbles = set_nybble(nybbles, i, value);
  }

  state_t new_state_with_tile(size_t i, uint8_t value) const {
    return state_t(set_nybble(nybbles, i, value));
  }

  template <typename Predicate> bool any_row(Predicate predicate) const {
    for (size_t y = 0; y < size; ++y) {
      uint16_t row_nybbles = 0;
      for (size_t x = 0; x < size; ++x) {
        uint8_t value = get_grid_nybble(nybbles, x, y);
        row_nybbles = line_t<size>::set_nybble(row_nybbles, x, value);
      }
      if (predicate(line_t<size>(row_nybbles))) {
        return true;
      }
    }
    return false;
  }

  template <typename Predicate> bool any_col(Predicate predicate) const {
    for (size_t x = 0; x < size; ++x) {
      uint16_t col_nybbles = 0;
      for (size_t y = 0; y < size; ++y) {
        uint8_t value = get_grid_nybble(nybbles, x, y);
        col_nybbles = line_t<size>::set_nybble(col_nybbles, y, value);
      }
      if (predicate(line_t<size>(col_nybbles))) {
        return true;
      }
    }
    return false;
  }

  template <typename Predicate> bool any_row_or_col(Predicate predicate) const {
    return any_row(predicate) || any_col(predicate);
  }

  struct adjacent_pair_t {
    adjacent_pair_t(uint8_t value, bool zeros_unknown) :
      value(value), zeros_unknown(zeros_unknown) { }

    bool operator()(const line_t<size> &line) const {
      return line.has_adjacent_pair(value, zeros_unknown);
    }
  private:
    uint8_t value;
    bool zeros_unknown;
  };

  state_t move_left(bool zeros_unknown) const {
    nybbles_t result = 0;
    for (size_t y = 0; y < size; ++y) {
      uint16_t row_nybbles = 0;
      for (size_t x = 0; x < size; ++x) {
        uint8_t value = get_grid_nybble(nybbles, x, y);
        row_nybbles = line_t<size>::set_nybble(row_nybbles, x, value);
      }
      if (zeros_unknown) {
        row_nybbles = line_t<size>::lookup_move_zeros_unknown(row_nybbles);
      } else {
        row_nybbles = line_t<size>::lookup_move(row_nybbles);
      }
      for (size_t x = 0; x < size; ++x) {
        uint8_t value = line_t<size>::get_nybble(row_nybbles, x);
        result = set_grid_nybble(result, x, y, value);
      }
    }
    return state_t(result);
  }
};

template <int size>
std::ostream &operator << (std::ostream &os, const state_t<size> &state) {
  for (int i = 0; i < size * size; ++i) {
    if (i > 0) os << ' ';
    os << (int)state[i];
  }
  return os;
}

}

namespace std {
  template <int size> struct hash<twenty48::state_t<size> > {
    size_t operator()(const twenty48::state_t<size> &state) const {
      return std::hash<typename twenty48::state_t<size>::nybbles_t>()(
        state.get_nybbles());
    }
  };
}

#define TWENTY48_STATE_HPP
#endif
