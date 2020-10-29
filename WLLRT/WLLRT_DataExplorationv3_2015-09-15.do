/*-------1---------2---------3---------4---------5---------6--------*/
/* Start Log File                                                   */
/*-------1---------2---------3---------4---------5---------6--------*/
capture log close   // suppress error and close any open logs
log using work/WLLRT_DataExplorationv3_2015-09-15, replace text
/********-*********-*********-*********-*********-*********-*********/
/* Description of Program                                           */
/********-*********-*********-*********-*********-*********-*********/
// program:    WLLRT_DataExplorationv3_2015-09-15.do
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

/* List of possible cities 
local CBSAid = 12420 
local city = "Austin"

local CBSAid = 16740
local city = "Charlotte"

local CBSAid = 19100
local city = "Dallas"

local CBSAid = 19740
local city = "Denver"

local CBSAid = 26420
local city = "Houston"

local CBSAid = 31100
local city = "Los Angeles"

local CBSAid = 38060
local city = "Pheonix"

local CBSAid = 3890
0local city = "Portland"

local CBSAid = 40900
local city = "Sacramento"

local CBSAid = 41620
local city = "Salt Lake"

local CBSAid = 41740
local city = "San Diego"

local CBSAid = 42660
local city = "Seattle"
*/

use Work\WLLRT_`CBSAid'wacS000JT032002_2013.dta, clear


/*-------------------------------------------------------------------*/
/* Setting panel data                                                */
/*-------------------------------------------------------------------*/
* In this case “county” represents the entities or panels (i) 
* “year” Represents the time variable (t).
* Panel variables need to be real not string
format panelblockid %15.0f

sort panelblockid year

xtset panelblockid year
* Save first and last year for future programs
local yrmin = r(tmin)
local yrmax = r(tmax)

/*-------------------------------------------------------------------*/
/* Set Provenance                                                    */
/*-------------------------------------------------------------------*/
global dofilename "WLLRT_DataExplorationv3_2015-09-15"
global provenance "Provenance: ${dofilename}.do `c(filename)' `c(current_date)'"
global source "Wei Li, LODES"
local file1 "WLLRT_`CBSAid'_2015-09-15"
local outputfile "Work\`file1'.rtf" 

/*-------------------------------------------------------------------*/
/* Set Dependent Variable                                            */
/*-------------------------------------------------------------------*/
local dep_var c000jt03 /* total number of jobs */
local dep_var_label: variable label `dep_var'

/*-------------------------------------------------------------------*/
/* MODEL 1 Explanatory Variables                                     */
/*-------------------------------------------------------------------*/
local model1_expvars r1 r2 r3 r4

/*-------------------------------------------------------------------*/
/* Set Formats for Output Tables and Graphs                          */
/*-------------------------------------------------------------------*/
* What format would work for the stats?
local stat_fmt "%18.0fc"
* What format would work for the Model Tables?
local coef_fmt "%6.3fc"
local se_fmt "%14.2fc"

/*-------------------------------------------------------------------*/
/* Collapse into Block Groups and Census Tract                       */
/*-------------------------------------------------------------------*/


foreach cvar of varlist w_bgrp w_censustractfp w_zcta {
preserve
local cvar w_censustractfp
collapse (sum) c000jt03 ca* ce* cn* ///
		(mean) primarycounty meandist=mindlrt ///
		(min) mindist=mindlrt   ///
		      mindonut=donutrange ///
		(max) maxdist=mindlrt, by(year `cvar')


sort `cvar' year

* gen range variables based on max values
gen rmean1 = 0
gen rmean2 = 0
gen rmean3 = 0
gen rmean4 = 0
gen rmean5 = 0
replace rmean1 = 1 if meandist <= 0.25
replace rmean2 = 1 if meandist > 0.25  & meandist <= 0.5
replace rmean3 = 1 if meandist > 0.5  & meandist <= 1
replace rmean4 = 1 if meandist > 1  & meandist != 99999
replace rmean5 = 1 if meandist == 99999

* gen range variables based on min values
gen rmin1 = 0
gen rmin2 = 0
gen rmin3 = 0
gen rmin4 = 0
gen rmin5 = 0
replace rmin1 = 1 if mindist <= 0.25
replace rmin2 = 1 if mindist > 0.25  & mindist <= 0.5
replace rmin3 = 1 if mindist > 0.5  & mindist <= 1
replace rmin4 = 1 if mindist > 1  & mindist != 99999
replace rmin5 = 1 if mindist == 99999

sort `cvar' year

