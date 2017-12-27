import * as d3 from 'd3'

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
}

export default class Driver {
  constructor (container, boardSize, policy, generator, emptyState) {
    this.container = container
    this.boardSize = boardSize
    this.policy = policy
    this.generator = generator
    this.state = emptyState

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
      .style('fill', '#bbb')

    for (let i = 0; i < this.boardSize; ++i) {
      for (let j = 0; j < this.boardSize; ++j) {
        background.append('rect')
          .attr('x', DisplayTile.offset(i))
          .attr('y', DisplayTile.offset(j))
          .attr('width', CELL_PX)
          .attr('height', CELL_PX)
          .style('fill', '#ddd')
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
      .style('fill', '#fff')

    newTileSvgs.append('text')
      .attr('x', CELL_PX / 2)
      .attr('y', CELL_PX / 2)
      .attr('dominant-baseline', 'middle')
      .attr('text-anchor', 'middle')
      .style('stroke', '#000')
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
      .select('text')
      .transition(t)
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

  run () {
    this.state.placeRandomTile(this.generator)
    this.state.placeRandomTile(this.generator)

    let step = () => {
      this.update(PLACE_DURATION).on('end', () => {
        if (this.state.isWin() || this.state.isLose()) return

        let canonicalTransform = this.state.getCanonicalTransform()
        let canonicalState =
          this.state.copy().applyTransform(canonicalTransform)
        let canonicalAction = this.policy.getAction(canonicalState)
        let action = canonicalTransform.invertAction(canonicalAction)
        this.state.move(action)

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
