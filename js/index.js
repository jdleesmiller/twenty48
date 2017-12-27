import * as d3 from 'd3'
import Game from './lib/game'

document.addEventListener('DOMContentLoaded', function () {
  let game310 = new Game(3, 10)
  game310.Policy.load('/policy_3x3_1024_packed.csv').then((policy) => {
    new game310.PolicyPlayer(d3.select('#policy-player-3x3'), policy).run()
  })

  let game45 = new Game(4, 5)
  game45.Policy.load('/policy_4x4_32_packed.csv').then((policy) => {
    new game45.PolicyPlayer(d3.select('#policy-player-4x4'), policy).run()
  })
})
