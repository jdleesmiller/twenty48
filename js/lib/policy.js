import _ from 'lodash'
import 'whatwg-fetch'

import DIRECTIONS from './directions'

const PACKED_DIRECTIONS = [
  DIRECTIONS.LEFT, DIRECTIONS.RIGHT,
  DIRECTIONS.UP, DIRECTIONS.DOWN
]

function checkStatus (response) {
  if (response.status >= 200 && response.status < 300) {
    return response
  } else {
    var error = new Error(response.statusText)
    error.response = response
    throw error
  }
}

export default function makePolicy (boardSize) {
  const STATE_STRING_LENGTH = boardSize * boardSize

  function getStateName (state) {
    return _.padStart(state.toString(16), STATE_STRING_LENGTH, '0')
  }

  class Policy {
    constructor (actionValues) {
      this.actionValues = actionValues
    }

    getAction (canonicalState) {
      let actionIndex = this.actionValues[canonicalState.toString()]
      if (actionIndex == null) {
        throw new Error('No policy for ' + canonicalState.toString())
      }
      return PACKED_DIRECTIONS[actionIndex]
    }

    static load (path) {
      function unpack (lines) {
        let previous = 0
        let actionValues = {}

        lines.forEach((line) => {
          let [ delta36, action ] = line.split(',')
          let delta = parseInt(delta36, 36)
          let state = previous + delta
          previous = state
          actionValues[getStateName(state)] = parseInt(action, 10)
        })

        return new Policy(actionValues)
      }

      return fetch(path)
        .then(checkStatus)
        .then((response) => response.text())
        .then((text) => text.split('\n').slice(1)) // strip header
        .then(unpack)
    }
  }

  return Policy
}
