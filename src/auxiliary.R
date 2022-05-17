## Eliminate accents and punctuation so that they can be used as
## regular R factors
clean_party_name <- function(x) {
  if (!is.factor(x)) {
    stop("Party variable is expected to be a factor")
  }

  levels(x) <- stri_trans_general(levels(x), "latin-ascii") 
  levels(x) <- stri_replace_all_charclass(levels(x), "[[:punct:]]", "")
  levels(x) <- stri_replace_all_charclass(levels(x), "[[:whitespace:]]", ".")
  return(x)
  
}

#' This function is used to set a parallel socket cluster with
#' information living in pre-defined variables ANSIBLE_INVENTORY,
#' ANSIBLE_LOCALHOST, CLUSTER_LOG, and RSCRIPT_BIN. 
set_cluster <- function() {
  require(doParallel)

  ## Pull IP and ssh from ansible files
  inventory <- read_yaml(ANSIBLE_INVENTORY)
  sshkey <- inventory$droplet$vars$ansible_ssh_private_key_file
  workersips <- names(inventory$droplet$hosts)
  localhostip <- read_yaml(ANSIBLE_LOCALHOST)
  
  ## Cleanup cluster log
  if (file.exists(CLUSTER_LOG)) file.remove(CLUSTER_LOG)
  
  ## Make cluster

  cl <- makePSOCKcluster(names=rep(workersips, 2),
                         master=localhostip,
                         user="root",
                         homogeneous=FALSE,
                         useXDR=FALSE,
                         outfile=CLUSTER_LOG,
                         rscript=RSCRIPT_BIN,
                         rshopts=c("-o", "StrictHostKeyChecking=no",
                                   "-o", "IdentitiesOnly=yes",
                                   "-i", sshkey))
  
  return(cl)
}


get_model <- function(location, basename) {
  mfit <- readRDS(file.path(location, paste0(basename, ".RDS")))
  m <- xgb.load(file.path(location, paste0(basename, ".xgb")))
  mfit$finalModel$handle <- m$handle
  mfit$finalModel$raw <- m$raw
  return(mfit)
}
