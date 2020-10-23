/*-------------------------------------------------------------------*/
/* What Model Are you Running                                        */
/*-------------------------------------------------------------------*/
local model = "1"
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
/*Model 1: Version 1                                                 */
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
/* Date Last Updated: 3Aug14                                         */
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
/*-------------------------------------------------------------------*/
/* Drop Variables that include other variables                       */
/*-------------------------------------------------------------------*/

drop dn_percapitaiaih dn_percapitatotal_pagrants fsduration
/// sum of dn_percapitaha and dn_percapitaotheria
/// sum of dn_percapitapacatab dn_percapitapacatcg
/// Including both sum_ for each type and duration for each type is redundant
/// fsduration is always 0 - designation used before time period

rename sum_disasternum dst_count
/// need to rename sum by disaster type so that I can use sum_*

/*-------------------------------------------------------------------*/
/* Shorten Variable Labels to make tables nice                       */
/*-------------------------------------------------------------------*/
label variable drduration "Major Disaster (Days)"
label variable emduration "Emergency (Days)"
label variable fmduration "Fire Management (Days)"
label variable percapitapa_ttloblg "PA Percapita ($/County)"
label variable dn_percapitaha "HA Percapita ($/Disaster)"
label variable dn_percapitaotheria "Other IA Percapita ($/Disaster)"
label variable dn_percapitapacatab "PA Emergency Work Percapita ($/Disaster)"
label variable dn_percapitapacatcg "PA Permanent Work Percapita ($/Disaster)"

/*-------------------------------------------------------------------*/
/* Setting Time Series Data                                          */
/*-------------------------------------------------------------------*/
/* Comment:
The Stata command to run timeseries is tsset
Before using tsset you need to set Stata to handle timeseries data by using
the command tsset.
In this case “county” represents the entities or panels (i) and “year”
Represents the time variable (t). */

///generate dateyear = real(year)
generate panel = real(fips_county)
sort panel year

tsset panel year, yearly

/*-------------------------------------------------------------------*/
/* Create Natural Logs of Variables                                  */
/*-------------------------------------------------------------------*/
/* See Bettencourt et al 2007 Growth, Innovation, scaling, and the pace of life in cities
 Natural log helps clean up variable differences and fits log scale of population
*/

generate lnt_pop = log(t_pop)
generate lnestall = log(estall)
generate lnest44 = log(est44) 		/* Retail Trade */
generate lnest447 = log(est447) 	/* Gasoline Stations */
generate totaldvmt = intrstdvmt + otherdvmt
generate ln_totaldvmt = log(totaldvmt)
// generate ln_intrstdvmt = log(intrstdvmt) if intrstdvmt != 0 /*DVMT from on interstate*/

/* need to figure out how to handle counties with no interstate

generate ln_intrstdvmt = 0 if intrstdvmt == 0 /*DVMT from on interstate*/
generate ln_otherdvmt = log(otherdvmt) if otherdvmt != 0 /*DVMT from on other major roads*/
generate ln_otherdvmt = 0 if otherdvmt == 0 /*DVMT from on other major roads*/
*/
/*-------------------------------------------------------------------*/
/* Set Explantory Variables                                          */
/*-------------------------------------------------------------------*/

local expvars_base m_1993 m_2003 m_2013 a_1993 a_2003 a_2013 urate pall
/* 2003 seems to be an issue might be that there is not enough variation 
between 2003 and other years meaning that there is a strong correlation
*/
local expvars2_base m_1993 m_2013 a_1993 a_2013 urate pall 
local expvars lnt_pop
local expvars3 ln_totaldvmt
/*-------------------------------------------------------------------*/
/* Set Explantory Variables - Differencing                           */
/*-------------------------------------------------------------------*/
/* Looks at difference between Year T and T-1 for the county */
/// local Dexpvars D.t_pop

/*-------------------------------------------------------------------*/
/* Regresion Analysis                                                */
/*-------------------------------------------------------------------*/
/*
Include i.year to control for time trends
Controls for overall trend in data for fewer gas stations
*/

regress lnestall `expvars' `expvars2_base' i.year
predict double resid, residuals
summarize resid
sort resid

regress lnest447 `expvars' `expvars2_base' i.year if lnest447 > 0 // some counties only have 1 gas station
predict double yhat
predict double resid447, residuals
summarize resid447

