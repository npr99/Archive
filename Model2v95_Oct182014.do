/*-------------------------------------------------------------------*/
/* What Model Are you Running                                        */
/*-------------------------------------------------------------------*/
local model = "2v99"
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
/*       with SNAP Data from 2005-2011. For Dissertation Research    */
/*       Model 2 – In-county SNAP retail opportunities               */
/*          by Nathanael Proctor Rosenheim                           */
/*-------------------------------------------------------------------*/
/*-------------------------------------------------------------------*/
/*Model 2: Version 2.95                                              */
/*-------------------------------------------------------------------*/
/* Plan:
      Adding total population made a significant impact on the model
	  Many of the variables are correlated with population so I am
	  looking at ways to caputre this in the model.
	  Adding the USDA timeseries data on number of participants in
	  county.
	  
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
/* Date Last Updated: 18Oct14                                        */
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
/* Data Source - Output from SAS                                     */
/*-------------------------------------------------------------------*/
local state = "TX"
local fyear = "2005"
local lyear = "2011"
local tyears = 7

use C:\Users\Nathanael\Dropbox\MyData\Dissertation\Oct18Model2v9`state'_`fyear'_`lyear'.dta, clear

/*-------------------------------------------------------------------*/
/* Check BEA average benefit numbers                                 */
/*-------------------------------------------------------------------*/
/* For some counties BEA and USDA values are off significantly
to adjust for this I will drop counties where the average monthly benefit
is more than 2 standard deviations from the mean.
This will clear out some of the low population counties that BEA may 
have incorrectly imputed the distribution amounts
*/

gen avgben_prgnum = bea_snap / usda_prgnum
label variable avgben_prgnum "Average Annual Benefit, ($/SNAP Participant)"

local test_var avgben_prgnum
/*Find the mean */
egen mean_`test_var' = mean(`test_var')

/*Find the SD */
egen sd_`test_var' = sd(`test_var')

