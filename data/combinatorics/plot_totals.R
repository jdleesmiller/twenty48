library(ggplot2)
library(reshape2)

# Center plot titles.
theme_update(plot.title = element_text(hjust = 0.5))

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

dCanonical <- transform(
  read.csv('canonical.csv'),
  estimate = 'canonical'
)

dTotals <- transform(
  rbind(
    dBasicTotal, dCombinatorialTotal, dTruncatedTotal, dReachable, dCanonical),
  board_size_factor = factor(
    board_size,
    levels = c(2, 3, 4),
    labels = c('2x2', '3x3', '4x4')))

ggplot(
  dTotals,
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

#
# Simpler summary plot for first blog post.
#

svg('combinatorics_totals.svg', width = 8, height = 4)
ggplot(
  transform(
    subset(dTotals, estimate %in% c('combinatorial', 'truncated')),
    estimate_factor = factor(
      estimate,
      levels = c('combinatorial', 'truncated'),
      labels = c('Baseline', 'Layer Reachability'))),
  aes(
    x = 2**max_exponent,
    y = total_states,
    color = board_size_factor,
    linetype = estimate_factor)) +
  geom_step() +
  scale_linetype_discrete(guide = guide_legend(title = 'Method')) +
  scale_color_discrete(guide = guide_legend(title = 'Board Size')) +
  scale_x_continuous(
    trans = 'log2',
    breaks = 2 ** seq(1, 11, by = 2)) +
  scale_y_continuous(
    trans = 'log10',
    labels = function (n) format(n, scientific = FALSE, big.mark = ',')) +
  ggtitle('Number of States by Maximum Tile and Board Size') +
  xlab('Maximum Tile') +
  ylab('Number of States (log scale)')
dev.off()

#
# Plot the ratio of reachable to canonical states for known totals.
#

mTotals <- melt(
  dTotals,
  c('board_size', 'max_exponent', 'estimate'),
  c('total_states'))

dReachableCanonical <- transform(
  dcast(mTotals, board_size + max_exponent ~ estimate),
  reachableToCanonical = reachable / canonical)

ggplot(
  dReachableCanonical,
  aes(max_exponent, reachableToCanonical, color = factor(board_size))
) +
  geom_line()


