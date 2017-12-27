import * as d3 from 'd3'
import MersenneTwister from 'mersenne-twister'

import makeState from './state'
import makePolicy from './policy'

export default function Game (boardSize, maxExponent) {
  // 2x2: win: 47, lose quickly: 43
  // 3x3: win: 56, lose: 42-55
  const generator = new MersenneTwister(56)
  const State = makeState(boardSize, maxExponent)
  const Policy = makePolicy(boardSize)

  // seed
  // speed option
  // policy as json --- no uint64_t support
  // show value (compute on fly? requires complete policy)
  // load policy in chunks?
  // reduce policies before converting to JSON? needed for 3x3
  const CELL_PX = 42
  const PAD = 8
  const INFLATE = 1.5
  const BOARD_PX = boardSize * CELL_PX + (boardSize + 1) * PAD

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

  class PolicyPlayer {
    constructor (container, policy) {
      this.container = container
      this.policy = policy

      this.svg = container.append('svg')
        .attr('width', BOARD_PX)
        .attr('height', BOARD_PX)
      this.drawBackground()
      this.board = this.svg.append('svg')
      this.state = State.newEmpty()
    }

    drawBackground () {
      let background = this.svg.append('svg')
      background.append('rect')
        .attr('width', BOARD_PX)
        .attr('height', BOARD_PX)
        .style('fill', '#bbb')

      for (let i = 0; i < boardSize; ++i) {
        for (let j = 0; j < boardSize; ++j) {
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
      for (let i = 0; i < boardSize; ++i) {
        for (let j = 0; j < boardSize; ++j) {
          let tile = this.state.getTileAt(i, j)
          if (tile) displayTiles.push(new DisplayTile(tile, i, j))
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

    update () {
      var t = this.board.transition().duration(300)
      let tiles = this.board.selectAll('svg.tile')
        .data(this.getDisplayTiles(), DisplayTile.key)
      this.draw(t, tiles)
      return t
    }

    run () {
      this.state.placeRandomTile(generator)
      this.state.placeRandomTile(generator)

      let step = () => {
        this.update().on('end', () => {
          if (this.state.isWin() || this.state.isLose()) return

          let canonicalTransform = this.state.getCanonicalTransform()
          let canonicalState =
            this.state.copy().applyTransform(canonicalTransform)
          let canonicalAction = this.policy.getAction(canonicalState)
          let action = canonicalTransform.invertAction(canonicalAction)
          this.state.move(action)

          this.update().on('end', () => {
            this.state.placeRandomTile(generator)
            setTimeout(step, 0)
          })
        })
      }
      step()
    }
  }

  this.Policy = Policy
  this.PolicyPlayer = PolicyPlayer
}
