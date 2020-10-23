/*-------------------------------------------------------------------*/
/* What Model Are you Running                                        */
/*-------------------------------------------------------------------*/
local model = "2v95"

/*-------------------------------------------------------------------*/
/* What are important directories                                    */
/*-------------------------------------------------------------------*/
local rootdir = "C:\Users\Nathanael\Dropbox"
local outputdir = "`rootdir'\URSC PhD\Dissertation"
local outputtex = "`outputdir'\DissertationLaTexDoc\tables"
local outputtex_fig = "`outputdir'\DissertationLaTexDoc\figures\STATAruns"
local datadir = "`rootdir'\MyData\Dissertation\"

/*-------------------------------------------------------------------*/
/* Change directory that contains programs and schemes               */
/*-------------------------------------------------------------------*/

cd "`rootdir'\MyPrograms\Dissertation\STATA\"

/*-------------------------------------------------------------------*/
/* Set scheme - SSCCL from Sheather 2009                             */
/*-------------------------------------------------------------------*/

set scheme ssccl

/*-------------------------------------------------------------------*/
/* Start Log                                                         */
/*-------------------------------------------------------------------*/
local c_date = c(current_date)
local c_time = c(current_time)
local c_time_date = "`c_date'"+"_" +"`c_time'"
local time_string = subinstr("`c_time_date'", ":", "_", .)
local time_string = subinstr("`time_string'", " ", "_", .)
/* Note to use filenames with a space include `" before and "' after */

/* close any logs that might be open */
capture log close

log using `"`outputdir'\StataLogs\model_`model'_`time_string'.log"', text
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
      Preparing to meet with Walt to discuss differences between 
	  Fixed-Effects and Random-Effects.
	  Also interested in applying Validity Tests that Sheather 2009
	  recommends
	  
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
/* Date Last Updated: 19Jan15                                        */
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
clear all
drop _all



set more off

/*-------------------------------------------------------------------*/
/* Data Source                                                       */
/*-------------------------------------------------------------------*/
local state = "TX"
local fyear = "2005"
local lyear = "2011"
local tyears = 7

use `datadir'\Sept26Model2v9`state'_`fyear'_`lyear'.dta, clear

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
bysort fips_county: gen nfips=[_N]

keep if nfips==`tyears' 

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
/* Need \\$ so that LaTex converts \$ to $*/
label variable redamt "Redeemed, (\\$)"
label variable bea_snap "Distributed, (\\$)"

gen Diff_SNAP_bea = redamt - bea_snap
label variable Diff_SNAP_bea "Net Difference, (\\$)"

gen Prct_SNAP_bea = Diff_SNAP_bea / bea_snap
label variable Prct_SNAP_bea "Net Difference, (\\%)"

/* Select the Dependent Variable to use for all future models */
local dep_var Diff_SNAP_bea
local dep_varlabel : variable label `dep_var' 
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
/* Ln Transform Explanatory Variable Labels                          */
/*-------------------------------------------------------------------*/

gen ln_occse01 = log(occse01)
label variable ln_occse01 "Outbound Low-income workers, (ln(jobs))"

gen ln_iccse01 = log(iccse01)
label variable ln_iccse01 "Inbound Low-income workers, (ln(jobs))"

gen ln_unemployed = log(unemployed)
label variable ln_unemployed "Unemployed, (ln(persons))"

gen ln_eall = log(eall)
label variable ln_eall "Poverty, (ln(persons))"

/*-------------------------------------------------------------------*/
/* Create New Variables - Stores Per SNAP Particpant                 */
/*-------------------------------------------------------------------*/
/* Decided to do per 10000 SNAP recipients in the county to make the 
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

/*-------------------------------------------------------------------*/
/* Change Explanatory Variable Labels                                */
/*-------------------------------------------------------------------*/

