fileNames <- Sys.glob('data/layer_states/board_size-4.max_exponent-11.max_lose_depth-0.max_win_depth-0/*')
fileSums <- as.numeric(gsub('^.+/(\\d+).bin', '\\1', fileNames))
fileSizes <- file.size(fileNames)

fileData <- transform(
  data.frame(name = fileNames, sum = fileSums, size = fileSizes),
  states = size / 8)
fileData <- transform(
  fileData,
  cumStates = cumsum(states))

with(fileData, plot(sum, states))

with(fileData, plot(sum, cumStates))

with(fileData, plot(sum, log(states)))

with(fileData, plot(sum, log(cumStates)))

# Drop the last point, which is usually still in progress.
fileDataComplete <- fileData[1:(nrow(fileData)-1),]

library(ggplot2)

# Try an affine + square root fit. Seems pretty close.
lmSqrt <- lm(log(states) ~ sum + sqrt(sum), data=fileDataComplete)
summary(lmSqrt)

# Doesn't seem like we have enough data to say much about future growth (when
# extrapolating from sum 126) using this model.
ggplot(
    merge(data.frame(sum = seq(4, 2048, by = 2)),
          fileDataComplete,
          all.x = TRUE),
    aes(x = sum, y = log(states))) +
  geom_line() +
  geom_smooth(method = 'lm', formula = y ~ x + sqrt(x), fullrange = TRUE)

print(sum(fileData$states))

