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

export default function makePolicy (boardSize, maxExponent) {
  const STATE_STRING_LENGTH = boardSize * boardSize

  function getStateName (state) {
    return _.padStart(state.toString(maxExponent), STATE_STRING_LENGTH, '0')
  }

  class ActionValue {
    constructor (action, value) {
      this.action = action
      this.value = value
    }
  }

  class Policy {
    constructor (actionValues, haveValues) {
      this.actionValues = actionValues
      this.haveValues = haveValues
    }

    getHaveValues () {
      return this.haveValues
    }

    getAction (canonicalState) {
      return PACKED_DIRECTIONS[this.getActionValue(canonicalState).action]
    }

    getValue (canonicalState) {
      return this.getActionValue(canonicalState).value
    }

    getActionValue (canonicalState) {
      let actionValue = this.actionValues[canonicalState.toString()]
      if (actionValue == null) {
        let error = new Error('No policy for ' + canonicalState.toString())
        error.code = 'no_policy'
        throw error
      }
      return actionValue
    }

    //
    // See bin/pack_policy for an explanation of this (rather weird) format.
    //
    static load (path) {
      function unpackWithValues (actionValues, action, pairs, mostCommonValue) {
        let previous = 0
        for (let i = 0; i < pairs.length; i += 2) {
          let delta36 = pairs[i]
          let value10 = pairs[i + 1]
          let delta = delta36 === '' ? 1 : parseInt(delta36, 36)
          let value = value10 === '' ? mostCommonValue : parseInt(value10, 10)
          let packed = previous + delta
          previous = packed
          actionValues[getStateName(packed)] =
            new ActionValue(action, value / 100.0)
        }
        return actionValues
      }

      function unpackWithoutValues (actionValues, action, delta36s) {
        let previous = 0
        for (let delta36 of delta36s) {
          let delta = delta36 === '' ? 1 : parseInt(delta36, 36)
          let packed = previous + delta
          previous = packed
          actionValues[getStateName(packed)] = new ActionValue(action)
        }
        return actionValues
      }

      function unpack (lines) {
        let header = lines.shift()
        let mostCommonValue = null
        let haveValues = false
        if (header.startsWith('av')) {
          haveValues = true
          mostCommonValue = parseFloat(header.split(' ')[1])
        }

        let actionValues = {}
        for (let line of lines) {
          let [actionString, ...rest] = line.split(' ')
          let action = parseInt(actionString, 10)
          if (haveValues) {
            unpackWithValues(actionValues, action, rest, mostCommonValue)
          } else {
            unpackWithoutValues(actionValues, action, rest)
          }
        }
        return new Policy(actionValues, haveValues)
      }

      return fetch(path)
        .then(checkStatus)
        .then((response) => response.text())
        .then((text) => text.split('\n'))
        .then(unpack)
    }
  }

  return Policy
}
