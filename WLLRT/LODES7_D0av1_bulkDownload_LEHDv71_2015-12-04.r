# Program: LODES7_D0av1_bulkDownload_LEHDv71_2015-12-04.r
# Download and Unzip all LODES7 Files
# Final folder size - 655 GB; 122,739 files, 204 Folders
# https://github.com/npr99/LEHD_LODES7_bulkDownload/blob/master/LEHDv7.md
# R

# Unzip Utility
library(R.utils) 

# cpath <- "C:/Temp/wget/lehd.ces.census.gov/onthemap/LODES7/"
cpath<- "L:/LODES7_D0av1_bulkDownload_LEHDv71_2015-12-04/"
setwd(cpath)

# What year do you want to download? e.g. _2013
# use _20 to download all years
year <- "_20"
# need a list of states with abbreviated state names (US postal abbrev.
# state name = STUSAB)
if (!file.exists("state.txt")){
  download.file("http://web.archive.org/web/20141125122851/http://www.census.gov/geo/reference/docs/state.txt", destfile = "state.txt")
} else { 
  states <- read.table("state.txt", sep = "|", header = T, colClasses = "character")
  states <- states[order(as.numeric(states$STATE)), ]
  states.keep <- states[-c(52:57),]
  nstates <- dim(states.keep)[1]
}
for (i in 1:51) {
  stusab <- tolower(states.keep[i, 2])
  fname <- paste0("lodes_", stusab)
  # md5sum new name for LODES7.1 - possible to compare to old file
  mname <- paste0(fname, "_7_1.md5sum")
  fname <- paste0(fname, ".md5sum")      # Contains list of all files
  xname <- paste0(stusab, "_xwalk.csv.gz") # Geography crosswalk file
  npath <- paste0(cpath, stusab)
  opath <- paste0(npath, "/od")
  rpath <- paste0(npath, "/rac")
  wpath <- paste0(npath, "/wac")
  if (!file.exists(npath)) {dir.create(npath)}
  if (!file.exists(opath)) {dir.create(opath)}
  if (!file.exists(rpath)) {dir.create(rpath)}
  if (!file.exists(wpath)) {dir.create(wpath)}
  url <- paste0("http://lehd.ces.census.gov/data/lodes/LODES7/", stusab)
  url <- paste0(url, "/")
  ourl <- paste0(url, "od/")
  rurl <- paste0(url, "rac/")
  wurl <- paste0(url, "wac/")
  setwd(npath)
  
   # Download and unzip the Geography crosswalk file
  dfile <- paste0(url, xname)
  if (!file.exists(xname)){download.file(dfile, destfile = xname)}
  gunzip(xname,skip=TRUE,overwrite=FALSE, remove=FALSE)
  
  # Download the md5sum file - list of all files in the folders
  dfile <- paste0(url, fname)
  if (!file.exists(mname)){download.file(dfile, destfile = mname)}
  md5sum71 <- read.table(mname, sep = " ", header = F, colClasses = "character")
  md5sum71 <- md5sum71[, -c(2)]
  nobs <- dim(md5sum71)[1]
  
  for (n in 1:nobs) {
    target <- md5sum71[n, 2]
    if ((length(grep("_od_", target)) > 0)&(length(grep(year, target)) > 0)) {
      setwd(opath)
      oname <- paste0(target, ".gz")
      ofile <- paste0(ourl, oname)
      if (file.exists(target)){
        message("Unzipped File already exists: ",target)
      } else {
        download.file(ofile, destfile = oname)
        gunzip(oname,skip=TRUE,overwrite=FALSE, remove=FALSE) 
      }
    } else if ((length(grep("_rac_", target)) > 0)&(length(grep(year, target)) > 0)) {
      setwd(rpath)
      rname <- paste0(target, ".gz")
      rfile <- paste0(rurl, rname)
      if (file.exists(target)){
        message("Unzipped File already exists: ",target)
      } else {
         download.file(rfile, destfile = rname)
         gunzip(rname,skip=TRUE,overwrite=FALSE, remove=FALSE)
      }
    } else if ((length(grep("_wac_", target)) > 0)&(length(grep(year, target)) > 0)) {
      setwd(wpath)
      wname <- paste0(target, ".gz")
      wfile <- paste0(wurl, wname)
      if (file.exists(target)){
        message("Unzipped File already exists: ",target)
      } else {
        download.file(wfile, destfile = wname)
        gunzip(wname,skip=TRUE,overwrite=FALSE, remove=FALSE)
      }
    } 
  }
}
