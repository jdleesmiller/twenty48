import _ from 'lodash'

import DIRECTIONS from './directions'
import makeTransforms from './transforms'

/**
 * Move a row of tiles left, in place.
 */
function moveLineLeft (line) {
  let done = 0
  let merged = 0
  for (let i = 0; i < line.length; ++i) {
    let tile = line[i]
    if (!tile) continue

    if (done > merged && line[done - 1].isSame(tile)) {
      line[done - 1].startMerge(tile)
      line[i] = null
      merged = done
    } else {
      if (i > done) {
        line[done] = tile
        line[i] = null
      }
      ++done
    }
  }
}

export default function makeState (boardSize, maxExponent) {
  const { Point, REFLECT_X, ROTATE_90, TRANSPOSE, TRANSFORMS } =
    makeTransforms(boardSize)

  const INDEXES = _.times(boardSize) // [0, 1, ..., boardSize - 1]
  const POINTS = _.flatten(INDEXES.map(i => INDEXES.map(j => new Point(i, j))))

  let tileId = 0

  class Tile {
    constructor (value) {
      this.value = value
      this.id = ++tileId
      this.mergingWith = null
    }

    isSame (other) {
      return other && this.value === other.value
    }

    startMerge (tile) {
      this.mergingWith = tile
    }

    isMerging () {
      return !!this.mergingWith
    }
  }

  class State {
    constructor (tiles) {
      this.tiles = tiles
    }

    static newEmpty () {
      return State.fromValues(new Array(boardSize * boardSize).fill(0))
    }

    static fromValues (values) {
      let tiles = values.map((value) => value === 0 ? null : new Tile(value))
      return new State(_.chunk(tiles, boardSize))
    }

    startMove (direction) {
      switch (direction) {
        case DIRECTIONS.LEFT:
          this.tiles.forEach(moveLineLeft)
          return this
        case DIRECTIONS.RIGHT:
          return this.reflectX().startMove(DIRECTIONS.LEFT).reflectX()
        case DIRECTIONS.UP:
          return this.transpose().startMove(DIRECTIONS.LEFT).transpose()
        case DIRECTIONS.DOWN:
          return this.transpose().startMove(DIRECTIONS.RIGHT).transpose()
        default:
          throw new Error('bad direction ' + direction)
      }
    }

    finishMove () {
      POINTS.forEach((point) => {
        let tile = this.getTile(point)
        if (tile && tile.isMerging()) {
          this.setTile(point, new Tile(tile.value + 1))
        }
      })
    }

    move (direction) {
      this.startMove(direction)
      this.finishMove()
      return this
    }

    rotate90 () {
      return this.applyTransform(ROTATE_90)
    }

    reflectX () {
      return this.applyTransform(REFLECT_X)
    }

    transpose () {
      return this.applyTransform(TRANSPOSE)
    }

    getTileAt (i, j) {
      return this.tiles[i][j]
    }

    getTile (point) {
      return this.getTileAt(point.i, point.j)
    }

    setTileAt (i, j, tile) {
      this.tiles[i][j] = tile
    }

    setTile (point, tile) {
      this.setTileAt(point.i, point.j, tile)
    }

    applyTransform (transform) {
      let state = this.copy()
      POINTS.forEach((point) => {
        this.setTile(transform.apply(point), state.getTile(point))
      })
      return this
    }

    getCanonicalTransform () {
      return _.minBy(TRANSFORMS, (transform) =>
        this.copy().applyTransform(transform).toString()
      )
    }

    canonicalize () {
      return this.applyTransform(this.getCanonicalTransform())
    }

    copy () {
      return new State(_.cloneDeep(this.tiles))
    }

    getValue (point) {
      let tile = this.getTile(point)
      return tile ? tile.value : 0
    }

    getValues () {
      return POINTS.map((point) => this.getValue(point))
    }

    toString () {
      return this.getValues().map((value) => value.toString(16)).join('')
    }

    getAvailableCellIndexes () {
      return this.getValues().reduce((available, value, index) => {
        if (value === 0) {
          available.push(index)
        }
        return available
      }, [])
    }

    countAvailableCells () {
      return this.getAvailableCellIndexes().length
    }

    placeRandomTile (generator) {
      let availableCellIndexes = this.getAvailableCellIndexes()
      if (availableCellIndexes.length > 0) {
        let index = generator.random_int() % availableCellIndexes.length
        let point = Point.fromIndex(availableCellIndexes[index])
        let tile = new Tile(generator.random() < 0.1 ? 2 : 1)
        this.setTile(point, tile)
      }
      return this
    }

    isEqual (other) {
      return _.isEqual(this.tiles, other.tiles)
    }

    isWin () {
      return this.getValues().some((value) => value >= maxExponent)
    }

    isLose () {
      if (this.countAvailableCells() === boardSize * boardSize) return true
      if (this.isWin()) return false
      let state = this.copy()
      return _(DIRECTIONS).values().every((direction) => {
        state.move(direction)
        return this.isEqual(state)
      })
    }
  }

  return State
}
