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
    //
    // static fromIndex (index) {
    //   let i = Math.floor(index / boardSize)
    //   let j = index % boardSize
    //   return new Point(i, j, boardSize)
    // }
  }

  class Transform {
    apply (point) { return point }
    unapply (point) { return this.apply(point) }
  }

  class Transpose extends Transform {
    apply (point) { return new Point(point.j, point.i) }
  }

  class ReflectX extends Transform {
    apply (point) { return new Point(point.i, boardSize - 1 - point.j) }
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

    unapply (point) {
      let reversedTransforms = this.transforms.slice().reverse()
      return reversedTransforms.reduce(
        (result, transform) => transform.unapply(result), point)
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
