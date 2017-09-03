library(ggplot2)
library(jsonlite)
library(Matrix)

# Center plot titles.
theme_update(plot.title = element_text(hjust = 0.5))

movesHistogram <- read.csv('moves_histogram.csv')

numTrials <- aggregate(frequency ~ max_exponent, movesHistogram, sum)
names(numTrials) <- c('max_exponent', 'num_trials')

movesHistogram <- transform(
  merge(movesHistogram, numTrials, by = 'max_exponent', sort = TRUE),
  density = frequency / num_trials)

# Calculate the empirical mean and variance
movesMeanVariance <- local({
  movesMean <-
    aggregate(density * moves ~ max_exponent, movesHistogram, sum)
  names(movesMean) <- c('max_exponent', 'moves_mean')
  movesVariance <- aggregate(
    density * (moves - moves_mean)^2 ~ max_exponent,
    merge(movesHistogram, movesMean, by = 'max_exponent', sort = TRUE),
    sum
  )
  names(movesVariance) <- c('max_exponent', 'moves_variance')
  merge(movesMean, movesVariance, sort = TRUE)
})
movesMeanVariance

# Check against the calculated mean and variance.
# As expected, there is one extra step in the simulation results, because of
# the move from pre-start state to start state.
expectedSteps <- read.csv('expected_steps.csv')
expectedStepsFromStart <- subset(expectedSteps, state == '[]')

transform(
  merge(movesMeanVariance, expectedStepsFromStart),
  error_mean = moves_mean - expected_steps,
  error_variance = moves_variance - variance_steps,
  stdev_steps = sqrt(variance_steps))

#
# Summary: not all that easy to read.
#

ggplot(
  movesHistogram,
  aes(moves, density)) +
  geom_bar(aes(color = factor(max_exponent)), stat = 'identity')

#
# Just the game to 2048.
#

plotMovesHistogram <- function (maxExponent) {
  expectedMean <- subset(
    expectedStepsFromStart, max_exponent == maxExponent)$expected_steps - 1
  empiricalMean <- subset(
    movesMeanVariance, max_exponent == maxExponent)$moves_mean
  ggplot(
    subset(movesHistogram, max_exponent == maxExponent),
    aes(moves, density)) +
    geom_bar(stat = 'identity', width = 1) +
    geom_vline(xintercept = expectedMean, color = 'blue') +
    # geom_vline(xintercept = empiricalMean, color = 'red', linetype = 'dotted') +
    xlab('Moves to Win') +
    ylab('Probability') +
    ggtitle('Histogram of Minimum Moves to Win from the Markov Chain')
}
plotMovesHistogram(11)

svg('markov_chain_moves_histogram.svg', width=8, height=5)
plotMovesHistogram(11)
dev.off()

#
# Binomial mixture idea. First, we need win states and weights.
#

parseState <- function (state) {
  values <- strsplit(as.character(state), '\\D+')[[1]]
  values <- values[2:length(values)]
  as.numeric(values)
}
parseState('[2, 2, 16, 16, 2048]')

# For sorting states in numeric order, treat the log2 tile values as a base-12
# integer.
stateToNumber <- function (tiles) {
  sum(log2(tiles) * 12 ** seq(from = 1, to = length(tiles)))
}
stateToNumber(parseState('[2]'))
stateToNumber(parseState('[2, 2]'))
stateToNumber(parseState('[2, 2, 16, 16, 2048]'))

zeroPadState <- function (tiles) {
  c(rep(0, times = 16 - length(tiles)), tiles)
}
zeroPadState(parseState('[2, 2, 16, 16, 2048]'))

toSetNotation <- function (states) {
  sub('\\[', '{', sub('\\]', '}', states))
}
toSetNotation(c('[2]', '[2, 2]'))

bindStateInfo <- function (frame) {
  transform(
    frame,
    max_value = sapply(as.character(state), function (s) {
      values <- as.numeric(fromJSON(s))
      if (length(values) > 0) {
        max(values)
      } else {
        0
      }
    }),
    value_sum = sapply(as.character(state), function (s) {
      sum(as.numeric(fromJSON(s)))
    }),
    num_tiles = sapply(as.character(state), function (s) {
      length(as.numeric(fromJSON(s)))
    })
  )
}

absorbingProbabilities <- bindStateInfo(
  read.csv('absorbing_probabilities.csv'))

