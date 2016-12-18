#ifndef TWENTY48_LINE_HPP

#include <array>
#include <iomanip>
#include <map>
#include <iostream>

#include "twenty48.hpp"

namespace twenty48 {

template <int size> class line_t {
  uint16_t nybbles;

  public:
  typedef std::array<uint8_t, size> array_t;

  line_t(uint16_t initial_nybbles = 0) {
    nybbles = initial_nybbles;
  }

  explicit line_t(const array_t &array) {
    nybbles = 0;
    for (size_t i = 0; i < size; ++i) {
      set_nybble(i, array[i]);
    }
  }

  line_t<size> move() {
    array_t line = to_a();

    size_t done = 0;
    size_t merged = 0;
    for (size_t i = 0; i < size; ++i) {
      uint8_t value = line[i];

      if (value == 0) continue;
      if (done > merged && line[done - 1] == value) {
        line[done - 1] += 1;
        line[i] = 0;
        merged = done;
      } else {
        if (i > done) {
          line[done] = value;
          line[i] = 0;
        }
        ++done;
      }
    }

    return line_t(line);
  }

  /**
   * Does the line contain a pair of cells, both with value `value`, separated
   * only by zero or more (known) zeros? If so, we can always swipe along the
   * line to get the `value + 1` tile.
   *
   * @param zeros_unknown treat zero as 'unknown', not 'empty'
   */
  bool has_adjacent_pair(uint8_t value, bool zeros_unknown = false) const {
    bool found_first = false;
    for (size_t i = 0; i < size; ++i) {
      uint8_t cell_value = (*this)[i];
      if (found_first) {
        if (!zeros_unknown && cell_value == 0) {
          continue;
        }
        return cell_value == value;
      }
      if (cell_value == value) {
        found_first = true;
      }
    }
    return false;
  }

  uint16_t get_nybbles() const {
    return nybbles;
  }

  uint8_t operator[](size_t i) const {
    return twenty48::get_nybble(nybbles, i, size);
  }

  array_t to_a() const {
    array_t result;
    for (size_t i = 0; i < size; ++i) result[i] = (*this)[i];
    return result;
  }

  #ifndef SWIG
  /**
   * Precompute all possible moves. It only takes about 1MiB, even for the
   * 4x4 board. This actually computes moves with tiles up to 2^15.
   */
  struct table_t {
    const static size_t TABLE_SIZE = UINT16_MAX >> 4 * (4 - size);

    uint16_t table[TABLE_SIZE + 1];

    table_t() {
      for (uint32_t nybbles = 0; nybbles <= TABLE_SIZE; ++nybbles) {
        table[nybbles] = line_t(nybbles).move().get_nybbles();
      }
    }
  };
  #endif

  /**
   * Look up the result of moving the given line.
   */
  static uint16_t lookup_move(uint16_t nybbles) {
    static table_t table;
    return table.table[nybbles];
  };

  static uint16_t lookup_move(const line_t<size> &line) {
    return lookup_move(line.get_nybbles());
  };

  static uint8_t get_nybble(uint16_t nybbles, size_t i) {
    return twenty48::get_nybble(nybbles, i, size);
  }

  static uint16_t set_nybble(uint16_t nybbles, size_t i, uint8_t value) {
    return twenty48::set_nybble(nybbles, i, value, size);
  }

private:
  void set_nybble(size_t i, uint8_t value) {
    nybbles = set_nybble(nybbles, i, value);
  }
};

template <int size>
std::ostream &operator << (std::ostream &os, const line_t<size> &line) {
  for (size_t i = 0; i < size; ++i) {
    if (line[i] == 0) {
      os << "  ";
    } else {
      os << (1 << line[i]) << ' ';
    }
  }
  os << "(0x" << std::hex << line.get_nybbles() << std::dec << ')';
  return os;
}

}

#define TWENTY48_LINE_HPP
#endif
