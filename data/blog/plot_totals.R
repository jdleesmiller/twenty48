library(ggplot2)

dBasicTotal <- transform(
  read.csv('layers_basic_total.csv'),
  estimate = 'basic'
)

dCombinatorialTotal <- transform(
  read.csv('layers_total.csv'),
  estimate = 'combinatorial'
)

dTruncatedTotal <- transform(
  read.csv('layers_truncated_total.csv'),
  estimate = 'truncated'
)

dReachable <- transform(
  read.csv('reachable.csv'),
  estimate = 'reachable'
)

dTotals <- rbind(dBasicTotal, dCombinatorialTotal, dTruncatedTotal, dReachable)

ggplot(
  transform(
    dTotals,
    board_size_factor = factor(
    board_size,
    levels = c(2, 3, 4),
    labels = c('2x2', '3x3', '4x4'))),
  aes(
    x = 2**max_exponent,
    y = total_states,
    color = board_size_factor,
    linetype = estimate)) +
  geom_step() +
  facet_grid(board_size_factor ~ ., scales = 'free_y') +
  scale_x_continuous(
    trans = 'log2',
    breaks = 2 ** seq(1, 11, by = 2)) +
  scale_y_continuous(
    trans = 'log10',
    labels = function (n) format(n, scientific = FALSE, big.mark = ','))
