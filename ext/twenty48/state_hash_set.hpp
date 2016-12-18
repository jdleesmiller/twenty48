#ifndef TWENTY48_STATE_HASH_SET_HPP

#include <iostream>
#include <iomanip>
#include <vector>
#include <map>

#include "twenty48.hpp"
#include "state.hpp"

namespace twenty48 {

/**
 * Fixed-size hash set for states with simple linear probing. Trying to use
 * as little memory per state as possible.
 *
 * Because we use the zero state to denote an empty slot in the hash table,
 * we adopt the convention that the zero (lose) state is always in the table.
 */
template <int board_size> struct state_hash_set_t {
  state_hash_set_t(size_t max_size) : data(max_size, 0), count(1) { }

  size_t max_size() const {
    return data.size();
  }

  size_t size() const {
    return count;
  }

  void insert(const state_t<board_size> &state) {
    if (state.get_nybbles() == 0) return;
    if (count >= data.size()) {
      throw std::length_error("state hash set is full");
    }
    size_t index;
    if (find(state, index)) return;
    data[index] = state;
    ++count;
  }

  bool member(const state_t<board_size> &state) const {
    if (state.get_nybbles() == 0) return true;

    size_t index;
    return find(state, index);
  }

private:
  typedef std::hash<state_t<board_size> > hash_t;

  std::vector<state_t<board_size> > data;
  size_t count;
  hash_t hash;

  bool find(const state_t<board_size> &state, size_t &index) const {
    for (index = hash(state) % max_size(); ; ++index) {
      if (index == max_size()) index = 0;
      if (data[index] == state) return true;
      if (data[index].get_nybbles() == 0) return false;
    }
  }
};

}

#define TWENTY48_STATE_HASH_SET_HPP
#endif
