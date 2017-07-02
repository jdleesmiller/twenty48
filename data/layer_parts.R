library(stringr)
library(jsonlite)

readPartSizes <- function(dir) {
  PART_INFO_NAME_RX <- 'sum-(\\d+)[.]max_value-(\\d)[.]json'
  infoFiles <- list.files(dir, '*.json')
  stopifnot(length(infoFiles) > 0)

  info <- str_match(infoFiles, PART_INFO_NAME_RX)
  stopifnot(length(infoFiles) == nrow(info))

  colnames(info) <- c('file', 'sum', 'max_value')
  info <- transform(
    info,
    sum = as.numeric(as.character(sum)),
    max_value = as.numeric(as.character(max_value)))

  info$num_states <- sapply(info$file, function (file) {
    fromJSON(file.path(dir, file))$num_states
  })

  info
}
