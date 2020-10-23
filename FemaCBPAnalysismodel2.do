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
/* Tried adding GA and SC but model did not change much */
/* Going to try to see if have a different intercept for Texas 
makes a difference */

generate GOMstate2 = 0
replace GOMstate2 = 1 if state == "TX"

/* Matrix size needs to be large enough for states */
set matsize 10000
/*-------------------------------------------------------------------*/
/* Percent of small establishements                                  */
/*-------------------------------------------------------------------*/
/* It looks like the model for predicting the number of establishements
in retail is good but what might make a difference is the number of 
stores with less than 9 employees.
Will add a variable that represents the percentage of total establishments
with fewer than 10 employees. This should help the model and increase the 
overall number of establishments in areas with smaller stores
*/

generate ratio_n1_9 = n1_944 / est44

/*-------------------------------------------------------------------*/
/* Drop Variables that include other variables                       */
/*-------------------------------------------------------------------*/

drop dn_percapitaiaih dn_percapitatotal_pagrants duration_fs
/// sum of dn_percapitaha and dn_percapitaotheria
/// sum of dn_percapitapacatab dn_percapitapacatcg
/// Including both sum_ for each type and duration for each type is redundant
/// fsduration is always 0 - designation used before time period

rename sum_disasternum dst_count
/// need to rename sum by disaster type so that I can use sum_*

/*-------------------------------------------------------------------*/
/* Shorten Variable Labels to make tables nice                       */
/*-------------------------------------------------------------------*/
label variable duration_dr "Major Disaster (Days)"
label variable duration_em "Emergency (Days)"
label variable duration_fm "Fire Management (Days)"
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

gen L1t_pop = L1.t_pop
gen L2t_pop = L2.t_pop
generate lnt_pop = log(t_pop)
gen lag1lnt_pop = log(L1t_pop)
gen lag2lnt_pop = log(L2t_pop)

/* interested in how percent hispanic and percent elderly influences population
*/

gen prct_hspnc1 = t_hspnc1 / t_pop
label variable prct_hspnc1 "Percent Hispanic"
summarize prct_hspnc1

gen prct_age65p = t_age65p / t_pop
label variable prct_age65p "Percent 65+"
summarize prct_age65p

/* unemployment rate may not be the best option, instead of population
I could do the log of employed */

generate lnemployed = log(employed)
label variable lnemployed "Log of persons employed"

gen lag2lnemployed = L2.lnemployed

/* instead of percent poverty I could do log of estimated poverty */
generate lnpoverty = log(eall)
gen lag1poverty = log(L.eall)

generate lnestall = log(estall)
generate lnest44 = log(est44) 		/* Retail Trade */
generate lnest447 = log(est447) 	/* Gasoline Stations */
generate totaldvmt = intrstdvmt + otherdvmt
generate ln_totaldvmt = log(totaldvmt)

generate lnt_age0_4 = log(t_age0_4)
generate lnt_age5_14 = log(t_age5_14)
generate lnt_age15_29 = log(t_age15_29)
generate lnt_age65p = log(t_age65p)

/* it might be possible that disaster exposure can be captured by percapita spending */
gen ln_percapitapa_ttloblg = log(percapitapa_ttloblg)

// generate ln_intrstdvmt = log(intrstdvmt) if intrstdvmt != 0 /*DVMT from on interstate*/

/* need to figure out how to handle counties with no interstate

generate ln_intrstdvmt = 0 if intrstdvmt == 0 /*DVMT from on interstate*/
generate ln_otherdvmt = log(otherdvmt) if otherdvmt != 0 /*DVMT from on other major roads*/
generate ln_otherdvmt = 0 if otherdvmt == 0 /*DVMT from on other major roads*/
*/
/*-------------------------------------------------------------------*/
/* Set Explantory Variables                                          */
/*-------------------------------------------------------------------*/

local expvars2_base m_2003 a_2003 urate pall minc ratio_n1_9

local expvars3_base m_2003 a_2003 lnemployed lnpoverty minc ratio_n1_9

