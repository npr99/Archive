# Program: LODES7_D1av1_OD_dst_brng_LEHDv71_2016-04-06.r
# Combine LODES files specifically for Origin and Destination 
# Add distance and bearing to OD Pairs
# Combine LODES files into panel format
# https://github.com/npr99/LEHD_LODES7_bulkDownload/blob/master/LEHDv7.md
# R

# Store program name for defining folders
prgnm <- "LODES7_D1av1_OD_dst_brng_LEHDv71_2016-04-06"

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

#install.packages("geosphere")
library(geosphere) # to calculate distance and bearing between OD pairs

# Data Path for LODES Data
c1path <- "L:/LODES7_D0av1_bulkDownload_LEHDv71_2015-12-04/"
setwd(c1path)

# Data Path for Block Centroid Data
c2path <- "L:/LODES7_D0bv1_ObtainBlockCentroids_2016-02-02/"

# need a list of states with abbreviated state names (US postal abbrev.
# state name = STUSAB)
if (!file.exists("state.txt")){
  download.file("http://web.archive.org/web/20141125122851/http://www.census.gov/geo/reference/docs/state.txt", destfile = "state.txt")
}
states <- read.table("state.txt", sep = "|", header = T, colClasses = "character")
states <- states[order(as.numeric(states$STATE)), ]
states.keep <- states[-c(52:57),]
nstates <- dim(states.keep)[1]

# There are three types of LODES data files
## OD - Origin-Destination data, jobs totals are associated with both a home Census Block and a
## work Census Block
## RAC - Residence Area Characteristic data, jobs are totaled by home Census Block
## WAC - Workplace Area Characteristic data, jobs are totaled by work Census Block
datafiletype <- "od"

# There are two parts to the OD file - main or aux
## Complimentary parts of the state file, the main part includes 
## jobs with both workplace and residence in the state and the aux part 
## includes jobs with the workplace in the state and the residence outside of the state.
odpart <- "main"

# There are 10 possible segments of the workforce
# "S000", "SA01", "SA02", "SA03", "SE01", "SE02", "SE03", "SI01", "SI02", or "SI03"
seg <- "S000"


