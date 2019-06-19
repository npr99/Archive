* Preinstall the following programs:
* ssc install tabcount, replace // used to see result codes 
* ssc install labutil, replace // utilities needed to clean up value lables
/*-------1---------2---------3---------4---------5---------6--------*/
/* Start Log File: Change working directory to project directory    */
/*-------1---------2---------3---------4---------5---------6--------*/
capture log close   // suppress error and close any open logs
log using Q2Stata_1av1_ImportQualtrics_2019-06-18, replace text
/********-*********-*********-*********-*********-*********-*********/
/* Description of Program                                           */
/********-*********-*********-*********-*********-*********-*********/
// program:    Q2Stata_1av1_ImportQualtrics_2019-06-18.do
// task:       Read In Qualtrics Data to Stata
// version:    First Version
// project:    Q2Stata - Generic Program Qualtrics to Stata 15
// author:     Nathanael Rosenheim \ April 14, 2019

/*------------------------------------------------------------------*/
/* Control Stata                                                    */
/*------------------------------------------------------------------*/
* Generic do file that sets up stata environment
clear all          // Clear existing data files
macro drop _all    // Drop macros from memory
version 15       // Set Version
set more off       // Tell Stata to not pause for --more-- messages
set varabbrev off  // Turn off variable abbreviations
set linesize 80    // Set Line Size - 80 Characters for Readability
numlabel _all, add // Print Prefix numeric values to value labels 
*set matsize 5000   // Set Matrix Size if program has a large matrix
*set max_memory 2g  // if the file size is larger than 64M change size

/*-------------------------------------------------------------------*/
/* Set Provenance                                                    */
/*-------------------------------------------------------------------*/
// What is the do file name? What program is needed to replicate results?
global dofilename "Q2Stata_1av1_ImportQualtrics_2019-06-18" 
global source "Qualtrics to Stata a program by Nathanael Rosenheim" // what is the data source

/*-------------------------------------------------------------------*/
/* Establish Project Directory Structure                             */
/*-------------------------------------------------------------------*/
* Stata can create folders if they do not exist
capture mkdir ${dofilename}     // Folder saves all outputs from do file
global savefolder ${dofilename} 

/********-*********-*********-*********-*********-*********-*********/
/* Obtain Data                                                      */
/********-*********-*********-*********-*********-*********-*********/
* Data downloaded from Qualtrics
global sourcefolder "../../SourceData/qualtrics.com"
global sourcefile "[enter name of source file here]"

insheet using "${sourcefolder}/${sourcefile}.csv", clear
global provenance "Provenance: ${dofilename}.do `c(filename)' `c(current_date)'"
notes : Source Data File: "${sourcefolder}/${sourcefile}.csv"

/*-------------------------------------------------------------------*/
/* Fill in Question Text in Notes and Relabel                        */
/*-------------------------------------------------------------------*/

foreach var of varlist * {
	*Rename Variable with information in row 1
	local varname = `var'[1]
	* Remove spaces and special characters from varname
	local varname = subinstr("`varname'"," ","",.) // Remove spaces
	local varname = subinstr("`varname'","(","",.) // Remove open parenthesis (
	local varname = subinstr("`varname'",")","",.) // Remove closed parenthesis )
	local varname = subinstr("`varname'",".","_",.) // Replace . with _
	local varname = subinstr("`varname'","#","_",.) // Replace # with _
	display "`var' `varname'"
	rename `var' `varname'
}

* Save question text to notes
foreach var of varlist * {
	* CSV file Question Text is in row 2
	local questiontext = `var'[2]
	* Notes may have square brackets which provide background information
	* If the note has a square bracket replace "[" with "{break}"
	* The "{break}" tells Stata Markup and Control Language (SMCL)
	*   to skip a line in the note - this will help with readability
	local questiontext = subinstr("`questiontext'","[","{break}",.)
	local questiontext = subinstr("`questiontext'","]","{break}",.)
	* Save the question text as a note
	* if question text already exists note will be in the second position
	notes `var': [Question Text] `questiontext'
}

/*-------------------------------------------------------------------*/
/* Label Variables                                                   */
/*-------------------------------------------------------------------*/

