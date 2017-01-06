#ifndef TWENTY48_STATE_HASH_SET_HPP

#include <fstream>
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

  bool insert(const state_t<board_size> &state) {
    if (state.get_nybbles() == 0) return false;
    if (count >= data.size()) {
      throw std::length_error("state hash set is full");
    }
    size_t index;
    if (find(state, index)) return false;
    data[index] = state;
    ++count;
    return true;
  }

  bool member(const state_t<board_size> &state) const {
    if (state.get_nybbles() == 0) return true;

    size_t index;
    return find(state, index);
  }

  void dump(const char *pathname) const {
    std::ofstream of(pathname);
    of << state_t<board_size>(0) << std::endl;
    for (typename state_hash_set_t<board_size>::data_t::const_iterator it =
      data.begin(); it != data.end(); ++it) {
      if (it->get_nybbles() == 0) continue;
      of << *it << std::endl;
    }
    of.close();
  }

  void load_binary(const char *pathname) {
    std::ifstream is(pathname, std::ios::in | std::ios::binary);
    for (;;) {
      state_t<board_size> state(state_t<board_size>::read_bin(is));
      if (!is) break;
      insert(state);
    }
    is.close();
  }

  void dump_binary(const char *pathname) const {
    std::ofstream os(pathname, std::ios::out | std::ios::binary);
    for (typename state_hash_set_t<board_size>::data_t::const_iterator it =
      data.begin(); it != data.end(); ++it) {
      if (it->get_nybbles() == 0) continue;
      it->write_bin(os);
    }
    os.close();
  }

  void dump_hex(const char *pathname) const {
    std::ofstream os(pathname);
    os << std::hex << std::setfill('0');
    for (typename state_hash_set_t<board_size>::data_t::const_iterator it =
      data.begin(); it != data.end(); ++it) {
      uint64_t nybbles = it->get_nybbles();
      if (nybbles == 0) continue;
      os << std::setw(16) << nybbles << std::endl;
    }
    os.close();
  }

  std::vector<state_t<board_size> > to_a() const {
    std::vector<state_t<board_size> > result;
    result.reserve(count);
    result.push_back(state_t<board_size>(0));
    for (typename data_t::const_iterator it = data.begin(); it != data.end();
      ++it) {
      if (it->get_nybbles() == 0) continue;
      result.push_back(*it);
    }
    return result;
  }

private:
  typedef std::hash<state_t<board_size> > hash_t;
  typedef std::vector<state_t<board_size> > data_t;

  data_t data;
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
