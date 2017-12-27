import MersenneTwister from 'mersenne-twister'

import Driver from './driver'
import makeState from './state'
import makePolicy from './policy'

export default function Game (boardSize, maxExponent) {
  // 2x2: win: 47, lose quickly: 43
  // 3x3: win: 56, lose: 42-55
  const generator = new MersenneTwister(56)
  const State = makeState(boardSize, maxExponent)
  const Policy = makePolicy(boardSize)

  function makeDriver (container, policy) {
    return new Driver(
      container,
      boardSize,
      policy,
      generator,
      State.newEmpty()
    )
  }
  this.makeDriver = makeDriver

  this.Policy = Policy
}
