/*-------------------------------------------------------------------*/
/* What Model Are you Running                                        */
/*-------------------------------------------------------------------*/
local model = "2"
/*-------------------------------------------------------------------*/
/* Start Log                                                         */
/*-------------------------------------------------------------------*/
local c_date = c(current_date)
local c_time = c(current_time)
local c_time_date = "`c_date'"+"_" +"`c_time'"
local time_string = subinstr("`c_time_date'", ":", "_", .)
local time_string = subinstr("`time_string'", " ", "_", .)
/* Note to use filenames with a space include `" before and "' after */
log using `"C:\Users\Nathanael\Dropbox\MyPrograms\XiaPeacock\FEMACBP_stata\FEMACBP_`model'_`time_string'.log"', text
/*-------------------------------------------------------------------*/
/*       Program for Exploring CBP with FEMA data                    */
/*          by Nathanael Proctor Rosenheim                           */
/*-------------------------------------------------------------------*/
/*-------------------------------------------------------------------*/
/*Model 2: Version 1                                                 */
/*-------------------------------------------------------------------*/
/* Plan:
Look at how CBP are influenced by FEMA data
	 
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
/* Date Last Updated: 23Aug14                                        */
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

use C:\Users\Nathanael\Dropbox\MyData\XiaoPeacockRDC\L48FEMACBP_2001_2012, clear
describe
summarize e* n1_9* p* t_*

/*-------------------------------------------------------------------*/
/* Create Gulf of Mexico States                                      */
/*-------------------------------------------------------------------*/

generate GOMstate = 0
replace GOMstate = 1 if inlist(state,"TX","LA","MS","AL","FL")
/* Tried adding GA and SC but model did not change much */
/* Going to try to see if have a different intercept for Texas 
makes a difference */


/*-------------------------------------------------------------------*/
/* Create Wind Category                                              */
/*-------------------------------------------------------------------*/
/* Using the Saffir-Simpson Hurricane Wind Scale
http://www.nhc.noaa.gov/aboutsshws.php
*/

generate WindCat = 1
replace WindCat = 2 if max_mph < 157
replace WindCat = 3 if max_mph < 130
replace WindCat = 4 if max_mph < 111
replace WindCat = 5 if max_mph < 96
replace WindCat = 6 if max_mph < 74
replace WindCat = 7 if max_mph < 38
replace WindCat = 8 if max_mph == .

label define WindCat ///
	1 "Category 5" ///
	2 "Category 4" ///
	3 "Category 3" ///
	4 "Category 2" ///
	5 "Category 1" ///
	6 "Tropical Storm" ///
	7 "Tropical Depression" ///
	8 "No Wind Data", add
	
/*-------------------------------------------------------------------*/
/* Summarize Establishments by state and Wind Category               */
/*-------------------------------------------------------------------*/
/* Check Windspeed Data */
drop if GOMstate != 1
tabstat max_mph, statistics( mean ) by(WindCat)

foreach NAICS_var of varlist est44 est72 est23{
	local label : variable label `NAICS_var'
	eststo clear
	quietly estpost tabstat `NAICS_var' if year == 2002 & GOMstate == 1, statistics( sum ) by(WindCat)
	quietly estimates store AllStates

	foreach st_type in AL FL LA MS TX{
		eststo clear
		quietly estpost tabstat `NAICS_var' if year == 2002 & state == "`st_type'", statistics( sum ) by(WindCat)
		quietly estimates store `st_type'	
	}
	esttab AllStates AL FL LA MS TX using ///
	`"C:\Users\Nathanael\Dropbox\TXCRDC\XiaPeacockProposal\STATAModelTables\FEMACBP_`model'_`time_string'.rtf"' ///
	, append nogap label modelwidth(10) cells("sum(fmt(%12.0gc))") mtitles(Total AL FL LA MS TX) ///
	title(Establishment Statistics: 2002 `label' in Gulf of Mexico States.) ///
	nonumbers addnote("Establishment counts represent the two digit NAICS code for `label'." "Source: County Business Patterns, NOAA Wind Speed Data")
	eststo clear
	estimates drop AllStates AL FL LA MS TX
}

/*-------------------------------------------------------------------*/
/* Summarize Population by state and Wind Category                   */
/*-------------------------------------------------------------------*/

foreach year_type in 2002 2010{
eststo clear
quietly estpost tabstat t_pop if year == `year_type' & GOMstate == 1, statistics( sum ) by(WindCat)
quietly estimates store AllStates

foreach st_type in AL FL LA MS TX{
	eststo clear
	quietly estpost tabstat t_pop if year == `year_type' & state == "`st_type'", statistics( sum ) by(WindCat)
	quietly estimates store `st_type'
}
	
esttab AllStates AL FL LA MS TX using ///
`"C:\Users\Nathanael\Dropbox\TXCRDC\XiaPeacockProposal\STATAModelTables\FEMACBP_`model'_`time_string'.rtf"' ///
, append nogap label modelwidth(20) cells("sum(fmt(%12.0gc))") mtitles(Total AL FL LA MS TX) ///
title(Population estimates `year_type' in Gulf of Mexico States.) ///
nonumbers addnote("Source: Author's calculations form Population Census")
eststo clear
estimates drop AllStates AL FL LA MS TX
}
/*-------------------------------------------------------------------*/
/* End Log                                                           */
/*-------------------------------------------------------------------*/
*/
log close
exit

