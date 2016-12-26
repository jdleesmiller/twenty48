#ifndef TWENTY48_START_STATES_HPP

#include <set>
#include <vector>

#include "twenty48.hpp"
#include "state.hpp"

namespace twenty48 {
  /**
   * Generate an array of start states. They are guaranteed to be in ascending
   * order.
   */
  template <int size>
  std::vector<state_t<size> > generate_start_states() {
    typedef typename state_t<size>::transitions_t transitions_t;
    typedef std::set<state_t<size> > state_set_t;

    state_set_t result;
    state_t<size> empty_state;
    transitions_t transitions_1 = empty_state.random_transitions();
    for (typename transitions_t::const_iterator it = transitions_1.begin();
      it != transitions_1.end(); ++it)
    {
      transitions_t transitions_2 = it->first.random_transitions();
      for (typename transitions_t::const_iterator it2 = transitions_2.begin();
        it2 != transitions_2.end(); ++it2)
      {
        result.insert(it2->first);
      }
    }
    return std::vector<state_t<size> >(result.begin(), result.end());
  }
}

#define TWENTY48_START_STATES_HPP
#endif
