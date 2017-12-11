import _ from 'lodash'

export default function Game (boardSize, maxExponent) {
  const DIRECTIONS = {
    LEFT: 'left',
    RIGHT: 'right',
    UP: 'up',
    DOWN: 'down'
  }

  /**
   * Move a line of tiles to the left. This is the basic operation used to
   * implement moving a state.
   *
   * @param  {[type]} values [description]
   * @return {[type]}        [description]
   */
  function moveLine (values) {
    let result = new Array(values.length).fill(0)
    let i = 0
    let last = null
    for (let value of values) {
      // Slide through empty cells.
      if (value === 0) continue

      if (value === last) {
        // Merge adjacent tiles.
        result[i - 1] += 1
        last = null
      } else {
        // Keep the tile.
        result[i] = value
        i += 1
        last = value
      }
    }
    return result
  }

  /**
   * Coordinates for a cell on the board.
   */
  class Point {
    constructor (x, y) {
      this.x = x
      this.y = y
    }

    transpose () {
      return new Point(this.y, this.x)
    }

    reflectX () {
      return new Point(boardSize - 1 - this.x, this.y)
    }

    rotate90 () {
      return this.reflectX().transpose()
    }

    reflectY () {
      return this.transpose().reflectX().transpose()
    }

    toIndex () {
      return boardSize * this.y + this.x
    }

    static fromIndex (index) {
      let x = index % boardSize
      let y = Math.floor(index / boardSize)
      return new Point(x, y, boardSize)
    }
  }

  /**
   * A board configuration.
   */
  class State {
    constructor (values) {
      this.values = values
    }

    getSum () {
      return _.sum(this.values.map(
        (value) => value === 0 ? 0 : Math.pow(2, value)
      ))
    }

    canonicalize () {
      let rotations = [this]
      rotations.push(rotations[0].rotate90())
      rotations.push(rotations[1].rotate90())
      rotations.push(rotations[2].rotate90())
      let reflections = rotations.map(State.reflectX)
      let candidates = [...rotations, ...reflections]
      return _.minBy(candidates, State.toString)
    }

    rotate90 () {
      return new State(this.values.map((_, index) =>
        this.values[Point.fromIndex(index).rotate90().toIndex()]
      ))
    }

    reflectX () {
      return new State(this.values.map((_, index) =>
        this.values[Point.fromIndex(index).reflectX().toIndex()]
      ))
    }

    transpose () {
      return new State(this.values.map((_, index) =>
        this.values[Point.fromIndex(index).transpose().toIndex()]
      ))
    }

    move (direction) {
      switch (direction) {
        case DIRECTIONS.LEFT:
          return new State(
            _(this.values)
              .chunk(boardSize).map(moveLine).flatten()
              .value())
        case DIRECTIONS.RIGHT:
          return this.reflectX().move(DIRECTIONS.LEFT).reflectX()
        case DIRECTIONS.UP:
          return this.transpose().move(DIRECTIONS.LEFT).transpose()
        case DIRECTIONS.DOWN:
          return this.transpose().move(DIRECTIONS.RIGHT).transpose()
        default:
          throw new Error('bad direction ' + direction)
      }
    }

    toString () {
      return this.values.map(function (value) {
        return value.toString(16)
      }).join('')
    }

    static toString (state) {
      return state.toString()
    }

    static newFromValueArrayString (string) {
      return new State(JSON.parse(string))
    }
  }

  class Policy {
    constructor (actionValues) {
      this.actionValues = actionValues
    }

    getAction (state) {
      return this.getActionCanonicalized(state.canonicalize())
    }

    getActionCanonicalized (state) {
      return this.actionValues[state.toString()].action
    }

    static newFromCsv (data) {
      let actionValues = {}
      data.forEach(function (row) {
        let state = State.newFromValueArrayString(row.state).toString()
        actionValues[state] = { action: row.action, value: row.value }
      })
      return new Policy(actionValues)
    }
  }

  // seed
  // speed option
  // policy as json --- no uint64_t support
  // show value (compute on fly? requires complete policy)
  // load policy in chunks?
  // reduce policies before converting to JSON? needed for 3x3
  class PolicyPlayer {
    constructor (container) {
      this.container = container
    }

    run (data) {
      let policy = Policy.newFromCsv(data)
      console.log(policy)
      let state = new State([0, 0, 2, 1])
      console.log(state.toString())
      console.log(state.canonicalize().toString())
      console.log(policy.getAction(state))
      console.log(state.move('left').toString())
    }
  }

  this.State = State
  this.PolicyPlayer = PolicyPlayer
  this.DIRECTIONS = DIRECTIONS
}
