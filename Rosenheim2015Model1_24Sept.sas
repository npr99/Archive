/*-------------------------------------------------------------------*/
/*       Program for Building Balanced Panel Data Set                */
/*       with SNAP Data from 2006-2010. For Dissertation Research    */
/*       Model 1v2 – Basic Mobility Model                            */
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
/* Date Last Updated: 24Sept14                                       */
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

* Set Macro Variables for State and Years;
%LET State = tx;
%LET Statefp = '48'; *FIPS Code for state;
%LET FYear = 2006; *First year in panel;
%LET LYear = 2010; *Last year in panel;
%LET TYears = 5;
* Years covered by redemption data;
%LET YEARS_Red = 05 06 07 08 09 10 11 12;
* Years in both redemption and benefit data;
%LET YEARS_Both = 06 07 08 09 10 11 12;

* Set Macro Variables for Level of Geography;
%LET GEOLevel = County;

* Set Macro Varialbes for job type of interest;
%LET JobType = JT01; * Primary Jobs in LODES;

/*-------------------------------------------------------------------*/
/* Define SAS Library                                                */
/*-------------------------------------------------------------------*/
%let library = Model1v2;
LIBNAME &library "&dd_SASLib.&library";

/*-------------------------------------------------------------------*/
/* Variables in Panel 1 for Model 1                                  */
/*-------------------------------------------------------------------*/
/*
Dependent Variable 
WCR represents the ratio of SNAP benefits redeemed within a county 
as the ratio of total within-county redemptions to total within-county
benefit distributions for county i and in year t

Explanatory variables
OCC represents the proportion of low-income jobs that commute out-of-county in county i and in year t;

ICC is the proportion of low-income jobs that commute into county i 
and in year t

County Characteristics in county i and in year t likely to be associated
with within-county redemptions

CC1 percentage unemployment

CC2 percentage of households without a vehicle

CC3 percentage of SNAP participants that are children

CC4 percentage of SNAP participants that elderly

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

%let dataset = USDARed;
%let library = Model1v2;

LIBNAME &dataset "&dd_SASLib.&dataset";
Data &library..&library._&dataset.&FYear._&LYear Replace;
	Set USDA.USDARed_2005_2012;
	Where year between &Fyear and &LYear;
	If statefp = &statefp;
Run;

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
%let library = Model1v2;

LIBNAME &dataset "&dd_SASLib.&dataset";
Data &library..&library._&dataset.&FYear._&LYear Replace;
	Set &dataset..&BEACode._&state._1969_2012;
	Where year between &Fyear and &LYear;
Run;

/*-------------------------------------------------------------------*/
/* Data Source:                                                      */
 /* The Texas Health and Human Services Commission reports 
          on SNAP Cases by county from September 2005 through 
          October 2013;
    http://www.hhsc.state.tx.us/research/TANF-FS-results.asp          */
/* Years Available: 2006-2012
/* Updates expected
/*-------------------------------------------------------------------*/

* Include Macro that imports distribution data from TXHHS;
* Data Imported using
%INCLUDE "&Include_prog.TXHHS\ImportTXHHSData.sas";

%let dataset = TXHHS;
%let library = Model1v2;

LIBNAME &dataset "&dd_SASLib.&dataset";
Data &library..&library._&dataset.&FYear._&LYear Replace;
	Set &dataset..&dataset.2006_2012;
	Where year between &Fyear and &LYear;
Run;
/*-------------------------------------------------------------------*/
/* Sort TXHHS Data                                                   */
/*-------------------------------------------------------------------*/

Proc Sort Data = &library..&library._&dataset.&FYear._&LYear;
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

* Include Macro that imports distribution data from TXHHS;
* Data Imported using;
* %INCLUDE "&Include_prog.USDA_SAS\ImportUSDAStoreCounts.sas";

%let dataset = SNAPStoreCount;
%let library = Model1v2;

LIBNAME &dataset "&dd_SASLib.&dataset";
Data &library..&library._&dataset.&FYear._&LYear Replace;
	Set USDA.SNAPStoreCount2005_2012;
	Where year between &Fyear and &LYear;
	If statefp = &statefp;
Run;

/*-------------------------------------------------------------------*/
/* Import LODES7 Data                                                */
/*-------------------------------------------------------------------*/
/* Data Source:                                                      */
/* United States Census Bureau (2013) LEHD Origin-Destination        */ 
/*       Employment Statistics (LODES)Dataset Structure Format       */
/*       Version 7.0 Retrieved 5/22/2013 from                        */
/*       http://lehd.ces.census.gov/data/                            */
/*-------------------------------------------------------------------*/
* Data provides county level data on number of workers who are
employed in a county, live in a county, or both;
* Data Imported using;
* %INCLUDE "&Include_prog.LODES_SAS\ImportLodes7.sas";

