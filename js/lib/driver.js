import * as d3 from 'd3'
import MersenneTwister from 'mersenne-twister'

const CELL_PX = 42
const PAD = 8
const INFLATE = 1.5

const PLACE_DURATION = 200
const MERGE_DURATION = 200
const MOVE_DURATION = 200

class DisplayTile {
  constructor (tile, i, j) {
    this.tile = tile
    this.i = i
    this.j = j
  }

  static key (displayTile) {
    return displayTile.tile.id
  }

  static offset (ij) {
    return PAD + ij * (CELL_PX + PAD)
  }

  static x (displayTile) {
    return DisplayTile.offset(displayTile.j)
  }

  static y (displayTile) {
    return DisplayTile.offset(displayTile.i)
  }

  static displayValue (displayTile) {
    return Math.pow(2, displayTile.tile.value)
  }

  // Colors from http://gabrielecirulli.github.io/2048
  static textColor (displayTile) {
    if (!displayTile.tile || displayTile.tile.value < 3) return '#776e65'
    return '#f9f6f2'
  }

  // Colors from http://gabrielecirulli.github.io/2048
  static fill (displayTile) {
    if (!displayTile.tile) return ''
    switch (displayTile.tile.value) {
      case 1: return '#eee4da'
      case 2: return '#ede0c8'
      case 3: return '#f2b179'
      case 4: return '#f59563'
      case 5: return '#f67c5f'
      case 6: return '#f65e3b'
      case 7: return '#edcf72'
      case 8: return '#edcc61'
      case 9: return '#edc850'
      default: return '#edc53f'
    }
  }
}

export default class Driver {
  constructor (container, dispatch, boardSize) {
    this.container = container
    this.dispatch = dispatch
    this.boardSize = boardSize

    this.svg = container.append('svg')
      .attr('width', this.getBoardPx())
      .attr('height', this.getBoardPx())
    this.drawBackground()
    this.board = this.svg.append('svg')
  }

  getBoardPx () {
    return this.boardSize * CELL_PX + (this.boardSize + 1) * PAD
  }

  drawBackground () {
    let background = this.svg.append('svg')
    background.append('rect')
      .attr('width', this.getBoardPx())
      .attr('height', this.getBoardPx())
      .style('fill', '#bbada0')

    for (let i = 0; i < this.boardSize; ++i) {
      for (let j = 0; j < this.boardSize; ++j) {
        background.append('rect')
          .attr('x', DisplayTile.offset(i))
          .attr('y', DisplayTile.offset(j))
          .attr('width', CELL_PX)
          .attr('height', CELL_PX)
          .style('fill', 'rgba(238, 228, 218, 0.35)')
      }
    }
  }

  getDisplayTiles () {
    let displayTiles = []
    for (let i = 0; i < this.boardSize; ++i) {
      for (let j = 0; j < this.boardSize; ++j) {
        let tile = this.state.getTileAt(i, j)
        if (tile) {
          displayTiles.push(new DisplayTile(tile, i, j))
          if (tile.mergedWith) {
            displayTiles.push(new DisplayTile(tile.mergedWith, i, j))
          }
        }
      }
    }
    return displayTiles
  }

  clear () {
    this.board.selectAll('svg.tile')
      .data(this.getDisplayTiles(), DisplayTile.key)
      .exit()
      .remove()
  }

  draw (t, tileSvgs) {
    let newTileSvgs = tileSvgs.enter()
      .append('svg')
      .attr('x', DisplayTile.x)
      .attr('y', DisplayTile.y)
      .attr('class', 'tile')
      .style('fill-opacity', 1e-6)
      .style('stroke-opacity', 1e-6)

    newTileSvgs.append('rect')
      .attr('width', CELL_PX)
      .attr('height', CELL_PX)
      .style('fill', DisplayTile.fill)

    newTileSvgs.append('text')
      .attr('x', CELL_PX / 2)
      .attr('y', CELL_PX / 2)
      .attr('dominant-baseline', 'middle')
      .attr('text-anchor', 'middle')
      .style('stroke', DisplayTile.textColor)
      .style('fill', DisplayTile.textColor)
      .text(DisplayTile.displayValue)

    newTileSvgs
      .transition(t)
      .style('fill-opacity', 1)
      .style('stroke-opacity', 1)

    tileSvgs
      .transition(t)
      .attr('x', DisplayTile.x)
      .attr('y', DisplayTile.y)

    tileSvgs
      .select('rect')
      .style('fill', DisplayTile.fill)

    tileSvgs
      .select('text')
      .transition(t)
      .style('stroke', DisplayTile.textColor)
      .style('fill', DisplayTile.textColor)
      .text(DisplayTile.displayValue)

    tileSvgs.exit()
      .transition(t)
      .ease(d3.easeExp)
      .attr('x', (d) => DisplayTile.x(d) - INFLATE)
      .attr('y', (d) => DisplayTile.y(d) - INFLATE)
      .remove()

    tileSvgs.exit()
      .lower()
      .select('rect')
      .transition(t)
      .ease(d3.easeExp)
      .attr('width', CELL_PX + 2 * INFLATE)
      .attr('height', CELL_PX + 2 * INFLATE)
  }

  update (duration) {
    var t = this.board.transition().duration(duration)
    let tiles = this.board.selectAll('svg.tile')
      .data(this.getDisplayTiles(), DisplayTile.key)
    this.draw(t, tiles)
    return t
  }

  cleanupMergedTiles () {
    for (let i = 0; i < this.boardSize; ++i) {
      for (let j = 0; j < this.boardSize; ++j) {
        let tile = this.state.getTileAt(i, j)
        if (tile) tile.mergedWith = null
      }
    }
    return this.update(MERGE_DURATION)
  }

  run (emptyState, policy, seed) {
    this.state = emptyState
    this.policy = policy
    this.generator = new MersenneTwister(seed)

    this.clear()

    this.state.placeRandomTile(this.generator)
    this.state.placeRandomTile(this.generator)

    let step = () => {
      this.update(PLACE_DURATION).on('end', () => {
        if (this.state.isWin() || this.state.isLose()) {
          this.dispatch.call('end', null, this.state.isWin())
          return
        }

        let canonicalTransform = this.state.getCanonicalTransform()
        let canonicalState =
          this.state.copy().applyTransform(canonicalTransform)
        let canonicalAction = this.policy.getAction(canonicalState)
        let action = canonicalTransform.invertAction(canonicalAction)
        this.state.move(action)
        this.dispatch.call('move', null, action)

        this.update(MOVE_DURATION).on('end', () => {
          this.cleanupMergedTiles().on('end', () => {
            this.state.placeRandomTile(this.generator)
            setTimeout(step, 0)
          })
        })
      })
    }
    step()
  }
}
