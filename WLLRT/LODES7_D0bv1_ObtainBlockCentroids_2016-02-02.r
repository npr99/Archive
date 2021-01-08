# Make sure R is uptodate 
# updateR()
#*-------1---------2---------3---------4---------5---------6--------*/
#* Start Log File: Change working directory to project directory    */
#*-------1---------2---------3---------4---------5---------6--------*/

cpath<- "L:/"
setwd(cpath)

"********-*********-*********-*********-*********-*********-*********"
"* Description of Program                                           *"
"********-*********-*********-*********-*********-*********-*********"
" Do file name structure - where no spaces are included in file name:"
"/ 3-5 letter project mnemonic [-task] step [letter] [Vversion]"
"/ [-description] yyyy-mm-dd.do"
"/ program:    LODES7_D0bv1_ObtainBlockCentroids_2016-02-02"
"/ project:    To be used by several projects"
"/ author:     Nathanael Rosenheim \ Feb 2, 2016"
"/ Project Planning Details:"
"/ Collect data from the Census Tiger file website:
  Block County-based Shapefile Record Layout (2010 Census)
  ftp://ftp2.census.gov/geo/tiger/TIGER2010/TABBLOCK/2010/
  tl_2010_<state-county FIPS>_tabblock10.zip
  This program will unzip the Census file and read the .DBF file to 
  extract the lat and lon for the block Centroids."

"*------------------------------------------------------------------*"
"* Call special R Libraries                                         *"
"*------------------------------------------------------------------*"
library(foreign) # Needed to read DBF files

"*------------------------------------------------------------------*"
"* Obtain Data                                                      *"
"*------------------------------------------------------------------*"

# state name = STUSAB)
if (!file.exists("state.txt")){
  download.file("http://web.archive.org/web/20141125122851/http://www.census.gov/geo/reference/docs/state.txt", destfile = "state.txt")
}
states <- read.table("state.txt", sep = "|", header = T, colClasses = "character")
states <- states[order(as.numeric(states$STATE)), ]
states.keep <- states[-c(52:57),]
nstates <- dim(states.keep)[1]

# For each state
for (i in 1:nstates) {
  stfips <- tolower(states.keep[i, 1])

# What is the web address for the files to download:
webaddress<-"ftp://ftp2.census.gov/geo/tiger/TIGER2010/TABBLOCK/2010/"
# Set name of file to download
file1<- paste0("tl_2010_",stfips,"_tabblock10")
zipname<-paste0("work/",file1,".zip")
sourcename <- paste0(webaddress,file1,".zip")
# Generate Filename for CSV file
csvname<-paste0("LODES7_D0bv1_ObtainBlockCentroids_2016-02-02/",file1,".csv")

# Download file if CSV has not already been created
if (!file.exists(csvname)){
  download.file(sourcename, destfile = zipname)
}


if (!file.exists(csvname)){

  # Unzip File
  z <- unzip(zipname, exdir = "/work")
  
  # remove unwanted files
  z2 <- z[2:5]
  file.remove(z2)
  file.remove(zipname)
  
  # Read DBF File
  dbfname<-paste0("work/",file1,".dbf")
  dbfdata <- read.dbf(dbfname)
  
  # Write CSV
  write.csv2(dbfdata, file = csvname, col.names = TRUE, sep = ";")
  
  # remove unwanted files
  file.remove(dbfname)
}

}


"
To Read the CSV files created use:
Read CSV
## csvdata <- read.csv2(csvname, header = TRUE, nrows = 5, sep = ";", quote = "\"")
"
Metadata from:
http://www2.census.gov/geo/pdfs/maps-data/data/tiger/tgrshp2010/TGRSHP10SF1CH5.pdf 
Table 5.2.1

Field Length  Type  Description
STATEFP10 2 String  2010 Census state FIPS code
COUNTYFP10  3 String  2010 Census county FIPS code
TRACTCE10 6 String  2010 Census census tract code
BLOCKCE10 4 String  2010 Census tabulation block number
GEOID10 15  String Block identifier; a concatenation of 2010 Census state FIPS code, county FIPS code, census tract code and tabulation block number.
NAME10  10  String 2010 Census tabulation block name; a concatenation of 'Block' and the current tabulation block number
MTFCC10 5 String  MAF/TIGER feature class code (G5040)
UR10  1 String  2010 Census urban/rural indicator
UACE10  5 String  2010 Census urban area code
UATYP10 1 String  2010 Census urban area type
FUNCSTAT10  1 String  2010 Census functional status
ALAND10 14  Number  2010 Census land area
AWATER10  14 Number 2010 Census water area
INTPTLAT10  11  String  2010 Census latitude of the internal point
INTPTLON10  12  String  2010 Census longitude of the internal point
"