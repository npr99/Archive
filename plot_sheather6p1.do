program plot_sheather6p1
version 12.1
syntax varlist

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