# For each Job Type 0 - All Jobs to 5 - Federal Primary Jobs
for (t in 0:0) {
  # Creates file type for each job type
  JobType <- paste0("JT0",t)
  LODESfiletype <- paste0(datafiletype,"_",odpart,"_",JobType)
}
# For each state
for (i in 44:44) {

  # Store state abbrevation 
  stusab <- tolower(states.keep[i, 2])
  # Store state FIPS Code
  stfips <- tolower(states.keep[i, 1])
  
  fname <- paste0(stusab,"_",LODESfiletype)
  # md5sum new name for LODES7.1 - possible to compare to old file
  
  # Set directory for panel output
  panelpath <- paste0("L:/",prgnm,"/",LODESfiletype)
  panelname <- paste0(panelpath,"/",fname, ".csv")
  if (!file.exists(panelpath)) {dir.create(panelpath)}
  
  npath <- paste0(c1path, stusab)
  opath <- paste0(npath, "/od")
  rpath <- paste0(npath, "/rac")
  wpath <- paste0(npath, "/wac")
  

  # Create Data Frame with geography file
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
  
  #keep if in county list
  # Make a list of unique states and counties
  geoctylist <- c("48041")
  geoxwalktDatav3 <- geoxwalktDatav2[which(geoxwalktDatav2$cty %in% geoctylist),]
  
  # Create Data Frame with block centroids
  setwd(c2path)
  centroidname <- paste0("tl_2010_",stfips,"_tabblock10.csv")
  # Need to make sure that all CSV columns are read in as characters
  # Without this provision geo codes may loose their leading 0
  sampleData <- read.csv(centroidname, header = TRUE, sep = ";", nrows = 5)
  classes <- rep("character",ncol(sampleData))
  centroidData <- read.csv(centroidname, header = TRUE, nrows = -1 , sep = ";", colClasses = classes)
  centroidData$cty <- paste0(centroidData$STATEFP10,centroidData$COUNTYFP10)
  # keep specific variables 
  keepvars <- c("GEOID10","INTPTLAT10","INTPTLON10")
  centroidDatav2 <- centroidData[keepvars]
  # Convert Lat and Lon to Numeric
  centroidDatav2$INTPTLAT10 <- as.numeric(centroidDatav2$INTPTLAT10,length(16))
  centroidDatav2$INTPTLON10 <- as.numeric(centroidDatav2$INTPTLON10,length(16))
  
  # Collect the names of panel files
  # From Worker Characteristics Files for State
  setwd(opath)
  
  panelpattern = paste0("*\\_",LODESfiletype,"_2010.*\\.csv$")
  filenames <- list.files(path = ".",pattern = panelpattern)
  
  read_csv_filename <- function(filename){
    # Need to make sure that all CSV columns are read in as characters
    # Without this provision FIPS codes may loose their leading 0
    sampleData <- read.csv(filename, header = TRUE, nrows = 5)
    classes <- rep("character",ncol(sampleData))
    ret1 <- read.csv(filename, header = TRUE, nrows = -1, colClasses = classes)
    
    #merge data with extracted geography crosswalk for home and work blocks
    # Home First Block GEO Crosswalk
    ret2 <- merge(x=ret1,y=geoxwalktDatav3, by.x = "h_geocode", by.y = "tabblk2010")
    # rename "st", "cty", "trct", "cbsa" variables
    names(ret2)[names(ret2)=="st"] <- "h_st"
    names(ret2)[names(ret2)=="cty"] <- "h_cty"
    names(ret2)[names(ret2)=="trct"] <- "h_trct"
    names(ret2)[names(ret2)=="cbsa"] <- "h_cbsa"
 
    # Work Second Block GEO Crosswalk
    ret3 <- merge(x=ret2,y=geoxwalktDatav3, by.x = "w_geocode", by.y = "tabblk2010")
    # rename "st", "cty", "trct", "cbsa" variables
    names(ret3)[names(ret3)=="st"] <- "w_st"
    names(ret3)[names(ret3)=="cty"] <- "w_cty"
    names(ret3)[names(ret3)=="trct"] <- "w_trct"
    names(ret3)[names(ret3)=="cbsa"] <- "w_cbsa"   
    
    #merge data with Lat Lon Centroid Data for Work and Home oring and destinations
    # Work Block Centroids
    ret4 <- merge(x=ret3,y=centroidDatav2, by.x = "w_geocode", by.y = "GEOID10")
    # rename lat lon variables
    names(ret4)[names(ret4)=="INTPTLAT10"] <- "w_lat"
    names(ret4)[names(ret4)=="INTPTLON10"] <- "w_lon"
    
    # Home Block Centroids
    ret5 <- merge(x=ret4,y=centroidDatav2, by.x = "h_geocode", by.y = "GEOID10")
    # rename lat lon variables
    names(ret5)[names(ret5)=="INTPTLAT10"] <- "h_lat"
    names(ret5)[names(ret5)=="INTPTLON10"] <- "h_lon"
    
    ret5$Source <- filename #EDIT
    
    ret5
  }
  
  import.list <- ldply(filenames, read_csv_filename)
  
  # Add year variable
  import.list$year <- substr(import.list$Source,17,20)
  
  # Add distance and bearing information
  # prepare spatial data
  w_coord <- cbind(import.list$w_lon,import.list$w_lat)
  h_coord <- cbind(import.list$h_lon,import.list$h_lat)
  w_sp <- SpatialPoints(w_coord, proj4string=CRS("+proj=longlat"))
  h_sp <- SpatialPoints(h_coord, proj4string=CRS("+proj=longlat"))
  
  # Calculate Distance in Meters
  import.list$od_dist <- distHaversine(w_sp,h_sp)
  # Calculate Bearing (direction of travel; true course) along a rhumb line (loxodrome) between two points
  # Values range from 0 to 360
  import.list$od_bearing <- bearingRhumb(h_sp,w_sp)

  # Output panel data to csv
  write.table(import.list, file = panelname, sep = ";", dec = ".")
}