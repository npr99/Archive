/*-------------------------------------------------------------------*/
/*       Combine FEMA Disaster Data with CBP Data                    */
/*          by Nathanael Rosenheim                                   */
/*-------------------------------------------------------------------*/
/*                                                                   */
/* This material is provided "as is" by the author.                  */
/* There are no warranties, expressed or implied, as to              */
/* merchantability or fitness for a particular purpose regarding     */
/* the materials or code contained herein. The author is not         */
/* responsible for errors in this material as it now exists or       */
/* will exist, nor does the author provide technical support for it. */
/*                                                                   */
/*-------------------------------------------------------------------*/
/* Date Last Updated: 27Jul2014                                      */
/*-------------------------------------------------------------------*/
/* Questions or problem reports concerning this material may be      */
/* addressed to the author on github: https://github.com/npr99       */
/*                                                                   */
/*-------------------------------------------------------------------*/
/* Data Source:                                                      */
/* Various
/*-------------------------------------------------------------------*/

/*-------------------------------------------------------------------*/
/* Important Folder Locations                                        */
/*-------------------------------------------------------------------*/

%LET dd_data = C:\Users\Nathanael\Dropbox\MyData\;
%LET dd_data2 = C:\Users\Nathanael\MyData\;
%LET dd_SASLib = C:\Users\Nathanael\MySASLib\;
%LET Include_prog = C:\Users\Nathanael\Dropbox\MyPrograms\;

/*-------------------------------------------------------------------*/
/* Important Macro Variables                                         */
/*-------------------------------------------------------------------*/

%Let FYear = 2001;
%Let LYear = 2012;
%let library = FEMACBP;

LIBNAME &library "&dd_SASLib.&library";

/*-------------------------------------------------------------------*/
/* Import County Business Patterns                                   */
/*-------------------------------------------------------------------*/
/* Counts of employees and establishments by county and year
/* also firm size in terms of number of employees
/*-------------------------------------------------------------------*/
/* Data Source:                                                      */
/* US Census Bureau (2013) County Business Patterns 2001-2012        */
/*     http://www.census.gov/econ/cbp/download/                      */
/* Years Available: 2001-2012
/* Updates expected
/*-------------------------------------------------------------------*/
* Data Imported using 
%INCLUDE "&Include_prog.CBP\MacroImportCBP.sas";

%let dataset = CBP;
%let library = FEMACBP;

LIBNAME &dataset "&dd_SASLib.&dataset";
Data &library..FEMACBP_&dataset.&FYear._&LYear Replace;
	Set CBP.CBP2001_2012;
	Where year between &Fyear and &LYear;
Run;
/*-------------------------------------------------------------------*/
/* Sort CBP Data                                                     */
/*-------------------------------------------------------------------*/

Proc Sort Data = &library..FEMACBP_&dataset.&FYear._&LYear;
	BY FIPS_County Year;
RUN;

/*-------------------------------------------------------------------*/
/* Sort CBP Gas Stations Data                                        */
/*-------------------------------------------------------------------*/

%let dataset = CBP447;
%let library = FEMACBP;

LIBNAME &dataset "&dd_SASLib.&dataset";
Data &library..FEMACBP_&dataset.&FYear._&LYear Replace;
	Set CBP.CBP4472001_2012;
	Where year between &Fyear and &LYear;
Run;
/*-------------------------------------------------------------------*/
/* Sort CBP Data                                                     */
/*-------------------------------------------------------------------*/

Proc Sort Data = &library..FEMACBP_&dataset.&FYear._&LYear;
	BY FIPS_County Year;
RUN;

/*-------------------------------------------------------------------*/
/* Import FEMA Data                                                  */
/*-------------------------------------------------------------------*/
/*-------------------------------------------------------------------*/
/* Data Source:                                                      */
/* FEMA Disaster Declarations Summary
http://www.fema.gov/media-library/assets/documents/28318
/* FEMA Public Assistance Funded Projects Detail - Open Government Initiative
http://www.fema.gov/media-library/assets/documents/28331
/* Years Available: 1999-2014
/* Updates expected
/*-------------------------------------------------------------------*/

* Data Imported using 
%INCLUDE "&Include_prog.FEMA\MacroCountyFEMA.sas";

%let dataset = FEMA;
%let library = FEMACBP;

LIBNAME &dataset "&dd_SASLib.&dataset";
Data &library..FEMACBP_&dataset.&FYear._&LYear Replace;
	Set FEMA.TotalsFEMADcls_PAwithIA;
	Where year between &Fyear and &LYear;
Run;
/*-------------------------------------------------------------------*/
/* Sort FEMA Data                                                    */
/*-------------------------------------------------------------------*/

Proc Sort Data = &library..FEMACBP_&dataset.&FYear._&LYear;
	BY FIPS_County Year;
RUN;

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
* Data Imported using 
* %INCLUDE "&Include_prog.USDA_SAS\RuralUrbanCodes.sas";

%let dataset = USDA;
%let library = FEMACBP;

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
* Data Imported using 
* %INCLUDE "&Include_prog.Census\MacroSAIPEdata.sas";

%let dataset = SAIPE;
%let library = FEMACBP;

LIBNAME &dataset "&dd_SASLib.&dataset";

Data &library..FEMACBP_&dataset.&FYear._&LYear Replace;
	Set SAIPE.SAIPE2001_2012;
	Where year between &Fyear and &LYear;
Run;
/*-------------------------------------------------------------------*/
/* Sort SAIPES Data                                                  */
/*-------------------------------------------------------------------*/

Proc Sort Data = &library..FEMACBP_&dataset.&FYear._&LYear;
	BY FIPS_County Year;
