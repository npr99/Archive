* Preinstall the following programs:
* ssc install estout, replace // to create tables install estout
* ssc install fastcd, replace // great for changing working directory quickly
/*-------1---------2---------3---------4---------5---------6--------*/
/* Start Log File: Change working directory to project directory    */
/*-------1---------2---------3---------4---------5---------6--------*/

capture log close   // suppress error and close any open logs
log using work/WLLRT-DataExplore02av1-NHGISDemographyData-2015-10-07, replace text
/********-*********-*********-*********-*********-*********-*********/
/* Description of Program                                           */
/********-*********-*********-*********-*********-*********-*********/
// Do file name structure - where no spaces are included in file name:
	// 3-5 letter project mnemonic [-task] step [letter] [Vversion] 
	// [-description] yyyy-mm-dd.do
// program:    WLLRT-DataExplore02av1-NHGISDemographyData-2015-10-07.do
// project:    Wei Li Light Rail Transity
// author:     Nathanael Rosenheim \ Oct 7, 2015
// Project Planning Details:
/*
Look at 2000 and 2010 Decninial Census and ACS data
The files have been standardized (population characteristics)
and normalized (median household income)
The current plan is to see which Census Tracts have significant changes
in demographic characteristics between the 2 time periods.
The CTs with significant changes will be given a dummy value which could 
be included in a random effects panel model
*/

/*------------------------------------------------------------------*/
/* Control Stata                                                    */
/*------------------------------------------------------------------*/
* Generic do file that sets up stata environment
clear all          // Clear existing data files
macro drop _all    // Drop macros from memory
version 12.1       // Set Version
set more off       // Tell Stata to not pause for --more-- messages
set varabbrev off  // Turn off variable abbreviations
set linesize 80    // Set Line Size - 80 Characters for Readability
*set matsize 5000   // Set Matrix Size if program has a large matrix
set max_memory 2g  // if the file size is larger than 64M change size

/*-------------------------------------------------------------------*/
/* Set Provenance                                                    */
/*-------------------------------------------------------------------*/
// What is the do file name? What program is needed to replicate results?
global dofilename "WLLRT-DataExplore02av1-NHGISDemographyData-2015-10-07" 
global provenance "Provenance: ${dofilename}.do `c(filename)' `c(current_date)'"
global source "2000 Decinial Census, 2010 Decinial Census, 2008-2012 ACS, NHGIS" // what is the data source
local outputfile "Work/${dofilename}.rtf" // location to save output file

/********-*********-*********-*********-*********-*********-*********/
/* Scrub Data - Derive Stata Files from Sources                     */
/********-*********-*********-*********-*********-*********-*********/
/* Common scrubbing tasks
- Convert data from one format to another
- Filter observations
- Extract and replace values
- Split, merge, stack, or extract columns */

/*-------------------------------------------------------------------*/
/* Demographic Characteristics by Census Tract for 2000 and 2010     */
/*-------------------------------------------------------------------*/
* Get variable labels from second row of CSV File
import delimited using "Posted/nhgis0010_csv/nhgis0010_ts_geog2010_tract.csv", ///
	clear varnames(1) rowrange(2:2)
	
* store variable labels
foreach v of varlist * {
   local l`v' = `v'
   if `"`l`v''"' == "" {
   local l`v' "`v'"
   }
 } 
 * import data starting in Row 3
 import delimited using "Posted/nhgis0010_csv/nhgis0010_ts_geog2010_tract.csv", ///
	clear varnames(1) rowrange(3)

	
* Attach the saved labels after collapse
foreach v of varlist *  {
	* Remove units from lable
	local temp_lable=substr("`l`v''",1,.)
	label var `v' "`temp_lable'"
}

* convert string values to numeric
destring cn* cm* cp*, replace

* compress file
compress

* create merge variables
gen panelyear = datayear

gen fips_county = statea+countya

order fips_county gisjoin datayear panelyear

sort gisjoin panelyear

notes:  Source nhgis0010_ts_geog2010_tract: Minnesota Population Center. ///
	National Historical Geographic Information ///
    System: Version 2.0. Minneapolis, MN: University of Minnesota 2011.
notes:  US Census Bureau - Texas County Characteristics Datasets:
notes:  nhgis0010_ts_geog2010_tract retrieved from: ///
		"https://www.nhgis.org/"
notes: $provenance
saveold "work/WLLRT-nhgis0010_ts_geog2010_tract.dta", replace 

/*-------------------------------------------------------------------*/
/* Income Data by Census Tract for 2000 and 2010                     */
/*-------------------------------------------------------------------*/

* Get variable labels from second row of CSV File
import delimited using "Posted/nhgis0010_csv/nhgis0010_ts_nominal_tract.csv", ///
	clear varnames(1) rowrange(2:2)
	
* store variable labels
foreach v of varlist * {
   local l`v' = `v'
   if `"`l`v''"' == "" {
   local l`v' "`v'"
   }
 } 
 * import data starting in Row 3
 import delimited using "Posted/nhgis0010_csv/nhgis0010_ts_nominal_tract.csv", ///
	clear varnames(1) rowrange(3)

	
* Attach the saved labels after collapse
foreach v of varlist *  {
	* Remove units from lable
	local temp_lable=substr("`l`v''",1,.)
	label var `v' "`temp_lable'"
}

* convert string values to numeric
destring b* a*, replace

* compress file
compress

* Drop years prior to 2000
keep if year == "2000" | year == "2008-2012"

* create merge variables
gen panelyear = "2000"
replace panelyear = "2010" if year == "2008-2012" 

