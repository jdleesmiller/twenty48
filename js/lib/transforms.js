import DIRECTIONS from './directions'

export default function makeTransforms (boardSize) {
  /**
   * Coordinates for a cell on the board.
   */
  class Point {
    constructor (i, j) {
      this.i = i
      this.j = j
    }

    // toIndex () {
    //   return boardSize * this.i + this.j
    // }

    static fromIndex (index) {
      let i = Math.floor(index / boardSize)
      let j = index % boardSize
      return new Point(i, j)
    }
  }

  class Transform {
    apply (point) { return point }
    invertAction (action) { return action }
  }

  class Transpose extends Transform {
    apply (point) { return new Point(point.j, point.i) }

    invertAction (action) {
      switch (action) {
        case DIRECTIONS.LEFT: return DIRECTIONS.UP
        case DIRECTIONS.RIGHT: return DIRECTIONS.DOWN
        case DIRECTIONS.UP: return DIRECTIONS.LEFT
        case DIRECTIONS.DOWN: return DIRECTIONS.RIGHT
      }
    }
  }

  class ReflectX extends Transform {
    apply (point) { return new Point(point.i, boardSize - 1 - point.j) }

    invertAction (action) {
      switch (action) {
        case DIRECTIONS.LEFT: return DIRECTIONS.RIGHT
        case DIRECTIONS.RIGHT: return DIRECTIONS.LEFT
        default: return action
      }
    }
  }

  class Composition extends Transform {
    constructor (transforms) {
      super()
      this.transforms = transforms
    }

    apply (point) {
      return this.transforms.reduce(
        (result, transform) => transform.apply(result), point)
    }

    invertAction (action) {
      let reversedTransforms = this.transforms.slice().reverse()
      return reversedTransforms.reduce(
        (result, transform) => transform.invertAction(result), action)
    }
  }

  class Rotate90 extends Composition {
    constructor () {
      super([new ReflectX(), new Transpose()])
    }
  }

  class Rotate180 extends Composition {
    constructor () {
      super([new Rotate90(), new Rotate90()])
    }
  }

  class Rotate270 extends Composition {
    constructor () {
      super([new Rotate180(), new Rotate90()])
    }
  }

  const REFLECT_X = new ReflectX()
  const TRANSPOSE = new Transpose()
  const ROTATE_90 = new Rotate90()

  const ROTATIONS = [
    new Transform(), // identity
    new Rotate90(),
    new Rotate180(),
    new Rotate270()
  ]
  const REFLECTIONS = ROTATIONS.map(
    (rotation) => new Composition([rotation, REFLECT_X])
  )

  return {
    Point,
    REFLECT_X,
    TRANSPOSE,
    ROTATE_90,
    TRANSFORMS: [...ROTATIONS, ...REFLECTIONS]
  }
}
