/* global describe, it */

import assert from 'assert'
import Game from '../game'

function assertSameState (expected, observed) {
  assert.deepEqual(expected.values, observed.values)
}

describe('Game', () => {
  const GAME_2_5 = new Game(2, 5)
  const GAME_4_11 = new Game(4, 11)

  describe('State', () => {
    describe('toString', () => {
      it('prints digits', () => {
        let state = new GAME_2_5.State([
          0, 1,
          2, 3
        ])
        assert.equal(state.toString(), '0123')
      })

      it('prints digits in hexadecimal', () => {
        let state = new GAME_4_11.State([
          0, 1, 2, 3,
          4, 5, 6, 7,
          8, 9, 10, 11,
          0, 1, 2, 3
        ])
        assert.equal(state.toString(), '0123456789ab0123')
      })
    })

    describe('reflectX', () => {
      it('reflects the 2x2 board horizontally', () => {
        function makeState (values) { return new GAME_2_5.State(values) }
        let state = makeState([
          0, 1,
          2, 3])
        assertSameState(makeState([
          1, 0,
          3, 2
        ]), state.reflectX())
      })
    })

    describe('rotate90', () => {
      it('rotates the 2x2 board clockwise', () => {
        function makeState (values) { return new GAME_2_5.State(values) }
        let state = makeState([
          0, 1,
          2, 3])
        assertSameState(makeState([
          2, 0,
          3, 1
        ]), state.rotate90())
      })
    })

    describe('canonicalize', () => {
      it('finds the canonical state', () => {
        let canonical

        function makeState (values) { return new GAME_2_5.State(values) }
        function assertCanonical (values) {
          assertSameState(
            makeState(canonical),
            makeState(values).canonicalize())
        }

        canonical = [0, 0, 0, 0]
        assertCanonical([0, 0, 0, 0])

        canonical = [0, 0, 0, 1]
        assertCanonical([1, 0, 0, 0])
        assertCanonical([0, 1, 0, 0])
        assertCanonical([0, 0, 1, 0])
        assertCanonical([0, 0, 0, 1])

        canonical = [
          0, 0,
          1, 2
        ]
        assertCanonical(canonical)
        assertCanonical([
          1, 2,
          0, 0
        ])
        assertCanonical([
          0, 2,
          0, 1
        ])
        assertCanonical([
          0, 1,
          0, 2
        ])
        assertCanonical([
          0, 0,
          2, 1
        ])
        assertCanonical([
          2, 0,
          1, 0
        ])
        assertCanonical([
          1, 0,
          2, 0
        ])
        assertCanonical([
          0, 0,
          1, 2
        ])

        canonical = [
          0, 1,
          2, 3
        ]
        assertCanonical(canonical)
        assertCanonical([
          2, 3,
          0, 1
        ])
        assertCanonical([
          0, 2,
          1, 3
        ])
        assertCanonical([
          1, 0,
          3, 2
        ])
        assertCanonical([
          3, 1,
          2, 0
        ])
        assertCanonical([
          1, 3,
          0, 2
        ])
        assertCanonical([
          0, 2,
          1, 3
        ])
        assertCanonical([
          3, 2,
          1, 0
        ])
      })
    })
  })
})