sumProbabilities <- aggregate(
  probability ~ max_exponent + value_sum,
  absorbingProbabilities, sum
)
sumProbabilities

# check that probabilities sum to 1
aggregate(probability ~ max_exponent, sumProbabilities, sum)

plotAbsorbingProbabilities <- function () {
  ap <- subset(absorbingProbabilities,
    max_exponent == 11 & probability > 1e-3)
  orderedStates <- with(ap,
    state[order(value_sum,
      sapply(lapply(lapply(state, parseState), zeroPadState), stateToNumber))])
  ap <- transform(ap,
    state = factor(state, orderedStates, toSetNotation(orderedStates),
      ordered = TRUE)
  )
  ggplot(ap, aes(x = state, y = probability)) +
    geom_bar(aes(fill = factor(value_sum, ordered = TRUE)), stat = 'identity') +
    scale_fill_discrete(guide = guide_legend(title = 'Sum of Tiles')) +
    theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5)) +
    xlab('Absorbing State') +
    ylab('Absorbing Probability') +
    ggtitle('Absorbing Probabilities for the Markov Chain')
}
plotAbsorbingProbabilities()

svg('markov_chain_absorbing_probabilities.svg', width=8, height=5)
plotAbsorbingProbabilities()
dev.off()

plotSumProbabilities <- function () {
  sumData <- transform(
    subset(sumProbabilities, max_exponent == 11 & value_sum < 2080),
    value_sum = factor(value_sum, ordered = TRUE)
  )
  ggplot(
    sumData,
    aes(x = value_sum, y = probability)) +
    geom_bar(aes(fill = value_sum), stat = 'identity') +
    scale_fill_discrete(guide = FALSE) +
    xlab('Sum of Tiles at Absorption (Win)') +
    ylab('Total Absorbing Probability') +
    ggtitle('Total Absorbing Probabilities by Sum of Tiles')
}
plotSumProbabilities()

svg('markov_chain_sum_probabilities.svg', width=8, height=5)
plotSumProbabilities()
dev.off()

#
# Create the joint distribution of the number of moves and the sum of the values
# after that number of moves. This is binomial:
#
# P(M = m, S = s) = B(s / 2 - m, m, p)
#
# Since, in m moves, we accumulate 2m for sure, plus 2 for each success (i.e.
# we get a 4). That is, the sum is 2m + 2k, so if k = s/2 - m, the sum is
# 2m + s - 2m = s.
#
makeBinomialJoint <- function () {
  p <- 0.1
  do.call(rbind, lapply(3:11, function (maxExponent) {
    valueSums <- subset(sumProbabilities, max_exponent == maxExponent)$value_sum
    do.call(rbind, lapply(valueSums, function (valueSum) {
      maxMoves <- valueSum / 2
      minMoves <- ceiling(maxMoves / 2)
      numMoves <- seq(minMoves, maxMoves)
      data.frame(
        max_exponent = maxExponent,
        num_moves = numMoves,
        value_sum = valueSum,
        probability = dbinom(valueSum / 2 - numMoves, numMoves, p)
      )
    }))
  }))
}
binomialJoint <- makeBinomialJoint()
head(binomialJoint)

#
# We want P(M = m | S = s), which we can find from the joint distribution and
# the marginal distribution of S by
#
# P(M = m | S = s) = P(M = m, S = s) / P(S = s)
#

binomialStateSumMargin <- aggregate(
  probability ~ max_exponent + value_sum,
  binomialJoint,
  sum)

binomialMoveGivenSum <- transform(
  merge(binomialJoint, binomialStateSumMargin,
    by = c('max_exponent', 'value_sum'),
    suffixes = c('_joint', '_state_sum_margin')),
  probability_moves_given_sum = probability_joint / probability_state_sum_margin
)[, c('max_exponent', 'value_sum', 'num_moves', 'probability_moves_given_sum')]
head(binomialMoveGivenSum)

#
# Finally, if we let W be the event that we've won, we have P(S = s | W) from
# the absorption probabilities of the Markov chain.
#
# Want P(M = m, S = s | W) = P(M = m | S = s, W) * P(S = s | W)
# P(MS|W) = P(M|SW)P(S|W)
# P(M|SW) = P(M|S) because M and W are conditionally independent given S.
#
# Is an absorbing probability P(S|W)? We know we are going to be absorbed, so
# it's just a question of which state. We've then aggregated up by sum, so I
# think yes, P(S|W) is an absorbing probability.

