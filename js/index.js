import * as d3 from 'd3'
import makeGame from './lib/game'

document.addEventListener('DOMContentLoaded', function () {
  d3.selectAll('.twenty48-policy-player')
    .datum(function () { return this.dataset })
    .each(function (data) {
      makeGame(
        d3.select(this),
        parseInt(data.boardSize, 10),
        parseInt(data.maxExponent, 10),
        data.packedPolicyPath,
        data.initialSeed
      )
    })
})
