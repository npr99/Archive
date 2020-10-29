* Preinstall the following programs:
* ssc install estout, replace // to create tables install estout
* ssc install fastcd, replace // great for changing working directory quickly
/*-------1---------2---------3---------4---------5---------6--------*/
/* Start Log File: Change working directory to project directory    */
/*-------1---------2---------3---------4---------5---------6--------*/

capture log close   // suppress error and close any open logs
log using work/WLLRT-Data01av1-CensusTract2000_2010-2015-10-07, replace text
/********-*********-*********-*********-*********-*********-*********/
/* Description of Program                                           */
/********-*********-*********-*********-*********-*********-*********/
// Do file name structure - where no spaces are included in file name:
	// 3-5 letter project mnemonic [-task] step [letter] [Vversion] 
	// [-description] yyyy-mm-dd.do
// program:    WLLRT-Data01av1-CensusTract2000_2010-2015-10-07.do
// project:    Wei Li Light Rail Transity
// author:     Nathanael Rosenheim \ Oct 7, 2015
// Project Planning Details:
/*
Look at 2000 and 2010 Decninial Census and ACS data
The files have been standardized (population characteristics)
and normalized (median household income)
The current plan is to see which Census Tracts have significant changes
in demographic characteristics between the 2 time periods.
The CTs with significant changes will be given a dummy value which could 
be included in a random effects panel model
*/

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
*set matsize 5000   // Set Matrix Size if program has a large matrix
set max_memory 2g  // if the file size is larger than 64M change size

/*-------------------------------------------------------------------*/
/* Set Provenance                                                    */
/*-------------------------------------------------------------------*/
// What is the do file name? What program is needed to replicate results?
global dofilename "WLLRT-Data01av1-CensusTract2000_2010-2015-10-07" 
global provenance "Provenance: ${dofilename}.do `c(filename)' `c(current_date)'"
global source "2000 Decinial Census, 2010 Decinial Census, 2008-2012 ACS, NHGIS" // what is the data source
local outputfile "Work/${dofilename}.rtf" // location to save output file

/********-*********-*********-*********-*********-*********-*********/
/* Scrub Data - Derive Stata Files from Sources                     */
/********-*********-*********-*********-*********-*********-*********/
/* Common scrubbing tasks
- Convert data from one format to another
- Filter observations
- Extract and replace values
- Split, merge, stack, or extract columns */

/*-------------------------------------------------------------------*/
/* Demographic Characteristics by Census Tract for 2000 and 2010     */
/*-------------------------------------------------------------------*/
* Get variable labels from second row of CSV File
import delimited using "Posted/nhgis0010_csv/nhgis0010_ts_geog2010_tract.csv", ///
	clear varnames(1) rowrange(2:2)
	
* store variable labels
foreach v of varlist * {
   local l`v' = `v'
   if `"`l`v''"' == "" {
   local l`v' "`v'"
   }
 } 
 * import data starting in Row 3
 import delimited using "Posted/nhgis0010_csv/nhgis0010_ts_geog2010_tract.csv", ///
	clear varnames(1) rowrange(3)

	
* Attach the saved labels after collapse
foreach v of varlist *  {
	* Remove units from lable
	local temp_lable=substr("`l`v''",1,.)
	label var `v' "`temp_lable'"
}

* convert string values to numeric
destring cn* cm* cp*, replace

* compress file
compress

* create merge variables
gen panelyear = datayear

gen fips_county = statea+countya

order fips_county gisjoin datayear panelyear

sort gisjoin panelyear

notes:  Source nhgis0010_ts_geog2010_tract: Minnesota Population Center. ///
	National Historical Geographic Information ///
    System: Version 2.0. Minneapolis, MN: University of Minnesota 2011.
notes:  US Census Bureau - Texas County Characteristics Datasets:
notes:  nhgis0010_ts_geog2010_tract retrieved from: ///
		"https://www.nhgis.org/"
