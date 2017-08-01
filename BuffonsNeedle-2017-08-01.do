/********-*********-*********-*********-*********-*********-*********/
/* Description of Program                                           */
/********-*********-*********-*********-*********-*********-*********/
// program:    BuffonsNeedle-2017-08-01.do
// task:       Implement Monte Carlo Simulation in Stata
// "Buffon's needle" (Dorrie 1965)
// Calculate Pi from a random process
// version:    Version 1
// project:    Generic
// author:     Nathanael Rosenheim \ August 1, 2017
// http://mathworld.wolfram.com/BuffonsNeedleProblem.html

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
numlabel _all, add // Print Prefix numeric values to value labels 
*set matsize 5000   // Set Matrix Size if program has a large matrix
*set max_memory 2g  // if the file size is larger than 64M change size

/********-*********-*********-*********-*********-*********-*********/
/* Generate Data                                                    */
/********-*********-*********-*********-*********-*********-*********/

set seed 12345673
* starting number of samples, works with any n, this value speeds up the while-loop
local n = 100
local percision = 10^10
* set post file to save output
* Post file will include estimate of Pi, upper and lower bound, and 
* Coeffiecient of Variation
postfile memname pi_e c1 c2 cov using pisim, replace
set obs `n'

* What is the length of the needle?
local l = 31
* What is the distance between lines
local D = 40
* the probability of the needle touching a line:
local pN = (2*`l')/(c(pi)*`D')
display `pN'

* Generate random values
generate a = runiformint(0,`percision')
* Does the needle touch the line?
generate I = 1 if a <= `pN'*`percision'
replace I = 0 if I == .
sum I
local m = `r(mean)'
local v = `r(Var)'/`n'
local se = sqrt(`v')
local c1 = `m' - 1.96*`se'
local c2 = `m' + 1.96*`se'
* Coefficients of variation
local cov = `se'/`m' 
display `cov'

local pi_e = (2*`l')/(`m'*`D')
display `pi_e' " 95% CI " `c1'

*this loop is used to determine the number of samples n needed to achieve COV = 1%
while `cov' > 0.01 {
	local inc = 1
	local n = `n' + `inc'
	quietly set obs `n'
	quietly replace a = runiformint(0,`percision') if a == .
	quietly replace I = 1 if a <=  `pN'*`percision'
	quietly replace I = 0 if I == .
	quietly sum I
	local m = `r(mean)'
	local v = `r(Var)'/`n'
	local se = sqrt(`v')
	local c1 = `m' - 1.96*`se'
	local c2 = `m' + 1.96*`se'
	* Coefficients of variation
	local cov = `se'/`m' 
	*display `cov'
	local pi_e = (2*`l')/(`m'*`D')
	*display `pi_e' " 95% CI " `c1'
	post memname (`pi_e') (`c1') (`c2') (`cov')
}
/********-*********-*********-*********-*********-*********-*********/
/* Scrub Output                                                     */
/********-*********-*********-*********-*********-*********-*********/
postclose memname
use pisim, clear

gen id = _n
label variable id "Sample Count"
local l = 31
local D = 40
gen upb = (2*`l')/(c2*`D')
gen lwb = (2*`l')/(c1*`D')
label variable upb "Upper Bound 95% CI"
label variable lwb "Lower Bound 95% CI"
label variable pi_e "Estimate of Pie"


/********-*********-*********-*********-*********-*********-*********/
/* Explore Output                                                   */
/********-*********-*********-*********-*********-*********-*********/

twoway rarea lwb upb id if cov >= .01, sort color(gs14) || ///
	line pi_e id if cov >= .01
