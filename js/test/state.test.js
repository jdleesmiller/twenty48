/* global describe, it */

import assert from 'assert'
import DIRECTIONS from '../lib/directions'
import makeState from '../lib/state'

function assertValues (actual, expected) {
  assert.deepEqual(actual.getValues(), expected)
}

describe('State', () => {
  const State25 = makeState(2, 5)
  const State411 = makeState(4, 11)

  function newState (values) {
    if (values.length === 4) return State25.fromValues(values)
    return State411.fromValues(values)
  }

  describe('toString', () => {
    it('prints digits', () => {
      let state = newState([
        0, 1,
        2, 3
      ])
      assert.equal(state.toString(), '0123')
    })

    it('prints digits in hexadecimal', () => {
      let state = newState([
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
      let state = newState([
        0, 1,
        2, 3])
      state.reflectX()
      assertValues(state, [
        1, 0,
        3, 2
      ])
    })
  })

  describe('transposes', () => {
    it('transposes the 2x2 board like a matrix', () => {
      let state = newState([
        0, 1,
        2, 3])
      state.transpose()
      assertValues(state, [
        0, 2,
        1, 3
      ])
    })
  })

  describe('rotate90', () => {
    it('rotates the 2x2 board counterclockwise', () => {
      let state = newState([
        0, 1,
        2, 3])
      state.rotate90()
      assertValues(state, [
        1, 3,
        0, 2
      ])
    })
  })

  describe('canonicalize', () => {
    it('finds the canonical state', () => {
      let canonical

      function assertCanonical (values) {
        assertValues(newState(values).canonicalize(), canonical)
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

  describe('getAvailableCellIndexes / countAvailableCells', () => {
    it('returns available cell indexes', () => {
      function assertAvailable (values, indexes) {
        let state = newState(values)
        assert.deepEqual(state.getAvailableCellIndexes(), indexes)
        assert.equal(state.countAvailableCells(), indexes.length)
      }
      assertAvailable([0, 0, 0, 0], [0, 1, 2, 3])
      assertAvailable([1, 0, 0, 0], [1, 2, 3])
      assertAvailable([0, 1, 0, 0], [0, 2, 3])
      assertAvailable([0, 0, 1, 0], [0, 1, 3])
      assertAvailable([0, 0, 0, 1], [0, 1, 2])
      assertAvailable([1, 2, 0, 0], [2, 3])
      assertAvailable([0, 1, 2, 0], [0, 3])
      assertAvailable([0, 0, 1, 2], [0, 1])
      assertAvailable([1, 2, 3, 0], [3])
      assertAvailable([0, 1, 2, 3], [0])
      assertAvailable([1, 2, 3, 4], [])
    })
  })

  describe('isWin', () => {
    it('detects wins', () => {
      function assertWin (values, isWin) {
        let state = newState(values)
        assert.equal(state.isWin(), isWin)
      }

      assertWin([0, 0, 0, 5], true)
      assertWin([1, 2, 3, 5], true)
      assertWin([0, 0, 0, 4], false)
    })
  })

  describe('isLose', () => {
    it('detects losses', () => {
      function assertLose (values, isLose) {
        let state = newState(values)
        assert.equal(state.isLose(), isLose)
      }

      assertLose([0, 0, 0, 0], true) // special 'lose' state
      assertLose([0, 0, 0, 1], false)
      assertLose([1, 1, 1, 1], false)
      assertLose([1, 2, 3, 4], true)
      assertLose([1, 2, 3, 5], false) // we've won
    })
  })

  describe('move', () => {
    it('moves left (2x2)', () => {
      function assertMove (origin, destination) {
        assertValues(newState(origin).move(DIRECTIONS.LEFT), destination)
      }

      assertMove([
        0, 0,
        0, 0
      ], [
        0, 0,
        0, 0
      ])

      assertMove([
        0, 1,
        0, 0
      ], [
        1, 0,
        0, 0
      ])

      assertMove([
        0, 0,
        0, 1
      ], [
        0, 0,
        1, 0
      ])

      assertMove([
        0, 0,
        1, 0
      ], [
        0, 0,
        1, 0
      ])

      assertMove([
        0, 0,
        1, 1
      ], [
        0, 0,
        2, 0
      ])

      assertMove([
        0, 1,
        0, 1
      ], [
        1, 0,
        1, 0
      ])

      assertMove([
        1, 1,
        0, 1
      ], [
        2, 0,
        1, 0
      ])

      assertMove([
        1, 1,
        1, 1
      ], [
        2, 0,
        2, 0
      ])
    })

    it('moves right (2x2)', () => {
      function assertMove (origin, destination) {
        assertValues(newState(origin).move(DIRECTIONS.RIGHT), destination)
      }

      assertMove([
        0, 0,
        0, 0
      ], [
        0, 0,
        0, 0
      ])

      assertMove([
        0, 1,
        0, 0
      ], [
        0, 1,
        0, 0
      ])

      assertMove([
        0, 0,
        0, 1
      ], [
        0, 0,
        0, 1
      ])

      assertMove([
        0, 0,
        1, 0
      ], [
        0, 0,
        0, 1
      ])

      assertMove([
        0, 0,
        1, 1
      ], [
        0, 0,
        0, 2
      ])

      assertMove([
        0, 1,
        0, 1
      ], [
        0, 1,
        0, 1
      ])

      assertMove([
        1, 1,
        0, 1
      ], [
        0, 2,
        0, 1
      ])

      assertMove([
        1, 1,
        1, 1
      ], [
        0, 2,
        0, 2
      ])
    })

    it('moves up (2x2)', () => {
      function assertMove (origin, destination) {
        assertValues(newState(origin).move(DIRECTIONS.UP), destination)
      }

      assertMove([
        0, 0,
        0, 0
      ], [
        0, 0,
        0, 0
      ])

      assertMove([
        0, 1,
        0, 0
      ], [
        0, 1,
        0, 0
      ])

      assertMove([
        0, 0,
        0, 1
      ], [
        0, 1,
        0, 0
      ])

      assertMove([
        0, 0,
        1, 0
      ], [
        1, 0,
        0, 0
      ])

      assertMove([
        0, 0,
        1, 1
      ], [
        1, 1,
        0, 0
      ])

      assertMove([
        0, 1,
        0, 1
      ], [
        0, 2,
        0, 0
      ])

      assertMove([
        1, 1,
        0, 1
      ], [
        1, 2,
        0, 0
      ])

      assertMove([
        1, 1,
        1, 1
      ], [
        2, 2,
        0, 0
      ])
    })

    it('moves down (2x2)', () => {
      function assertMove (origin, destination) {
        assertValues(newState(origin).move(DIRECTIONS.DOWN), destination)
      }

      assertMove([
        0, 0,
        0, 0
      ], [
        0, 0,
        0, 0
      ])

      assertMove([
        0, 1,
        0, 0
      ], [
        0, 0,
        0, 1
      ])

      assertMove([
        0, 0,
        0, 1
      ], [
        0, 0,
        0, 1
      ])

      assertMove([
        0, 0,
        1, 0
      ], [
        0, 0,
        1, 0
      ])

      assertMove([
        0, 0,
        1, 1
      ], [
        0, 0,
        1, 1
      ])

      assertMove([
        0, 1,
        0, 1
      ], [
        0, 0,
        0, 2
      ])

      assertMove([
        1, 1,
        0, 1
      ], [
        0, 0,
        1, 2
      ])

      assertMove([
        1, 1,
        1, 1
      ], [
        0, 0,
        2, 2
      ])
    })

    it('moves lines (4x4)', () => {
      // Based on line_with_known_tests.rb
      function moveLine (origin, destination) {
        let originState = newState([
          ...origin,
          ...origin,
          ...origin,
          ...origin
        ])
        let destinationState = newState([
          ...destination,
          ...destination,
          ...destination,
          ...destination
        ])
        assertValues(
          originState.copy().move(DIRECTIONS.LEFT),
          destinationState.getValues())
        assertValues(
          originState.copy().reflectX().move(DIRECTIONS.RIGHT),
          destinationState.copy().reflectX().getValues())
        assertValues(
          originState.copy().rotate90().move(DIRECTIONS.DOWN),
          destinationState.copy().rotate90().getValues())
        assertValues(
          originState.copy().rotate90().rotate90().rotate90().move(
            DIRECTIONS.UP),
          destinationState.copy().rotate90().rotate90().rotate90().getValues())
      }

      // Leading 0
      moveLine([0, 0, 0, 0], [0, 0, 0, 0])
      moveLine([0, 0, 0, 1], [1, 0, 0, 0])
      moveLine([0, 0, 0, 2], [2, 0, 0, 0])

      moveLine([0, 0, 1, 0], [1, 0, 0, 0])
      moveLine([0, 0, 1, 1], [2, 0, 0, 0])
      moveLine([0, 0, 1, 2], [1, 2, 0, 0])

      moveLine([0, 0, 2, 0], [2, 0, 0, 0])
      moveLine([0, 0, 2, 1], [2, 1, 0, 0])
      moveLine([0, 0, 2, 2], [3, 0, 0, 0])

      moveLine([0, 1, 0, 0], [1, 0, 0, 0])
      moveLine([0, 1, 0, 1], [2, 0, 0, 0])
      moveLine([0, 1, 0, 2], [1, 2, 0, 0])

      moveLine([0, 1, 1, 0], [2, 0, 0, 0])
      moveLine([0, 1, 1, 1], [2, 1, 0, 0])
      moveLine([0, 1, 1, 2], [2, 2, 0, 0])

      moveLine([0, 1, 2, 0], [1, 2, 0, 0])
      moveLine([0, 1, 2, 1], [1, 2, 1, 0])
      moveLine([0, 1, 2, 2], [1, 3, 0, 0])

      moveLine([0, 2, 0, 0], [2, 0, 0, 0])
      moveLine([0, 2, 0, 1], [2, 1, 0, 0])
      moveLine([0, 2, 0, 2], [3, 0, 0, 0])

      moveLine([0, 2, 1, 0], [2, 1, 0, 0])
      moveLine([0, 2, 1, 1], [2, 2, 0, 0])
      moveLine([0, 2, 1, 2], [2, 1, 2, 0])

      moveLine([0, 2, 2, 0], [3, 0, 0, 0])
      moveLine([0, 2, 2, 1], [3, 1, 0, 0])
      moveLine([0, 2, 2, 2], [3, 2, 0, 0])

      // # Leading 1
      moveLine([1, 0, 0, 0], [1, 0, 0, 0])
      moveLine([1, 0, 0, 1], [2, 0, 0, 0])
      moveLine([1, 0, 0, 2], [1, 2, 0, 0])

      moveLine([1, 0, 1, 0], [2, 0, 0, 0])
      moveLine([1, 0, 1, 1], [2, 1, 0, 0])
      moveLine([1, 0, 1, 2], [2, 2, 0, 0])

      moveLine([1, 0, 2, 0], [1, 2, 0, 0])
      moveLine([1, 0, 2, 1], [1, 2, 1, 0])
      moveLine([1, 0, 2, 2], [1, 3, 0, 0])

      moveLine([1, 1, 0, 0], [2, 0, 0, 0])
      moveLine([1, 1, 0, 1], [2, 1, 0, 0])
      moveLine([1, 1, 0, 2], [2, 2, 0, 0])

      moveLine([1, 1, 1, 0], [2, 1, 0, 0])
      moveLine([1, 1, 1, 1], [2, 2, 0, 0])
      moveLine([1, 1, 1, 2], [2, 1, 2, 0])

      moveLine([1, 1, 2, 0], [2, 2, 0, 0])
      moveLine([1, 1, 2, 1], [2, 2, 1, 0])
      moveLine([1, 1, 2, 2], [2, 3, 0, 0])

      moveLine([1, 2, 0, 0], [1, 2, 0, 0])
      moveLine([1, 2, 0, 1], [1, 2, 1, 0])
      moveLine([1, 2, 0, 2], [1, 3, 0, 0])

      moveLine([1, 2, 1, 0], [1, 2, 1, 0])
      moveLine([1, 2, 1, 1], [1, 2, 2, 0])
      moveLine([1, 2, 1, 2], [1, 2, 1, 2])

      moveLine([1, 2, 2, 0], [1, 3, 0, 0])
      moveLine([1, 2, 2, 1], [1, 3, 1, 0])
      moveLine([1, 2, 2, 2], [1, 3, 2, 0])

      // # Leading 2
      moveLine([2, 0, 0, 0], [2, 0, 0, 0])
      moveLine([2, 0, 0, 1], [2, 1, 0, 0])
      moveLine([2, 0, 0, 2], [3, 0, 0, 0])

      moveLine([2, 0, 1, 0], [2, 1, 0, 0])
      moveLine([2, 0, 1, 1], [2, 2, 0, 0])
      moveLine([2, 0, 1, 2], [2, 1, 2, 0])

      moveLine([2, 0, 2, 0], [3, 0, 0, 0])
      moveLine([2, 0, 2, 1], [3, 1, 0, 0])
      moveLine([2, 0, 2, 2], [3, 2, 0, 0])

      moveLine([2, 1, 0, 0], [2, 1, 0, 0])
      moveLine([2, 1, 0, 1], [2, 2, 0, 0])
      moveLine([2, 1, 0, 2], [2, 1, 2, 0])

      moveLine([2, 1, 1, 0], [2, 2, 0, 0])
      moveLine([2, 1, 1, 1], [2, 2, 1, 0])
      moveLine([2, 1, 1, 2], [2, 2, 2, 0])

      moveLine([2, 1, 2, 0], [2, 1, 2, 0])
      moveLine([2, 1, 2, 1], [2, 1, 2, 1])
      moveLine([2, 1, 2, 2], [2, 1, 3, 0])

      moveLine([2, 2, 0, 0], [3, 0, 0, 0])
      moveLine([2, 2, 0, 1], [3, 1, 0, 0])
      moveLine([2, 2, 0, 2], [3, 2, 0, 0])

      moveLine([2, 2, 1, 0], [3, 1, 0, 0])
      moveLine([2, 2, 1, 1], [3, 2, 0, 0])
      moveLine([2, 2, 1, 2], [3, 1, 2, 0])

      moveLine([2, 2, 2, 0], [3, 2, 0, 0])
      moveLine([2, 2, 2, 1], [3, 2, 1, 0])
      moveLine([2, 2, 2, 2], [3, 3, 0, 0])
    })
  })
})
