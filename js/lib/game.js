// import * as d3 from 'd3'
import makeState from './state'

export default function Game (boardSize, maxExponent) {
  const State = makeState(boardSize, maxExponent)

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
  const CELL_PX = 42
  const PAD = 8
  const BOARD_PX = boardSize * CELL_PX + (boardSize + 1) * PAD

  class PolicyPlayer {
    constructor (container) {
      this.container = container
      this.svg = container.append('svg')
        .attr('width', BOARD_PX)
        .attr('height', BOARD_PX)
      this.state = State.fromValues([0, 0, 2, 1])

      this.drawBackground()
    }

    drawBackground () {
      this.svg.append('rect')
        .attr('width', BOARD_PX)
        .attr('height', BOARD_PX)
        .style('fill', '#bbb')

      for (let i = 0; i < boardSize; ++i) {
        for (let j = 0; j < boardSize; ++j) {
          this.svg.append('rect')
            .attr('x', PAD + i * (CELL_PX + PAD))
            .attr('y', PAD + j * (CELL_PX + PAD))
            .attr('width', CELL_PX)
            .attr('height', CELL_PX)
            .style('fill', '#ddd')
        }
      }
    }

    run (data) {
      // let policy = Policy.newFromCsv(data)
      // console.log(policy)
      // let state = new State([0, 0, 2, 1])
      // console.log(state.toString())
      // console.log(state.canonicalize().toString())
      // console.log(policy.getAction(state))
      // console.log(state.move('left').toString())
    }
  }

  this.State = State
  this.PolicyPlayer = PolicyPlayer
}