label variable t_pop "Total Population, (persons)"
label variable htotal_s000 "Workers living in county, (jobs)"
label variable unemployed "Unemployed, (persons)"
label variable eall "People of all ages in poverty"
label variable dyear1 "2005"
label variable dyear2 "2006"
label variable dyear3 "2007"
label variable dyear4 "2008"
label variable dyear5 "2009"
label variable dyear6 "2010"
label variable dyear7 "2011"


/*-------------------------------------------------------------------*/
/* Set Explantory Variables                                          */
/*-------------------------------------------------------------------*/
/* Try explanatory variables that are not logged */
/* tried t_pop but that did not make a significant difference */
/* removing dyear also does not make a signifnicant difference */
local model1_redvar2 // dyear*

local model1_basevars occse01 iccse01 unemployed eall

local model1_ln_basevars ln_occse01 ln_iccse01 ln_unemployed ln_eall

local model2_vars meanss meansm meancs meanco

local model2_per_vars perSNAP_SS perSNAP_SM perSNAP_CS perSNAP_CO

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
/* Disucused using , beta vce(robust) with Walt and he is of the opinion
that robust regression is overkill and that the SE reported without
robust can be applied. Therefore will not use
"Robust regression used because normality not assumed"
*/
bysort fips_county: center  redamt bea_snap Prct_SNAP_bea `dep_var', ///
	prefix(c0all) meansave(m0all) replace
label variable m0all`dep_var' "Mean of Net Difference, (\\$)"

bysort fips_county: center `model1_redvar2' `model1_basevars', ///
	prefix(c1all) meansave(m1all) replace

bysort fips_county: center `model2_vars', ///
	prefix(c2all) meansave(m2all) replace

bysort fips_county: center `model1_ln_basevars', ///
	prefix(c1ln) meansave(m1ln) replace
	
bysort fips_county: center `model2_per_vars', ///
	prefix(c2per) meansave(m2per) replace
	
/*For Texas I am going to skip metro/rural interaction
Not significant enough of a change for ACSP paper
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

/*
/*-------------------------------------------------------------------*/
/* Fixed effects Model 1 Using Sheather 2009 Validity Check          */
/*-------------------------------------------------------------------*/

/*
Generate figure that shows a scatter plot matrix of the predictors.
Do the predictors seem to be related linarly at least approximately?
*/
//Sheather 2009 figure 6.1
graph matrix `model1_redvar2' `model1_basevars', ///
	caption("Scatter Plot Matrix of the Model 1 Predictors")
graph export `"`outputtex_fig'/scatter_predictors_`model'_`time_string'.png"', replace

/* Desription of Sheather 2009 6.1 plots 
Based on above plots both the untransformed and the log transformed
variables are related linearly.
*/

xtreg `dep_var' `model1_redvar2' `model1_basevars', fe /* Model 1 mobility only */

/* Xtreg does not allow for prediction of standard residuals use xi: regress 
Notes from Torres-Reyna

Fixed Effects using least squares dummy variable model (LSDV)
The least square dummy variable model (LSDV) provides a good way to understand fixed
effects.
The effect of x1 is mediated by the differences across countries.
By adding the dummy for each country we are estimating the pure effect of x1 (by
controlling for the unobserved heterogeneity).
Each dummy is absorbing the effects particular to each country.
*/

xi: regress `dep_var' `model1_redvar2' `model_basevars' i.fips_county
predict double stanres_m1, rstandard
label variable stanres_m1 "Standardized Residuals Model 1"

/* Create plots of the standardized residual against each predictor */
local i = 0
foreach x_var of varlist `model1_redvar2' `model1_basevars'{
	local i = 1 + `i'
	twoway scatter stanres_m1 `x_var', name("g`i'") nodraw
}
//Figure 6.2 
graph combine g1 g2 g3 g4, rows(2) xsize(10) ysize(10)  ///
	caption("Standardized Residual Plotted Against Each Model 1 Predictor")
