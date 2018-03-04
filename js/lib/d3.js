import * as dispatch from 'd3-dispatch'
import * as dsv from 'd3-dsv'
import * as selection from 'd3-selection'
import * as transition from 'd3-transition'

const d3 = Object.assign({},
  dispatch, dsv, selection, transition
)

// Based on https://github.com/d3/d3/blob/4/rollup.node.js
Object.defineProperty(d3, 'event', {
  get: function () { return selection.event }
})

export default d3
