library(ggplot2)
d <- read.csv('layers.csv')

ggplot(subset(d, board_size == 2 & max_exponent == 5 & layer_sum > 0), aes(layer_sum, num_states)) + scale_y_continuous(trans='log10') +  geom_point()

ggplot(subset(d, board_size == 3 & max_exponent == 10 & layer_sum > 0), aes(layer_sum, num_states)) + scale_y_continuous(trans='log10') +  geom_point()

ggplot(subset(d, board_size == 4 & max_exponent == 11 & layer_sum > 0), aes(layer_sum, num_states)) + scale_y_continuous(trans='log10') +  geom_point()

ggplot(
  subset(
    d,
    (
      (board_size == 2 & max_exponent == 5) |
      (board_size == 3 & max_exponent == 10) |
      (board_size == 4 & max_exponent == 11)
    ) & layer_sum > 0),
  aes(x = layer_sum, y = num_states, color = board_size)) +
  geom_point() + 
  scale_y_continuous(trans='log10')
