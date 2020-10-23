/*-------------------------------------------------------------------*/
/*       Program for Building Balanced Panel Data Set                */
/*       with SNAP Data from 2006-2010. For Dissertation Research    */
/*       Model 3 – Spatial Lag Model                                 */
/*          by Nathanael Proctor Rosenheim                           */
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
/* Date Last Updated: 18Feb15                                        */
/*-------------------------------------------------------------------*/
/* Questions or problem reports concerning this material may be      */
/* addressed to the author on github: https://github.com/npr99       */
/*                                                                   */
/*-------------------------------------------------------------------*/


/*-------------------------------------------------------------------*/
/* Research Question                                                 */
/*-------------------------------------------------------------------*/
/*
How do mobility and the locations of food retailers shape spending 
patterns among poorer households?
*/
/*-------------------------------------------------------------------*/
/* Model Hypothesis                                                  */
/*-------------------------------------------------------------------*/
/*
Hypothesis 1: The mobility of low-income populations within a county 
will have a negative effect on the amount of SNAP benefits redeemed
within a county.
*/
/*-------------------------------------------------------------------*/
/* Data Sources                                                      */
/*-------------------------------------------------------------------*/
/*
See included programs for more details on data sources
*/
/*-------------------------------------------------------------------*/
/* Control Symbolgen                                                 */
/*-------------------------------------------------------------------*/

* Turn on SYBMBOLGEN option to see how macro variables are resolved in log;
* global system option MPRINT to view the macro code with the 
macro variables resolved;
options SYMBOLGEN MPRINT;

* SYMBOLGEN option can be turned off with the following command;
* options nosymbolgen;

/*-------------------------------------------------------------------*/
/* Important Folder Locations                                        */
/*-------------------------------------------------------------------*/

%LET dd_data = C:\Users\Nathanael\Dropbox\MyData\;
%LET dd_SASLib = C:\Users\Nathanael\MySASLib\;
%LET Include_prog = C:\Users\Nathanael\Dropbox\MyPrograms\;

/*-------------------------------------------------------------------*/
/* Important Macro Variables                                         */
/*-------------------------------------------------------------------*/

/* This program will merge all state data that is available */
%LET State = ALL;
%LET FYear = 2005; *First year in panel;
%LET LYear = 2012; *Last year in panel;

/*-------------------------------------------------------------------*/
/* Define SAS Library                                                */
/*-------------------------------------------------------------------*/
%let main_library = Model4v1;
LIBNAME &main_library "&dd_SASLib.&main_library";

/*-------------------------------------------------------------------*/
/* Import SNAP Dollars Redemption Data                               */
/*-------------------------------------------------------------------*/
/* Dollars Redeemed at Stores in Counties                            */
/*-------------------------------------------------------------------*/
/* Data Source:                                                      */
/* Supplemental Nutrition Assistance Program, Retailer Policy and    */
/*       Management Division, Food and Nutrition Service,            */
/*       U.S. Department of Agriculture. (Mar 2014 email             */ 
/*       communication with RPMDHQ-WEB@fns.usda.gov                  */
/*-------------------------------------------------------------------*/

* Include Macro that imports redemption data from USDA;
* Data Imported using;
* %INCLUDE "&Include_prog.USDA_SAS\ImportUSDARed.sas";

%let dataset = USDA;
%let library = &main_library;

LIBNAME &dataset "&dd_SASLib.&dataset";
Data &library..&library._&state.&FYear._&LYear._&dataset.Red Replace;
	Set USDA.USDARed_2005_2012;
	Where year between &Fyear and &LYear;
Run;

/*-------------------------------------------------------------------*/
/* Sort SNAP Dollars Redemption Data                                 */
/*-------------------------------------------------------------------*/

Proc Sort Data = &library..&library._&state.&FYear._&LYear._&dataset.Red;
	BY FIPS_County Year;
RUN;

