import * as d3 from 'd3'
import Game from './lib/game'

document.addEventListener('DOMContentLoaded', function () {
  d3.csv('/policy_2x2_32.csv', function (data) {
    let game = new Game(2, 5)
    new game.PolicyPlayer(d3.select('#policy-player-2x2')).run(data)
  })
})