* encode is limited to less than 65K unique ids
encode `cvar', gen(panel) 
order panel

xtset panel year

/*-------------------------------------------------------------------*/
/* Set Dependent Variable                                            */
/*-------------------------------------------------------------------*/
local dep_var c000jt03 /* total number of jobs */
local dep_var_label: variable label `dep_var'

/*-------------------------------------------------------------------*/
/* MODEL 1 Explanatory Variables                                     */
/*-------------------------------------------------------------------*/
local model1_expvars rmin1 rmin2 rmin3 rmin4
local file1 "WLLRT_`CBSAid'_2015-09-15"
local outputfile "Work\`file1'.rtf" 

/*-------------------------------------------------------------------*/
/* Demean Explanatory Variables                                      */
/*-------------------------------------------------------------------*/

// For bacground on the code below see:
// program:		/NPRSNAP/Work/Scratch/UnderstandingXtreg.do

gen one=1
local idvar panel
local fixedvars `dep_var' `model1_expvars'
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
* Create Local for demeaned values
foreach var of varlist `model1_expvars' {
	local  demeaned_m1 `demeaned_m1' dm_`var'
}


/*-------------------------------------------------------------------*/
/* Compare correlation matrix                                        */
/*-------------------------------------------------------------------*/

pwcorr `model1_expvars'

/*-------------------------------------------------------------------*/
/* Histogram of Dependent Variable                                   */
/*-------------------------------------------------------------------*/

table `dep_var' mindonut if `dep_var' <= 20, column

/*-------------------------------------------------------------------*/
/* Set Scales Graphs                                                 */
/*-------------------------------------------------------------------*/
* Scale for histograms with all observations
local y1_scale = 2000
local y1_step = 500
* Scale for histograms by year
local y2_scale = 200
local y2_step = 100