notes: $provenance
saveold "work/WLLRT-nhgis0010_ts_geog2010_tract.dta", replace 

/*-------------------------------------------------------------------*/
/* Income Data by Census Tract for 2000 and 2010                     */
/*-------------------------------------------------------------------*/

* Get variable labels from second row of CSV File
import delimited using "Posted/nhgis0010_csv/nhgis0010_ts_nominal_tract.csv", ///
	clear varnames(1) rowrange(2:2)
	
* store variable labels
foreach v of varlist * {
   local l`v' = `v'
   if `"`l`v''"' == "" {
   local l`v' "`v'"
   }
 } 
 * import data starting in Row 3
 import delimited using "Posted/nhgis0010_csv/nhgis0010_ts_nominal_tract.csv", ///
	clear varnames(1) rowrange(3)

	
* Attach the saved labels after collapse
foreach v of varlist *  {
	* Remove units from lable
	local temp_lable=substr("`l`v''",1,.)
	label var `v' "`temp_lable'"
}

* convert string values to numeric
destring b* a*, replace

* compress file
compress

* Drop years prior to 2000
keep if year == "2000" | year == "2008-2012"

* create merge variables
gen panelyear = "2000"
replace panelyear = "2010" if year == "2008-2012" 

gen fips_county = statea+countya

order fips_county gisjoin year panelyear

sort gisjoin panelyear

notes:  Source nhgis0010_ts_nominal_tract: Minnesota Population Center. ///
	National Historical Geographic Information ///
    System: Version 2.0. Minneapolis, MN: University of Minnesota 2011.
notes:  US Census Bureau - Texas County Characteristics Datasets:
notes:  nhgis0010_ts_nominal_tract retrieved from: ///
		"https://www.nhgis.org/"
notes: $provenance
saveold "work/WLLRT-nhgis0010_ts_nominal_tract.dta", replace 


/*-------------------------------------------------------------------*/
/* Merge Data Files Together                                         */
/*-------------------------------------------------------------------*/

use "work/WLLRT-nhgis0010_ts_geog2010_tract.dta", clear
sort gisjoin panelyear
merge gisjoin panelyear using "work/WLLRT-nhgis0010_ts_nominal_tract.dta"

* Check merge
tab _merge

* check census tracts in the demography file but not in the income file
tab state panelyear if _merge == 1
* check census tracts in the income file but not in the demography file
tab state panelyear if _merge == 2
* check census tracts in the both files
tab state panelyear if _merge == 3

drop _merge

/*-------------------------------------------------------------------*/
/* Merge in CBSA data                                                */
/*-------------------------------------------------------------------*/

sort fips_county

merge fips_county using "posted/WLLRT_cbsatocountycrosswalk.dta"
tab _merge
tab state if _merge == 2

drop if countyname == "STATEWIDE"
* a few counties in VI, PR and mostly AK

drop if _merge == 2

tab _merge

drop _merge
saveold "work/WLLRT-Data01av1-CensusTract2000_2010.dta", replace 
/*-------------------------------------------------------------------*/
/* Merge in Census Tract Area Data                                   */
/*-------------------------------------------------------------------*/
use "work/WLLRT_US_tract_2010.dta", clear
notes: WLLRT_US_tract_2010.dta created from NHGIS US Tract 2010 Shape file

sort gisjoin

saveold "work/WLLRT_US_tract_2010.dta", replace

use "work/WLLRT-Data01av1-CensusTract2000_2010.dta", clear

sort gisjoin

merge  gisjoin using  "work/WLLRT_US_tract_2010.dta"
tab _merge
tab state panelyear if _merge == 1

gen missingjoin = 0
replace missingjoin = 1 if _merge == 1
label variable missingjoin "Census Tract not in 2010 NHGIS List"


saveold "work/WLLRT-Data01bv1-CensusTract2000_2010.dta", replace 


