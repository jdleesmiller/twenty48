import MersenneTwister from 'mersenne-twister'

import makeState from './state'
import makePolicy from './policy'

//
// Run headlessly according to the policy and record the outcome.
//
export default function evaluate (
  boardSize, maxExponent, packedPolicyPath, startSeed, endSeed) {
  const State = makeState(boardSize, maxExponent)
  const Policy = makePolicy(boardSize, maxExponent)

  const LOSE = 'lose'
  const WIN = 'win'
  const NO_POLICY = 'no_policy'

  function run (policy, seed) {
    let generator = new MersenneTwister(seed)
    let state = State.newEmpty()

    state.placeRandomTile(generator)
    state.placeRandomTile(generator)

    try {
      for (;;) {
        if (state.isWin()) return WIN
        if (state.isLose()) return LOSE

        let canonicalTransform = state.getCanonicalTransform()
        let canonicalState = state.copy().applyTransform(canonicalTransform)
        let canonicalAction = policy.getAction(canonicalState)
        let action = canonicalTransform.invertAction(canonicalAction)
        state.move(action)
        state.placeRandomTile(generator)
      }
    } catch (e) {
      if (e.code === 'no_policy') return NO_POLICY
      throw e
    }
  }

  return Policy.load(packedPolicyPath).then((policy) => {
    let outcomes = { win: 0, lose: 0, no_policy: 0 }
    for (let seed = startSeed; seed <= endSeed; ++seed) {
      console.log('.')
      outcomes[run(policy, seed)] += 1
    }
    outcomes.prWin = outcomes.win / (outcomes.lose + outcomes.win)
    return outcomes
  })
}