* Summarize to store min and max scalars for all years
* This will make all of the graphs on the same scale
quietly summarize `dep_var'
local min = r(min)
local min_strng = string(`min',"`stat_fmt'")
local max = r(max)
local max_strng = string(`max',"`stat_fmt'")
local mean = r(mean)
local mean_strng = string(`mean',"`stat_fmt'")
local sd = r(sd)

* LaTex using PDFlatex does not recognize *.eps - *.pdf is the best option
local graph_name = "`file1'_hist`dep_var'`cvar'"
* Caption for Graph
local graphcaption = "Histogram of `dep_var_label'."
histogram `dep_var', frequency normal kdensity ///
	xlabel(`min' "`min_strng'" `mean' "`mean_strng'" `max' "`max_strng'") ///
	xtick(`min'(`sd')`max') ///
	xscale(range(`min' `max')) ///
	ylabel(0(`y1_step')`y1_scale')  ///
	scheme(lean2)
graph export `"`graph_name'.pdf"', replace

* LaTex using PDFlatex does not recognize *.eps - *.pdf is the best option
local graph_name = "`file1'_histdm_`dep_var'`cvar'"
* Caption for Graph
local graphcaption = "Histogram of Demeaned `dep_var_label'."
histogram dm_`dep_var', frequency normal kdensity ///
	xlabel(`min' "`min_strng'" `mean' "`mean_strng'" `max' "`max_strng'") ///
	xtick(`min'(`sd')`max') ///
	xscale(range(`min' `max')) ///
	ylabel(0(`y1_step')`y1_scale')  ///
	scheme(lean2)
graph export `"`graph_name'.pdf"', replace
/*-------------------------------------------------------------------*/
/* Generate Descriptive Stats                                        */
/*-------------------------------------------------------------------*/

eststo clear
estpost tabstat `dep_var' `model1_expvars', ///
		statistics(min max p50 p75 p90 mean sd count) columns(statistics)
esttab using ///
`outputfile' ///
, b(%6.3fc) replace nogap label modelwidth(10) cells("count(fmt(%12.0fc)) min(fmt(%12.3fc)) max(fmt(%12.3fc)) p50(fmt(%6.3fc)) p75(fmt(%6.3fc)) p90(fmt(%6.3fc)) mean(fmt(%6.3fc)) sd(fmt(%6.3fc))") noobs ///
title(Basic Descriptive Statistics `cvar' `city' 2002-2013) ///
nonumbers addnote("Source: $source" "$provenance")
eststo clear

/* Job statistics for blocks by Donut Range*/
eststo clear
estpost tabstat `dep_var' `model1_expvars', ///
		by(mindonut) statistics(mean sd) columns(statistics) listwise
esttab using ///
`outputfile' ///
, b(a3) append main(mean %12.2fc) aux(sd %12.2fc) ///
title(Basic Descriptive Statistics for Jobs for `cvar' by Min Donut Range `city' 2002-2013) ///
	nostar unstack label modelwidth(20) onecell ///
	gaps collabels(none) nomtitle nonumber noobs ///
	addnote("Source: $source" "$provenance")
eststo clear

/*-------------------------------------------------------------------*/
/* ANOVA                                                             */
/*-------------------------------------------------------------------*/
eststo clear
foreach dpvars of varlist `dep_var' `model1_expvars' {
	anova `dpvars' mindonut
	eststo: regress, baselevels
}

esttab using ///
	`outputfile' ///
	, r2 append nogap wide nopar not label modelwidth(10) ///
	b(%10.2fc) ///
	title(ANOVA Results - by Min Donut Range `cvar' `city' 2002-2013) ///
	nonumbers  ///
	addnote("Source: $source" "$provenance")
eststo clear

eststo clear
local anovavars1 ca01jt03 ca02jt03 ca03jt03 ce01jt03 ce02jt03 ce03jt03

foreach dpvars of varlist `anovavars1' {
	anova `dpvars' mindonut
	eststo: regress, baselevels
}

esttab using ///
	`outputfile' ///
	, r2 append nogap wide nopar not label modelwidth(10) ///
	b(%10.2fc) ///
	title(ANOVA Results - by Min Donut Range `cvar' `city' 2002-2013) ///
	nonumbers  ///
	addnote("Source: $source" "$provenance")
eststo clear


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
twoway (tsline c000jt03) (tsline ce01jt03) ///
	(tsline ce02jt03) (tsline ce03jt03) if `cvar' == "`max`i'`cvar''",               /// 
	ytitle(Primary Jobs) ytitle(, size(small))                       ///
	ylabel(, labels labsize(small) format(%12.0gc))              ///
	ttitle(Year) ttitle(, size(small)) tlabel(, labsize(small)) ///
	legend(cols(2) size(small) position(7)) scheme(lean2) ///
	title("Greatest `i' difference from Center of `dep_var'") ///
	subtitle("for `CBSAid' `cvar' = `max`i'`cvar''") ///
	caption("Source: $source" "$provenance", size(vsmall))
local graph_name = "`file1'_max`i'`cvar'"
graph export `"`graph_name'.pdf"', replace
	
local max2`cvar' = `cvar'[_N-12]
}
	
* Min Change (only negative changes)

/* the below gives the same tracts - need to find the biggest decline
local dep_var c000jt03 /* total number of jobs */
gsort -center_`dep_var'i
bys panel: gen min_`dep_var' = center_`dep_var'i[_N]

format min_`dep_var' center_`dep_var'i %6.2fc
order min_`dep_var' center_`dep_var'i `dep_var'
sort min_`dep_var' panel year

local max`cvar' = `cvar'[_N]
*/
restore
}

/*-------------------------------------------------------------------*/
/* End Log                                                           */
/*-------------------------------------------------------------------*/

log close
