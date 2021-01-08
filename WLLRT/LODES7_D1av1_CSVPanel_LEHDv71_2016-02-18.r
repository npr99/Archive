# Program: LODES7_D1av1_CSVPanel_LEHDv71_2016-02-18.r
# Combine LODES files into panel format
# https://github.com/npr99/LEHD_LODES7_bulkDownload/blob/master/LEHDv7.md
# R

# installing/loading the package:
if(!require(installr)) {
  install.packages("installr"); require(installr)} #load / install+load installr
updateR()

# I had a really hard time getting these packages to install, probably an issue with
# my permissions on the network. It may be better to have R intalled on my harddrive.
# I found online people with a similar problem and they used the command
# debug(utils:::unpackPkgZip) 
# install.packages("plyr")
# install.packages("dplyr")
# By running the above command the upackPkgZip command ran in debug mode and I was 
# able to step through it line by line
# For what ever reason this seems to have allowed the packages to install correctly
# I also had to make sure that R was updated. Which was ok but I needed to uninstall the old
# version before the RStudio would recognize the newer vesrsion.

# Unzip Utility
library(R.utils) 

library(data.table)

library(plyr)

library(dplyr)

library(sqldf) # Read in a portion of a CSV file

# cpath <- "C:/Temp/wget/lehd.ces.census.gov/onthemap/LODES7/"
# cpath <- "L:/LODES7_D0av1_bulkDownload_LEHDv71_2015-12-04/"
cpath <- "L:/LODES7_D0av1_bulkDownload_LEHDv71_2015-12-04/"
setwd(cpath)

# need a list of states with abbreviated state names (US postal abbrev.
# state name = STUSAB)
if (!file.exists("state.txt")){
  download.file("http://web.archive.org/web/20141125122851/http://www.census.gov/geo/reference/docs/state.txt", destfile = "state.txt")
}
states <- read.table("state.txt", sep = "|", header = T, colClasses = "character")
states <- states[order(as.numeric(states$STATE)), ]
states.keep <- states[-c(52:57),]
nstates <- dim(states.keep)[1]

# For each Job Type 0 - All Jobs to 5 - Federal Primary Jobs
for (t in 0:0) {
  # Creates file type for each job type
  LODESfiletype <- paste0("wac_S000_JT0",t)
# For each state
for (i in 1:1) {
  stusab <- tolower(states.keep[i, 2])
  fname <- paste0(stusab,"_",LODESfiletype)
  # md5sum new name for LODES7.1 - possible to compare to old file
  panelpath <- paste0("L:/LODES7_D1av1_CSVPanel_LEHDv71_2016-02-18/",LODESfiletype)
  panelname <- paste0(panelpath,"/",fname, ".csv")
  if (!file.exists(panelpath)) {dir.create(panelpath)}
  
  npath <- paste0(cpath, stusab)
  opath <- paste0(npath, "/od")
  rpath <- paste0(npath, "/rac")
  wpath <- paste0(npath, "/wac")
  setwd(wpath)
  
  # Collect the names of panel files
  panelpattern = paste0("*\\_",LODESfiletype,"_.*\\.csv$")
  filenames <- list.files(path = ".",pattern = panelpattern)
  
  read_csv_filename <- function(filename){
    # Need to make sure that all CSV columns are read in as characters
    # Without this provision FIPS codes may loose their leading 0
    sampleData <- read.csv(filename, header = TRUE, nrows = 5)
    classes <- rep("character",ncol(sampleData))
    ret <- read.csv(filename, header = TRUE, nrows = 5, colClasses = classes)
    ret$Source <- filename #EDIT
    ret
  }
  
  import.list <- ldply(filenames, read_csv_filename)
  
  # Add year variable
  import.list$year <- substr(import.list$Source,18,21)
  
 
  
  # merge in geography file
  # Set name of geography file
  geoname <- paste0(stusab,"_xwalk.csv")
  setwd(npath)
  # Need to make sure that all CSV columns are read in as characters
  # Without this provision geo codes may loose their leading 0
  sampleData <- read.csv(geoname, header = TRUE, nrows = 5)
  classes <- rep("character",ncol(sampleData))
  geoxwalktData <- read.csv(geoname, header = TRUE, nrows = -1 , colClasses = classes)
  
  # keep specific variables 
  keepvars <- c("tabblk2010", "st", "cty", "trct", "cbsa")
  geoxwalktDatav2 <- geoxwalktData[keepvars]
  # Keep specific observations
  
  ctylist <- c("01001","01005")
  geoxwalktDatav3 <- geoxwalktDatav2[which(geoxwalktDatav2$cty %in% ctylist),]
  
  
  geoxwalktData <- data.frame(ID = sample(rep(letters, each=3)), value = rnorm(n=26*3))
  keep <- c("a", "d", "r", "x")
  
   merge1Data <- merge(x=import.list,y=geoxwalktData, by.x = "w_geocode", by.y = "tabblk2010", all.x = TRUE, all.y = TRUE)
  

   
   # Output panel data to csv
   write.csv2(merge1Data, file = panelname)
}
} 
  
  
# additional steps
# merge in geography file
# Collapse data by scales and year
# add year varaible from substring of file name

}