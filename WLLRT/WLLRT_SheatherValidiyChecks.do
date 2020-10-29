// include: 	Analysis/NPRSNAP-Sheatherch6.doi
// used by: 	NPRSNAP*.do analysis files
// task:		Checks model validity using methods set out by 
//				Sheather 2009 A Modern Approach to Regression with R
// author:		Nathanael Rosenheim \ 2015-01-20

* NOTE * This indclude file will add graphs to existing LaTex File

/*-------------------------------------------------------------------*/
/* Create Charts using Sheather 2009 Validity Check                  */
/*-------------------------------------------------------------------*/

* LaTex using PDFlatex does not recognize *.eps - *.pdf is the best option
local graph_name = "Scatter6_1`RoundDepVar'"
* Caption for Graph
local graphcaption = "Scatter Plot Matrix of the Predictors for `depvartitle'"
local graphsource = "USDA, SAIPES, BLS, BEA, LODES 7"
/*
Generate figure that shows a scatter plot matrix of the predictors.
Do the predictors seem to be related linarly at least approximately?
*/
//Sheather 2009 figure 6.1 and 6.9
graph matrix `model1_expvars' `model2_expvars'
graph export `"`output_fig'`graph_name'.pdf"', replace

file open `dst' using `LaTexFile', write append
file write `dst' "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%" _n 
file write `dst' "\begin{figure}[!htp]" _n
file write `dst' "\centering" _n
file write `dst' "\caption{`graphcaption'}" _n 
file write `dst' "\label{figure:`graph_name'}" _n 
file write `dst' "\includegraphics[width=\textwidth]{`PrjDir'`output_fig'`graph_name'.pdf}" _n
file write `dst' "\begin{flushleft}" _n
file write `dst' "\figsource{`graphsource'} \par" _n
file write `dst' "\end{flushleft}" _n
file write `dst' "\end{figure}" _n
file write `dst' "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%" _n 
file close `dst'

/*-------------------------------------------------------------------*/
/*  What is figure 6.1 showing?                                      */
/*-------------------------------------------------------------------*/
file open `dst' using `LaTexFile', write append
file write `dst' "What is Figure~\ref{figure:`graph_name'} showing?" _n
file write `dst' "Figure~\ref{figure:`graph_name'} provides a visual check" _n
file write `dst' "to see if the predictor variables linearly related\cite[p. 155]{Sheather2009}" _n
file write `dst' "Condition 6.7 - Are the predictor variables linearly related?
file write `dst' "If condition 6.7 holds then the residual plots may provide insight
file write `dst' "into how the model is misspecified.

	
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
	The effect of x1 is mediated by the differences across counties.
	By adding the dummy for each county we are estimating the pure effect of x1 (by
	controlling for the unobserved heterogeneity).
	Each dummy is absorbing the effects particular to each county.
	*/

	xi: regress `dep_var' `model_expvars' ///
		i.fips_county
	predict double stanres_`mnum', rstandard
	label variable stanres_`mnum' "Standardized Residuals `mname'"

	/* Create plots of the standardized residual against each predictor */
	foreach x_var of varlist `model_expvars'{
		local label_xvar : variable label `x_var'
		twoway scatter stanres_`mnum' `x_var' ///
		|| lfit stanres_`mnum' `x_var', legend(off) ///
		xtitle(`label_xvar') ytitle("Y") ///
		name(`x_var') nodraw
		local graphnames `graphnames' `x_var'
	}
	//Figure 6.2 
	display `graphnames'

	graph combine `graphnames', cols(2) xsize(10) ysize(10)  ///
		caption("Standardized Residual Plotted Against Each `mname' Predictor")
	graph export `"`outputtex_fig'/scatter_standardresid_`mnum'_predictors_`model'_`time_string'.png"', replace
	graph drop `graphnames'
    /*
	What is figure 6.2 checking?
	Figure 6.2 is checking to see if the variance of the error term is constant.
	Gauss-Markov Assumption for Multiple Linear Regression Models (MLR) - assumption
	number 5 ``Homoskedasticity - The error u has the same variance given any
	values of the explanatory variables. In other words, 
	Var(u \mid x_1,...,x_k)= \sigma^2.'' \cite[p. 94]{Wooldridge2009}
	
	For each plot of the standardized residual  
	variance of the standardized residuals is not constant
	Figure 6.2 contains a plot of standardized residuals against each
	explanatory variable. It is evident from Figure 6.2 that the variability in the
	standardized residuals tends to increase with each explanatory variable. Thus,
	the assumption that the variance of the errors is constant (homoskedasticity) 
	appears to be violated in this case (heteroskedasticity is present). 
	If, as in Figure 6.2 , the distribution of standardized residuals
	appears to be funnel shaped, there is evidence that the error variance is not
	constant.
	``However, the nonrandom patterns do not provide direct information on
    how the model is misspecified.'' \cite[p. 156]{Sheather2009}
	Figures 6.2 and 6.3 provide insight into misspecification if the conditional
	mean of Y given x is an unkown function of the linear function of X and if 
	the conditional mean of X_i given X_j is approximately equal to an 
	unknown linear function of X_j. In other words each predictor variable is a
	linear function of the other predictor variables (figure 6.1)
	(Sheather 2009 p. 155 equations 6.6, 6.7)
	Therefore the residual plots only provide insight into a missing predictor 
	variable if the missing predictor is linearly related to all other predictor
	variables.
	*/
	
	/*
	Figure 6.3 provides an alternative representation of homoskedasticity.
	A valid model has been fit if the residuals show a random patten for 
	any linear combination of the predictors. The fitted values plotted against
	the observed values should show a random pattern along the linear line.
	*/

	predict fitted_`mnum', xb
	label variable fitted_`mnum' "Fitted Values `mname'"
	//Figure 6.3
	twoway scatter `dep_var' fitted_`mnum' ///
	|| lfit `dep_var' fitted_`mnum', ytitle(DependentVariable) legend(off) ///
		title("Dependent Variable Plotted Against") ///
		subtitle("`mname' Fitted Values")
	graph export `"`outputtex_fig'/y_`mnum'_fitted_`model'_`time_string'.png"', replace
	
	// This produces 80+ plots avplots, recast(scatter)