gen yhat_est447 = exp(yhat) // inverse of the ln should be in terms of establishments
gen resid_est447 = est447 - yhat_est447

sort resid_est447

order county_name state fips_county year t_pop est447 yhat_est447 resid_est447 `expvars' `expvars2_base'

/*----------------------------
Look at Gas stations by DVMT
-----------------------------*/
regress lnest447 `expvars3' `expvars2_base' i.year if lnest447 > 0 // some counties only have 1 gas station
predict double yhat2
predict double resid2_447, residuals
summarize resid2_447

gen yhat2_est447 = exp(yhat2) // inverse of the ln should be in terms of establishments
gen resid2_est447 = est447 - yhat2_est447

sort resid2_est447

order county_name state fips_county year t_pop est447 yhat_est447 resid_est447 yhat2_est447 resid2_est447 `expvars' `expvars3' `expvars2_base' 

/*
Notes:
Looking at residuals for gas stations
Fort Benning Georgia - might need to drop or control for military bases
Counties with low automobile use are also an issue
- New York, San Fransico... the model significantly over predicts


/* Want to see the trend in establishments over time */
* tabstat est447, by(year) stat(sum)
/* Graph shows population on one axis and gas stations on a second axis
easy to see that as population has increased over time the number 
of gas stations has decreased */
* graph twoway (bar t_pop year, yaxis(2)) (bar est447 year, yaxis(1))

*regress lnest447 lnt_pop if year == 2001 & m_2003 == 1

*graph twoway (scatter lnest447 lnt_pop) (lfitci lnest447 lnt_pop) 