/*Make dummy for values within 2 SD */
gen sd2_`test_var'  = 1 if /// 
	(`test_var' >= mean_`test_var' - (2*sd_`test_var')) & ///
	(`test_var' <= mean_`test_var'+ (2*sd_`test_var'))

/* drop mean and sd variables */
drop mean_`test_var' sd_`test_var' 

/* drop values outside of 2 sd from testvar */
drop if sd2_`test_var' == . 

/* drop dummy variable */
drop sd2_`test_var'

/*-------------------------------------------------------------------*/
/* Create Year Dummies                                               */
/*-------------------------------------------------------------------*/
/* Generates dummy variable for each year */
tabulate year, generate(dyear)

/*-------------------------------------------------------------------*/
/* Make a balanced panel                                             */
/*-------------------------------------------------------------------*/
/* Drop variables with missing redemption data */
drop if redamt == .
bys fips_county: gen nfips=[_N]

keep if nfips==`tyears' 

/*-------------------------------------------------------------------*/
/* Determine 95% CI of Avg Annual Benefit for context                */
/*-------------------------------------------------------------------*/

quietly ci avgben_prgnum
/* Save upper and lower CI numbers */
local lb_avgben  = string(r(lb),"%8.2fc")
local ub_avgben  = string(r(ub),"%8.2fc")

quietly summarize avgben_prgnum
/* Save standard deviation */
local sd_avgben  = string(r(sd),"%8.2fc")

/*-------------------------------------------------------------------*/
/* Create Dependent Variable - Within County Redemptions             */
/*-------------------------------------------------------------------*/
/* Diff_SNAP represents the difference between SNAP benefits redeemed within a county 
and the total within-county benefit distributions for county i and in year t

There are 2 sources for in county distributions. The TXHHS provides
administrative data reported monthly, up to the a cut-off. For example
May 14 is cut-off for authorizing and the numbers for June do not include
people that come in after May 14. Therefore the values for TXHHS are lower
than the values reported by BEA. BEA interpolates the values for each county
so that the totals add up to the state total. The state total is 
adminstratively produced and therefore represents 100% of the SNAP dollars 
distributed to a state in the given year. The BEA numbers do not take into
consideration variation in county level caseloads.

I compared the BEA, TXHHS, and USDA Time Series data and found that the BEA
and USDA sources were almost identical for 2006-2010, during this same time period
the TXHHS data was consistently differnt from the BEA and USDA data. For an unkown reason 
2011 data had significant discrepencies between all three sources. I suspect that
the TXHHS data is more dependable. 

I am curious to see if the values make a difference. I would imagine that 
the fixed-effects model may allow for the same results since the dependent
variable becomes demeaned. By including a dummy for each year the equations
based on TXHHS data should be similar to the BEA data. The BEA data may not 
need the dummy for each year.

Redemption data is provided from administrative records from the USDA.
This data represents all dollars redeemed in a given year at stores within
the county. This data should be very reliable.
*/
/* Tried bea_snap - redamt but the signs make more sense in the reverse.
An out of count commuter takes money away from the county.
*/
label variable redamt "Redeemed, (SNAP $)"
label variable bea_snap "Distributed, (SNAP $)"

gen Diff_SNAP_bea = redamt - bea_snap
label variable Diff_SNAP_bea "Net Difference, (SNAP $)"
format redamt bea_snap Diff_SNAP_bea %16.2fc

/* Looking into using log to help adjust distribution and reduce dispersion effects */
gen ln_bea_snap = log(bea_snap)
label variable ln_bea_snap "Distributed, (ln SNAP $)"
format ln_bea_snap %12.4fc

gen ln_redamt = log(redamt)
label variable ln_redamt "Redeemed, (ln SNAP $)"
format ln_redamt %12.4fc

gen ln_Diff_SNAP_bea = ln_redamt - ln_bea_snap
label variable ln_Diff_SNAP_bea "Net Difference, (ln SNAP $)"
format ln_Diff_SNAP_bea %12.4fc

/* Considering chaning the model to look at "trips" which is a way to capture
the increasing dollar amounts over the years. In 2005 the mininum dollar amount
distributed to a county was $82 and the max was $280. In 2011 the min was
$217 and the max was $337. The mean increased from $221 to $279.
By dividing the county redemptions and distributions by average monthly payments
I am trying to capture this change in the model. 
I tried simply adding average monthly benefit to the model and that was not 
significant in the model.
*/

gen trips_bea_snap = bea_snap / avgmonthlypayments
label variable trips_bea_snap "Start in County, (Monthly Trips)"
format trips_bea_snap %12.0fc

gen trips_redamt = redamt / avgmonthlypayments
label variable trips_redamt "End in County, (Monthly Trips)"
format trips_redamt %12.0fc

gen Diff_trips = trips_redamt - trips_bea_snap
label variable Diff_trips "Net Difference, (Monthly Trips)"
format Diff_trips %12.0fc

/* Looking into using log to help adjust distribution and reduce dispersion effects */
gen ln_trips_bea_snap = log(trips_bea_snap)
label variable ln_trips_bea_snap "Start in County, (ln Monthly Trips)"
format ln_trips_bea_snap %12.4fc

gen ln_trips_redamt = log(trips_redamt)
label variable ln_trips_redamt "End in County, (ln Monthly Trips)"
format ln_trips_redamt %12.4fc

gen ln_Diff_trips = ln_trips_redamt - ln_trips_bea_snap
label variable ln_Diff_trips "Net Difference, (ln Monthly Trips)"
format ln_Diff_trips %12.4fc

order usda_prgnum redamt bea_snap Diff_SNAP_bea /// 
	Diff_trips avgmonthlypayments trips_bea_snap ///
	bea_snap trips_redamt redamt ///
	ln_Diff_trips ln_trips_redamt ln_trips_bea_snap ln_Diff_SNAP_bea ln_redamt ln_bea_snap

local dep_var Diff_SNAP_bea
local dep_varlabel : variable label `dep_var' 

local dep_var2 Diff_trips
local dep_var2label : variable label `dep_var2' 

/* Variables that are critical to the creation of the depedent variable */
local foundation_var redamt bea_snap avgmonthlypayments trips_redamt trips_bea_snap

/*-------------------------------------------------------------------*/
/* Look at Histograms of Dependent Variables                         */
/*-------------------------------------------------------------------*/
/*
histogram `dep_var', freq normal ///
 title("Historgram of `dep_varlabel'")
graph rename `dep_var', replace
// graph export ///
// `"C:\Users\Nathanael\Dropbox\URSC PhD\Dissertation\StataGraphs\DemeanedWCR_`model'_`time_string'.pdf"'
*/
/*-------------------------------------------------------------------*/
/* Create Explanatory Variable - Mobility of Workers                 */
/*-------------------------------------------------------------------*/
/* 
OCC represents the number of low-income jobs that 
commute out-of-county in county i and in year t
These low-income workers have a home-work activity space that is larger than their
home county.

ICC is the number of low-income jobs that commute into county i 
and in year
These low-income workers have a home-work activity space that is larger than their
home county.
*/
/* 
Data generated using LODES 7  Primary Jobs
SE01 = Workers Earning $1,250 per month or less
Out of County Commuters (OCC) is equivelant to
Living in the County but Employed Outside = Living in the County - Living & Employed in the County
*/
gen occse01 = htotal_se01 - sum_se01
label variable occse01 "Outbound Low-income workers, (jobs)"
/* Proportion of county workers that have multi-county home-work activity space */

gen prpt_occse01 = occse01 / htotal_se01
label variable prpt_occse01 "Proportion of low-income workers commuting out of county"

/* 
Data generated using LODES 7  Primary Jobs
SE01 = Workers Earning $1,250 per month or less
Into County Commuter (ICC) is equivelant to
Employed in the Selection Area but Living Outside = Living in the County - Living & Employed in the County
*/
gen iccse01 = wtotal_se01 - sum_se01
label variable iccse01 "Inbound Low-income workers, (jobs)"


/* Proportion of county workers that have multi-county home-work activity space */

gen prpt_iccse01 = iccse01 / wtotal_se01
label variable prpt_iccse01 "Proportion low-income workers commuting into county"

/*-------------------------------------------------------------------*/
/* Create New Variables - Stores Per SNAP Particpant                 */
/*-------------------------------------------------------------------*/
/* Decided to do per 1000 SNAP recipients in the county to make the 
numbers easier to interpret

ISSUE - Average monthly recipients is a TXHHS provided piece of data
I have t_pop and poverty data... not sure how these compare or which one would work 
better
*/

local perSNAP_denom t_pop 
local perSNAP_Label = "persons"
local perSNAP_divsor = 10000

gen perSNAP_SS = meanss / (`perSNAP_denom'/`perSNAP_divsor') // Super Store/Chain Store
gen perSNAP_SM = meansm / (`perSNAP_denom'/`perSNAP_divsor') // Supermarket
gen perSNAP_CS = meancs / (`perSNAP_denom'/`perSNAP_divsor') // Convenience Store
gen perSNAP_CO = meanco / (`perSNAP_denom'/`perSNAP_divsor') // Combination Grocery/Other
gen perSNAP_MG = meanmg / (`perSNAP_denom'/`perSNAP_divsor') // Medium Grocery Store

label variable perSNAP_SS "Supercenters Per `perSNAP_divsor' `perSNAP_Label'"
label variable perSNAP_SM "Supermarkets Per `perSNAP_divsor' `perSNAP_Label'"
label variable perSNAP_CS "Convenience Stores Per `perSNAP_divsor' `perSNAP_Label'"
label variable perSNAP_CO "Combination Grocery/Other Per `perSNAP_divsor' `perSNAP_Label'"
label variable perSNAP_MG "Medium Grocery Stores Per Per `perSNAP_divsor' `perSNAP_Label'"

gen meanog = meanlg + meanmg + meansg
label variable meanog "Small to Large Grocery Store"

/*-------------------------------------------------------------------*/
/* Change Explanatory Variable Labels                                */
/*-------------------------------------------------------------------*/

label variable t_pop "Total Population"
label variable usda_prgnum "SNAP Participants, (persons)"
label variable unemployed "Unemployed, (persons)"
label variable eall "People of all ages in poverty"
label variable meanss "Supercenter"
label variable dyear1 "2005"
label variable dyear2 "2006"
label variable dyear3 "2007"
label variable dyear4 "2008"
label variable dyear5 "2009"
label variable dyear6 "2010"
label variable dyear7 "2011"

/*-------------------------------------------------------------------*/
/* Create New Variables - ARRA Dummy                                 */
/*-------------------------------------------------------------------*/
/* The years after 2009 may have a significant impact on the model.
Average monthly benefits increased significantly and participation rates
increased
*/

gen ARRA = 0
replace ARRA = 1 if (year >= 2009)
label variable ARRA "ARRA, 2009-2011"
/* ARRA did not have a significant impact on the model */

/*-------------------------------------------------------------------*/
/* Create Explanatory Variable - Age Groups of SNAP Participants     */
/*-------------------------------------------------------------------*/


gen prgnum_a01 = usda_prgnum * percra01
label variable prgnum_a01 "SNAP Participants Age 0-5, (persons)"

gen prgnum_a02 = usda_prgnum * percra02
label variable prgnum_a02 "SNAP Participants Age 5-17, (persons)"

gen prgnum_a03 = usda_prgnum * percra03
label variable prgnum_a03 "SNAP Participants Age 18-59, (persons)"

gen prgnum_a04 = usda_prgnum * percra04
label variable prgnum_a04 "SNAP Participants Age 60-64, (persons)"

gen prgnum_a05 = usda_prgnum * percra05
label variable prgnum_a05 "SNAP Participants Age 65+, (persons)"

gen prgnum_a06 = prgnum_a03 + prgnum_a04
label variable prgnum_a06 "SNAP Participants Age 18-64, (persons)"

gen prgnum_a07 = prgnum_a01 + prgnum_a02
label variable prgnum_a07 "SNAP Participants Age 0-17, (persons)"

/*
// Try SAIPES value for poverty instead of mixing TXHSS and USDA numbers
gen prgnum_a07 = e0_17 
Overall numbers do not change in any MAJOR way but many of the 
coefficients do change in significant ways. Since not all children in
poverty are on SNAP and since not all children on SNAP are in poverty
the numbers are close but there are differences and the totals do not
add up to the estimate of SNAP participants.
*/


/*-------------------------------------------------------------------*/
/* Create New Variables - Poverty Rate Unemployment Rate             */
/*-------------------------------------------------------------------*/

gen poverty_rate = eall / t_pop
label variable poverty_rate "Poverty, (%)"

gen unemployed_rate = unemployed / (t_age15_29 + t_age30_54 + t_age55_64)
label variable unemployed_rate "Unemployed, (%)"
/* poverty_rate unemployed_rate mess up the model - do not use */
/* will use unemplouyed_rate in dividing up prgnum into mobility */

/*-------------------------------------------------------------------*/
/* Create Explanatory Variable - Estimate of county commuters        */
/*-------------------------------------------------------------------*/
/* occse01 should be larger than the actual number of possible 
SNAP participants that are working out of county therefore to get a more 
realistic number I will use the propotion of outbound workers to estimate a 
maximum number of outbound SNAP workers.
This assumes that SNAP workers come primarily from the age 18-64 group.
This should be a strong assumption. The outbound workers should never 
be larger than this number.
The value is also based on the assumption that SNAP workers commute outbound
in similar patterns to all lowincome workers in the county.
It is possible for a family to have a monthly income in group SE02 from the
LODES data. So this assumption may not hold. The work I am trying to do
at the Census Tract level using the LODES may help improve this assumption. 
Despite the assumptions the new variable will have a more realistic scale
and not dilute the coefficient. In the previous models it is not clear 
how many outbound workers would need to be combined to represent a SNAP
household.
*/
/* New thought - could break adults age 18-64 into three groups:
Low-mobility - unemployed workers
Medium-mobility - work and live in county
High-mobilty - workers that live in the county but work outside
*/

gen prgnum_Unemployed = prgnum_a06 * unemployed_rate
label variable prgnum_Unemployed "Unemployed, (SNAP Participants Age 18-64)"

gen prgnum_Commute = (prgnum_a06 - prgnum_Unemployed) * prpt_occse01
label variable prgnum_Commute "Work outside county, (SNAP Participants Age 18-64)"

gen prgnum_incounty = prgnum_a06 - prgnum_Commute - prgnum_Unemployed
label variable prgnum_incounty "Work inside county, (SNAP Participants Age 18-64)"

/*-------------------------------------------------------------------*/
/* Create New Variables - Nonparticipants                            */
/*-------------------------------------------------------------------*/

gen nonprg_pop = t_pop - usda_prgnum
label variable nonprg_pop "SNAP Non-Participants, (persons)"

/*,¸¸,ø¤º°`°º¤ø,¸,ø¤°º¤ø,¸¸,ø¤º¤ø,¸¸,ø¤º°`°º¤ø,¸,ø¤°º¤ø,¸¸,ø¤º°`°º¤ø,*/
/*¯`·._.·¯`·._.·¯`·._.·¯`·._ Section Break _.·´¯·._.·´¯·._.·´¯·._.·´¯*/
/*,¸¸,ø¤º°`°º¤ø,¸,ø¤°º¤ø,¸¸,ø¤º¤ø,¸¸,ø¤º°`°º¤ø,¸,ø¤°º¤ø,¸¸,ø¤º°`°º¤ø,*/

/*-------------------------------------------------------------------*/
/* Set Explantory Variables                                          */
/*-------------------------------------------------------------------*/
/* Try explanatory variables that are not logged */
/* tried t_pop but that did not make a significant difference */
/* removing dyear also does not make a signifnicant difference */
local model1_redvar2 nonprg_pop ///
	prgnum_Commute prgnum_incounty prgnum_Unemployed ///
	prgnum_a07 prgnum_a05

local model1_basevars iccse01 

// Going to try to use the per_SNAP and remove the nonprg_pop
// Using perSNAP is not helpful local model2_vars perSNAP_* 

local model2_vars meanss meansm meancs meanco

/*For Texas I am going to skip metro/rural interaction
Not significant enough of a change for ACSP paper */
/*-------------------------------------------------------------------*/
/* Create New Variables - Metro/Rural Interaction Terms              */
/*-------------------------------------------------------------------*/
/* Generate rural code dummy 1 = rural in 2003 (nonmetro)*/
gen r_2003 = 0
replace r_2003 = 1 if (m_2003 == 0)
label variable r_2003 "Nonmetro 2003"

/*
foreach rural_metro in r m { 
	foreach interaction_var of varlist `model1_redvar2' `model1_basevars' `model2_vars' {
		generate i_`rural_metro'_2003_`interaction_var' = `interaction_var' * `rural_metro'_2003
		local label : variable label `interaction_var'
		local label2 : variable label `rural_metro'_2003
		label variable i_`rural_metro'_2003_`interaction_var' `"`label' X `label2'"'
	}
}
	
/* Note on Non Metro Counties */
/* Including both Metro and Nonmetro dummy interactions helps to do the math
to see how rural counties and urban counties differ in terms of shopping patterns.
*/

/*-------------------------------------------------------------------*/
/* Set Explantory Variables - Within Interaction Terms               */
/*-------------------------------------------------------------------*/

local model2v9_vars m_2003 i_m_2003*

local model2v91_vars r_2003 i_r_2003*
*/
/*-------------------------------------------------------------------*/
/* Setting panel data                                                */
/*-------------------------------------------------------------------*/
/* Comment:
The Stata command to run fixed effects is xtreg
Before using xtreg you need to set Stata to handle panel data by using
the command xtset.
In this case “county” represents the entities or panels (i) and “year”
Represents the time variable (t).
*/

/* Panel variables need to be real not string */

generate panel = real(fips_county)
sort panel year

xtset panel year

/* linear regresion is not needed for ACSP paper
/*-------------------------------------------------------------------*/
/* Look at base covariates linear regression                         */
/*-------------------------------------------------------------------*/
eststo clear

eststo: regress `dep_var' `model1_redvar2' `model1_basevars'
eststo: regress `dep_var' `model1_redvar2' `model1_basevars' `model2_vars'

// eststo: regress `dep_var' `model1_redvar2' `model1_basevars' `model2_vars' `model2v9_vars'
// eststo: regress `dep_var' `model1_redvar2' `model1_basevars' `model2_vars' `model2v91_vars'

esttab using ///
	`"C:\Users\Nathanael\Dropbox\URSC PhD\Dissertation\Statatables\Model_`model'_`time_string'.rtf"' ///
	, b(%14.2fc) se(%14.2fc) append onecell label modelwidth(16) ///
	title(Linear regression results for redemption model using the base covariates for `state' Counties `fyear'-`lyear') ///
	alignment(c) noparentheses mtitles(Model Model) ///
	addnote("Source: Author Calculations, USDA, SAIPES, BLS, BEA, LODES 7" "model_`model'_`time_string'")
eststo clear

*/
/*-------------------------------------------------------------------*/
/* Fixed effects: n entity-specific intercepts using xtreg (ln values*/
/*-------------------------------------------------------------------*/
/* Accoring to: https://kb.iu.edu/d/auur
The xtreg command produces correct parameter estimates without creating 
dummy variables; however, due to the larger degrees of freedom, its 
standard errors and, consequently, R-squared statistic are incorrect. 

areg produce correct parameter estimates, standard errors, and R-squared statistics.
*/

local final_expvars `model1_redvar2' `model1_basevars' `model2_vars'
/* run areg to get adjusted r-square for model 1 */
areg `dep_var' `model1_redvar2' `model1_basevars', absorb(fips_county)
/* store adjusted r-square to be displayed as a comment on fixed effect output */
local model1_r2a = string(e(r2_a),"%8.3f")
/* run areg to get adjusted r-square for model 2 */
areg `dep_var' `final_expvars', absorb(fips_county)
/* store adjusted r-square to be displayed as a comment on fixed effect output */
local model2_r2a = string(e(r2_a),"%8.3f")
display "Adjusted R2 for model 1: `model1_r2a' model 2: `model2_r2a'"

/// Compared models and Fixed-effects is the prefered model

eststo clear
foreach re_fe in fe {

eststo: xtreg `dep_var' t_pop, `re_fe'

eststo: xtreg `dep_var' nonprg_pop usda_prgnum, `re_fe'

eststo: xtreg `dep_var' nonprg_pop prgnum_a07 prgnum_a06 prgnum_a05, `re_fe'

eststo: xtreg `dep_var' iccse01 occse01 unemployed eall, `re_fe'

eststo: xtreg `dep_var' `model1_redvar2' `model1_basevars' i.year, `re_fe' 
/* test to see if the effect for commuters is the same or different */
//lincom occse01-iccse01

eststo: xtreg `dep_var' `model1_redvar2' `model1_basevars' `model2_vars', `re_fe'
/* test to see if the effect for commuters is the same or different */
//lincom occse01-iccse01
//lincom meanss-meansm
/* Look at same model normalized by average monthly benefit per household */
eststo: xtreg `dep_var2' `model1_redvar2' `model1_basevars' `model2_vars', `re_fe'

// eststo: xtreg `dep_var' `model1_redvar2' `model1_basevars' `model2_vars' `model2v9_vars', `re_fe' /* Model 2 metro interaction */

// eststo: xtreg `dep_var' `model1_redvar2' `model1_basevars' `model2_vars' `model2v91_vars', `re_fe' /* Model 2 rural interaction */
}

esttab using ///
	`"C:\Users\Nathanael\Dropbox\URSC PhD\Dissertation\Statatables\Model_`model'_`time_string'.rtf"' ///
	, b(%14.2fc) se(%14.2fc) ar2 onecell append label modelwidth(16) /// 
	title(Parameter Estimates from Models of Change in net difference of SNAP dollars for `state' Counties `fyear'-`lyear') ///
	alignment(c) parentheses /// mtitles(Model Model)  
	addnote("Source: Author Calculations, USDA, SAIPES, BLS, BEA, LODES 7, TXHHS" ///
		"Balanced Panel" ///
		"model_`model'_`time_string'" ///
		"Adjusted R2 for model 1: `model1_r2a' model 2: `model2_r2a'" ///
		"95% CI of Average Annual Benefit Per SNAP Participant $`lb_avgben' - $`ub_avgben', sd($`sd_avgben')")
eststo clear


/*,¸¸,ø¤º°`°º¤ø,¸,ø¤°º¤ø,¸¸,ø¤º¤ø,¸¸,ø¤º°`°º¤ø,¸,ø¤°º¤ø,¸¸,ø¤º°`°º¤ø,*/
/*¯`·._.·¯`·._.·¯`·._.·¯`·._ Section Break _.·´¯·._.·´¯·._.·´¯·._.·´¯*/
/*,¸¸,ø¤º°`°º¤ø,¸,ø¤°º¤ø,¸¸,ø¤º¤ø,¸¸,ø¤º°`°º¤ø,¸,ø¤°º¤ø,¸¸,ø¤º°`°º¤ø,*/


/*-------------------------------------------------------------------*/
/* Generate residuals                                                */
/*-------------------------------------------------------------------*/
*/
local modeltype xife
local predict_var `dep_var'

xi: regress `predict_var' `final_expvars' i.fips_county
predict double resid`modeltype', residuals
predict double yhat`modeltype'
summarize resid`modeltype'
// gen yhat`modeltype'_`predict_var' = exp(yhat`modeltype') // inverse of the ln should be in terms of original variable
gen resid`modeltype'_`predict_var' = `predict_var' - yhat`modeltype'
gen prct_off`modeltype'`predict_var' = resid`modeltype'_`predict_var' / redamt
summarize prct_off`modeltype'`predict_var'


local modeltype xi
local predict_var `dep_var'

xi: regress `predict_var' `final_expvars'
predict double resid`modeltype', residuals
predict double yhat`modeltype'
summarize resid`modeltype'
// gen yhat`modeltype'_`predict_var' = exp(yhat`modeltype') // inverse of the ln should be in terms of original variable
gen resid`modeltype'_`predict_var' = `predict_var' - yhat`modeltype'
gen prct_off`modeltype'`predict_var' = resid`modeltype'_`predict_var' / redamt
summarize prct_off`modeltype'`predict_var'

order county_name t_pop eall usda_prgnum state fips_county year redamt  bea_snap `dep_var' ///
	yhatxife yhatxi  ///
	prct_offxife`predict_var' prct_offxi`predict_var' ///
	prct_offxi`predict_var' retailtotal `final_expvars' 
format prct_offxi`predict_var' prct_offxife`predict_var' %8.2f
format `dep_var' %16.2fc
format t_pop eall usda_prgnum prgnum_* %12.0fc
format yhatxi yhatxife redamt bea_snap %16.2fc

/* Checking residuals
Austin County - 48015 off by -42% in 2006 - county performed worse than expected.
Would be interesting to see if store type changed in 2007 because the number of retailers
did not change. County has had 3 super centers and no supermarkets during the time period.

Cochran County - 48079 off by -31% in 2007 - county saw a spike in redemptions in 2009
then in 2010 redemptions dropped. Overall the county has a low WCR.
Cochran county had less than 4 stores before 2008.

Concho County - 48095 off by -17% in 2008. County has only 4 retail stores.

Bandera County - 48019 2005 Redemption data is off significantly. USDA data says
the county redeemed 2.4 million dollars in 2005 and in 2006 that drops to 650K.
Probably an error in the data because the total retail does not change.

Overall I am very impressed with the model. Is it over specified? By controlling
for each year and each county do I have a "perfect" model?
*/
/*
One option would to make sure the panel is balanced
*/

/*,¸¸,ø¤º°`°º¤ø,¸,ø¤°º¤ø,¸¸,ø¤º¤ø,¸¸,ø¤º°`°º¤ø,¸,ø¤°º¤ø,¸¸,ø¤º°`°º¤ø,*/
/*¯`·._.·¯`·._.·¯`·._.·¯`·._ Section Break _.·´¯·._.·´¯·._.·´¯·._.·´¯*/
/*,¸¸,ø¤º°`°º¤ø,¸,ø¤°º¤ø,¸¸,ø¤º¤ø,¸¸,ø¤º°`°º¤ø,¸,ø¤°º¤ø,¸¸,ø¤º°`°º¤ø,*/


/*-------------------------------------------------------------------*/
/* Generate Descriptive Statistics                                   */
/*-------------------------------------------------------------------*/

eststo clear
estpost tabstat `foundation_var' `dep_var' `dep_var2' usda_prgnum `final_expvars', ///
		statistics(min max p50 mean sd count) columns(statistics)
esttab using ///
`"C:\Users\Nathanael\Dropbox\URSC PhD\Dissertation\Statatables\Model_`model'_`time_string'.rtf"' ///
, alignment(r) append label gaps modelwidth(20) ///
cells("count(fmt(%16.0fc)) min(fmt(%16.0fc)) max(fmt(%16.0fc)) p50(fmt(%16.0fc)) mean(fmt(%16.0fc)) sd(fmt(%16.0fc))") noobs ///
title(Basic Descriptive Statistics for SNAP and Mobility Related Variables for `state' Counties `fyear'-`lyear') ///
nonumbers addnote("Source: Author Calculations, USDA, SAIPES, BLS, BEA, LODES 7" "model_`model'_`time_string'")
eststo clear


/*-------------------------------------------------------------------*/
/* Summarize Variables by Year                                       */
/*-------------------------------------------------------------------*/

foreach sum_var of varlist `dep_var' `dep_var2' `final_expvars' `foundation_var' {
	local sum_var_varlabel : variable label `sum_var' 
	eststo clear
	estpost tabstat `sum_var', by(year) ///
			statistics(min max p50 mean sd count)
	esttab using ///
	`"C:\Users\Nathanael\Dropbox\URSC PhD\Dissertation\Statatables\Model_`model'_`time_string'.rtf"' ///
	, alignment(r) append label gaps modelwidth(20) ///
	cells("count(fmt(%16.0fc)) min(fmt(%16.0fc)) max(fmt(%16.0fc)) p50(fmt(%16.0fc)) mean(fmt(%16.0fc)) sd(fmt(%16.0fc))") noobs ///
	title(Sum of `sum_var_varlabel' for `state' Counties by year.) ///
	nonumbers addnote("Source: Author Calculations, USDA, SAIPES, BLS, BEA, LODES 7" "model_`model'_`time_string'")
	eststo clear
}


/*,¸¸,ø¤º°`°º¤ø,¸,ø¤°º¤ø,¸¸,ø¤º¤ø,¸¸,ø¤º°`°º¤ø,¸,ø¤°º¤ø,¸¸,ø¤º°`°º¤ø,*/
/*¯`·._.·¯`·._.·¯`·._.·¯`·._ Section Break _.·´¯·._.·´¯·._.·´¯·._.·´¯*/
/*,¸¸,ø¤º°`°º¤ø,¸,ø¤°º¤ø,¸¸,ø¤º¤ø,¸¸,ø¤º°`°º¤ø,¸,ø¤°º¤ø,¸¸,ø¤º°`°º¤ø,*/


/*-------------------------------------------------------------------*/
/* Install Center Moduel From SSC                                    */
/*-------------------------------------------------------------------*/
/* I am interested in 2 things
1. If I just have the mean of the county redemptions what would the
adjusted r square be... in other words how much of the variance is 
explained just by knowing the county mean. If a significant amount of 
the variance is explained by the mean then the explanatory variables 
do not have much significance.

2. What is the correlation (pwcorr) between the centered variables?
There is significant correlation between the standard variables. Counties
with high occ and icc have high unemployment, ss, sc. This is really a
factor of using absolute numbers. 
*/
ssc install center, replace

/*-------------------------------------------------------------------*/
/* Add demeaned values by County                                     */
/*-------------------------------------------------------------------*/

bysort fips_county: center `dep_var', ///
	prefix(c0all) meansave(m0all) replace
label variable m0all`dep_var' "Mean of `dep_varlabel'"
eststo: regress `dep_var' m0all`dep_var', beta vce(robust)
	
bysort fips_county: center `model1_redvar2' `model1_basevars', ///
	prefix(c1all) meansave(m1all) replace
eststo: regress `dep_var' m0all`dep_var' c1all*, beta vce(robust)

bysort fips_county: center `model2_vars', ///
	prefix(c2all) meansave(m2all) replace
eststo: regress `dep_var' m0all`dep_var' c1all* c2all*, beta vce(robust)

bysort fips_county: center `dep_var2', ///
	prefix(c3all) meansave(m3all) replace
eststo: regress `dep_var2' m3all`dep_var2' c1all* c2all*, beta vce(robust)

esttab using ///
	`"C:\Users\Nathanael\Dropbox\URSC PhD\Dissertation\Statatables\Model_`model'_`time_string'.rtf"' ///
	, b(%14.2fc) se(%14.2fc) ar2 onecell append label modelwidth(16) /// 
	title(Parameter Estimates from Models of Change in net difference of SNAP dollars for `state' Counties `fyear'-`lyear') ///
	alignment(c) parentheses ///
	addnote("Source: Author Calculations, USDA, SAIPES, BLS, BEA, LODES 7" "Balanced Panel" "model_`model'_`time_string'" ///
	"Robust regression used because normality not assumed")
eststo clear

/*-------------------------------------------------------------------*/
/* Does model 2 have a statistically significant R2                  */
/*-------------------------------------------------------------------*/
/* Use Nestreg on the demeaned values to determine the incremental
increase between the 2 models */
nestreg: regress `dep_var' (m0all`dep_var') (c1all*) (c2all*)

/* Since dep_var is not normally distributed use beta vce(robust)
See Acock p. 255
*/
nestreg: regress `dep_var' (m0all`dep_var') (c1all*) (c2all*), beta vce(robust)

/*,¸¸,ø¤º°`°º¤ø,¸,ø¤°º¤ø,¸¸,ø¤º¤ø,¸¸,ø¤º°`°º¤ø,¸,ø¤°º¤ø,¸¸,ø¤º°`°º¤ø,*/
/*¯`·._.·¯`·._.·¯`·._.·¯`·._ Section Break _.·´¯·._.·´¯·._.·´¯·._.·´¯*/
/*,¸¸,ø¤º°`°º¤ø,¸,ø¤°º¤ø,¸¸,ø¤º¤ø,¸¸,ø¤º°`°º¤ø,¸,ø¤°º¤ø,¸¸,ø¤º°`°º¤ø,*/


/*-------------------------------------------------------------------*/
/* Check Values for Predicting Redemptions                           */
/*-------------------------------------------------------------------*/

bysort fips_county: center redamt, meansave replace
bysort fips_county: center usda_prgnum, meansave replace

regress c_redamt c_usda_prgnum c2allmean*

/*-------------------------------------------------------------------*/
/* Thoughts                                                          */
/*-------------------------------------------------------------------*/ 
/*
      _.,----,._
    .:'        `:.
  .'              `.
 .'                `.
 :                  :
 `    .'`':'`'`/    '
  `.   \  |   /   ,'
    \   \ |  /   /
     `\_..,,.._/'
      {`'-,_`'-}
      {`'-,_`'-}
      {`'-,_`'-}
       `YXXXXY'
         ~^^~

There is a significant time trend associated with unemployement
overall redemptions increases 
		 
*/		 
/*-------------------------------------------------------------------*/
/* Discussion                                                        */
/*-------------------------------------------------------------------*/
/* Using the mean does explain a signifcant portion of the variance
the adjusted r-square is around .72 for years 2005-2008 and years
2009-2011. The coefficients on the mobility variables are similar.
The coefficients on the store variables are actually negative. 
I am not sure why they would be negative. It may be that the loss of time
series leads to a lack of direction, a county that is becoming 
increasingly attractive over time due to increases in stores would have
a mean that is lower and store counts that are higher.  

Using the centered values produces the same coefficients as the fixed
effects model. The standard errors are slighlty larger and the constant
is nolonger significant. The overall adjusted r-square is 0.35. The fixed-effects
model combines the mean for the county and the centered values to 
predict the depedent variable.
*/

/*-------------------------------------------------------------------*/
/* Principle Component Factor Analysis                               */
/*-------------------------------------------------------------------*/
/* Attempting to create an index */
pwcorr c0all* c1all* c2all*

local factorvars `model1_redvar2' `model1_basevars' `model2_vars'

factor `factorvars', pcf
rotate


/* based on the above factor analysis going to make a factor */
predict factor_SNAP1
// label variable factor_SNAP1 "SNAP info Factor" 


local factorcvars c1all* c2all*

factor `factorcvars', pcf
rotate

/* Results
2 factors
*/
/* based on the above factor analysis going to make a factor */
predict factor_SNAP2 factor_SNAP3

/*-------------------------------------------------------------------*/
/* End Log                                                           */
/*-------------------------------------------------------------------*/
*/
log close