weightedMixture <- transform(
  merge(
    binomialMoveGivenSum, sumProbabilities,
    by = c('max_exponent', 'value_sum')),
  density = probability_moves_given_sum * probability
)[, c('max_exponent', 'value_sum', 'num_moves', 'density')]
head(weightedMixture)

plotWeightedMixture <- function () {
  maxExponent <- 11
  ggplot(
    subset(weightedMixture, max_exponent == maxExponent & density > 1e-5),
    aes(num_moves, density)) +
    geom_bar(
      aes(x = moves),
      data = subset(movesHistogram, max_exponent == maxExponent),
      stat = 'identity', width = 1) +
    geom_area(
      aes(x = num_moves - 2,
        color = factor(value_sum),
        fill = factor(value_sum)),
      position = 'stack', alpha = 0.5) +
    scale_color_discrete(guide = guide_legend(title = 'Sum of Tiles')) +
    scale_fill_discrete(guide = guide_legend(title = 'Sum of Tiles')) +
    xlab('Moves to Win') +
    ylab('Probability Density') +
    ggtitle('Simulated and Binomial Mixture Model Distributions for Minimum Moves to Win')
}
plotWeightedMixture()

# For conversion to PNG.
# pdf('markov_chain_weighted_mixture.pdf', width=8, height=4.2)
# plotWeightedMixture()
# dev.off()

svg('markov_chain_weighted_mixture.svg', width=8, height=5)
plotWeightedMixture()
dev.off()

#
# Count states
#

states <- bindStateInfo(read.csv('states.csv'))

numStates <- as.data.frame(xtabs( ~ max_exponent, states))
numStates

numStatesByMaxValue <- aggregate(
  count ~ max_exponent + max_value,
  transform(states, count = 1),
  sum)
subset(numStatesByMaxValue, max_exponent == 11)

numStatesByValueSum <- aggregate(
  count ~ max_exponent + value_sum,
  transform(states, count = 1),
  sum)

ggplot(
  subset(numStatesByValueSum, max_exponent == 11),
  aes(x = value_sum, y = count))+
  geom_step()

max(subset(numStatesByValueSum, max_exponent == 11)$value_sum)

numTilesByValueSum <- merge(
  aggregate(num_tiles ~ max_exponent + value_sum, states, min),
  aggregate(num_tiles ~ max_exponent + value_sum, states, max),
  by = c('max_exponent', 'value_sum'),
  suffixes = c('_min', '_max'))

ggplot(
  subset(numTilesByValueSum, max_exponent == 11)) +
  geom_step(aes(x = value_sum, y = num_tiles_min), color = 'red') +
  geom_step(aes(x = value_sum, y = num_tiles_max), color = 'blue')

ggplot(
  subset(numTilesByValueSum, max_exponent == 11)) +
  geom_step(aes(x = value_sum, y = num_tiles_max - num_tiles_min))

#
# Have a look at the canonical matrix and the fundamental matrix
#

canonical <- read.csv('canonical_matrix_sparse_11.csv')
canonicalStates <- read.csv('canonical_matrix_states_11.csv')

canonicalMatrix <- local({
  offset <- 0 # to zoom in on the lower corner
  with(
    subset(canonical, i >= offset & j >= offset),
    sparseMatrix(i - offset, j - offset, x = probability, index1 = FALSE))
})
image(canonicalMatrix)

canonicalP <- nrow(canonicalMatrix)
canonicalQ <- 3461

plotCanonicalMatrix <- function () {
  ggplot(canonical, aes(x = j, y = i)) +
    geom_tile(aes(fill = probability)) +
    scale_fill_gradient(low = 'gray', high = 'black',
      guide = guide_legend(title = 'Probability', reverse = TRUE)) +
    scale_x_continuous(expand = c(0, 0)) +
    scale_y_continuous(trans = 'reverse', expand = c(0, 0)) +
    coord_equal(ratio = 1) +
    xlab('Transition Matrix Column') +
    ylab('Transition Matrix Row') +
    ggtitle('Complete Canonical Matrix for the 2048 Markov Chain')
}
plotCanonicalMatrix()

svg('markov_chain_canonical.svg', width=8, height=5)
plotCanonicalMatrix()
dev.off()

