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

# want: probability of reaching the given sum x exactly in units of 2 or 4 in
# n moves: f((x - n)/2, n/2, p) for f = dbinom
# we reach x in n moves if we have x - n successes, where a success is a 4

# mixture = max_exponent, num_moves, sum, probability
makeBinomialMixture <- function () {
  p <- 0.1
  indices <- with(sumProbabilities, list(max_exponent, state_sum))
  do.call(rbind, by(sumProbabilities, indices, function (part) {
    maxExponent <- part$max_exponent[1]
    stateSum <- part$state_sum[1]
    maxMoves <- stateSum / 2
    minMoves <- ceiling(maxMoves / 2)
    # print(paste(minMoves, maxMoves))
    # 1024 in 1024 moves -> 1024 moves, 0 successes
    # 1024 in 1023 moves -> 1023 moves, 1 success
    # ...
    # 1024 in 512 moves -> 512 moves, 512 successes
    #
    # 1033 in 1033 moves -> 0 successes
    # 1033 in 1032 moves -> 1 success
    # ...
    # 1033 in 517 moves -> 516 successes
    #
    # hit 2066 in say 950 moves
    # means we need (2066-2*950) = 166 in extras, so 83 4s.
    # 1033-950 = 83
    #
    # or 949 moves -> 1898 in 2s; and 83 4s gets you to 2064, then one more 4
    # gets you over 2066. However... doesn't it mean that you get to 2068? There
    # is another group for that.
    #
    # 1033 - 950 = 83 successes in 949 moves -> 866 failures
    # (n C x-n) p^(x-n) q^n + (n-1 C x-n) p^(x-n) q^(n-1) p
    #
    n <- seq(minMoves, maxMoves)
    data.frame(
      max_exponent = maxExponent,
      state_sum = stateSum,
      moves = n,
      probability = dbinom(maxMoves - n, n, p) +
        dbinom(maxMoves - n, n - 1, p) * p
    )
  }))
}
binomialMixture <- makeBinomialMixture()

weightedMixture <- transform(
  merge(
    binomialMixture, sumProbabilities,
    by = c('max_exponent', 'state_sum'),
    suffixes = c('_binomial', '_sum')),
  density = probability_binomial * probability_sum
)
head(weightedMixture)

plotMixture <- function (maxExponent) {
  ggplot(
    subset(weightedMixture, max_exponent == maxExponent & density > 1e-6),
    aes(y = density)) +
    geom_bar(
      aes(x = moves),
      data = subset(movesHistogram, max_exponent == maxExponent),
      stat = 'identity') +
    geom_area(
      aes(x = moves - 2, color = factor(state_sum), fill = factor(state_sum)),
      position = 'stack', alpha = 0.5)
}
plotMixture(11)

# Check mixture stats

mixtureMeanVariance <- local({
  mixture <- aggregate(density ~ moves + max_exponent, weightedMixture, sum)
  mixtureMean <-
    aggregate(density * moves ~ max_exponent, mixture, sum)
  names(mixtureMean) <- c('max_exponent', 'moves_mean')
  mixtureVariance <- aggregate(
    density * (moves - moves_mean)^2 ~ max_exponent,
    merge(mixture, mixtureMean, by = 'max_exponent'),
    sum
  )
  names(mixtureVariance) <- c('max_exponent', 'moves_variance')
  merge(mixtureMean, mixtureVariance)
})
mixtureMeanVariance

# mixture = max_exponent, num_moves, sum, probability
makeBinomialMixture2 <- function () {
  p <- 0.1
  # idea: compute binomials for fixed numbers of moves, then sum them up
  maxExponent <- 4
  maxMoves <- 2**(maxExponent)
  numMoves <- seq(0, maxMoves)
  params <- subset(
    data.frame(
      successes = numMoves,
      num_moves = rep(numMoves, each = maxMoves)
    ),
    successes < num_moves)
  result <- aggregate(
    density ~ max_exponent + state_sum + num_moves,
    transform(params,
      density = dbinom(successes, num_moves, p),
      max_exponent = maxExponent,
      state_sum = 2 * num_moves + 2 * successes),
    sum)
  result[with(result, order(max_exponent, state_sum, num_moves)),]
}
binomialMixture2 <- makeBinomialMixture2()
head(binomialMixture2)

ggplot(
  aggregate(
    density ~ max_exponent + state_sum,
    binomialMixture2,
    sum
  ),
  aes(state_sum, density)) + geom_line()

ggplot(
  aggregate(
    density ~ max_exponent + num_moves,
    binomialMixture2,
    sum
  ),
  aes(num_moves, density)) + geom_line()

# Still not getting all the mass...
# I think the reason is that there's always a chance that you miss the number.
# To hit it, you need to be on state n-2 and get a 2 (probability 0.9), or
# you need to be on state n-4 and get a 4 (probability 0.1).
# The absorption probabilities from the Markov chain should already have this
# effect built in. But there's still no way to recover the mass.

weightedMixture2 <- transform(
  merge(
    binomialMixture2,
    subset(sumProbabilities, max_exponent == 11),
    by = c('max_exponent', 'state_sum')
  ),
  joint_density = density * probability
)

ggplot(subset(aggregate(
  density ~ state_sum,
  binomialMixture2,
  sum), density > 1e-6),
  aes(state_sum, density)) + geom_line()

ggplot(
  subset(weightedMixture2, joint_density > 1e-6),
  aes(num_moves, joint_density * 1.1)) +
  geom_bar(
    aes(x = moves, y = density),
    data = subset(movesHistogram, max_exponent == 11),
    stat = 'identity') +
  geom_area(
    aes(x = num_moves - 2, color = factor(state_sum), fill = factor(state_sum)),
    position = 'stack', alpha = 0.5)


    # mixture = max_exponent, num_moves, sum, probability

makeBinomialMixture3 <- function () {
  p <- 0.1
  maxExponent <- 11
  stateSums <- subset(sumProbabilities, max_exponent == maxExponent)$state_sum
  do.call(rbind, lapply(stateSums, function (stateSum) {
    maxMoves <- stateSum / 2
    minMoves <- ceiling(maxMoves / 2)
    numMoves <- seq(minMoves, maxMoves)
    data.frame(
      max_exponent = maxExponent,
      num_moves = numMoves,
      state_sum = stateSum,
      density = dbinom(stateSum / 2 - numMoves, numMoves, p)
    )
  }))
}
binomialMixture3 <- makeBinomialMixture3()
head(binomialMixture3)

weightedMixture3 <- transform(
  merge(
    binomialMixture3,
    subset(sumProbabilities, max_exponent == 11),
    by = c('max_exponent', 'state_sum')
  ),
  joint_density = density * probability
)

ggplot(
  subset(weightedMixture3, joint_density > 1e-6),
  aes(num_moves, joint_density * 1.1)) +
  geom_bar(
    aes(x = moves, y = density),
    data = subset(movesHistogram, max_exponent == 11),
    stat = 'identity') +
  geom_area(
    aes(x = num_moves - 2, color = factor(state_sum), fill = factor(state_sum)),
    position = 'stack', alpha = 0.5)
