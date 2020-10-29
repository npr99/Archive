/*-------1---------2---------3---------4---------5---------6--------*/
/* Start Log File                                                   */
/*-------1---------2---------3---------4---------5---------6--------*/
capture log close   // suppress error and close any open logs
log using work/WLLRT_DataExplorationv4_2015-09-15, replace text
/********-*********-*********-*********-*********-*********-*********/
/* Description of Program                                           */
/********-*********-*********-*********-*********-*********-*********/
// program:    WLLRT_DataExplorationv4_2015-09-15.do
// task:       Panel Data with LRT
// Version:    First Version
// project:    Wei Li LRT LODES Data
// author:     Nathanael Rosenheim \ Sept 4 2015
// Project Planning Details
// Testing out data for the first time

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
set matsize 5000   // Set Matrix Size
set max_memory 2g  // the file size is larger than 64M 

/*-------------------------------------------------------------------*/
/* Data Source                                                       */
/*-------------------------------------------------------------------*/

local CBSAid = 26420
local city = "Houston"

use Work\WLLRT_`CBSAid'wacS000JT032002_2013.dta, clear

/*-------------------------------------------------------------------*/
/* Set Provenance                                                    */
/*-------------------------------------------------------------------*/
global dofilename "WLLRT_DataExplorationv4_2015-09-15"
global provenance "Provenance: ${dofilename}.do `c(filename)' `c(current_date)'"
global source "LODES"
local file1 "WLLRT_`CBSAid'_2015-09-15"
local outputfile "Work\`file1'.rtf" 

/*-------------------------------------------------------------------*/
/* Look at changes over time for entire CBSA                         */
/*-------------------------------------------------------------------*/
preserve
local collapsevars c000jt03 ca* ce* cn*
/* Saved labels before collapse                                      */
foreach v of varlist `collapsevars' {
   local l`v' : variable label `v'
   if `"`l`v''"' == "" {
   local l`v' "`v'"
   }
}

collapse (sum) `collapsevars', by(year)

/* Attach the saved labels after collapse                            */
foreach v of varlist `collapsevars' {
	* Remove units from lable
	local temp_lable=substr("`l`v''",1,strpos("`l`v''"," ("))
	label var `v' "`temp_lable'"
}

* Set time-series data
* check to see if I can turn year dates in dd-mm-yyyy
* LODES data is actuall for April 1 of the given year not Jan 1
gen ddmmyyyy = mdy(4,1,year)
format ddmmyyyy %d
order ddmmyyyy year

tsset ddmmyyyy

twoway (tsline c000jt03) (tsline ce01jt03)                      ///
	(tsline ce02jt03) (tsline ce03jt03),                        /// 
	ytitle(Private Primary Jobs) ytitle(, size(small))          ///
	ylabel(, labels labsize(small) format(%12.0gc))             ///
	ttitle(Year) ttitle(, size(small)) tlabel(, labsize(small)) ///
	legend(cols(2) size(small) position(7)) scheme(lean2)       ///
	title("Greatest `i' difference from Center of `dep_var'")   ///
	subtitle("for `city'")                                      ///
	xlabel(,format(%tdCCYY))                                    ///
	tline(12sep2009, lc(red))                                   ///
	note("Red Line: Hurricane Ike Sept 13, 2008", size(small))  ///
	caption("Source: $source" "$provenance", size(vsmall)) 
local graph_name = "`file1'_`city'"
graph export `"`graph_name'.pdf"', replace

saveold Work\WLLRT_`CBSAid'`city'wacS000JT032002_2013.dta, replace

restore


/*-------------------------------------------------------------------*/
/* Look at changes over time for Galveston                           */
/*-------------------------------------------------------------------*/
preserve
/*-------------------------------------------------------------------*/
/* Select Galveston                                                  */
/*-------------------------------------------------------------------*/

local CBSAid = "26420_1"
local city = "Galveston"

keep if w_censustractfp >= "48167724000" 
keep if w_censustractfp <= "48167726100"

local collapsevars c000jt03 ca* ce* cn*
/* Saved labels before collapse                                      */
foreach v of varlist `collapsevars' {
   local l`v' : variable label `v'
   if `"`l`v''"' == "" {
   local l`v' "`v'"
   }
}

collapse (sum) `collapsevars', by(year)

/* Attach the saved labels after collapse                            */
foreach v of varlist `collapsevars' {
	* Remove units from lable
	local temp_lable=substr("`l`v''",1,strpos("`l`v''"," ("))
	label var `v' "`temp_lable'"
}

* Set time-series data
* check to see if I can turn year dates in dd-mm-yyyy
* LODES data is actuall for April 1 of the given year not Jan 1
gen ddmmyyyy = mdy(4,1,year)
format ddmmyyyy %d
order ddmmyyyy year

tsset ddmmyyyy

twoway (tsline c000jt03) (tsline ce01jt03)                      ///
	(tsline ce02jt03) (tsline ce03jt03),                        /// 
	ytitle(Private Primary Jobs) ytitle(, size(small))          ///
	ylabel(, labels labsize(small) format(%12.0gc))             ///
	ttitle(Year) ttitle(, size(small)) tlabel(, labsize(small)) ///
	legend(cols(2) size(small) position(7)) scheme(lean2)       ///
	title("Greatest `i' difference from Center of `dep_var'")   ///
	subtitle("for `city'")                                      ///
	xlabel(,format(%tdCCYY))                                    ///
	tline(12sep2009, lc(red))                                   ///
	note("Red Line: Hurricane Ike Sept 13, 2008", size(small))  ///
	caption("Source: $source" "$provenance", size(vsmall)) 