/*-------------------------------------------------------------------*/
/* Generate new variables                                            */
/*-------------------------------------------------------------------*/
use "work/WLLRT-Data01bv1-CensusTract2000_2010.dta", clear
/*
Population density (# of persons per square mile)
Household Income ($)
Percentage of female (0-1)
Percentage of people 65 years or older (0-1)
Percentage of people under 18 years old (0-1)
Percentage of people with a college degree (0-1)
Percentage of African American population (0-1)
Percentage of Hispanic population (0-1)
Percentage of White population  (0-1)
*/

* Sum values for total population
gen pop_t = 0
label variable pop_t "Total Population"
notes pop_t: From WLLRT-nhgis0010_ts_geog2010_tract sum of all Persons Variables 

gen pop_m = 0
label variable pop_m "Male Population"
notes pop_m: From WLLRT-nhgis0010_ts_geog2010_tract sum of all Persons Female Variables
 
gen pop_f = 0
label variable pop_f "Female Population"
notes pop_f: From WLLRT-nhgis0010_ts_geog2010_tract sum of all Persons Male Variables 

gen pop_65 = 0
label variable pop_65 "65 years or older"
notes pop_65: From WLLRT-nhgis0010_ts_geog2010_tract sum of all Persons 65 and over

gen pop_18 = 0
label variable pop_18 "18 years old"
notes pop_18: From WLLRT-nhgis0010_ts_geog2010_tract sum of all Persons Under 5 and up to 18 

gen pop_AA = 0
label variable pop_AA "African American population"
notes pop_AA: From WLLRT-nhgis0010_ts_geog2010_tract ///
	CP7AC: Persons: Not Hispanic or Latino ~ Black or African American alone ///
	or in combination with one or more other races
 
gen pop_HS = 0
label variable pop_HS "Hispanic population"
notes pop_HS: From WLLRT-nhgis0010_ts_geog2010_tract ///
	CP7AH: Persons: Hispanic or Latino ~ Total races tallied

gen pop_W = 0
label variable pop_W "White population"
notes pop_W: From WLLRT-nhgis0010_ts_geog2010_tract ///
	CP7AB: Persons: Not Hispanic or Latino ~ White alone or in combination with one or more other races