gen fips_county = statea+countya

order fips_county gisjoin year panelyear

sort gisjoin panelyear

notes:  Source nhgis0010_ts_nominal_tract: Minnesota Population Center. ///
	National Historical Geographic Information ///
    System: Version 2.0. Minneapolis, MN: University of Minnesota 2011.
notes:  US Census Bureau - Texas County Characteristics Datasets:
notes:  nhgis0010_ts_nominal_tract retrieved from: ///
		"https://www.nhgis.org/"
notes: $provenance
saveold "work/WLLRT-nhgis0010_ts_nominal_tract.dta", replace 

/*-------------------------------------------------------------------*/
/* Merge Data Files Together                                         */
/*-------------------------------------------------------------------*/

use "work/WLLRT-nhgis0010_ts_geog2010_tract.dta", clear
sort gisjoin panelyear
merge gisjoin panelyear using "work/WLLRT-nhgis0010_ts_nominal_tract.dta"

* Check merge
tab _merge

* check census tracts in the demography file but not in the income file
tab state panelyear if _merge == 1
* check census tracts in the income file but not in the demography file
tab state panelyear if _merge == 2
* check census tracts in the both files
tab state panelyear if _merge == 3

drop _merge

/*-------------------------------------------------------------------*/
/* Merge in CBSA data                                                */
/*-------------------------------------------------------------------*/

sort fips_county

merge fips_county using "posted/WLLRT_cbsatocountycrosswalk.dta"


/*-------------------------------------------------------------------*/
/* Generate new variables                                            */
/*-------------------------------------------------------------------*/

gen tot_wa = wa_male + wa_female // total white alone population
label variable tot_wa "Total White Alone Population"
notes tot_wa: Source: US Census Bureau - Texas County Characteristics Datasets
notes tot_wa: tot_wa = wa_male + wa_female 
notes tot_wa: White alone male population + White alone female population

gen tot_ba = ba_male + ba_female // total black alone population
label variable tot_ba "Total Black Alone Population"
notes tot_ba: Source: US Census Bureau - Texas County Characteristics Datasets
notes tot_ba: tot_ba = ba_male + ba_female 
notes tot_ba: Black alone male population + Black alone female population

gen tot_h = h_male + h_female // total Hispanic alone population
label variable tot_h "Total Hispanic Alone Population"
notes tot_h: Source: US Census Bureau - Texas County Characteristics Datasets
notes tot_h: tot_h = h_male + h_female 
notes tot_h: Hispanic male population + Hispanic female population

/*-------------------------------------------------------------------*/
/* Drop Variables                                                    */
/*-------------------------------------------------------------------*/

keep state county tot*        // drop sex variables
saveold "work/TMPWF-Pop_2010_TX", replace 

/*-------------------------------------------------------------------*/
/* Clean SAIPE Excel Files                                           */
/*-------------------------------------------------------------------*/
 
use "work/TMPWF-SAIPE_est10ALL.dta", clear
drop K-V Z-AE      // Do not need variables
* Example of Stata native variables
drop if _n <= 3    // Drop first 3 rows
keep if state == "48"  // Keep Texas
destring, replace  // Convert Strings to numeric
saveold "work/TMPWF-SAIPE_2010_TX", replace 

/*-------------------------------------------------------------------*/
/* Add Merge ID - FIPS County Pop Data                               */
/*-------------------------------------------------------------------*/

use "work/TMPWF-Pop_2010_TX", clear 
// generated FIPS_Code from State and County Codes
gen str5 FIPS_County = string(state,"%02.0f")+string(county,"%03.0f")
sort FIPS_County
saveold "work/TMPWF-Pop_2010_TX_id", replace 

* Add Merge ID - FIPS County SAIPE Data
use "work/TMPWF-SAIPE_2010_TX", clear 
// generated FIPS_Code from State and County Codes
gen str5 FIPS_County = string(state,"%02.0f")+string(county,"%03.0f")
sort FIPS_County
saveold "work/TMPWF-SAIPE_2010_TX_id", replace 

* Merge SAIPE and SEER Data
use "work/TMPWF-Pop_2010_TX_id", clear 
merge FIPS_County using "work/TMPWF-SAIPE_2010_TX_id" 
saveold "work/TMPWF-SAIPE_POP_2010_TX", replace

* Drop uneeded variables and reorder
use "work/TMPWF-SAIPE_POP_2010_TX", clear
drop state county _merge
order FIPS_County 
saveold "work/TMPWF-SAIPE_POP_2010_TX_fltr", replace

/*-------------------------------------------------------------------*/
/* Add pop percent variables, label new variables                    */
/*-------------------------------------------------------------------*/

use "work/TMPWF-SAIPE_POP_2010_TX_fltr", clear
* EXAMPLE OF LOOP
foreach re in wa ba h { // loop through white, black Hispanic
 gen p_`re' = tot_`re' / tot_pop * 100 
 format p_`re' %04.2f //
}
* Label variables
label variable p_wa "Percent White"
label variable p_ba "Percent Black"
label variable p_h  "Percent Hispanic" 


/*-------------------------------------------------------------------*/
/* Notes on Data Sources                                             */
/*-------------------------------------------------------------------*/

notes: $provenance

/*-------------------------------------------------------------------*/
/* Generate Codebook                                                 */
/*-------------------------------------------------------------------*/
codebook, compact
notes

saveold "Work/${dofilename}.dta", replace

/*-------------------------------------------------------------------*/
/* End Log                                                           */
/*-------------------------------------------------------------------*/

log close
exit