/*-------------------------------------------------------------------*/
/* End Log                                                           */
/*-------------------------------------------------------------------*/
*/
log close
exit
/*-------------------------------------------------------------------*/
/* Working on below                                                  */
/*-------------------------------------------------------------------*/
/*-------------------------------------------------------------------*/
/* Factor Analysis                                                   */
/*-------------------------------------------------------------------*/
/*
factor `expvars6', pcf
rotate
*/
/* Results


/*-------------------------------------------------------------------*/
/* Time Series: Look at Lag and Difference                           */
/*-------------------------------------------------------------------*/
foreach timevar of varlist `expvars' {
				local label : variable label `timevar'
				generate Diff_`timevar' = D.`timevar'
				label variable Diff_`timevar' `"Diff `label'"'

}
eststo clear
estpost summarize Diff_*
esttab using ///
`"C:\Users\Nathanael\Dropbox\TXCRDC\XiaPeacockProposal\STATAModelTables\GVPUFmodel_`model'_`time_string'.rtf"' ///
, b(a3) append nogap label modelwidth(10) cells("count mean sd min max") noobs ///
title(Summary of CBP Explanatory Variables) ///
nonumbers addnote("Source: CBP")
eststo clear
foreach timevar of varlist `expvars' {
				local label : variable label `timevar'
				generate Lag_`timevar' = L.`timevar'
				label variable Lag_`timevar' `"Lag `label'"'
}
estpost summarize Lag_*
esttab using ///
`"C:\Users\Nathanael\Dropbox\TXCRDC\XiaPeacockProposal\STATAModelTables\GVPUFmodel_`model'_`time_string'.rtf"' ///
, b(a3) append nogap label modelwidth(10) cells("count mean sd min max") noobs ///
title(Summary of FEMA Disaster Explanatory Variables) ///
nonumbers addnote("Source: FEMA")
eststo clear
/*
foreach NAICS of varlist dp_per* totalcosts* slcu* r_edv*{
				/* 
				histogram `NAICS', freq normal ///
					name(hist`NAICS', replace) nodraw
				histogram `NAICS'_diff, freq normal ///
					name(hist`NAICS'_diff, replace) nodraw
				graph combine hist`NAICS' hist`NAICS'_diff, cols(2) title("Comparing Variable and Differencing Distribution of `label'", size(small)), nodraw
				graph rename combined_`NAICS', replace
				graph export ///
				`"C:\Users\Nathanael\Dropbox\TXCRDC\XiaPeacockProposal\STATAModelGraphs\hist`NAICS'_diff_`model'_`time_string'.png"'
				*/
				eststo clear
				/// eststo: quietly regress D.`NAICS' `Dexpvars'
				/// eststo: quietly regress D.`NAICS' `Dexpvars2' if hurricane > 0
				eststo: quietly regress D.`NAICS' `Dexpvars6' if hurricane > 0
				eststo: quietly regress D.`NAICS' `Dexpvars2' `Dexpvars7'  if hurricane > 0
				eststo: quietly regress D.`NAICS' `Dexpvars2' `Dexpvars9'  if hurricane > 0
				///eststo: quietly regress D.`NAICS' `Dexpvars2' `Dexpvars8' if hurricane > 0 did worse than dexpvars7
				///eststo: quietly regress D.`NAICS' `Dexpvars4'
				///eststo: quietly regress D.`NAICS' `Dexpvars5'
				if e(r2_a) > 0.1 {
				local label : variable label `NAICS'
				generate `NAICS'_diff = D.`NAICS'
				label variable `NAICS'_diff `"Diff `label'"'
				estpost summarize `NAICS'_diff
				
				esttab using ///
				`"C:\Users\Nathanael\Dropbox\TXCRDC\XiaPeacockProposal\STATAModelTables\GVPUFmodel_`model'_`time_string'.rtf"' ///
				, se ar2 append nogap onecell label modelwidth(10) ///
				title(Hurricane Counties Differencing from previous year Medicare fee-for-service beneficiaries `label') ///
				nonumbers mtitles("Model A" "Model B" "Model C" "Model D" "Model E") ///
				addnote("Source: CBP") 
				eststo clear 
				
				esttab using ///
				`"C:\Users\Nathanael\Dropbox\TXCRDC\XiaPeacockProposal\STATAModelTables\GVPUFmodel_`model'_`time_string'.rtf"' ///
				, append nogap label modelwidth(10) cells("count mean sd min max") noobs ///
				title(Summary of Difference In `label') ///
				nonumbers addnote("Source: CBP")
				eststo clear
				}
				eststo clear
}

*/
/*-------------------------------------------------------------------*/
/* Generate new variable that describes disaster type                */
/*-------------------------------------------------------------------*/

gen disastercat = ""
gen lagdstrcat = ""
label variable disastercat  "Type of Disaster"
label variable disastercat  "Type of Disaster over 2 years"
replace disastercat = "NoDisaster" if dst_count == 0
replace lagdstrcat = "NoDisaster" if dst_count == 0 & L.dst_count == 0

foreach it_type of varlist it_:{
	local label : variable label `it_type'
	foreach dec_type in em dr{
		replace disastercat = "`label'_`dec_type'" if dst_count > 0 & sum_`dec_type' > 0 & `it_type' > 0
		replace lagdstrcat = "`label'_`dec_type'" if dst_count > 0 & sum_`dec_type' > 0 & `it_type' > 0 & L.dst_count > 0 & L.sum_`dec_type' > 0 & L.`it_type' > 0
		}
}
/*-------------------------------------------------------------------*/
/* Set Explantory Variables - Differencing using Generate Diff Vars  */
/*-------------------------------------------------------------------*/
/* Had No Obs error come up when using D. */
local 

* Define Adjusted R-Square Threshold
local arthreshold = 0.05
local obsthreshold = 100

/*-------------------------------------------------------------------*/
/* Produce Output of Regression                                      */
/*-------------------------------------------------------------------*/
/* Note Removed Fire from study */
foreach dep_var of varlist dp_per* totalcosts* slcu* r_edv*{
	generate `dep_var'_diff = D.`dep_var'
	local label : variable label `dep_var'
	label variable `dep_var'_diff `"Diff `label'"'
	eststo clear
	eststo: quietly regress D.`dep_var' `Diff_CMS' `Dexpvars10' /* base model */
	local base_ar = e(r2_a)
	eststo: quietly regress D.`dep_var' `Diff_CMS' `Dexpvars10' if disastercat == "NoDisaster" /*No Disasters in current year*/
	eststo: quietly regress D.`dep_var' `Diff_CMS' `Dexpvars10' if lagdstrcat == "NoDisaster" /*No Disasters for 2 years */
	local i = 0
	local i2 = 0
	local m_titles ""
	foreach it_type of varlist it_flood it_severeicestorm it_severestorm it_hurricane it_other{
		local itsig = 0
		local it_label : variable label `it_type'
		foreach dec_type in dr em {
			quietly count if disastercat == "`it_label'_`dec_type'" & `dep_var'_diff > 0 & !missing(`dep_var'_diff, Diff_avgage, Diff_perfemale, Diff_peraa, Diff_perhis)
			if r(N) > `obsthreshold'{
				quietly regress D.`dep_var' `Diff_CMS' if disastercat == "`it_label'_`dec_type'" 
				/* base model by disaster, this is to see if the smaller sample size for the disaster is differnt from the base*/
				/* This makes sure that the disaster county increase in AR is not due to changes in CMS data */
				if e(r2_a) - `base_ar' < 0.05 { 
					quietly regress D.`dep_var' `Diff_CMS' `Dexpvars10' if disastercat == "`it_label'_`dec_type'"
					if e(r2_a) - `base_ar' > `arthreshold' {
						eststo: quietly regress D.`dep_var' `Diff_CMS' `Dexpvars10' if disastercat == "`it_label'_`dec_type'"
					local i = `i' + 1
					local itdec_label `" "`it_label'_`dec_type'""'
					local m_titles `"`m_titles' `itdec_label'"'
					}
				}
			}
			quietly count if lagdstrcat == "`it_label'_`dec_type'" & `dep_var'_diff > 0 & !missing(`dep_var'_diff, Diff_avgage, Diff_perfemale, Diff_peraa, Diff_perhis)
			if r(N) > `obsthreshold'{
				quietly regress D.`dep_var' `Diff_CMS' if lagdstrcat == "`it_label'_`dec_type'" 
				/* base model by disaster, this is to see if the smaller sample size for the disaster is differnt from the base*/
				local base_ar2 = e(r2_a)
				/* This makes sure that the disaster county increase in AR is not due to changes in CMS data */
				if e(r2_a) - `base_ar' < 0.05 { 
					quietly regress D.`dep_var' `Diff_CMS' `Dexpvars10' if lagdstrcat == "`it_label'_`dec_type'"
					if e(r2_a) - `base_ar' > `arthreshold' {
						eststo: quietly regress D.`dep_var' `Diff_CMS' `Dexpvars10' if lagdstrcat == "`it_label'_`dec_type'"
					local i2 = `i2' + 1
					local itdec_label `" "`it_label'_`dec_type'2yrs""'
					local m_titles `"`m_titles' `itdec_label'"'
					}
				}
			}
		}
	}
	local itsig = `itsig' + `i2' + `i'
	if `i' > 0{
		esttab using ///
		`"C:\Users\Nathanael\Dropbox\TXCRDC\XiaPeacockProposal\STATAModelTables\GVPUFmodel_`model'_`time_string'.rtf"' ///
		, ar2 append nogap label modelwidth(10) wide ///
		title(Adjusted R-2 > `arthreshold' from base Counties Differencing from previous year Medicare fee-for-service beneficiaries `label') ///
		nonumbers mtitles(All NoDisaster NoDiaster2yrs `m_titles') ///
		addnote("Source: CBP, FEMA" "Incident Types: `m_titles'")
		eststo clear 
	
		estpost tabstat `dep_var'_diff, by(disastercat) statistics(mean max)
		esttab using ///
		`"C:\Users\Nathanael\Dropbox\TXCRDC\XiaPeacockProposal\STATAModelTables\GVPUFmodel_`model'_`time_string'.rtf"' ///
		, append nogap label modelwidth(10) main(mean) ///nostar unstack nonote wide nonumbers
		title(Summary of Difference In Means of `label' by major disasters declared) ///
		 addnote("Source: CBP, FEMA")
		eststo clear
	}
	if `i2' > 0{
	estpost tabstat `dep_var'_diff, by(lagdstrcat) statistics(mean max)
	esttab using ///
	`"C:\Users\Nathanael\Dropbox\TXCRDC\XiaPeacockProposal\STATAModelTables\GVPUFmodel_`model'_`time_string'.rtf"' ///
	, append nogap label modelwidth(10) main(mean) aux(se) nostar unstack nonote ///
	title(Summary of Difference In Means of `label' by major disasters declared 2 years in a row) ///
	wide nonumbers addnote("Source: CBP, FEMA")
	eststo clear
	}
	display `itsig'
}

/*-------------------------------------------------------------------*/
/* End Log                                                           */
/*-------------------------------------------------------------------*/
*/
log close