foreach v of varlist cn7* {
	local l`v' : variable label `v'
	if substr("`l`v''",1,8) == "Persons:" {
		quietly: replace pop_t = pop_t + `v'
		}
	if substr("`l`v''",1,15) == "Persons: Female" {
		quietly: replace pop_f = pop_f+ `v'
		}
	if substr("`l`v''",1,13) == "Persons: Male" {
		quietly: replace pop_m = pop_m+ `v'
		}
	forvalues age = 65/85 {
	if strpos("`l`v''","Persons: Male ~ `age'") == 1 {
		quietly: replace pop_65 = pop_65 + `v'
		}
	if strpos("`l`v''","Persons: Female ~ `age'") == 1 {
		quietly: replace pop_65 = pop_65 + `v'
		}
	}

	if strpos("`l`v''","Persons: Male ~ Under 5") == 1 {
		quietly: replace pop_18 = pop_18 + `v'
		}
	if strpos("`l`v''","Persons: Female ~ Under 5") == 1 {
		quietly: replace pop_18 = pop_18 + `v'
		}
	forvalues age = 5/17 {
	if strpos("`l`v''","Persons: Male ~ `age' to") == 1 {
		quietly: replace pop_18 = pop_18 + `v'
		}
	if strpos("`l`v''","Persons: Female ~ `age' to") == 1 {
		quietly: replace pop_18 = pop_18 + `v'
		}
	}
}	

order pop_*
/* 
use the following to get non overlapping Race Ethnicity values
CP7AB: Persons: Not Hispanic or Latino ~ White alone or in combination with one or more other races
CP7AC: Persons: Not Hispanic or Latino ~ Black or African American alone or in combination with one or more other races
CP7AH:       Persons: Hispanic or Latino ~ Total races tallied
*/
replace pop_W = cp7ab
replace pop_AA = cp7ac
replace pop_HS = cp7ah

format pop* %15.2fc

* percentage values for population

* Sum values for total population

gen ppop_f = pop_f / pop_t
label variable ppop_f "Female Population (%)"

gen ppop_65 = pop_65 / pop_t 
label variable ppop_65 "65 years or older (%)"

gen ppop_18 = pop_18 / pop_t 
label variable ppop_18 "18 years old (%)"

gen ppop_AA = pop_AA / pop_t
label variable ppop_AA "African American population (%)"

gen ppop_HS = pop_HS / pop_t
label variable ppop_HS "Hispanic population (%)"

gen ppop_W = pop_W / pop_t
label variable ppop_W "White population (%)"

format ppop* %6.3f
order ppop*

* Generate household income variable
gen pop_income = b79aa
label variable pop_income "Median income in previous year"
notes: pop_income: From WLLRT-nhgis0010_ts_nominal_tract ///
	b79aa: Median income in previous year: Households
	
* Calcuate density
gen pop_dnsty = pop_t / (aland10/1000 * 0.386102)
label variable pop_dnsty "Population Density (persons per sq miles)"
notes pop_dnsty: From population total derived from WLLRT-nhgis0010_ts_geog2010_tract ///
	divided by ALAND10 in square meter convert to sq miles from NHGIS WLLRT_US_tract_2010
	

order ppop_* pop_*

notes

saveold "work/WLLRT-Data01cv1-CensusTract2000_2010.dta", replace

/*-------------------------------------------------------------------*/
/* Drop Variables                                                    */
/*-------------------------------------------------------------------*/
use "work/WLLRT-Data01cv1-CensusTract2000_2010.dta", clear

local keepvars cbsa cbsaname fips_county gisjoin datayear panelyear geogyear ///
	state statea county countya tracta                             ///
	pop* ppop* missingjoin
	
keep `keepvars'
order `keepvars'
	
notes: Last updated: $provenance

saveold "work/WLLRT-Data01dv1-CensusTract2000_2010.dta", replace

/*-------------------------------------------------------------------*/
/* Select Study Area Observations                                    */
/*-------------------------------------------------------------------*/
use "work/WLLRT-Data01dv1-CensusTract2000_2010.dta", clear

* Keep inlist can only have 10 values therefore need to create a study area dummy

gen studyarea = 0
label variable studyarea "In WLLRT 12 CBSA study area"

* CBSA's in study area
local cbsa_studyarea /// 
38060 /// Phoenix-Mesa-Glendale, AZ Metropolitan Statistical Area
31100 /// Los Angeles-Long Beach-Santa Ana, CA Metropolitan Statistical Area
31084 /// 31100 Los Angeles-Long Beach-Glendale, CA Metropolitan Division
42044 /// 31100 Santa Ana-Anaheim-Irvine, CA Metropolitan Division
40900 /// Sacramento--Arden-Arcade--Roseville, CA Metropolitan Statistical Area
41740 /// San Diego-Carlsbad-San Marcos, CA Metropolitan Statistical Area
19740 /// Denver-Aurora-Broomfield, CO Metropolitan Statistical Area
16740 /// Charlotte-Gastonia-Rock Hill, NC-SC Metropolitan Statistical Area
38900 /// Portland-Vancouver-Hillsboro, OR-WA Metropolitan Statistical Area
26420 /// Houston-Sugar Land-Baytown, TX Metropolitan Statistical Area
12420 /// Austin-Round Rock-San Marcos, TX Metropolitan Statistical Area
19100 /// Dallas-Fort Worth-Arlington, TX Metropolitan Statistical Area
19124 /// 19100 Dallas-Plano-Irving, TX Metropolitan Division
23104 /// 19100 Fort Worth-Arlington, TX Metropolitan Division
16740 /// Charlotte-Gastonia-Rock Hill, NC-SC Metropolitan Statistical Area
41620 /// Salt Lake City, UT Metropolitan Statistical Area
42660 /// Seattle-Tacoma-Bellevue, WA Metropolitan Statistical Area
42644 /// 42660 Seattle-Bellevue-Everett, WA Metropolitan Division
45104  // 42660 Tacoma, WA Metropolitan Division

foreach cbsakeep in `cbsa_studyarea' {
display "`cbsakeep'"
replace studyarea = 1 if cbsa == "`cbsakeep'"
}

tab cbsaname if studyarea == 1

* create new cbsa code that combines LA, DFW, and Seattle
gen cbsacode = cbsa
label variable cbsacode "CBSA Code"
* LA
replace cbsacode = "31100" if cbsa == "31084" 
replace cbsacode = "31100" if cbsa == "42044" 
* DFW
replace cbsacode = "19100" if cbsa == "19124" 
replace cbsacode = "19100" if cbsa == "23104" 
* Seattle
replace cbsacode = "42660" if cbsa == "42644" 
replace cbsacode = "42660" if cbsa == "45104" 

* Create shorter CBSA Name Labels
gen cbsaname2 = ""
label variable cbsaname2 "CBSA Name"

replace cbsaname2 = "Phoenix-Mesa-Glendale, AZ" if cbsacode == "38060"
replace cbsaname2 = "Los Angeles-Long Beach-Santa Ana, CA" if cbsacode == "31100"
replace cbsaname2 = "Sacramento--Arden-Arcade--Roseville, CA" if cbsacode == "40900"
replace cbsaname2 = "San Diego-Carlsbad-San Marcos, CA" if cbsacode == "41740"
replace cbsaname2 = "Denver-Aurora-Broomfield, CO" if cbsacode == "19740"
replace cbsaname2 = "Charlotte-Gastonia-Rock Hill, NC-SC" if cbsacode == "16740"
replace cbsaname2 = "Portland-Vancouver-Hillsboro, OR-WA" if cbsacode == "38900"
replace cbsaname2 = "Houston-Sugar Land-Baytown, TX" if cbsacode == "26420"
replace cbsaname2 = "Austin-Round Rock-San Marcos, TX" if cbsacode == "12420"
replace cbsaname2 = "Dallas-Fort Worth-Arlington, TX" if cbsacode == "19100"
replace cbsaname2 = "Salt Lake City, UT" if cbsacode == "41620"
replace cbsaname2 = "Seattle-Tacoma-Bellevue, WA" if cbsacode == "42660"

* Generate CBSACODE for rural areas
replace cbsacode = statea + "999" if cbsa == ""
replace cbsaname2 = state + " Rural" if cbsacode == statea + "999"

notes: Last updated: $provenance

saveold "work/WLLRT-Data01ev1-CensusTract2000_2010.dta", replace


/*-------------------------------------------------------------------*/
/* Create Variables that show change between 2000 and 2010           */
/*-------------------------------------------------------------------*/
use "work/WLLRT-Data01ev1-CensusTract2000_2010.dta", clear

* generate a panel var that is numeric
gen panelvar = statea + countya + tracta

destring panelvar, replace
format panelvar %14.0f

destring panelyear, replace
format panelyear %4.0f

order panelvar panelyear

sort panelvar panelyear

* Label values for Population Distribution
label define ppop_lmh_lbl 0 "0. No distribution data"
label define ppop_lmh_lbl 1 "1. 1 sd below mean", add
label define ppop_lmh_lbl 2 "2. 1 sd around mean", add
label define ppop_lmh_lbl 3 "3. 1 sd above mean", add

* Label values for Population Change
label define ppop_chng_lbl 0 "0. No distribution data"
label define ppop_chng_lbl 1 "1. Low 2000 - Low 2010", add
label define ppop_chng_lbl 2 "2. Low 2000 - Mid 2010", add
label define ppop_chng_lbl 3 "3. Low 2000 - High 2010", add
label define ppop_chng_lbl 4 "4. Mid 2000 - Low 2010", add
label define ppop_chng_lbl 5 "5. Mid 2000 - Mid 2010", add
label define ppop_chng_lbl 6 "6. Mid 2000 - High 2010", add
label define ppop_chng_lbl 7 "7. High 2000 - Low 2010", add
label define ppop_chng_lbl 8 "8. High 2000 - Mid 2010", add
label define ppop_chng_lbl 9 "9. High 2000 - High 2010", add

local change_vars ppop_* pop_income pop_dnsty

foreach v of varlist `change_vars' {

sort panelvar panelyear

local l`v' : variable label `v'

gen  lmh_`v' = 0
label variable  lmh_`v' "`l`v'' Distribution"
order  lmh_`v'

label values  lmh_`v' ppop_lmh_lbl 

bysort cbsacode panelyear: egen m_`v' = mean(`v')
label variable m_`v' "Mean `l`v'' for CBSA Year"
bysort cbsacode panelyear: egen sd_`v' = sd(`v')
label variable sd_`v' "SD `l`v'' for CBSA Year"

quietly: replace lmh_`v' = 1 if  `v' < m_`v' - sd_`v'
quietly: replace lmh_`v' = 2 if  `v' >= m_`v' - sd_`v'
quietly: replace lmh_`v' = 3 if  `v' > m_`v' + sd_`v' &  `v' < .
notes lmh_`v': Values based on the distribution for the CBSA in specific year. ///
	Does the Census Tract `l`v'' value fall into the low, mid and high parts ///
	of the distribution based on mean and sd of the CBSA in the data year.

gen  chng_`v' = 0
label variable  chng_`v' "`l`v'' change between 2000 and 2010"
notes chng_`v': When comparing the distribution for `l`v'' in the CBSA for each year ///
	does the Census Tract change distribution places. Since we do not know which ///
	year the Census Tract changes this variable simply highlights areas where change ///
	does happen. The changes are based on the distrubtions for each year, therefore ///
	the change does not reflect shifts in the metro area. For example, if the ///
	mean value for the metro area `l`v'' changes between 2000 and 2010 a Census Tract ///
	that does not change with the metro trend may move from the middle part of the ///
	distribution to the lower part of the distribution (based on standard deviations).
	