/*-------------------------------------------------------------------*/
/* Import SNAP Dollars Distributed Data                              */
/*-------------------------------------------------------------------*/
/* Dollars distributed to SNAP participants by county                */
/*-------------------------------------------------------------------*/
/* Data Source:                                                      */
/* Bureau of Economic Analysis (BEA) (May 30 2014)                   */ 
/*       CA35: Personal Current Transfer Receipts                    */
/*       Retrieved 7/29/2014 from                                    */
/*       http://www.bea.gov/regional/downloadzip.cfm                 */
/* Years Available: 1969-2012
/* For Texas Years 2006-2010 most reliable
/* Updates expected
/*-------------------------------------------------------------------*/

* Include Macro that imports distribution data from BEA;
* Data Imported using;
/* Remove This Comment to import data 
%INCLUDE "&Include_prog.BEA\ImportBEA.sas";

%LET BEACode = CA35; * BEA Table that includes SNAP data;
%LET D_Select = SNAP; * Data to select in CA35 table;
%let library = BEA;

%ImportBEA(
   State = &State,
   BEACode = &BEACode,
   D_Select = &D_Select);
/* Remove This Comment to import data */

%let dataset = BEA;
%let library = &main_library;

LIBNAME &dataset "&dd_SASLib.&dataset";
Data &library..&library._&state.&FYear._&LYear._&dataset Replace;
	Set &dataset..Ca35_allstates_1969_2012;
	Where year between &Fyear and &LYear;
Run;

/*-------------------------------------------------------------------*/
/* Import SNAP Dollars Distributed Data - USDA                       */
/*-------------------------------------------------------------------*/
/* Dollars distributed to SNAP participants by county                */
/*-------------------------------------------------------------------*/
/* Data Source:                                                      */
/* Supplemental Nutrition Assistance Program, Retailer Policy and    */
/*       Management Division, Food and Nutrition Service,            */
/*       U.S. Department of Agriculture. (Mar 2014 email             */ 
/*       communication with RPMDHQ-WEB@fns.usda.gov                  */
/* Supplemental Nutrition Assistance Program (SNAP) Data System      */
/*       Retreived from http://www.ers.usda.gov/datafiles/           */
/*       Supplemental_Nutrition_Assistance_Program_SNAP_Data_System/ */
/*       County_Data.xls on Oct 19, 2013                             */
/*-------------------------------------------------------------------*/

* Include Macro that imports distribution data from USDA;
* Data Imported using;
* %INCLUDE "&Include_prog.USDA_SAS\ImportUSDA_SNAP_timeseries.sas";

%let dataset = USDA;
%let library = &main_library;

LIBNAME &dataset "&dd_SASLib.&dataset";
Data &library..&library._&state.&FYear._&LYear._&dataset Replace;
	Set &dataset..USDA_CountyTimeSeries_1969_2012;
	Where year between &Fyear and &LYear;
Run;


/*-------------------------------------------------------------------*/
/* Import SNAP County SNAP benefits recipients - SAIPES              */
/*-------------------------------------------------------------------*/
/* Data Source:                                                      */
/* Table with column headers in row 3,,,,,,,,,,,,,,,,,,,,,
"Table:  County SNAP benefits recipients
Source:  U.S. Census Bureau, Small Area Estimates Branch
Release Date:  December 2014
http://www.census.gov/did/www/saipe/inputdata/cntysnap.csv
/*       on Feb 18, 2014                                             */
/*-------------------------------------------------------------------*/
* Include Macro that imports distribution data from USDA;
* Data Imported using;
* %INCLUDE "&Include_prog.Census\ImportSAIPE_SNAP.sas";

%let dataset = SAIPESNAP;
%let library = &main_library;

*LIBNAME &dataset "&dd_SASLib.&dataset";
Data &library..&library._&state.&FYear._&LYear._&dataset Replace;
	Set SAIPE.SAIPE_SNAP_2001_2012;
	Where year between &Fyear and &LYear;
Run;

