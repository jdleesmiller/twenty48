import d3 from './d3'
import DIRECTIONS from './directions'
import Driver from './driver'
import makeState from './state'
import makePolicy from './policy'

// Auto generate IDs so we can hook up labels
let formId = 0
function generateId () {
  return 'twenty48-auto-id-' + ++formId
}

export default function makeGame (
  container, boardSize, maxExponent, packedPolicyPath, initialSeed) {
  const State = makeState(boardSize, maxExponent)
  const Policy = makePolicy(boardSize)

  function rollSeed () {
    return Math.floor(Math.random() * 10000)
  }

  if (!initialSeed) initialSeed = rollSeed()

  const PAD = 10

  container.style('display', 'flex')

  let leftDiv = container.append('div')
  leftDiv.style('flex', 0)

  let rightDiv = container.append('div')
  rightDiv.style('flex', 1)

  let dispatch = d3.dispatch('move', 'end')
  let driver = new Driver(leftDiv, dispatch, boardSize)

  let form = rightDiv.append('form')

  let seedInputId = generateId()
  let seedDiv = form.append('div')
    .style('padding-bottom', PAD)

  seedDiv.append('label')
    .attr('for', seedInputId)
    .style('padding-left', PAD)
    .style('padding-right', PAD)
    .text('Random Seed')

  let seedInput = seedDiv.append('input')
    .attr('type', 'number')
    .attr('id', seedInputId)
    .attr('min', 0)
    .attr('max', 1e9)
    .attr('step', 1)
    .attr('value', initialSeed)
    .on('input', function () {
      d3.select(this).attr('value', this.value)
    })

  let seedButton = seedDiv.append('button')
    .style('margin-left', PAD)
    .html('&#x27f2;')
    .on('click', () => {
      d3.event.preventDefault()
      seedInput.attr('value', rollSeed())
    })

  let buttonDiv = form.append('div')
    .style('padding-left', PAD)

  let button = buttonDiv.append('button')
    .text('Start')
    .on('click', () => {
      d3.event.preventDefault()
      startRun()
    })

  let statusDiv = rightDiv.append('div')
    .style('padding-left', PAD)

  let moveCount = 0
  let policyLoad = null // only load the policy once
  function startRun () {
    toggleInputs(false)
    button.html('Loading Policy&hellip;')

    let seed = parseInt(seedInput.attr('value'), 10)

    moveCount = 0
    if (!policyLoad) policyLoad = Policy.load(packedPolicyPath)
    policyLoad.then((policy) => {
      button.html('Running&hellip;')

      dispatch.on('move', handleMove)
      dispatch.on('end', handleEnd)

      driver.run(State.newEmpty(), policy, seed)
    })
    .catch((err) => {
      alert(`Sorry, could not load the policy.
Please reload the page and try again.
${err}`)
    })
  }

  const ARROWS = {
    [DIRECTIONS.LEFT]: '←',
    [DIRECTIONS.RIGHT]: '→',
    [DIRECTIONS.UP]: '↑',
    [DIRECTIONS.DOWN]: '↓'
  }

  function handleMove (action) {
    statusDiv.text(`Move ${++moveCount}: ${ARROWS[action]}`)
  }

  function handleEnd (win) {
    statusDiv.text(`${win ? 'Won' : 'Lost'} in ${moveCount} moves`)
    toggleInputs(true)
    button.text('Start')
  }

  function toggleInputs (enable) {
    let value = enable ? null : true
    seedInput.attr('disabled', value)
    seedButton.attr('disabled', value)
    button.attr('disabled', value)
  }
}