order  chng_`v'
label values  chng_`v' ppop_chng_lbl

quietly: bysort panelvar: replace  chng_`v' = 1 if   lmh_`v'[1] == 1 &  lmh_`v'[2] == 1
quietly: bysort panelvar: replace  chng_`v' = 2 if   lmh_`v'[1] == 1 &  lmh_`v'[2] == 2
quietly: bysort panelvar: replace  chng_`v' = 3 if   lmh_`v'[1] == 1 &  lmh_`v'[2] == 3
quietly: bysort panelvar: replace  chng_`v' = 4 if   lmh_`v'[1] == 2 &  lmh_`v'[2] == 1
quietly: bysort panelvar: replace  chng_`v' = 5 if   lmh_`v'[1] == 2 &  lmh_`v'[2] == 2
quietly: bysort panelvar: replace  chng_`v' = 6 if   lmh_`v'[1] == 2 &  lmh_`v'[2] == 3
quietly: bysort panelvar: replace  chng_`v' = 7 if   lmh_`v'[1] == 3 &  lmh_`v'[2] == 1
quietly: bysort panelvar: replace  chng_`v' = 8 if   lmh_`v'[1] == 3 &  lmh_`v'[2] == 2
quietly: bysort panelvar: replace  chng_`v' = 9 if   lmh_`v'[1] == 3 &  lmh_`v'[2] == 3

