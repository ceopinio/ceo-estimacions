DTA_FOLDER <- "../dta"
RAW_DTA_FOLDER <- file.path(DTA_FOLDER, "raw-dta")
IMG_FOLDER <- "../img"
TXT_FOLDER <- "../txt"


assetize <- function(x) {
  return(file.path(DTA_FOLDER, x))
}