/*-------------------------------------------------------------------*/
/* Sort SAIPES Data                                                  */
/*-------------------------------------------------------------------*/

Proc Sort Data = &library..&library._&state.&FYear._&LYear._&dataset;
	BY FIPS_County Year;
RUN;

/*-------------------------------------------------------------------*/
/* Import USDA Store Count Data                                      */
/*-------------------------------------------------------------------*/
/*-------------------------------------------------------------------*/
/* Data Source:                                                      */
/* Supplemental Nutrition Assistance Program, Retailer Policy and    */
/*       Management Division, Food and Nutrition Service,            */
/*       U.S. Department of Agriculture. (May 2014 email             */ 
/*       communication with RPMDHQ-WEB@fns.usda.gov                  */
/*       Authorized Store Counts by State-County-Store Type CY       */
/*       2005-2012                                                   */
/*-------------------------------------------------------------------*/

* Include Macro that imports store count data from USDA;
* Data Imported using;
* %INCLUDE "&Include_prog.USDA_SAS\ImportUSDAStoreCounts.sas";

%let dataset = USDA;
%let library = &main_library;

LIBNAME &dataset "&dd_SASLib.&dataset";
Data &library..&library._&state.&FYear._&LYear._&dataset.StrCnt Replace;
	Set USDA.SNAPStoreCount2005_2012;
	Where year between &Fyear and &LYear;
Run;

/*-------------------------------------------------------------------*/
/* Import Rural County Codes                                         */
/*-------------------------------------------------------------------*/
/* Data defines if a county is metro, nonmetro, and adjacent to metro
/*-------------------------------------------------------------------*/
/* Data Source:
USDA (2013)
2013 Rural-Urban Continuum Codes
http://www.ers.usda.gov/data-products/rural-urban-continuum-codes.aspx#.U9GaNPldWt1
(July 24, 2014)
/* Years Available: 1993, 2003, 2013
/* Only one observation per county
/*-------------------------------------------------------------------*/
* Data Imported using; 
* %INCLUDE "&Include_prog.USDA_SAS\RuralUrbanCodes.sas";

%let dataset = USDA;
%let library = &main_library;

LIBNAME &dataset "&dd_SASLib.&dataset";
Data &library..ruralurbancodes Replace;
	Set USDA.ruralurbancodes;
Run;

/*-------------------------------------------------------------------*/
/* Sort Rural County Codes                                           */
/*-------------------------------------------------------------------*/

Proc Sort Data = &library..ruralurbancodes;
	BY FIPS_County;
RUN;

/*-------------------------------------------------------------------*/
/* Import MSA CBSA Codes                                             */
/*-------------------------------------------------------------------*/
/* Data defines METROPOLITAN AND MICROPOLITAN STATISTICAL AREAS AND COMPONENTS
/*-------------------------------------------------------------------*/
/* Data Source:
NBER 2014
CMS's SSA to FIPS CBSA and MSA County Crosswalk
http://www.nber.org/data/cbsa-msa-fips-ssa-county-crosswalk.html
(Feb 18, 2015)
/*-------------------------------------------------------------------*/
* Data downloaded from website;

%let dataset = NBER;
%let library = &main_library;

*LIBNAME &dataset "&dd_SASLib.&dataset";
Data &library..CBSAcodes Replace;
	Set NBER.cbsatocountycrosswalk;
	FIPS_County =fipscounty;
Run;

/*-------------------------------------------------------------------*/
/* Sort CBSA County Codes                                            */
/*-------------------------------------------------------------------*/

Proc Sort Data = &library..CBSAcodes;
	BY FIPS_County;
RUN;

/*-------------------------------------------------------------------*/
/* Import Poverty Data                                               */
/*-------------------------------------------------------------------*/
/* Data includes poverty estimates by county by year
/*-------------------------------------------------------------------*/
/* Data Source:                                                      */
/*-------------------------------------------------------------------*/
/* Census 2014 Small Area Income and Poverty Estimates (SAIPE)       */
/* http://www.census.gov/did/www/saipe/data/statecounty/data/index.html
/* Retrieved on July 19, 2014
/* Years Available: 2001-2012
/* Updates expected
/*-------------------------------------------------------------------*/
* Data Imported using;
* %INCLUDE "&Include_prog.Census\MacroSAIPEdata.sas";