tab  chng_`v'

} 
* check data
tab lmh_ppop_HS if cbsacode == "12420" & panelyear == 2010
summarize ppop_HS if cbsacode == "12420" & panelyear == 2010
local m=r(mean)
local sd=r(sd)
local low = `m'-`sd'
local high=`m'+`sd'

twoway histogram ppop_HS if cbsacode == "12420" & panelyear == 2010 , frequency  ///
   fc(none) lc(green) xline(`m') ///
   xline(`low', lc(blue)) xline(`high', lc(blue)) scale(0.5) ///
   text(0.12 `m' `"mean = `=string(`m',"%6.2f")'"', ///
   color(red) orientation(vertical) placement(2))
   
saveold "work/WLLRT-Data01fv1-CensusTract2000_2010.dta", replace

/*-------------------------------------------------------------------*/
/* Create Census Tract File for Merge with LODES Panel               */
/*-------------------------------------------------------------------*/

* I need to files for the Merge one with just Census Tract Data
* Second with data for 2000 and 2010
use "work/WLLRT-Data01fv1-CensusTract2000_2010.dta", clear

gen w_censustractfp = statea + countya + tracta
order w_censustractfp 

* first make file with Census Tract Level Variables that do not change
keep w_censustractfp chng_*

sort w_censustractfp
saveold "work/WLLRT-Data01gv1-CensusTract_chngvars.dta", replace