graph export `"`outputtex_fig'/scatter_standardresid_predictors_`model'_`time_string'.png"', replace
graph drop g1 g2 g3 g4


predict fitted_m1, xb
label variable fitted_m1 "Fitted Values Model 1"
//Figure 6.3
twoway scatter `dep_var' fitted_m1 ///
|| lfit `dep_var' fitted, ytitle(DependentVariable) legend(off) ///
	title("Dependent Variable Plotted Against") ///
	subtitle("Model 1 Fitted Values")
graph export `"`outputtex_fig'/y_fitted_`model'_`time_string'.png"', replace

/*-------------------------------------------------------------------*/
/* Fixed effects Model 1 Using Sheather 2009 Validity Check          */
/* Transform Variables using natural log                             */
/*-------------------------------------------------------------------*/

graph matrix `model1_ln_basevars', ///
	title("Scatter Plot Matrix of") ///
	subtitle("the Log of the Model 1 Predictors")
graph export `"`outputtex_fig'/scatter_ln_predictors_`model'_`time_string'.png"', replace

xi: regress `dep_var' `model1_redvar2' `model1_ln_basevars' i.fips_county
predict double stanres_m1ln, rstandard
label variable stanres_m1ln "Stand Resid Model 1 Log Trans"

/* Create plots of the standardized residual against each predictor */
local i = 0
foreach x_var of varlist `model1_redvar2' `model1_ln_basevars'{
	local i = 1 + `i'
	twoway scatter stanres_m1ln `x_var', name("g`i'") nodraw
}
//Figure 6.2 
graph combine g1 g2 g3 g4, rows(2) xsize(10) ysize(10)  ///
	title("Standardized Residual Plotted") ///
	subtitle("Against Each Log-transformed") ///
	t2title("Model 1 Predictor")
graph export `"`outputtex_fig'/scatter_standardresid_lnpredictors_`model'_`time_string'.png"', replace
graph drop g1 g2 g3 g4


predict fitted_m1ln, xb
label variable fitted_m1ln "Fitted Values Model 1"
//Figure 6.3
twoway scatter `dep_var' fitted_m1ln ///
|| lfit `dep_var' fitted_m1ln, ytitle("Dependent Variable") legend(off) ///
	title("Dependent Variable Plotted Against") /// 
	subtitle("Model 1 Fitted Values using Log-transform")
graph export `"`outputtex_fig'/y_fitted_ln_`model'_`time_string'.png"', replace

*/

/*-------------------------------------------------------------------*/
/* Fixed effects Model 2 Using Sheather 2009 Validity Check          */
/*-------------------------------------------------------------------*/