local graph_name = "`file1'_`city'"
graph export `"`graph_name'.pdf"', replace

saveold Work\WLLRT_`CBSAid'`city'wacS000JT032002_2013.dta, replace

restore



/*-------------------------------------------------------------------*/
/* Collapse into Block Groups and Census Tract                       */
/*-------------------------------------------------------------------*/

local CBSAid = 26420
local city = "Houston"

foreach cvar of varlist w_bgrp w_censustractfp w_zcta {
preserve

local collapsevars c000jt03 ca* ce* cn*
/* Saved labels before collapse                                      */
foreach v of varlist `collapsevars' {
   local l`v' : variable label `v'
   if `"`l`v''"' == "" {
   local l`v' "`v'"
   }
}


collapse (sum) `collapsevars', by(year `cvar')

/* Attach the saved labels after collapse                            */
foreach v of varlist `collapsevars' {
	* Remove units from lable
	local temp_lable=substr("`l`v''",1,strpos("`l`v''"," ("))
	label var `v' "`temp_lable'"
}

* Set time-series data
* check to see if I can turn year dates in dd-mm-yyyy
* LODES data is actuall for April 1 of the given year not Jan 1
gen ddmmyyyy = mdy(4,1,year)
format ddmmyyyy %d
order ddmmyyyy year


* encode is limited to less than 65K unique ids
encode `cvar', gen(panel) 
order panel

xtset panel ddmmyyyy

sort `cvar' ddmmyyyy

saveold Work\WLLRT_`CBSAid'`cvar'wacS000JT032002_2013.dta, replace
restore
}

exit


foreach cvar in w_bgrp w_censustractfp w_zcta {
local CBSAid = 26420
local city = "Houston"

use Work\WLLRT_`CBSAid'`cvar'wacS000JT032002_2013.dta, clear

/*-------------------------------------------------------------------*/
/* Set Dependent Variable                                            */
/*-------------------------------------------------------------------*/
local dep_var c000jt03 /* total number of jobs */
local dep_var_label: variable label `dep_var'

/*-------------------------------------------------------------------*/
/* Demean Explanatory Variables                                      */
/*-------------------------------------------------------------------*/

// For bacground on the code below see:
// program:		/NPRSNAP/Work/Scratch/UnderstandingXtreg.do

gen one=1
local idvar panel
local fixedvars `dep_var'
foreach var of varlist `fixedvars' {
	* Build mean value of var by id
	bys `idvar': gen double sum_`var'i =  sum(`var')
	bys `idvar': gen double count_`var'i =  sum(one)
	bys `idvar': gen double buildmeani_`var' =  sum_`var'i/count_`var'i 
	* summarize to save overal mean value
	summarize `var'
	bys `idvar': gen mean_`var' = r(mean)
	
	* find centered values for var by id
	bys `idvar': gen mean_`var'i = buildmeani_`var'[_N]
	bys `idvar': gen center_`var'i = `var' - mean_`var'i
	bys `idvar': gen dm_`var' = center_`var'i + mean_`var'
	
	* label demeaned variables
	local l`var' : variable label `var'
	label variable dm_`var' "Demeaned `l`var''"
}


/*-------------------------------------------------------------------*/
/* Look at areas with the biggest changes over time                  */
/*-------------------------------------------------------------------*/

* Max change (only positive changes)
sort panel center_`dep_var'i
bys panel: gen max_`dep_var' = center_`dep_var'i[_N]
format max_`dep_var' center_`dep_var'i %6.2fc
order max_`dep_var' center_`dep_var'i `dep_var'
sort max_`dep_var' panel year

local max1`cvar' = `cvar'[_N]
local max2`cvar' = `cvar'[_N-12]
local max3`cvar' = `cvar'[_N-24]

forvalues i = 1/3  {


twoway (tsline c000jt03) (tsline ce01jt03)                      ///
	(tsline ce02jt03) (tsline ce03jt03) if `cvar' == "`max`i'`cvar''", /// 
	ytitle(Private Primary Jobs) ytitle(, size(small))          ///
	ylabel(, labels labsize(small) format(%12.0gc))             ///
	ttitle(Year) ttitle(, size(small)) tlabel(, labsize(small)) ///
	legend(cols(2) size(small) position(7)) scheme(lean2)       ///
	title("Greatest `i' difference from Center of `dep_var'")   ///
	subtitle("for `city' `cvar' = `max`i'`cvar''")              ///
	xlabel(,format(%tdCCYY))                                    ///
	tline(12sep2009, lc(red))                                   ///
	note("Red Line: Hurricane Ike Sept 13, 2008", size(small))  ///
	caption("Source: $source" "$provenance", size(vsmall)) 
local graph_name = "`file1'_max`i'`cvar'"
graph export `"`graph_name'.pdf"', replace

}
}

/*-------------------------------------------------------------------*/
/* End Log                                                           */
/*-------------------------------------------------------------------*/

log close
