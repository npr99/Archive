/*-------1---------2---------3---------4---------5---------6--------*/
/* Start Log File                                                   */
/*-------1---------2---------3---------4---------5---------6--------*/
capture log close   // suppress error and close any open logs
log using work/WLLRT-DataExplore03av1-MapCBSACensusTact-2015-10-09, replace text
/********-*********-*********-*********-*********-*********-*********/
/* Description of Program                                           */
/********-*********-*********-*********-*********-*********-*********/
// program:    WLLRT-DataExplore03av1-MapCBSACensusTact-2015-10-09.do
// task:       Exploratory Spatial Anaylsis WLLRT Data
// Version:    First Version
// project:    Wei Li Light Rail Transity
// author:     Nathanael Rosenheim \ Oct 09, 2015

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

* STATA Mapping Help
* SPMAP HElP: http://fmwww.bc.edu/repec/bocode/s/spmap.html
* Stata Color Pallett http://statadaily.com/2010/09/23/color-palette/

/*------------------------------------------------------------------*/
/* Prepare Census Tract Shape File For Mapping                      */
/*------------------------------------------------------------------*/
global dd_shpCT2010 = "Shapefiles\nhgis_tl2010_us_tract_2010\"
global shpfile = "L48_tract_2010"

* Have to change directory for shp2dta to work
cd $dd_shpCT2010

shp2dta using ${shpfile}.shp, 		///
	database(${shpfile}) 			///
	coordinates(${shpfile}coord) 	///
	genid(coordid) replace

use "${shpfile}.dta", clear
// GISJOIN will be needed to merge coordid with other data
// In program files GISJOIN is lowercase
// coordid and POLY_ID2 should be the same
gen gisjoin = GISJOIN

sort gisjoin

saveold "${shpfile}.dta", replace
describe 
* change back to project directory
c WLLRT
/*------------------------------------------------------------------*/
/* Merge File For Mapping                                           */
/*------------------------------------------------------------------*/

// Load Data to Map
use "work/WLLRT-Data01fv1-CensusTract2000_2010.dta", clear
sort gisjoin

* Need to add the coordid that was generated from the shp2dta command
// Where is the Census Tract File created by the shp2dta command Located
local shp2dtafile "${dd_shpCT2010}\${shpfile}.dta"
merge gisjoin using "`shp2dtafile'"

tab _merge

drop _merge
describe
* save new file
saveold  "work/WLLRT-DataExplore03av1-MapCBSACensusTact-2015-10-09.dta", replace
* now file has coordid which should match the coordinate file created by shp2dta

/*------------------------------------------------------------------*/
/* Make Map                                                         */
/*------------------------------------------------------------------*/


use "work/WLLRT-DataExplore03av1-MapCBSACensusTact-2015-10-09.dta", clear
	
	local mapyear = 2010
	local mapvar ppop_HS
	local mapvar_label : variable label `mapvar'
	
	
	// Where is the Census Tract Coordinates File Located
	local coordfile "${dd_shpCT2010}\${shpfile}coord.dta"	
		
	/*
	spmap `mapvar' using "`coordfile'" 							   ///
		if datayear == "`mapyear'" & fips_county == "48453", id(coordid) 				   ///
		clmethod(quantile) legcount            ///
		ndfcolor(gs8) ndlab("Missing") 							   ///
		title("`mapvar_label' in `mapyear'", size(*.8)) 
		
	spmap lmh_`mapvar' using "`coordfile'" 							   ///
		if datayear == "`mapyear'" & fips_county == "48453", id(coordid) 				   ///
		clmethod(unique) legcount            ///
		ndfcolor(gs8) ndlab("Missing") 							   ///
		title("`mapvar_label' in `mapyear'", size(*.8)) 
	*/
	
	spmap chng_`mapvar' using "`coordfile'" 							   ///
		if datayear == "`mapyear'" & fips_county == "48453", id(coordid) 				   ///
		clmethod(unique) legcount            ///
		ndfcolor(gs8) ndlab("Missing") 							   ///
		title("`mapvar_label'", size(*.8)) 
graph export `"Work\WLLRT-DataExplore03av1-MapCBSACensusTact_`mapyear'_2015-10-09.tif"', replace
}
