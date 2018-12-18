/********-*********-*********-*********-*********-*********-*********/
/* Description of Program                                           */
/********-*********-*********-*********-*********-*********-*********/
// program:    STATA15_AccessVariableMetaData_2018-12-18.do
// task:       Explore metadata in Stata 15, examples of how to output
// Version:    First Version
// project:    General Understanding of Stata 15
// author:     Nathanael Rosenheim
// Application to making codebooks using Stata Metadata

* Example code to access variable metadata in STATA

* Obtain basic dataset 
sysuse auto

* To access variable metadata 
* macro -- Extended macro functions
* help extended_fcn 

/*------------------------------------------------------------------*/
/* File level Metadata                                              */
/*------------------------------------------------------------------*/
* File Description
notes
describe

* What is the Label for the Data
local dtalabel : data label
display "`dtalabel'"

* Number of observations or rows in the datafile
local obs = _N
display "[Observations=`obs']"

* Number of variables or columns in the datafile
quietly describe
local varcount = `r(k)'
display "`[Variables=varcount']"

* Notes related to data file
* IF a datafile has notes it will have a count of notes in Note 0
capture local dtanotecount = `_dta[note0]'
if `dtanotecount' != . {
forvalues i = 1/`dtanotecount' {
	local notetext `"`_dta[note`i']'"'
	display `"`notetext'"'
}
}

* How is the data sorted
local dtasort : sortedby
display "[Sorted by=`dtasort']"


/*------------------------------------------------------------------*/
/* Variable level Metadata                                          */
/*------------------------------------------------------------------*/

* Metadata for individual variable
notes make
describe make

local varlabel : variable label make
display "[Label=`varlabel']"

local vartype : type make
display "[Type=`vartype']"

local varformat : format make
display "[Format=`varformat']"


* Count non missing values
count if !missing(make)
local varvalid = r(N)
display "[Valid=`varvalid']"

* Count missing values
count if missing(make)
local varmissing = r(N)
display "[Missing=`varmissing']"

* Output Variable Value Labels
* Check to see if variable has value label
local var foreign
local variable_valuelabel_name : value label `var'
display "`variable_valuelabel_name'"

* Does the variable have a value label?
if "`variable_valuelabel_name'" != "" {
	display ("Value Labels for `varlabel'")
	
	* determine the min and max values for the value labels
	quietly label list `variable_valuelabel_name'

	forvalues i = `r(min)'/`r(max)' {
		local value_label_text : label `variable_valuelabel_name' `i', ///
									strict // strict specifies that nothing 
										   // is to be returned if there is 
										   // no value label for #.
		* Determine the count of variable with value label
		quietly sum `var' if  `var' == `i'
		local varcount = `r(N)'
		
		// Output value label if count and text are not empty
		if `varcount' == 0 & "`value_label_text'" == "" {
			// If varcount is 0 and text is empty do nothing
		}
		else {
			display "[Value=`i'][Label=`value_label_text'][Cases=`varcount']"
		}
	}
}

* If the variable does not have a value label...
if "`variable_valuelabel_name'" == "" {
	display ("Variable `var' has no value labels")
}

* Output Variable Notes
* Store the number of notes with variable
local var foreign
* IF a variable has notes it will have a count of notes in Note 0
capture local notecount = ``var'[note0]'
display "`notecount'"

* add a note to make
note `var': Temporary note 1
capture local notecount = ``var'[note0]'
display "`notecount'"

if `notecount' != . {
forvalues i = 1/`notecount' {
	local notetext `"``var'[note`i']'"'
	display `"`notetext'"'
}
}