%let dataset = LODES7;
%let library = Model1v2;

LIBNAME &dataset "&dd_SASLib.&dataset";

Data &library..&library._&dataset.&FYear._&LYear Replace;
	Set &dataset..Onthemap&state.county2002_2011;
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
%let library = Model1v2;

LIBNAME &dataset "&dd_SASLib.&dataset";
Data &library..ruralurbancodes Replace;
	Set USDA.ruralurbancodes;
	If statefp = &statefp;
Run;

/*-------------------------------------------------------------------*/
/* Sort Rural County Codes                                           */
/*-------------------------------------------------------------------*/

Proc Sort Data = &library..ruralurbancodes;
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
%let library = Model1v2;

LIBNAME &dataset "&dd_SASLib.&dataset";

Data &library..&library._&dataset.&FYear._&LYear Replace;
	Set SAIPE.SAIPE2001_2012;
	Where year between &Fyear and &LYear;
	If statefp = &statefp;
Run;
/*-------------------------------------------------------------------*/
/* Sort SAIPES Data                                                  */
/*-------------------------------------------------------------------*/

Proc Sort Data = &library..&library._&dataset.&FYear._&LYear;
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
%let library = Model1v2;

LIBNAME &dataset "&dd_SASLib.&dataset";

Data &library..&library._&dataset.&FYear._&LYear Replace;
	Set seer.seer_TotalPopAll;
	Where year between &Fyear and &LYear;
	If statefp = &statefp;
Run;
/*-------------------------------------------------------------------*/
/* Sort SEER Data                                                    */
/*-------------------------------------------------------------------*/

Proc Sort Data = &library..&library._&dataset.&FYear._&LYear;
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
%let library = Model1v2;

LIBNAME &dataset "&dd_SASLib.&dataset";
Data &library..&library._&dataset.&FYear._&LYear Replace;
	Set BLS.BLS2000_2013;
	Where year between &Fyear and &LYear;
	If statefp = &statefp;
Run;
/*-------------------------------------------------------------------*/
/* Sort BLS Data                                                     */
/*-------------------------------------------------------------------*/

Proc Sort Data = &library..&library._&dataset.&FYear._&LYear;
	BY FIPS_County Year;
RUN;

/*-------------------------------------------------------------------*/
/* Merge Datasets into one                                           */
/*-------------------------------------------------------------------*/
%let library = Model1v2;

DATA &library..AllData&library._&Fyear._&Lyear REPLACE;
	MERGE &library..&library._:;
	BY FIPS_County year;
RUN;

DATA &library..AllData&library._&Fyear._&Lyear REPLACE;
	MERGE 
		&library..AllData&library._&Fyear._&Lyear
		&library..ruralurbancodes;
	BY FIPS_County;
RUN;

/*-------------------------------------------------------------------*/
/* Drop Observations                                                 */
/*-------------------------------------------------------------------*/
/* I may need to drop counties that have redemptions less than 50,000
or distributions less than 50,000
Also may need to drop counties that are not balanced */
DATA &library..DropData&library._&Fyear._&Lyear REPLACE;
	Set &library..AllData&library._&Fyear._&Lyear;
	If FIPS_County = 48000 then delete;
RUN;

/*-------------------------------------------------------------------*/
/* Drop Variables                                                    */
/*-------------------------------------------------------------------*/

DATA &library..DropData&library._&Fyear._&Lyear REPLACE;
	Set &library..DropData&library._&Fyear._&Lyear;
	Drop E0_4: P0_4:; /*Estimate of people under age 5 in poverty Not Calculated for Counties*/
	Drop t_Hspnc9; /*Not Calculated after 1990 in SEER*/
	Drop htotal_SA: wtotal_SA: sum_SA:; /* Do not need LODES data by age group */
	Drop htotal_SI: wtotal_SI: sum_SI:; /* Do not need LODES data by industry group */
	Drop htotalcnt wtotalcnt; /* Do not need LODES data counts */
RUN;

DATA &library..DropData&library._&Fyear._&Lyear REPLACE;
	Retain
		FIPS_County
		Year
		Yeartxt
		CountyName
		State
		Statefp
		TXHHSCNTYBEN
		BEA_SNAP
		RedAmt
		t_pop
		AVGMonthlyRecipients
		URate
		Unemployed
		EALL
		PALL;
	Set &library..DropData&library._&Fyear._&Lyear;
RUN;

/*-------------------------------------------------------------------*/
/* Export dataset to Stata                                           */
/*-------------------------------------------------------------------*/

proc export data= &library..DropData&library._&Fyear._&Lyear 
    outfile= "&dd_data.Dissertation\Sept25Model_&Fyear._&Lyear..dta"
	Replace;
run;