local expvars lnt_pop
local expvars3 lnemployed lnpoverty m_2003 a_2003 ln_totaldvmt
/* 
expvars3 consistently underestimates the number of establishments
only a few overestimations, mostly resort towns
going to add in ln of retired and children to see if that reduces underestimation
*/
/* Employed is from the BLS and they did not report New Orleans area in 2005, 2006
*/
local expvars4 lnemployed lnpoverty m_2003 a_2003 ln_totaldvmt lnt_age*
/* without missing values from BLS
*/
local expvars5 lnt_pop m_2003 a_2003 ln_totaldvmt

/* for fixed effects model m_2003 a_2003 are constants and therefore must be dropped */
local expvars6 lnt_pop ln_totaldvmt urate pall

/* urate and pall results were not significant:
---------------------------------------------------------------------------------
        lnest44 |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
----------------+----------------------------------------------------------------
        lnt_pop |   .8297998   .0189956    43.68   0.000     .7925557    .8670438
   ln_totaldvmt |     .01658    .009633     1.72   0.085     -.002307     .035467
          urate |   .0013315   .0010238     1.30   0.194    -.0006759    .0033388
           pall |   .0007745   .0006109     1.27   0.205    -.0004232    .0019723
*/
/* dvmt is not consistent in 2009 and 2010 */
local expvars7 lnt_pop

/* trying to add in disaster data to see if it makes a difference */
*local expvars8 lnt_pop percapitapa_ttloblg
/* actually the above does not work becaus the ln of 0 is undefined...
all of the counties with no percapita spending are dropped from the model!
*/
local expvars8 lnt_pop percapitapa_ttloblg

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

/* running the fixed effect on the entire country seems to cause problems
I think it is because it tries to create an intercept for each county
*/

drop if GOMstate != 1

/* the model does not work well for counties with few people or few establishments
*/
regress lnest44 `expvars6' if GOMstate == 1 & t_pop < 15000 & est44 < 10

drop if t_pop < 15000
drop if est44 < 10

regress lnestall `expvars6' `expvars2_base' i.year
predict double resid, residuals
summarize resid


/*test using ln of employed and poverty */

regress lnest44 `expvars6' i.year if GOMstate == 1 & t_pop > 15000 & est44 > 10
// regress lnest44 `expvars' `expvars2_base'
predict double yhat
predict double resid44, residuals
summarize resid44

gen yhat_est44 = exp(yhat) // inverse of the ln should be in terms of establishments
gen resid_est44 = est44 - yhat_est44
gen prct_off44 = resid_est44 / est44
summarize prct_off44

gen lag1est44 = L1.est44 
gen lag1t_pop = L1.t_pop 
gen lag2t_pop = L2.t_pop 

order county_name state fips_county year lag2t_pop lag1t_pop t_pop lag1est44 est44 yhat_est44 prct_off44 resid_est44 `expvars' `expvars3_base'

/* look at difference in population for metro, adjacent and not adjenct counties */
/*
graph twoway (bar t_pop year if m_2003 == 1, yaxis(2)) ///
			(bar t_pop year if a_2003 == 0 & m_2003 == 0, yaxis(1)) ///
			(bar t_pop year if a_2003 == 1, yaxis(3))
			///
			(bar t_pop year if a_2003 == 1 ) ///
			(bar t_pop year)

/* Want to see the trend in establishments over time */
* tabstat est447, by(year) stat(sum)
/* Graph shows population on one axis and gas stations on a second axis
easy to see that as population has increased over time the number 
of gas stations has decreased */
* graph twoway (bar t_pop year, yaxis(2)) (bar est447 year, yaxis(1))

*regress lnest447 lnt_pop if year == 2001 & m_2003 == 1

graph twoway (scatter lnest44 lnt_pop if GOMstate == 1 & m_2003 == 1 & t_pop > 20000 & est44 > 10) ///
			(scatter lnest44 lnt_pop if GOMstate == 1 & a_2003 == 0 & m_2003 == 0 & t_pop > 20000 & est44 > 10) ///
			(scatter lnest44 lnt_pop if GOMstate == 1 & a_2003 == 1 & t_pop > 20000 & est44 > 10) ///
			(lfit lnest44 lnt_pop if GOMstate == 1 & a_2003 == 0 & m_2003 == 0 & t_pop > 20000 & est44 > 10) ///
			(lfit lnest44 lnt_pop if GOMstate == 1 & m_2003 == 1 & t_pop > 20000 & est44 > 10) ///
			(lfit lnest44 lnt_pop if GOMstate == 0 & m_2003 == 1 & t_pop > 20000 & est44 > 10)
