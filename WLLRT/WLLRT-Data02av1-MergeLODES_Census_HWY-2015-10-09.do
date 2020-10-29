* Preinstall the following programs:
* ssc install estout, replace // to create tables install estout
* ssc install fastcd, replace // great for changing working directory quickly
/*-------1---------2---------3---------4---------5---------6--------*/
/* Start Log File: Change working directory to project directory    */
/*-------1---------2---------3---------4---------5---------6--------*/

capture log close   // suppress error and close any open logs
log using work/WLLRT-Data02av1-MergeLODES_Census_HWY-2015-10-09, replace text
/********-*********-*********-*********-*********-*********-*********/
/* Description of Program                                           */
/********-*********-*********-*********-*********-*********-*********/
// Do file name structure - where no spaces are included in file name:
	// 3-5 letter project mnemonic [-task] step [letter] [Vversion] 
	// [-description] yyyy-mm-dd.do
// program:    WLLRT-Data02av1-MergeLODES_Census_HWY-2015-10-09.do
// project:    Wei Li Light Rail Transit
// author:     Nathanael Rosenheim \ Oct 9, 2015
// Project Planning Details:
/*
Merge together Block Level LODES with Census Tract Level Demographic data
and block level highway data
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
set max_memory 5g  // if the file size is larger than 64M change size

/*-------------------------------------------------------------------*/
/* Set Provenance                                                    */
/*-------------------------------------------------------------------*/
// What is the do file name? What program is needed to replicate results?
global dofilename "WLLRT-Data02av1-MergeLODES_Census_HWY-2015-10-09" 
global provenance "Provenance: ${dofilename}.do `c(filename)' `c(current_date)'"
global source "2000 Decinial Census, 2010 Decinial Census, 2008-2012 ACS, NHGIS" // what is the data source
local outputfile "Work/${dofilename}.rtf" // location to save output file

* CBSA's in study area
local cbsa_studyarea /// 
31100 /// Los Angeles-Long Beach-Santa Ana, CA Metropolitan Statistical Area
12420 /// Austin-Round Rock-San Marcos, TX Metropolitan Statistical Area
19100 /// Dallas-Fort Worth-Arlington, TX Metropolitan Statistical Area
16740 /// Charlotte-Gastonia-Rock Hill, NC-SC Metropolitan Statistical Area

foreach cbsakeep in `cbsa_studyarea' {
display "`cbsakeep'"

/*-------------------------------------------------------------------*/
/* Start with block level data                                       */
/*-------------------------------------------------------------------*/
local fyear = 2002 // First year in panel
local lyear = 2013 // Last year in panel LODES
local dfile = "wac" // Workplace Area Characteristics
local JobType = "JT03" // Primary Private Sector Jobs;
local SegType = "S000" // Total number of jobs in LODES;
global cbsaid = `cbsakeep' // Austin

local LODES_DataFile = "WLLRT_${cbsaid}`dfile'`SegType'`JobType'`fyear'_`lyear'"
display "work/`LODES_DataFile'"
use  "work/`LODES_DataFile'", clear

/*-------------------------------------------------------------------*/
/* Merge in Highway Data                                             */
/*-------------------------------------------------------------------*/

sort w_blockid

merge w_blockid using "work/WLLRT-Data02av1-CleanupHWYdata-2015-10-09.dta"

tab _merge

tab _merge if fips_county == w_countyfp

* drop _merge == 2 because the file is only for Austin CBSA
drop if _merge == 2

drop _merge

notes: Highway data merge $provenance
saveold  "work/WLLRT-Data02bv1-MergeLODES_HWY-${cbsaid}-2015-10-09.dta", replace
/*-------------------------------------------------------------------*/
/* Merge in CT Level Variables for Demography that show change       */
/*-------------------------------------------------------------------*/

use  "work/WLLRT-Data02bv1-MergeLODES_HWY-${cbsaid}-2015-10-09.dta", clear

sort w_censustractfp
merge w_censustractfp using "work/WLLRT-Data01gv1-CensusTract_chngvars.dta"

tab _merge

tab w_cbsa if _merge == 3

keep if w_cbsa == "${cbsaid}"
tab _merge

drop _merge

saveold  "work/WLLRT-Data02bv1-MergeLODES_Censusv1_HWY-${cbsaid}-2015-10-09.dta", replace

/*-------------------------------------------------------------------*/
/* Merge in CT Level Variables for Demography in 2000 and 2010       */
/*-------------------------------------------------------------------*/

use  "work/WLLRT-Data02bv1-MergeLODES_Censusv1_HWY-${cbsaid}-2015-10-09.dta", clear
sort w_censustractfp year
merge w_censustractfp year using "work/WLLRT-Data01hv1-CensusTract_2002_2013.dta"

tab _merge

tab w_cbsa if _merge == 3

sort w_blockid year

keep if w_cbsa == "${cbsaid}"
tab _merge

drop _merge

saveold  "work/WLLRT-Data02bv1-MergeLODES_Censusv2_HWY-${cbsaid}-2015-10-09.dta", replace

}

/*-------------------------------------------------------------------*/
/* End Log                                                           */
/*-------------------------------------------------------------------*/
log close

/*------------------------------------------------------------------*/
/* Print Codebook                                                   */
/*------------------------------------------------------------------*/
use "work/WLLRT-Data02bv1-MergeLODES_Censusv2_HWY-${cbsaid}-2015-10-09", clear
log using work/WLLRT-Data02bv1-MergeLODES_Censusv2_HWY-2015-10-09, replace text

describe

codebook, notes
notes


log close
exit
