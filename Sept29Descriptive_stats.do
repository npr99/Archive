/*-------------------------------------------------------------------*/
/* What Model Are you Running                                        */
/*-------------------------------------------------------------------*/
local model = "WCRCheck"
/*-------------------------------------------------------------------*/
/* Start Log                                                         */
/*-------------------------------------------------------------------*/
local c_date = c(current_date)
local c_time = c(current_time)
local c_time_date = "`c_date'"+"_" +"`c_time'"
local time_string = subinstr("`c_time_date'", ":", "_", .)
local time_string = subinstr("`time_string'", " ", "_", .)
/* Note to use filenames with a space include `" before and "' after */
log using `"C:\Users\Nathanael\Dropbox\URSC PhD\Dissertation\StataLogs\model_`model'_`time_string'.log"', text
/*-------------------------------------------------------------------*/
/*       Program for Running a Fixed Effects Model on a              */
/*       Balanced Panel Data Set                                     */
/*       with SNAP Data from 2006-2012. For Dissertation Research    */
/*       Model 2 – In-county SNAP retail opportunities               */
/*          by Nathanael Proctor Rosenheim                           */
/*-------------------------------------------------------------------*/
/*-------------------------------------------------------------------*/
/*Model 2: Version 2.94                                               */
/*-------------------------------------------------------------------*/
/* Plan:
      Since BEA data works well going to try to make the model nonstate
	  specfic.
	  This will effect the data that comes from TXHHS - specifically the 
	  over 65 age data which is unique to the TXHHS dataset.
	  
  Results:


  Discussion:


  
*/
/*-------------------------------------------------------------------*/
/*                                                                   */
/* This material is provided "as is" by the author.                  */
/* There are no warranties, expressed or implied, as to              */
/* merchantability or fitness for a particular purpose regarding     */
/* the materials or code contained herein. The author is not         */
/* responsible for errors in this material as it now exists or       */
/* will exist, nor does the author provide technical support.        */
/*                                                                   */
/*-------------------------------------------------------------------*/
/* Date Last Updated: 26Sept14                                       */
/*-------------------------------------------------------------------*/
/* Stata Version 12.1                                                */
/*-------------------------------------------------------------------*/
/* Questions or problem reports concerning this material may be      */
/* addressed to the author on github: https://github.com/npr99       */
/*                                                                   */
/*-------------------------------------------------------------------*/
/* Base Program Source:
Torres-Reyna Panel Data Analysis Fixed & Random Effects 
(using Stata 10.x)
http://www.princeton.edu/~otorres/Panel101.pdf
*/
/*-------------------------------------------------------------------*/
/* Stata Version                                                     */
/*-------------------------------------------------------------------*/

version 12.1
clear
set more off

/*-------------------------------------------------------------------*/
/* Data Source -                                                     */
/*-------------------------------------------------------------------*/
local SAS_Date = "Sept29" /* Date SAS Program Ran to Make Dataset */
local state = "All"
local fyear = "2005"
local lyear = "2012"
local tyears = 8
local root_dir = "C:\Users\Nathanael\Dropbox\"

use `root_dir'MyData\Dissertation\Sept29`model'`state'_`fyear'_`lyear'.dta, clear

/*-------------------------------------------------------------------*/
/* Create Year Dummies                                               */
/*-------------------------------------------------------------------*/
/* Generates dummy variable for each year */
tabulate year, generate(dyear)


/*-------------------------------------------------------------------*/
/* Make a balanced panel                                             */
/*-------------------------------------------------------------------*/
/* Drop variables with missing redemption data */
drop if redamt == . /* drop counties that have missing redemption data */
drop if ben_avg == . /* drop counties that have missing benefit data */

bys fips_county: gen nfips=[_N]

keep if nfips==8 

/*-------------------------------------------------------------------*/
/* Create Dependent Variable -                                       */
/* Difference between Benefits Redeemed and Benefits Distributed     */
/*-------------------------------------------------------------------*/
/* going to try a new dependent variable I am suspecting this will be
normally distributed and centered on zero.
A negative value would mean SNAP participants with the capability to 
shop in another choose a more attractive food shopping environment.
*/