* Save question text to notes
foreach var of varlist * {
	* CSV file Variable Label is in row 2
	local varlabel = `var'[2]
	* The Variable label is either the entire value in row 2
	** OR The first part before the first period
	** OR The Question plus the number
	
	* Where is the first period
	local first_period_position = strpos("`varlabel'",".")-1
	
	* If first position is negative then label is the entire value
	if `first_period_position' <= 0 {
		label variable `var' "`varlabel'"
	}
	if `first_period_position' > 0 {
		local varlabel2 = substr("`varlabel'", 1, `first_period_position')
		
		* look to see if the question number with a dash before it shows up 
		* later in the text. If it does the question is a sub question
		local subquestiontext = " - `varlabel2'"

		* look for subquestion text
		local subquestiontext_position = strpos("`varlabel'","`subquestiontext'")
		if `subquestiontext_position' > 0 {
			local varlabel2 = trim(substr("`varlabel'",`subquestiontext_position'+2,.))
		}
		
		label variable `var' "Question `varlabel2'"
	}
}

/*-------------------------------------------------------------------*/
/* Drop Non Data Observations                                        */
/*-------------------------------------------------------------------*/

* Now that labels and notes are saved
* Drop rows 1, 2, and 3
drop if inlist(_n,1,2,3)

/*-------------------------------------------------------------------*/
/* Destring and Compress File                                        */
/*-------------------------------------------------------------------*/

* Destring all variables
destring, replace

* Compress all variables
compress

/*-------------------------------------------------------------------*/
/* Convert Categorical Variables to Numeric and Label Values         */
/*-------------------------------------------------------------------*/
* For this to work Qualtrics needs to be formatted in a specific way:
* For example, if there is a yes no question the question text in 
* Qualtrics needs to have the categorical codes with the response:
* 1. Yes
* 2. No

* Loop through all question variables
foreach var of varlist Q* {

display "Variable under review: `var'"

	* Loop through unique values of all  variables
	* Check to make sure all are formatted correctly
	levelsof `var'
	local total_number_of_unique_values = r(r)
	local count_of_categorical_values = 0
	capture foreach level in `r(levels)' {
		local numericposition = strpos("`level'",".")-1
		* If numeric position is negative then do not label values
		if `numericposition' <= 0 {
			display "`var': `level' Not a categorical format"
			break
		}
		* The variable level has a period - but does it have a numeric value
		if `numericposition' > 0 {
			* Store numeric value to label value
			local numeric = substr("`level'", 1, `numericposition')  
			capture confirm integer number `numeric'
			if _rc { // error no number before period
				local variable_is_not_labeled = 1
				display "`var': `level' Not a categorical format"
				break
			}
			if !_rc { // No error - there is a number before the period
				display "`var': `level' Is a categorical format"
				local count_of_categorical_values = `count_of_categorical_values' + 1
			}
		}
	}

	* Loop through unique values of all  variables if all are formatted correctly
	if `count_of_categorical_values' == `total_number_of_unique_values' {
		levelsof `var'
		foreach level in `r(levels)' {
			* store numeric value
			local numericposition = strpos("`level'",".")-1
			* Store numeric value to label value
			local numeric = substr("`level'", 1, `numericposition')  
			
			* Create value lable for numeric level
			capture label define `var'_l `numeric' "`level'", add
			* Replace variable with numeric value
			replace `var' = "`numeric'" if `var' == "`level'"
		}

		destring `var', replace
		label values `var' `var'_l
		tab `var', nolabel missing
		tab `var', missing
		tabcount `var', v(0/`r(r)') zero missing
	}

}


/*-------------------------------------------------------------------*/
/* Drop Test and Preview Mode                                        */
/*-------------------------------------------------------------------*/

tab DistributionChannel, missing

* drop the test observations
drop if DistributionChannel == "preview"

/*-------------------------------------------------------------------*/
/* Check Status and Confirmation                                     */
/*-------------------------------------------------------------------*/

tab Progress, missing

/*-------------------------------------------------------------------*/
/* Add To the Data File                                              */
/*-------------------------------------------------------------------*/

notes : Program to replicate Data File: ${dofilename}.do

/*-------------------------------------------------------------------*/
/* Save File                                                         */
/*-------------------------------------------------------------------*/

save "${dofilename}/${dofilename}.dta", replace

/*-------------------------------------------------------------------*/
/* End Do File                                                       */
/*-------------------------------------------------------------------*/
log close
exit

