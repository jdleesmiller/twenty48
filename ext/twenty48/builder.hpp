#ifndef TWENTY48_BUILDER_HPP

#include <iostream>
#include <iomanip>
#include <set>
#include <vector>

#include "twenty48.hpp"
#include "state.hpp"

namespace twenty48 {

/**
 * Generate a full model.
 *
 * The general approach is to generate all of the possible start states and
 * then perform a depth first search. To reduce the number of states, the
 * builder also attempts to 'resolve' states that are close to an end game ---
 * if we're going to win in a couple of moves, we don't care exactly how.
 *
 * The approach to resolving is:
 * 1. Look for a win in one move. This is exact and deterministic.
 * 2. Use the 'unknown zeros' heuristic to look one more move ahead. That is
 *    safe, in the sense that we'll never say that we can win in two moves
 *    when it's in fact possible to win in one. I think we might still miss an
 *    'either or' situation, however. So, this step would be approximate (but
 *    that is OK).
 * 3. To go deeper, just have to expand the states.
 *
 * Or maybe we should just do exact resolution here... but we could phrase it
 * in terms of 'valuing' states. That way we'd handle both lose and win in a
 * consistent way. We can set the value of a state if (1) the expected value of
 * all actions is zero or (2) the expected value of at least one action is ???.
 * Maybe that is not a good idea. If we say that a state we can't value is a
 * NaN, then the expected value of an action will be NaN if any state is
 * unresolved. That seems like a good way to detect a loss. However, for
 * detecting a win, we want to know whether there is an action (considering
 * actions in canonical order) such that all states lead to a win in the given
 * number of moves. What if we did allow ourselves to resolve any state for
 * which at least one action had a known expected value? That would probably
 * not work, because it might be a loss, even though there was another action
 * that lead to a win. We could only value a state with certainty if all of
 * the actions had a known expectation, which is a much stronger condition than
 * what we were doing with resolving at least one action that leads to a win.
 *
 * Or maybe we should take a different approach in the native code... what if
 * we just enumerate the state set to build a Q function? Q(s, a) -> value. The
 * idea of 'resolving' may need some adaptation, since in that case we'll be
 * regenerating the transition probabilities dynamically when we do our value
 * updates. It no longer makes sense to do a lot of work on each expansion to
 * try to re-resolve states. I think the basic two-step 'unknown zeros'
 * heuristic would still be useful. We do seem to see diminishing returns for
 * resolve depth on the large models.
 *
 * In the Q case, the builder would start with all start states and then
 * enumerate possible successor states. If a successor state resolved according
 * to the heuristic, it would be nice to 'fix' the Q(s, a) value. When we
 * do the async value iteration, we can skip Q(s, a) values that are fixed. A
 * Q(s, a) value becomes fixed when it is computed using only fixed values. And
 * I guess that also gives us a stopping criterion... but I wonder whether they
 * will all become fixed or not. I think they should all become fixed. They are
 * all going to be some number of moves away from either a win (which has known
 * value) or a loss (which has known value).
 *
 * I like that this should allow us to generate Q functions up front for lots
 * of models, so we can see how much disk space we'd need just to store the Q
 * function. It should be possible to do it with a (state, action, value)
 * triple, which gives 8 + 1 + 4 = 13 bytes per state. We could potentially
 * try to find 3 bits in the value: we are only storing non-negative numbers,
 * so we don't need the sign bit. Or we could try to find two bits in the state.
 * We only use values up to 0xa (or 0xb if we say that wins are not implicit).
 * So, in a byte, we only use 100 = 0x64 (or 121 = 0x79) values, which gives
 * us the higher order bit free to stick a value in. So, if we compress adjacent
 * nybbles into a byte, we get one extra bit that we can store things in. That
 * would give us 8 bits to play with. If we needed more, we could probably
 * compress 4 bytes to get more.
 *
 * If we're going to do this packing, we could potentially avoid all of the
 * bit bashing in the state class anyway... if we're only going to materialize
 * individual states, then I doubt it's worth all the extra fiddling just to
 * save a 8 bytes per state.
 *
 * If we have a 500GB on disk, we can in principle store about 55 billion
 * state-action pairs, so about 10^10 states. The upper bound on the number
 * of states was 10^17, so it's still quite likely that we can't bridge that
 * gap, even with an order of magnitude for symmetries, an order of magnitude
 * for reachability, and an order of magnitude for resolving. However, we're
 * not that far away... hard to say.
 *
 * SO: First objective should be to write a state counter that does the DFS
 * and just records the number of states. v1 of that could be without
 * resolution. We can check that against our existing numbers. v2 should
 * include the heuristic resolution step. We should then be able to say whether
 * the Q function for the full 2048 is something we can feasibly store, or
 * whether it's going to require some big data techniques.
 *
 * TODO: First let's just get the basic builder without resolution going.
 * TODO: Then I would like to make sure that we are writing things out in a
 *       consistent way (action de-duplication and ordering, successor ordering)
 * TODO: Then let's try to add unknown-zeros based resolution (up to two moves).
 * TODO: Then let's try to add value-based resolution.
 *
 * Because state resolution is fairly expensive, we keep a 'transposition table'
 * that caches the resolved states.
 */
template <int size> struct builder_t {
  typedef typename state_t<size>::transitions_t transitions_t;
  typedef std::set<state_t<size> > state_set_t;

  explicit builder_t(int max_exponent) : max_exponent(max_exponent) { }

  void open_start_states() {
    state_t<size> empty_state;
    transitions_t transitions_1 = empty_state.random_transitions();
    for (typename transitions_t::const_iterator it = transitions_1.begin();
      it != transitions_1.end(); ++it)
    {
      transitions_t transitions_2 = it->first.random_transitions();
      for (typename transitions_t::const_iterator it2 = transitions_2.begin();
        it2 != transitions_2.end(); ++it2)
      {
        open.insert(it2->first);
      }
    }
  }

  const state_set_t &open_states() const {
    return open;
  }

  const state_set_t &closed_states() const {
    return closed;
  }

private:
  state_set_t open;
  state_set_t closed;
  int max_exponent;
};

}
#define TWENTY48_BUILDER_HPP
#endif