RUN;
/*-------------------------------------------------------------------*/
/* Import FHWA Highway Data                                          */
/*-------------------------------------------------------------------*/
/* Data Source:                                                      */
/*-------------------------------------------------------------------*/
/* Data Source:                                                      */
/* Federal Highway Administration (2013) HPMS - email request        */
/*     https://www.fhwa.dot.gov/policyinformation/hpms.cfm           */
/* Years Available: 2000-2008, 2010 (not all states) 2011-2012       */
/* Updates expected                                                   */
/*-------------------------------------------------------------------*/


* Data Imported using 
* %INCLUDE "&Include_prog.FHWA\MacroImportHPMS.sas";

%let dataset = FHWA;
%let library = FEMACBP;

LIBNAME &dataset "&dd_SASLib.&dataset";

Data &library..FEMACBP_&dataset.&FYear._&LYear Replace;
	Set &dataset..&dataset.2000_2012;
	Where year between &Fyear and &LYear;
Run;
/*-------------------------------------------------------------------*/
/* Sort FHWA Data                                                    */
/*-------------------------------------------------------------------*/

Proc Sort Data = &library..FEMACBP_&dataset.&FYear._&LYear;
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

* %INCLUDE "&Include_prog.SEER\AggregateSEER.sas";

%let dataset = SEER;
%let library = FEMACBP;

LIBNAME &dataset "&dd_SASLib.&dataset";

Data &library..FEMACBP_&dataset.&FYear._&LYear Replace;
	Set seer.seer_TotalPopAll;
	Where year between &Fyear and &LYear;
Run;
/*-------------------------------------------------------------------*/
/* Sort SEER Data                                                    */
/*-------------------------------------------------------------------*/

Proc Sort Data = &library..FEMACBP_&dataset.&FYear._&LYear;
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
* Data Imported using 
%INCLUDE "&Include_prog.BLS\MacroBLSLAUS.sas";

%let dataset = BLS;
%let library = FEMACBP;

LIBNAME &dataset "&dd_SASLib.&dataset";
Data &library..FEMACBP_&dataset.&FYear._&LYear Replace;
	Set BLS.BLS2000_2013;
	Where year between &Fyear and &LYear;
Run;
/*-------------------------------------------------------------------*/
/* Sort BLS Data                                                     */
/*-------------------------------------------------------------------*/

Proc Sort Data = &library..FEMACBP_&dataset.&FYear._&LYear;
	BY FIPS_County Year;
RUN;

/*-------------------------------------------------------------------*/
/* Import WindSpeed Data                                             */
/*-------------------------------------------------------------------*/

PROC IMPORT DATAFile = "&dd_data.XiaoPeacockRDC\MaxMPH_Allwindswaths.xls" 
	DBMS = XLS OUT = work.MaxMPHCounty REPLACE;
	GETNAMES = Yes;
	MIXED = YES;
RUN;

/*-------------------------------------------------------------------*/
/*-------------------------------------------------------------------*/
/*-------------------------------------------------------------------*/

/*-------------------------------------------------------------------*/
/* Merge Datasets into one                                           */
/*-------------------------------------------------------------------*/

DATA &library..FEMACBP_CBP&Fyear._&Lyear REPLACE;
	MERGE &library..FEMACBP_CBP&Fyear._&Lyear &library..ruralurbancodes work.MaxMPHCounty;
	BY FIPS_County;
RUN;

DATA &library..AllDataFEMACBP_&Fyear._&Lyear REPLACE;
	MERGE &library..FEMACBP_:;
	BY FIPS_County year;
RUN;

/*-------------------------------------------------------------------*/
/* Drop Observations                                                 */
/*-------------------------------------------------------------------*/

DATA &library..L48FEMACBP_&Fyear._&Lyear REPLACE;
	Set &library..AllDataFEMACBP_&Fyear._&Lyear;
	/* Delete Entries for Alaska, Hawaii, Puerto Rico, Virgin Islands) */
	If substr(FIPS_County,1,2) in ("00", "02",  "15", "72", "71") then delete;
	/* Delete Entries for State Level) */
	If substr(FIPS_County,3,3) in ("000") then delete;
	/* Delete Entries for Statewide establishments from CBP) */
	If substr(FIPS_County,3,3) in ("999") then delete;
RUN;

/*-------------------------------------------------------------------*/
/* Drop Variables                                                    */
/*-------------------------------------------------------------------*/

DATA &library..L48FEMACBP_&Fyear._&Lyear REPLACE;
	Set &library..L48FEMACBP_&Fyear._&Lyear;
	Drop E0_4: P0_4:; /*Estimate of people under age 5 in poverty Not Calculated for Counties*/
	Drop t_Hspnc9; /*Not Calculated after 1990 in SEER*/
RUN;

DATA &library..L48FEMACBP_&Fyear._&Lyear REPLACE;
	Retain
		FIPS_County
		Year
		CountyName
		State;
	Set &library..L48FEMACBP_&Fyear._&Lyear;
RUN;

/*-------------------------------------------------------------------*/
/* Export dataset to Stata                                           */
/*-------------------------------------------------------------------*/

proc export data= &library..L48FEMACBP_&Fyear._&Lyear 
    outfile= "&dd_data.XiaoPeacockRDC\L48FEMACBP_&Fyear._&Lyear..dta"
	Replace;
run;


/*-------------------------------------------------------------------*/
/* Test idea that BCS is most populous non interstate county         */
/*-------------------------------------------------------------------*/
/*
DATA &library..BCS_&Fyear._&Lyear REPLACE;
	Set &library..L48FEMACBP_&Fyear._&Lyear;
	If IntrstMi = 0;
RUN;

Proc Sort Data = &library..BCS_&Fyear._&Lyear;
	BY t_pop;
RUN;
*/
