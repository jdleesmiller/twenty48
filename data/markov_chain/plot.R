library(ggplot2)

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
  error_variance = moves_variance - variance_steps)

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
    geom_bar(stat = 'identity') +
    geom_vline(xintercept = expectedMean, color = 'blue') +
    geom_vline(xintercept = empiricalMean, color = 'red', linetype = 'dotted')
}
plotMovesHistogram(11)

#
# Binomial mixture idea. First, we need win states and weights.
#

parseState <- function (state) {
  values <- strsplit(as.character(state), '\\D+')[[1]]
  values <- values[2:length(values)]
  as.numeric(values)
}
parseState('[2, 2, 16, 16, 2048]')

absorbingProbabilities <- transform(
  read.csv('absorbing_probabilities.csv'),
  state_sum = sapply(state, function (s) sum(parseState(s)))
)

sumProbabilities <- aggregate(
  probability ~ max_exponent + state_sum,
  absorbingProbabilities, sum
)
sumProbabilities

# check that probabilities sum to 1
aggregate(probability ~ max_exponent, sumProbabilities, sum)

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
    stateSums <- subset(sumProbabilities, max_exponent == maxExponent)$state_sum
    do.call(rbind, lapply(stateSums, function (stateSum) {
      maxMoves <- stateSum / 2
      minMoves <- ceiling(maxMoves / 2)
      numMoves <- seq(minMoves, maxMoves)
      data.frame(
        max_exponent = maxExponent,
        num_moves = numMoves,
        state_sum = stateSum,
        probability = dbinom(stateSum / 2 - numMoves, numMoves, p)
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
  probability ~ max_exponent + state_sum,
  binomialJoint,
  sum)

binomialMoveGivenSum <- transform(
  merge(binomialJoint, binomialStateSumMargin,
    by = c('max_exponent', 'state_sum'),
    suffixes = c('_joint', '_state_sum_margin')),
  probability_moves_given_sum = probability_joint / probability_state_sum_margin
)[, c('max_exponent', 'state_sum', 'num_moves', 'probability_moves_given_sum')]
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
    by = c('max_exponent', 'state_sum')),
  density = probability_moves_given_sum * probability
)[, c('max_exponent', 'state_sum', 'num_moves', 'density')]
head(weightedMixture)

local({
  maxExponent <- 3
  ggplot(
    subset(weightedMixture, max_exponent == maxExponent & density > 1e-6),
    aes(num_moves, density)) +
    geom_bar(
      aes(x = moves),
      data = subset(movesHistogram, max_exponent == maxExponent),
      stat = 'identity') +
    geom_area(
      aes(x = num_moves - 2,
        color = factor(state_sum),
        fill = factor(state_sum)),
      position = 'stack', alpha = 0.5)
})