plotLowerRightCanonicalMatrix <- function () {
  cutoff <- 3300
  breaks <- c(cutoff, canonicalQ)
  labelOffset <- 7
  matrixNames <- data.frame(
    i = c(
      cutoff + labelOffset,
      cutoff + labelOffset,
      canonicalQ + labelOffset,
      canonicalQ + labelOffset),
    j = c(
      canonicalQ - labelOffset,
      canonicalP - labelOffset,
      canonicalQ - labelOffset,
      canonicalP - labelOffset),
    label = c('bold(Q)', 'bold(R)', 'bold("0")', 'bold(I)[r]')
  )
  ggplot(
    subset(canonical, i >= cutoff & j >= cutoff),
    aes(x = j, y = i)) +
    geom_tile(aes(fill = factor(format(probability, digits = 2))),
      height = 1, width = 1) +
    scale_fill_discrete(
      guide = guide_legend(title = 'Probability', reverse = TRUE)) +
    scale_x_continuous(breaks = breaks, expand = c(0, 0)) +
    scale_y_continuous(breaks = breaks, expand = c(0, 0), trans = 'reverse') +
    coord_equal(ratio = 1) +
    theme(panel.grid.minor = element_blank()) +
    xlab('Transition Matrix Column') +
    ylab('Transition Matrix Row') +
    ggtitle('Lower Right Corner of the Canonical Matrix') +
    geom_label(aes(label = label), data = matrixNames, parse = TRUE)
}
plotLowerRightCanonicalMatrix()

svg('markov_chain_canonical_lower_right.svg', width=8, height=5)
plotLowerRightCanonicalMatrix()
dev.off()

qMatrix <- canonicalMatrix[1:canonicalQ, 1:canonicalQ]
nMatrix <- solve(diag(canonicalQ) - qMatrix)
image(nMatrix[1:1000, 1:1000])
image(nMatrix[3000:canonicalQ, 3000:canonicalQ])

#
# The first row of the N matrix tells us the probability that we'll ever visit
# a state, which is an interesting way of collapsing the chain. We can see that
# we pass through certain 'key states'.
#

plot(nMatrix[1,])

nStates <- bindStateInfo(merge(
  data.frame(i = 0:(nrow(nMatrix) - 1), probability = nMatrix[1, ]),
  canonicalStates))
row.names(nStates) <- NULL
head(nStates)

transform(
  subset(nStates, probability >= 0.85,
    select = c(state, probability, value_sum)),
  ds = c(NA, diff(value_sum))
)

# maybe look at # of states per layer? probably low for high prob states

#
# Plot my human results
#

humanResults <- subset(
  read.csv('../screenshots/results.csv'),
  !is.na(Moves))

plotHumanResults <- function () {
  steps <- subset(expectedStepsFromStart, max_exponent == 11)
  expectedMean <- steps$expected_steps - 1
  stdDev <- sqrt(steps$variance_steps)
  labels <- data.frame(
    Moves = c(1025,
      expectedMean + 1,
      expectedMean - stdDev + 1,
      expectedMean + stdDev + 1),
    Tile.Sum = c(2070, 2250, 2250, 2250),
    label = c(
      'Minimum Tile Sum: 2066',
      'Minimum Expected Moves: 938.8',
      '-1 Standard Deviation', '+1 Standard Deviation'),
    hjust = c(1, 0, 0, 0),
    vjust = c(0, 0, 0, 0),
    angle = c(0, -90, -90, -90)
  )
  ggplot(humanResults, aes(x = Moves, y = Tile.Sum)) +
    geom_point() +
    geom_vline(xintercept = expectedMean, color = 'blue') +
    geom_vline(xintercept = expectedMean - stdDev, color = 'blue', linetype = 'dashed') +
    geom_vline(xintercept = expectedMean + stdDev, color = 'blue', linetype = 'dashed') +
    geom_hline(yintercept = 2066, color = 'red', linetype = 'dashed') +
    geom_text(aes(label = label, hjust = hjust, vjust = vjust, angle = angle),
      data = labels) +
    xlab('Moves to Win') +
    ylab('Sum of Tiles on the Board at Win') +
    ggtitle('Moves to Win and Tiles on Board for 28 (Human) Games')
}
plotHumanResults()

svg('markov_chain_human.svg', width=8, height=5)
plotHumanResults()
dev.off()
