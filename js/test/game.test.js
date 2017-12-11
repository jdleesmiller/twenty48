/* global describe, it */

import assert from 'assert'
import _ from 'lodash'
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

    describe('getAvailableCellIndexes / countAvailableCells', () => {
      it('returns available cell indexes', () => {
        function assertAvailable (values, indexes) {
          let state = new GAME_2_5.State(values)
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
          let state = new GAME_2_5.State(values)
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
          let state = new GAME_2_5.State(values)
          assert.equal(state.isLose(), isLose)
        }

        assertLose([0, 0, 0, 0], true) // special 'lose' state
        assertLose([0, 0, 0, 1], false)
        assertLose([1, 1, 1, 1], false)
        assertLose([1, 2, 3, 4], true)
        assertLose([1, 2, 3, 5], false) // we've won
      })
    })

    describe('placeRandomTile', () => {
      it('places a at random in an available cell', () => {
        function assertRandomTileIn (origin, destinations) {
          let originState = new GAME_2_5.State(origin)
          _.times(50, () => {
            let resultValues = originState.placeRandomTile().values
            assert(destinations.some(values => _.isEqual(values, resultValues)))
          })
        }

        assertRandomTileIn([0, 1, 1, 1], [[1, 1, 1, 1], [2, 1, 1, 1]])
        assertRandomTileIn([1, 1, 1, 0], [[1, 1, 1, 1], [1, 1, 1, 2]])
        assertRandomTileIn([1, 0, 0, 1], [
          [1, 0, 1, 1], [1, 0, 2, 1],
          [1, 1, 0, 1], [1, 2, 0, 1]])
      })
    })

    describe('move', () => {
      it('moves left (2x2)', () => {
        function assertMove (origin, destination) {
          let originState = new GAME_2_5.State(origin)
          let destinationState = new GAME_2_5.State(destination)
          assertSameState(
            originState.move(GAME_2_5.DIRECTIONS.LEFT),
            destinationState)
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
          let originState = new GAME_2_5.State(origin)
          let destinationState = new GAME_2_5.State(destination)
          assertSameState(
            originState.move(GAME_2_5.DIRECTIONS.RIGHT),
            destinationState)
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
          let originState = new GAME_2_5.State(origin)
          let destinationState = new GAME_2_5.State(destination)
          assertSameState(
            originState.move(GAME_2_5.DIRECTIONS.UP),
            destinationState)
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
          let originState = new GAME_2_5.State(origin)
          let destinationState = new GAME_2_5.State(destination)
          assertSameState(
            originState.move(GAME_2_5.DIRECTIONS.DOWN),
            destinationState)
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
          let originState = new GAME_4_11.State([
            ...origin,
            ...origin,
            ...origin,
            ...origin
          ])
          let destinationState = new GAME_4_11.State([
            ...destination,
            ...destination,
            ...destination,
            ...destination
          ])
          assertSameState(
            destinationState,
            originState.move(GAME_4_11.DIRECTIONS.LEFT))
          assertSameState(
            destinationState.reflectX(),
            originState.reflectX().move(GAME_4_11.DIRECTIONS.RIGHT))
          assertSameState(
            destinationState.rotate90(),
            originState.rotate90().move(GAME_4_11.DIRECTIONS.UP))
          assertSameState(
            destinationState.rotate90().rotate90().rotate90(),
            originState.rotate90().rotate90().rotate90().move(
              GAME_4_11.DIRECTIONS.DOWN))
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
})