%let dataset = SAIPE;
%let library = &main_library;

LIBNAME &dataset "&dd_SASLib.&dataset";

Data &library..&library._&state.&FYear._&LYear._&dataset Replace;
	Set SAIPE.SAIPE2001_2012;
	Where year between &Fyear and &LYear;
Run;
/*-------------------------------------------------------------------*/
/* Sort SAIPES Data                                                  */
/*-------------------------------------------------------------------*/

Proc Sort Data = &library..&library._&state.&FYear._&LYear._&dataset;
	BY FIPS_County Year;
RUN;

/*-------------------------------------------------------------------*/
/* Import SEER Data                                                  */
/*-------------------------------------------------------------------*/
/* Data includes population estimates by age groups, race, gender
/* By county by year
/*-------------------------------------------------------------------*/
/* Data Source:                                                      */
/* Surveillance, Epidemiology, and End Results Program (SEER) (2013) */
/* US Population Data - 1969-2012                                    */
/*     http://seer.cancer.gov/popdata/download.html (July 24, 2014)  */
/* Years Available: 1990-2012
/* Updates expected
/*-------------------------------------------------------------------*/
/* Note
Using 1990-2012 County-level: Expanded Races 
(White, Black, American Indian/Alaska Native, Asian/Pacific Islander) 
by Origin (Hispanic, Non-Hispanic);
County- and state-level population files with 19 age groups 
(<1, 1-4, ..., 80-84, 85+)
*/
* Data Imported using;
* %INCLUDE "&Include_prog.SEER\AggregateSEER.sas";

%let dataset = SEER;
%let library = &main_library;

LIBNAME &dataset "&dd_SASLib.&dataset";

Data &library..&library._&state.&FYear._&LYear._&dataset Replace;
	Set seer.seer_TotalPopAll;
	Where year between &Fyear and &LYear;
Run;
/*-------------------------------------------------------------------*/
/* Sort SEER Data                                                    */
/*-------------------------------------------------------------------*/

Proc Sort Data = &library..&library._&state.&FYear._&LYear._&dataset;
	BY FIPS_County Year;
RUN;

/*-------------------------------------------------------------------*/
/* Import Unemployement Data                                         */
/*-------------------------------------------------------------------*/
/*-------------------------------------------------------------------*/
/* Generate Unemployment Rates for Counties                          */
/*-------------------------------------------------------------------*/
/*-------------------------------------------------------------------*/
/* Data Source:                                                      */
/* Bureau of Labor Statistics (2014) Local Area Unemployment 
		Statistics Annual Average County Data Tables. 
		Retrieved from 
		http://www.bls.gov/lau/#tables on June 11, 2014.
                                                                     */
/*-------------------------------------------------------------------*/
* Data Imported using;
* %INCLUDE "&Include_prog.BLS\MacroBLSLAUS.sas";

%let dataset = BLS;
%let library = &main_library;

LIBNAME &dataset "&dd_SASLib.&dataset";
Data &library..&library._&state.&FYear._&LYear._&dataset Replace;
	Set BLS.BLS2000_2013;
	Where year between &Fyear and &LYear;
Run;
/*-------------------------------------------------------------------*/
/* Sort BLS Data                                                     */
/*-------------------------------------------------------------------*/

Proc Sort Data = &library..&library._&state.&FYear._&LYear._&dataset;
	BY FIPS_County Year;
RUN;

