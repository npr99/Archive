* Preinstall the following programs:
* ssc install estout, replace // to create tables install estout
* ssc install fastcd, replace // great for changing working directory quickly
/*-------1---------2---------3---------4---------5---------6--------*/
/* Start Log File: Change working directory to project directory    */
/*-------1---------2---------3---------4---------5---------6--------*/

capture log close   // suppress error and close any open logs
log using work/WLLRT-Data02av1-CleanupHWYdata-2015-10-09, replace text
/********-*********-*********-*********-*********-*********-*********/
/* Description of Program                                           */
/********-*********-*********-*********-*********-*********-*********/
// Do file name structure - where no spaces are included in file name:
	// 3-5 letter project mnemonic [-task] step [letter] [Vversion] 
	// [-description] yyyy-mm-dd.do
// program:    WLLRT-Data02av1-CleanupHWYdata-2015-10-09
// project:    Wei Li Light Rail Transit
// author:     Nathanael Rosenheim \ Oct 9, 2015
// Project Planning Details:
/*
Get Highway distance from ramp data ready for merge
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
global dofilename "WLLRT-Data02av1-CleanupHWYdata-2015-10-09" 
global provenance "Provenance: ${dofilename}.do `c(filename)' `c(current_date)'"
global source "NHGIS, ESRI Streets, Wei Li, Haotian Zhong " // what is the data source
local outputfile "Work/${dofilename}.rtf" // location to save output file


/*-------------------------------------------------------------------*/
/* Start with Haotian Zhong data                                     */
/*-------------------------------------------------------------------*/
* Data shared from Haotian Zhong
use "F:\Dropbox\Derived data\block_distance_dummy_v2.dta", clear

format BLOCKID10 %15.0f
gen statecounty = trunc(BLOCKID10/10000000000)
format statecounty %5.0f
order statecounty

gen fips_county = string(statecounty,"%05.0f")
order fips_county

* create the merge id
gen w_blockid = string(BLOCKID10,"%015.0f")
order w_blockid

sort w_blockid

/*-------------------------------------------------------------------*/
/* Label Variables                                                   */
/*-------------------------------------------------------------------*/
label variable Dist_halfmile "Excellent Hwy Access"
notes Dist_halfmile: Haotian Zhong determined that Census 2010 Block ///
was within 1/2 mile buffer of ramp. ///
Ramp defined by Wei Li using 2002 ESRI Streets file.

label variable Dist_1mile "Very Good Hwy Access"
notes Dist_1mile: Haotian Zhong determined that Census 2010 Block ///
was within 1 mile buffer of ramp. ///
Ramp defined by Wei Li using 2002 ESRI Streets file.

label variable Dist_3mile "Good Hwy Access"
notes Dist_3mile: Haotian Zhong determined that Census 2010 Block ///
was within 3 mile buffer of ramp. ///
Ramp defined by Wei Li using 2002 ESRI Streets file.

rename Land_Area blockarea
label variable blockarea "Census Block Area (m?)"
notes blockarea: Haotian Zhong writes - The land area was calculated based on ///
North America Lamber Conformal Conic projection system, ///
it may be a little different from what you got from census but ///
we can use it as a validating information. ///
Need to confirm units of measure.

/*-------------------------------------------------------------------*/
/* Drop Variables                                                    */
/*-------------------------------------------------------------------*/
* Do note need merge, statecounty or CBSAFP10
* CBSAFP10 has too many missing variables
drop merge* statecounty CBSAFP10

/*-------------------------------------------------------------------*/
/* Check Variables                                                   */
/*-------------------------------------------------------------------*/
 
tab CBSAFP10

sum Dist_halfmile
sum Dist_1mile
sum Dist_3mile

tab Dist_halfmile Dist_1mile

/*-------------------------------------------------------------------*/
/* Export Data to look at it in GIS                                  */
/*-------------------------------------------------------------------*/

outsheet using "work/WLLRT-Data02av1-CleanupHWYdata-2015-10-09.csv", replace

notes: WLLRT-Data02av1-CleanupHWYdata-2015-10-09 looks great, ///
exploratory spatial anaylsis confirms that that the three distance dummy ///
variables map to the correct locations.

sort w_blockid

saveold "work/WLLRT-Data02av1-CleanupHWYdata-2015-10-09.dta", replace

