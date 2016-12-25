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

  bool lose() const {
    return
      move(DIRECTION_LEFT) == *this &&
      move(DIRECTION_RIGHT) == *this &&
      move(DIRECTION_UP) == *this &&
      move(DIRECTION_DOWN) == *this;
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
    return get_nybble(nybbles, i);
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
   */
  transitions_t random_transitions() const {
    transitions_t transitions;
    for (size_t i = 0; i < size * size; ++i) {
      if ((*this)[i] != 0) continue;
      transitions[new_state_with_tile(i, 1).canonicalize()] +=
        0.9 / (size * size);
      transitions[new_state_with_tile(i, 2).canonicalize()] +=
        0.1 / (size * size);
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

  bool operator==(const state_t<size> &other) const {
    return nybbles == other.nybbles;
  }

  bool operator<(const state_t<size> &other) const {
    return nybbles < other.nybbles;
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
  char prev_fill = os.fill();
  os << "0x" << std::hex << std::setfill('0') << std::setw(size * size) <<
    state.get_nybbles() << std::dec << std::setfill(prev_fill);
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