/*-------------------------------------------------------------------*/
/* Import Hazard Data                                                */
/*-------------------------------------------------------------------*/
/* Data includes details on disaster declarations with individual assistance
/* FEMA Disaster Declarations Summary
Accessed July 15, 2014
http://www.fema.gov/media-library/assets/documents/28318
There is a relationship between increase SNAP benefits and disaster areas
* Notes: http://www.fns.usda.gov/sites/default/files/D-SNAP_Disaster.pdf
 FNS approves D-SNAP operations in an affected area under the authority of the Robert T. Stafford
Disaster Relief and Emergency Assistance Act when the area has received a Presidential disaster
declaration of Individual Assistance (IA) from the Federal Emergency Management Agency
(FEMA).;
/*-------------------------------------------------------------------*/
/* Data Source:                                                      */
/* ------------------------------------------*/
* Data Imported using;
* Myprograms/FEMA/MacroCountyFEMA.sas;


%let dataset = FEMA;
%let library = &main_library;

LIBNAME &dataset "&dd_SASLib.&dataset";
Data &library..&library._&state.&FYear._&LYear._&dataset Replace;
	Set FEMA.TotalsFEMADcls_PAwithIA;
	Where year between &Fyear and &LYear;
Run;

/*-------------------------------------------------------------------*/
/* Sort FEMA Data                                                    */
/*-------------------------------------------------------------------*/

Proc Sort Data = &library..&library._&state.&FYear._&LYear._&dataset;
	BY FIPS_County Year;
RUN;


/*-------------------------------------------------------------------*/
/* Merge Datasets into one                                           */
/*-------------------------------------------------------------------*/
%let library = &main_library;

DATA &library..AllData&library._&state.&FYear._&LYear REPLACE;
	MERGE &library..&library._&state.&FYear._&LYear._:;
	BY FIPS_County year;
RUN;

DATA &library..AllData&library._&state.&FYear._&LYear REPLACE;
	MERGE 
		&library..AllData&library._&state.&FYear._&LYear
		&library..ruralurbancodes
		&library..CBSAcodes;
	BY FIPS_County;
RUN;

/*-------------------------------------------------------------------*/
/* Drop Observations                                                 */
/*-------------------------------------------------------------------*/
/* I may need to drop counties that have redemptions less than 50,000
or distributions less than 50,000
Also may need to drop counties that are not balanced */
DATA &library..DropData&library._&state.&FYear._&LYear REPLACE;
	Set &library..AllData&library._&state.&FYear._&LYear;
	If substr(FIPS_County,3,3) = 000 then delete;
	If Statefp = "72" then delete; /* Drop Puerto Rico */
RUN;

/*-------------------------------------------------------------------*/
/* Drop Variables                                                    */
/*-------------------------------------------------------------------*/

DATA &library..DropData&library._&state.&FYear._&LYear REPLACE;
	Set &library..DropData&library._&state.&FYear._&LYear;
	Drop E0_4: P0_4:; /*Estimate of people under age 5 in poverty Not Calculated for Counties*/
	Drop t_Hspnc9; /*Not Calculated after 1990 in SEER*/
RUN;

/*-------------------------------------------------------------------*/
/* Reorder Variables                                                 */
/*-------------------------------------------------------------------*/

DATA &library..DropData&library._&state.&FYear._&LYear REPLACE;
	Retain
		FIPS_County
		Year
		Yeartxt
		County_Name
		State
		Statefp
		cbsa
		cbsaname
		USDA_prgnum
		SAIPE_SNAP1
		USDA_prgben
		BEA_SNAP
		RedAmt
		RedactedFlag
		t_pop
		AVGMonthlyRecipients
		Unemployed
		EALL
		Sum_IA_Dec
		DN_PerCapitaIAIH;
	Set &library..DropData&library._&state.&FYear._&LYear;
RUN;

/*-------------------------------------------------------------------*/
/* Export dataset to Stata                                           */
/*-------------------------------------------------------------------*/

proc export data= &library..DropData&library._&state.&FYear._&LYear 
    outfile= "&dd_data.Dissertation\Feb18&main_library.&state._&Fyear._&Lyear..dta"
	Replace;
run;