foreach ben_type in "ben_avg" "bea_snap" "usda_prgben" {
	gen diff_`ben_type' = redamt - `ben_type'
	label variable diff_`ben_type' "Difference between Benefits Redeemed and Benefits Distributed (`ben_type'), $"
	format diff_`ben_type' %16.2fc
}

/* Because of extreme values the natural log may look nicer */
/* Thought error - can't take a log of a negative number and values that are zero
gen diff_benefit_ln = log(diff_benefit)
label variable diff_benefit_ln "Difference between Benefits Redeemed and Benefits Distributed, ln($)"
format diff_benefit_ln %4.2fc

histogram diff_benefit_ln, freq normal

summarize diff_benefit_ln
*/

/*-------------------------------------------------------------------*/
/* Summarize Redemption Data by state and year                       */
/*-------------------------------------------------------------------*/
local sum_count = "sum"
foreach Sum_Var of varlist redamt bea_snap ben_avg diff_bea_snap diff_ben_avg {
	local label : variable label `Sum_Var'
	
	foreach yr_type in 2005 2006 2007 2008 2009 2010 2011 2012 {
	eststo clear
	quietly estpost tabstat `Sum_Var' if year == `yr_type', statistics( `sum_count' ) by(statefp) missing
	quietly estimates store Yr_`yr_type'
	}

	eststo clear
	quietly estpost tabstat `Sum_Var', statistics( `sum_count' ) by(statefp) missing
	quietly estimates store AllYears

	esttab Yr_2005 Yr_2006 Yr_2007 Yr_2008 Yr_2009 Yr_2010 Yr_2011 Yr_2012 AllYears using ///
	`"`root_dir'URSC PhD\Dissertation\Statatables\D_Stats_`model'_`time_string'.rtf"' ///
	, append nogap label modelwidth(20) cells("`sum_count'(fmt(%18.2gc))") mtitles(2005 2006 2007 2008 2009 2010 2011 2012 2005-2010) ///
	nonumbers title(SNAP Dollar Statistics: `label' for all states Count of counties or county equivalents) ///
	addnote("Source: USDA, BEA, SAIPES" "model_`model'_`time_string'") ///
	alignment(r)
	eststo clear

	estimates drop Yr_2005 Yr_2006 Yr_2007 Yr_2008 Yr_2009 Yr_2010 Yr_2011 Yr_2012 AllYears  
}

/*
/*-------------------------------------------------------------------*/
/* Generate Descriptive Statistics                                   */
/*-------------------------------------------------------------------*/

eststo clear
estpost tabstat redamt bea_snap occse01 iccse01 unemployed eall, ///
		statistics(min max p50 mean sd count) columns(statistics)
esttab using ///
`"C:\Users\Nathanael\Dropbox\URSC PhD\Dissertation\Statatables\Model_`model'_`time_string'.rtf"' ///
, alignment(r) append nogap label modelwidth(16) cells("count(fmt(%16.0fc)) min(fmt(%16.2fc)) max(fmt(%16.2fc)) p50(fmt(%16.2fc)) mean(fmt(%16.2fc)) sd(fmt(%16.2fc))") noobs ///
title(Basic Descriptive Statistics for Variables for `state' Counties `fyear'-`lyear') ///
nonumbers addnote("Source: Author Calculations, USDA, SAIPES, BLS, BEA, LODES 7" "model_`model'_`time_string'")
eststo clear

eststo clear
estpost tabstat ln_redamt `model1_redvar2' `model1_basevars' `model2_vars' `model2v9_vars' r_2003, ///
		statistics(min max p50 mean sd count) columns(statistics)
esttab using ///
`"C:\Users\Nathanael\Dropbox\URSC PhD\Dissertation\Statatables\Model_`model'_`time_string'.rtf"' ///
, alignment(r) append nogap label modelwidth(10) cells("count(fmt(%16.0fc)) min(fmt(%16.2fc)) max(fmt(%16.2fc)) p50(fmt(%16.2fc)) mean(fmt(%16.2fc)) sd(fmt(%16.2fc))") noobs ///
title(Log Transforms of Descriptive Statistics for Variables for `state' Counties `fyear'-`lyear') ///
nonumbers addnote("Source: Author Calculations, USDA, SAIPES, BLS, BEA, LODES 7" "model_`model'_`time_string'")
eststo clear

/*-------------------------------------------------------------------*/
/* End Log                                                           */
/*-------------------------------------------------------------------*/
*/
log close
