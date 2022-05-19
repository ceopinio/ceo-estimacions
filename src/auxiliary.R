## Eliminate accents and punctuation so that they can be used as
## regular R factors
get_model <- function(location, basename) {
  mfit <- readRDS(file.path(location, paste0(basename, ".RDS")))
  m <- xgb.load(file.path(location, paste0(basename, ".xgb")))
  mfit$finalModel$handle <- m$handle
  mfit$finalModel$raw <- m$raw
  return(mfit)
}