/*-------------------------------------------------------------------*/
/* Create Census Tract File for Merge with LODES Panel years         */
/*-------------------------------------------------------------------*/

use "work/WLLRT-Data01fv1-CensusTract2000_2010.dta", clear

gen w_censustractfp = statea + countya + tracta
order w_censustractfp 

* create numeric year for merge
destring datayear, generate(year)
label variable year "Panel Year"
order w_censustractfp year
 
* drop uneeded variables
keep w_censustractfp year pop_* ppop_*

* expand data set to have 2000 - 2013 
gen expandn = 0

* for the 2000 data year expand 6 times
replace expandn = 6 if year == 2000

* for the 2010 data year expand 8 times
replace expandn = 8 if year == 2010

* expand dataset
expand expandn, generate(duplicate)

* generate panel year variable
bysort w_censustractfp: gen panelyear = 1999 + _n

order panelyear duplicate

destring w_censustractfp, generate(panelvar)

* generate interpolated values for demography

local interpvars pop_* ppop_*

foreach v of varlist `interpvars' {
* remove values for years not 2000 or 2010
replace `v' = . if panelyear != 2000 & panelyear != 2010

sort panelvar panelyear
tsset panelvar panelyear

tsfill

bysort w_censustractfp: ipolate `v' panelyear, gen(i`v') epolate
order i`v' `v'

local l`v' : variable label `v'
label variable i`v' "Interpolated `l`v''"
notes i`v': $provenance values from 2000 and 2010 Census via NHGIS ///
standardized to Census 2010 Tracts. Values foe 2011-2013 are extrapolated.
}

* put 2000 pop value into 2002 for the purpose of keeping the information in the panel

local interpvars pop_* ppop_*

foreach v of varlist `interpvars' {
quietly: replace `v' = `v'[1] if panelyear == 2002

notes `v': The value for `v' in 2002 is actually the 2000 Census Value. ///
The i`v' value for 2002 is the interpolation of 2002 from 2000 to 2010.
} 

* drop years outside of panel
drop if panelyear == 2000 | panelyear == 2001

drop year
rename panelyear year // for merge
order w_censustractfp year

drop panelvar expandn duplicate

sort w_censustractfp year

saveold "work/WLLRT-Data01hv1-CensusTract_2002_2013.dta", replace

/*-------------------------------------------------------------------*/
/* End Log                                                           */
/*-------------------------------------------------------------------*/
log close

/*------------------------------------------------------------------*/
/* Print Codebook                                                   */
/*------------------------------------------------------------------*/
use "work/WLLRT-Data01fv1-CensusTract2000_2010.dta", clear
log using work/WLLRT-Data01fv1-CensusTract2000_2010_codebook_2015-10-06, replace text

describe

codebook, notes
notes


log close
exit