// Local for model number id, for variables and file names
local mnum = "m2_v2"
// Local variable for the name of the model, for titles and labels
local mname = "Model 2v2"
// Local for all the variables in the model
local model_expvars `model1_redvar2' `model1_ln_basevars' `model2_per_vars'

	/*
	Generate figure that shows a scatter plot matrix of the predictors.
	Do the predictors seem to be related linarly at least approximately?
	*/
	//Sheather 2009 figure 6.1
	graph matrix `model_expvars', ///
		caption("Scatter Plot Matrix of the `mname' Predictors")
	graph export `"`outputtex_fig'/scatter_`mnum'_predictors_`model'_`time_string'.png"', replace

	/* Desription of Sheather 2009 6.1 plots 
	Based on above plots both the untransformed and the log transformed
	variables are related linearly.
	*/

	xtreg `dep_var' `model_expvars', ///
		fe /* Model 1 mobility only */

	/* Xtreg does not allow for prediction of standard residuals use xi: regress 
	Notes from Torres-Reyna

	Fixed Effects using least squares dummy variable model (LSDV)
	The least square dummy variable model (LSDV) provides a good way to understand fixed
	effects.
	The effect of x1 is mediated by the differences across countries.
	By adding the dummy for each country we are estimating the pure effect of x1 (by
	controlling for the unobserved heterogeneity).
	Each dummy is absorbing the effects particular to each country.
	*/

	xi: regress `dep_var' `model_expvars' ///
		i.fips_county
	predict double stanres_`mnum', rstandard
	label variable stanres_`mnum' "Standardized Residuals `mname'"

	/* Create plots of the standardized residual against each predictor */
	local i = 0
	foreach x_var of varlist `model_expvars'{
		local i = 1 + `i'
		twoway scatter stanres_`mnum' `x_var', name(`x_var') nodraw
		local graphnames `graphnames' `x_var'
	}
	//Figure 6.2 
	display `graphnames'

	graph combine `graphnames', cols(2) xsize(10) ysize(10)  ///
		caption("Standardized Residual Plotted Against Each `mname' Predictor")
	graph export `"`outputtex_fig'/scatter_standardresid_`mnum'_predictors_`model'_`time_string'.png"', replace
	graph drop `graphnames'


	predict fitted_`mnum', xb
	label variable fitted_`mnum' "Fitted Values `mname'"
	//Figure 6.3
	twoway scatter `dep_var' fitted_`mnum' ///
	|| lfit `dep_var' fitted_`mnum', ytitle(DependentVariable) legend(off) ///
		title("Dependent Variable Plotted Against") ///
		subtitle("`mname' Fitted Values")
	graph export `"`outputtex_fig'/y_`mnum'_fitted_`model'_`time_string'.png"', replace
	
	avplots, recast(scatter)
/*-------------------------------------------------------------------*/
/* End Log                                                           */
/*-------------------------------------------------------------------*/
*/
log close
exit

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
foreach re_fe in fe re be{

//eststo: quietly 
xtreg `dep_var' `model1_redvar2' `model1_basevars', `re_fe' /* Model 1 with ben dollars split */
/* test to see if the effect for commuters is the same or different */
*lincom occse01-iccse01
*lincom -1*iccse01-occse01

//eststo: quietly 
xtreg `dep_var' `model1_redvar2' `model1_basevars' `model2_vars', `re_fe' /* Model 2 no interaction */
/* test to see if the effect for commuters is the same or different */
*lincom -1*iccse01-occse01
*lincom meanss-meansm

//eststo: quietly 
xtreg `dep_var' `model1_redvar2' `model2_vars', `re_fe' /* Model 2 no interaction */
/* test to see if the effect for commuters is the same or different */

// eststo: xtreg `dep_var' `model1_redvar2' `model1_basevars' `model2_vars' `model2v9_vars', `re_fe' /* Model 2 metro interaction */

// eststo: xtreg `dep_var' `model1_redvar2' `model1_basevars' `model2_vars' `model2v91_vars', `re_fe' /* Model 2 rural interaction */
}


/* Output tables to LaTex
esttab using ///
	`"`outputtex'\ParameterEstimates.tex"' ///
	, booktabs label replace fragment ///
	b(%14.2fc) se(%14.2fc) /// 
	title(Parameter Estimates from Models of Change in net difference of SNAP dollars for `state' Counties `fyear'-`lyear') ///
	mgroups("Model 1" "Model 2", pattern(1 1 0)                   ///
	prefix(\multicolumn{@span}{c}{) suffix(})   ///
	span erepeat(\cmidrule(lr){@span}))         ///
	alignment(D{.}{.}{-1}) nonumber ///
	addnote("Source: Author Calculations, USDA, SAIPES, BLS, BEA, LODES 7" "Balanced Panel" "model_`model'_`time_string'" ///
	"Adjusted R2 for model 1: `model1_r2a' model 2: `model2_r2a'")
eststo clear

* Add comment to Latex file to keep track of model and date that produced table
tempname dst
local addcomment1 "% model_`model'_`time_string'"
local addcomment2 "% Adjusted R2 for model 1: `model1_r2a' model 2: `model2_r2a'"
file open `dst' using `"`outputtex'\ParameterEstimates.tex"', write append
file write `dst' "`addcomment1'"_n
file write `dst' "`addcomment2'"
file close `dst'
/*-------------------------------------------------------------------*/
/* Generate residuals                                                */
/*-------------------------------------------------------------------*/

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

order county_name t_pop eall state fips_county year redamt  bea_snap `dep_var' ///
	yhatxife yhatxi  ///
	prct_offxife`predict_var' prct_offxi`predict_var' ///
	prct_offxi`predict_var' retailtotal `final_expvars' 
format prct_offxi`predict_var' prct_offxife`predict_var' %8.2f
format `dep_var' %16.2fc
format t_pop eall %12.0fc
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
/*-------------------------------------------------------------------*/
/* Generate Descriptive Statistics                                   */
/*-------------------------------------------------------------------*/

eststo clear
estpost tabstat `dep_var', by(year) ///
		statistics(min max p50 mean sd count)
esttab using ///
`"C:\Users\Nathanael\Dropbox\URSC PhD\Dissertation\Statatables\Model_`model'_`time_string'.rtf"' ///
, alignment(r) append label gaps modelwidth(20) ///
cells("count(fmt(%16.0fc)) min(fmt(%16.0fc)) max(fmt(%16.0fc)) p50(fmt(%16.0fc)) mean(fmt(%16.0fc)) sd(fmt(%16.0fc))") noobs ///
title(Summary of `state' Within-County Redemptions between `fyear' and `lyear') ///
nonumbers addnote("Source: Author Calculations, USDA, BEA" "model_`model'_`time_string'")
eststo clear

eststo clear
estpost tabstat t_pop redamt bea_snap `dep_var' `final_expvars', ///
		statistics(min max p50 mean sd count) columns(statistics)

* Add an indention for LeTex Output

foreach v of varlist `final_expvars' {
	label variable `v' `"\hspace{0.1cm} `: variable label `v''"'
	}