*/
*-------------------------------------------------------------------*/
/* Setting panel data                                                */
/*-------------------------------------------------------------------*/
/* Comment:
The Stata command to run fixed effects is xtreg
Before using xtreg you need to set Stata to handle panel data by using
the command xtset.
In this case “county” represents the entities or panels (i) and “year”
Represents the time variable (t).
*/
sort panel year
xtset panel year			

/* running the fixed effect on the entire country seems to cause problems
I think it is because it tries to create an intercept for each county
*/

drop if GOMstate != 1
drop if est44 < 10
/*-------------------------------------------------------------------*/
/* Fixed effects: n entity-specific intercepts using xtreg           */
/*-------------------------------------------------------------------*/
/* Comment:
Comparing the fixed effects using dummies with xtreg we get the same results.
*/

xtreg lnest44 `expvars7' i.year, fe

* store estimates for Hausman Test
estimates store fixed
/* Accoring to: https://kb.iu.edu/d/auur
This model produces correct parameter estimates without creating 
dummy variables; however, due to the larger degrees of freedom, its 
standard errors and, consequently, R-squared statistic are incorrect. 

areg produce correct parameter estimates, standard errors, and R-squared statistics.
*/
areg lnest44 `expvars7' i.year, absorb(fips_county)

xi: regress lnest44 `expvars7' i.fips_county i.year 
predict double residxi, residuals
predict double yhatxi
summarize residxi
gen yhatxi_est44 = exp(yhatxi) // inverse of the ln should be in terms of establishments
gen residxi_est44 = est44 - yhatxi_est44
gen prct_offxi44 = residxi_est44 / est44
summarize prct_offxi44
summarize prct_off44

areg lnest44 `expvars8' i.year, absorb(fips_county)
xi: regress lnest44 `expvars8' i.fips_county i.year 
predict double resid8xi, residuals
predict double yhat8xi
summarize resid8xi
gen yhat8xi_est44 = exp(yhat8xi) // inverse of the ln should be in terms of establishments
gen resid8xi_est44 = est44 - yhat8xi_est44
gen prct_off8xi44 = resid8xi_est44 / est44
summarize prct_offxi44
summarize prct_off8xi44
summarize prct_off44

gen diff_prct = prct_off8xi44 - prct_offxi44


order county_name state fips_county year percapitapa_ttloblg diff_prct prct_off8xi44 prct_offxi44 t_pop est44
sort panel year
/* 
Based on the analysis above it is hard to see how disasters are impacting
counties.
I am wondering now if what is happening is that disasters are impacting
population - both in terms of loss and growth.
The effect on population is what is effecting the number of establishements.
It might be that the disasters are causing some cities to lose population 
and recover slower. Or it could be that disasters cause slower population growth.

To look into this I think I can predict expected population for a county
based on the previous years population.
*/
drop if m_2003 == 0
xi: regress lnt_pop lag1lnt_pop prct_hspnc1 i.stfips i.year i.fips_county 
predict double yhatlnt_pop
gen yhatt_pop = exp(yhatlnt_pop) // inverse of the ln should be in terms of persons
gen residt_pop = t_pop - yhatt_pop
gen prct_offt_pop = residt_pop / t_pop

order county_name state fips_county year percapitapa_ttloblg t_pop yhatt_pop m_2003 prct_offt_pop
sort panel year

/* this seems to work but what I think I want to do is make the prediction without
the disaster counties and see if i can predict the all counties population
First see which counties have the highest mean money distributions
*/

/*-------------------------------------------------------------------*/
/* Install Center Moduel From SSC                                    */
/*-------------------------------------------------------------------*/

ssc install center, replace

/*-------------------------------------------------------------------*/
/* Add mean percapita values by County                               */
/*-------------------------------------------------------------------*/
bysort fips_county: center percapitapa_ttloblg, replace
bysort fips_county: center percapitapa_ttloblg, meansave(m_) replace
order county_name state fips_county year percapitapa_ttloblg c_percapitapa_ttloblg ///
m_percapitapa_ttloblg t_pop yhatt_pop m_2003 prct_offt_pop


/*-------------------------------------------------------------------*/
/* Predict population without disasters                              */
/*-------------------------------------------------------------------*/

/*-------------------------------------------------------------------*/
/*  Create variable that is equal to the first year obseravtion      */
/*-------------------------------------------------------------------*/
sort panel year
generate t_pop2001 = t_pop if year == 2001
bysort fips_county: replace t_pop2001 = t_pop2001[1]
generate lnt_pop2001 = log(t_pop2001)

/* poverty seems to mess up the model... not sure why */
generate  pall2001 = pall if year == 2001
bysort fips_county: replace pall2001 = pall2001[1]

generate prct_age65p2001 = prct_age65p if year == 2001
bysort fips_county: replace prct_age65p2001 = prct_age65p2001[1]

generate  prct_hspnc12001 = prct_hspnc1 if year == 2001
bysort fips_county: replace prct_hspnc12001 = prct_hspnc12001[1]

xi: regress lnt_pop lnt_pop2001 prct_hspnc12001 i.year if year > 2001
predict double yhatlnt_pop01 if year > 2001
gen yhatt_pop01 = exp(yhatlnt_pop01) // inverse of the ln should be in terms of persons
gen residt_pop01 = t_pop - yhatt_pop01
gen prct_offt_pop01 = residt_pop01 / t_pop

order county_name state fips_county year percapitapa_ttloblg t_pop ///
yhatt_pop yhatt_pop01 est44 emp44 yhatxi_est44 ///
m_2003 prct_offt_pop prct_offt_pop01 ///
c_percapitapa_ttloblg m_percapitapa_ttloblg t_pop yhatt_pop m_2003 prct_offt_pop

/* compare growth in counties with and without major disasters 
graph twoway (bar yhatt_pop01 year if m_percapitapa_ttloblg > 100 & state == "TX", yaxis(1)) ///
			(bar t_pop year if m_percapitapa_ttloblg > 100 & state == "TX", yaxis(1))

graph twoway (bar yhatt_pop01 year if m_percapitapa_ttloblg > 100 & state == "LA", yaxis(1)) ///
			(bar t_pop year if m_percapitapa_ttloblg > 100 & state == "LA", yaxis(1)) 

graph twoway (bar yhatt_pop01 year if state == "FL", yaxis(1)) ///
			(bar t_pop year if state == "FL", yaxis(1))
			
graph twoway (bar yhatt_pop01 year if m_percapitapa_ttloblg > 100 & state == "MS", yaxis(1)) ///
			(bar t_pop year if m_percapitapa_ttloblg > 100 & state == "MS", yaxis(1))
			
graph twoway (bar yhatt_pop01 year if state == "TX", yaxis(1)) ///
			(bar t_pop year if state == "TX", yaxis(1))

graph twoway (bar yhatt_pop01 year if m_percapitapa_ttloblg > 100 & state == "FL", yaxis(1)) ///
			(bar t_pop year if m_percapitapa_ttloblg > 100 & state == "FL", yaxis(1))
			
graph twoway (bar t_pop year if state == "FL", yaxis(1)) ///
			(bar t_pop year if state == "LA", yaxis(1))
*/
/*-------------------------------------------------------------------*/
/* Summarize by state and disaster                                   */
/*-------------------------------------------------------------------*/
tabstat est44 if year == 2002 & GOMstate == 1, statistics( sum ) by(state)
tabstat est44 if year == 2002 & GOMstate == 1 & m_percapitapa_ttloblg > 150 , statistics( sum ) by(state)

/*-------------------------------------------------------------------*/
/* End Log                                                           */
/*-------------------------------------------------------------------*/
*/
log close
exit

