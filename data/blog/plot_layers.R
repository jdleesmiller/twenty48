library(ggplot2)

d <- read.csv('layers.csv')

ggplot(
  subset(d, board_size == 2 & max_exponent == 5),
  aes(layer_sum, num_states)) +
  geom_step()

ggplot(
  subset(d, board_size == 3 & max_exponent == 10),
  aes(layer_sum, num_states + 1)) +
  scale_y_continuous(trans='log10') +
  geom_step()

ggplot(
  subset(d, board_size == 4 & max_exponent == 11),
  aes(layer_sum, num_states + 1)) +
  scale_y_continuous(trans='log10') +
  geom_step()

png('layers_summary.png', width = 8, height = 4, units = 'in', res = 2*72)
ggplot(
  subset(
    d,
    (
      (board_size == 2 & max_exponent == 11) |
      (board_size == 3 & max_exponent == 11) |
      (board_size == 4 & max_exponent == 11)
    )),
  aes(x = layer_sum, y = num_states, color = factor(board_size))) +
  geom_point(shape = '.') +
  scale_color_discrete(name = 'Board Size') +
  scale_x_continuous(
    breaks = 2048 * seq(1, 8)) +
  scale_y_continuous(
    trans = 'log10',
    labels = function (n) format(n, scientific = FALSE, big.mark = ','),
    breaks = 10 ** seq(3, 15, by = 3),
    minor_breaks = 10 ** seq(1, 16)) +
  xlab('Sum of Tiles in State') +
  ylab('Number of States (log scale)')
dev.off()

#
# Alternative view: log-log plot that compresses the upper end of the scale.
#

ggplot(
  subset(
    d,
    (
      (board_size == 2 & max_exponent == 11) |
      (board_size == 3 & max_exponent == 11) |
      (board_size == 4 & max_exponent == 11)
    )),
  aes(x = layer_sum, y = num_states, color = factor(board_size))) +
  geom_point(shape = 'o') +
  scale_color_discrete(name = 'Board Size') +
  scale_x_continuous(
    trans = 'log2',
    breaks = 2 ** seq(1, 14, by = 2)) +
  scale_y_continuous(
    trans = 'log10',
    labels = function (n) format(n, scientific = FALSE, big.mark = ','),
    breaks = 10 ** seq(3, 15, by = 3),
    minor_breaks = 10 ** seq(1, 16)) +
  xlab('Sum of Tiles in State (log scale)') +
  ylab('Number of States (log scale)')

#
# Peak values.
#

format(
  max(subset(d, board_size == 2)$num_states),
  scientific = FALSE, big.mark = ',')
format(
  max(subset(d, board_size == 3)$num_states),
  scientific = FALSE, big.mark = ',')
format(
  max(subset(d, board_size == 4)$num_states),
  scientific = FALSE, big.mark = ',')

#
# Truncation: if there are two consecutive zeros, we cannot play beyond the
# last sum before those two consecutive zeros. To do so, we'd need to add 6
# to the sum in a single move, which is not possible.
#

findFirstZeroPair <- function (xs) {
  i <- 1:(length(xs) - 1)
  which.max(xs[i] == 0 & xs[i + 1] == 0) - 1
}
stopifnot(findFirstZeroPair(c(1, 0, 0)) == 1)
stopifnot(findFirstZeroPair(c(1, 2, 0, 0)) == 2)
stopifnot(findFirstZeroPair(c(1, 0, 1, 0, 0)) == 3)
stopifnot(findFirstZeroPair(c(1, 0, 1, 0, 0, 0)) == 3)
stopifnot(findFirstZeroPair(c(1, 0, 1, 0, 0, 1, 0, 0)) == 3)

maxSum2 <- with(
  subset(d, board_size == 2 & max_exponent == 11),
  layer_sum[findFirstZeroPair(num_states)]
)
maxSum2

maxSum3 <- with(
  subset(d, board_size == 3 & max_exponent == 11),
  layer_sum[findFirstZeroPair(num_states)]
)
maxSum3

maxSum4 <- with(
  subset(d, board_size == 4 & max_exponent == 11),
  layer_sum[findFirstZeroPair(num_states)]
)
maxSum4

#
# Plot the truncated layer dataset.
#

dTruncated <- read.csv('layers_truncated.csv')
ggplot(
  subset(
    dTruncated,
    (
      (board_size == 2 & max_exponent == 11) |
      (board_size == 3 & max_exponent == 11) |
      (board_size == 4 & max_exponent == 11)
    )),
  aes(x = layer_sum, y = num_states, color = factor(board_size))) +
  geom_point(shape = '.') +
  scale_color_discrete(name = 'Board Size') +
  scale_x_continuous(
    breaks = 2048 * seq(1, 8)) +
  scale_y_continuous(
    trans = 'log10',
    labels = function (n) format(n, scientific = FALSE, big.mark = ','),
    breaks = 10 ** seq(3, 15, by = 3),
    minor_breaks = 10 ** seq(1, 16)) +
  xlab('Sum of Tiles in State') +
  ylab('Number of States (log scale)')

#
# And let's see it in log-log.
#

ggplot(
  subset(
    dTruncated,
    (
      (board_size == 2 & max_exponent == 11) |
      (board_size == 3 & max_exponent == 11) |
      (board_size == 4 & max_exponent == 11)
    )),
  aes(x = layer_sum, y = num_states, color = factor(board_size))) +
  geom_point(shape = 'o') +
  scale_color_discrete(name = 'Board Size') +
  scale_x_continuous(
    trans = 'log2',
    breaks = 2 ** seq(1, 14, by = 2)) +
  scale_y_continuous(
    trans = 'log10',
    labels = function (n) format(n, scientific = FALSE, big.mark = ','),
    breaks = 10 ** seq(3, 15, by = 3),
    minor_breaks = 10 ** seq(1, 16)) +
  xlab('Sum of Tiles in State (log scale)') +
  ylab('Number of States (log scale)')