esttab using ///
	`"`outputtex'\BasicDescriptiveStats.tex"' ///
	, replace fragment booktabs label nonum gaps noobs ///
	refcat(occse01 "\emph{Mobility}" meanss "\emph{Retail Environment}",nolabel) ///
	cells("count(fmt(%16.0fc)) min(fmt(%16.0fc)) max(fmt(%16.0fc)) p50(fmt(%16.0fc)) mean(fmt(%16.0fc)) sd(fmt(%16.0fc))") ///
	title(Basic Descriptive Statistics for SNAP and Mobility Related Variables for `state' Counties `fyear'-`lyear') ///
	addnote("Source: Author Calculations, USDA, SAIPES, BLS, BEA, LODES 7" "model_`model'_`time_string'")
eststo clear


/*-------------------------------------------------------------------*/
/* Summarize Variables by Year                                       */
/*-------------------------------------------------------------------*/

estpost tabstat t_pop redamt bea_snap `dep_var' `final_expvars', by(year) ///
	statistics(sum) columns(statistics) listwise
	
esttab using ///
`"C:\Users\Nathanael\Dropbox\URSC PhD\Dissertation\Statatables\Model_`model'_`time_string'.rtf"' ///
, append nogaps label modelwidth(20) main(sum %16.0fc) nostar unstack nomtitle ///
title(Sum of SNAP and Mobility Related Variables for `state' Counties by year.) ///
nonumbers addnote("Source: Author Calculations, USDA, SAIPES, BLS, BEA, LODES 7" "model_`model'_`time_string'")
eststo clear

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
/* Disucused using , beta vce(robust) with Walt and he is of the opinion
that robust regression is overkill and that the SE reported without
robust can be applied. Therefore will not use
"Robust regression used because normality not assumed"
*/
bysort fips_county: center  redamt bea_snap Prct_SNAP_bea `dep_var', ///
	prefix(c0all) meansave(m0all) replace
label variable m0all`dep_var' "Mean of Net Difference, (\\$)"
eststo: quietly regress `dep_var' m0all`dep_var'

bysort fips_county: center `model1_redvar2' `model1_basevars', ///
	prefix(c1all) meansave(m1all) replace
eststo: quietly regress `dep_var' m0all`dep_var' c1all*

bysort fips_county: center `model2_vars', ///
	prefix(c2all) meansave(m2all) replace
eststo: quietly regress `dep_var' m0all`dep_var' c1all* c2all*
eststo: quietly regress `dep_var' m0all`dep_var' c2all*

esttab using ///
	`"C:\Users\Nathanael\Dropbox\URSC PhD\Dissertation\Statatables\Model_`model'_`time_string'.rtf"' ///
	, b(%14.2fc) se(%14.2fc) ar2 onecell append label modelwidth(16) /// 
	title(Parameter Estimates from Models of Change in net difference of SNAP dollars for `state' Counties `fyear'-`lyear') ///
	alignment(c) parentheses ///
	addnote("Source: Author Calculations, USDA, SAIPES, BLS, BEA, LODES 7" "Balanced Panel" "model_`model'_`time_string'")
eststo clear

* Too wide to include all four models
* Model 1 
eststo: quietly regress `dep_var' m0all`dep_var'
eststo: quietly regress `dep_var' m0all`dep_var' c1all*
esttab using ///
	`"`outputtex'\ParameterDemeaned1.tex"' ///
	, booktabs label replace fragment ar2 ///
	b(%14.2fc) se(%14.2fc) /// 
	title(Parameter Estimates using demeaned values from Models of Change in net difference of SNAP dollars for `state' Counties `fyear'-`lyear') ///
	mgroups("Base Mean" "Model 1", pattern(1 1)                   ///
	prefix(\multicolumn{@span}{c}{) suffix(})   ///
	span erepeat(\cmidrule(lr){@span}))         ///
	alignment(D{.}{.}{-1}) nonumber ///
	addnote("Source: Author Calculations, USDA, SAIPES, BLS, BEA, LODES 7" "Balanced Panel" "model_`model'_`time_string'")
eststo clear

* Add comment to Latex file to keep track of model and date that produced table
tempname dst
local addcomment1 "% model_`model'_`time_string'"
local addcomment2 "% Parameter Estimates using demeaned values from Models of Change in net difference of SNAP dollars for `state' Counties `fyear'-`lyear'"
file open `dst' using `"`outputtex'\ParameterDemeaned.tex"', write append
file write `dst' "`addcomment1'"_n
file write `dst' "`addcomment2'"_n
file close `dst'

* Model 2
eststo: quietly regress `dep_var' m0all`dep_var' c1all* c2all*
eststo: quietly regress `dep_var' m0all`dep_var' c2all*
esttab using ///
	`"`outputtex'\ParameterDemeaned2.tex"' ///
	, booktabs label replace fragment ar2 ///
	b(%14.2fc) se(%14.2fc) /// 
	title(Parameter Estimates using demeaned values from Models of Change in net difference of SNAP dollars for `state' Counties `fyear'-`lyear') ///
	mgroups("Model 2", pattern(1 0)                   ///
	prefix(\multicolumn{@span}{c}{) suffix(})   ///
	span erepeat(\cmidrule(lr){@span}))         ///
	alignment(D{.}{.}{-1}) nonumber ///
	addnote("Source: Author Calculations, USDA, SAIPES, BLS, BEA, LODES 7" "Balanced Panel" "model_`model'_`time_string'")
eststo clear

* Add comment to Latex file to keep track of model and date that produced table
tempname dst
local addcomment1 "% model_`model'_`time_string'"
local addcomment2 "% Parameter Estimates using demeaned values from Models of Change in net difference of SNAP dollars for `state' Counties `fyear'-`lyear'"
file open `dst' using `"`outputtex'\ParameterDemeaned.tex"', write append
file write `dst' "`addcomment1'"_n
file write `dst' "`addcomment2'"_n
file close `dst'


regress m0all`dep_var' m1all* m2all* if year == 2005

/*-------------------------------------------------------------------*/
/* Generate Descriptive Statistics for Centered Values               */
/*-------------------------------------------------------------------*/
/* These values do not help clarify the results
eststo clear
estpost tabstat m0all`dep_var' if year == 2005, ///
		statistics(min max p50 mean sd count)
esttab using ///
`"C:\Users\Nathanael\Dropbox\URSC PhD\Dissertation\Statatables\Model_`model'_`time_string'.rtf"' ///
, alignment(r) append label gaps modelwidth(20) ///
cells("count(fmt(%16.0fc)) min(fmt(%16.0fc)) max(fmt(%16.0fc)) p50(fmt(%16.0fc)) mean(fmt(%16.0fc)) sd(fmt(%16.0fc))") noobs ///
title(Summary of `state' Mean Net County Redemptions between `fyear' and `lyear') ///
nonumbers addnote("Source: Author Calculations, USDA, BEA" "model_`model'_`time_string'")
eststo clear

eststo clear
estpost tabstat c0all* c1all* c2all*, ///
		statistics(min max p50 mean sd count) columns(statistics)
esttab using ///
`"C:\Users\Nathanael\Dropbox\URSC PhD\Dissertation\Statatables\Model_`model'_`time_string'.rtf"' ///
, alignment(r) append label gaps modelwidth(20) ///
cells("count(fmt(%16.0fc)) min(fmt(%16.0fc)) max(fmt(%16.0fc)) p50(fmt(%16.0fc)) mean(fmt(%16.0fc)) sd(fmt(%16.0fc))") noobs ///
title(Basic Descriptive Statistics for Centered SNAP and Mobility Related Variables for `state' Counties `fyear'-`lyear') ///
nonumbers addnote("Source: Author Calculations, USDA, SAIPES, BLS, BEA, LODES 7" "model_`model'_`time_string'" ///
"Demeaned values calculated using STATA 12.1 Center Moduel From SSC")
eststo clear
*/
/*-------------------------------------------------------------------*/
/* Does model 2 have a statistically significant R2                  */
/*-------------------------------------------------------------------*/
/* This test does not help clarify results
/* Use Nestreg on the demeaned values to determine the incremental
increase between the 2 models */
nestreg: regress `dep_var' (m0all`dep_var') (c1all*) (c2all*)

/* Since dep_var is not normally distributed use beta vce(robust)
See Acock p. 255
*/
nestreg: regress `dep_var' (m0all`dep_var') (c1all*) (c2all*), beta vce(robust)
*/
/*-------------------------------------------------------------------*/
/* Generate Descriptive Statistics by Quintile                       */
/*-------------------------------------------------------------------*/

xtile `dep_var'quint = `dep_var', nquantiles(5)
/*
/* Curious to see how many counties actually change quanitiles */
bysort fips_county: center `dep_var'quint, ///
	prefix(cq) meansave(mq) replace


estpost tabstat t_pop htotal_s000 redamt bea_snap `dep_var' Prct_SNAP_bea `final_expvars' year, by(`dep_var'quint) ///
	statistics(mean sd) columns(statistics) listwise
	
esttab using ///
`"C:\Users\Nathanael\Dropbox\URSC PhD\Dissertation\Statatables\Model_`model'_`time_string'.rtf"' ///
, append gaps label modelwidth(20) main(mean %16.2fc) aux(sd %16.2fc) nostar unstack nomtitle obs ///
title(Mean and Standard Deviation of SNAP and Mobility Related Variables for `state' Counties by quintiles for `dep_varlabel'.) ///
nonumbers addnote("Source: Author Calculations, USDA, SAIPES, BLS, BEA, LODES 7" "model_`model'_`time_string'")
eststo clear

/* The quintiles based on absolute values are skewed going to try 
Prct_SNAP_bea */
xtile Prct_SNAP_bea_quint = Prct_SNAP_bea, nquantiles(5)

/* Curious to see how many counties actually change quanitiles */
bysort fips_county: center Prct_SNAP_bea_quint, ///
	prefix(cq2) meansave(mq2) replace

estpost tabstat t_pop htotal_s000 redamt bea_snap `dep_var' Prct_SNAP_bea `final_expvars' year, by(Prct_SNAP_bea_quint) ///
	statistics(mean sd) columns(statistics) listwise
	
esttab using ///
`"C:\Users\Nathanael\Dropbox\URSC PhD\Dissertation\Statatables\Model_`model'_`time_string'.rtf"' ///
, append gaps label modelwidth(20) main(mean %16.2fc) aux(sd %16.2fc) nostar unstack nomtitle obs ///
title(Mean and Standard Deviation of SNAP and Mobility Related Variables for `state' Counties by quintiles for `dep_varlabel' (%).) ///
nonumbers addnote("Source: Author Calculations, USDA, SAIPES, BLS, BEA, LODES 7" "model_`model'_`time_string'")
eststo clear

/* The quintiles based on largest changes from the mean */
xtile c0allPrct_SNAP_bea_quint = c0allPrct_SNAP_bea, nquantiles(5)

estpost tabstat c0all* c1all* c2all*, by(c0allPrct_SNAP_bea_quint) ///
	statistics(max min) columns(statistics) listwise
	
esttab using ///
`"C:\Users\Nathanael\Dropbox\URSC PhD\Dissertation\Statatables\Model_`model'_`time_string'.rtf"' ///
, append gaps label modelwidth(20) main(max %16.2fc) aux(min %16.2fc) nostar unstack nomtitle obs ///
title(Mean and Standard Deviation of Centered SNAP and Mobility Related Variables for `state' Counties by quintiles for centered `dep_varlabel' (%).) ///
nonumbers addnote("Source: Author Calculations, USDA, SAIPES, BLS, BEA, LODES 7" "model_`model'_`time_string'")
eststo clear
*/

gen pall = eall / t_pop
label variable pall "Percent of population in poverty"

gen punemployed = unemployed / t_pop
label variable punemployed "Percent of population unemployed"

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
// gen perSNAP_MG = meanmg / (`perSNAP_denom'/`perSNAP_divsor') // Medium Grocery Store

label variable perSNAP_SS "Supercenters Per `perSNAP_divsor' `perSNAP_Label'"
label variable perSNAP_SM "Supermarkets Per `perSNAP_divsor' `perSNAP_Label'"
label variable perSNAP_CS "Convenience Stores Per `perSNAP_divsor' `perSNAP_Label'"
label variable perSNAP_CO "Combination Grocery/Other Per `perSNAP_divsor' `perSNAP_Label'"
// label variable perSNAP_MG "Medium Grocery Stores Per Per `perSNAP_divsor' `perSNAP_Label'"


/* After looking at all of the above I am going to select this version */
estpost tabstat t_pop `dep_var' `final_expvars' , by(`dep_var'quint) /// pall punemployed  perSNAP_* prpt_iccse01 prpt_occse01
	statistics(mean) columns(statistics) listwise
	
esttab using ///
	`"`outputtex'\QuintilesofDepVar.tex"' ///
	, replace fragment booktabs label nonum nogaps noobs unstack compress ///
	refcat(occse01 "\emph{Mobility}" meanss "\emph{Retail Environment}",nolabel) ///
	main(mean %16.0fc) ///
	title(Quintiles of `dep_varlabel': Mean of SNAP and Mobility Related Variables for `state'.) ///
	addnote("Source: Author Calculations, USDA, SAIPES, BLS, BEA, LODES 7" "model_`model'_`time_string'")
eststo clear

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
/* End Log                                                           */
/*-------------------------------------------------------------------*/
*/
log close
