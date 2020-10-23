/*-------------------------------------------------------------------*/
/*       Macro for Createing FIPS_County Poverty Data                */
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
/* Date Last Updated: 25July2014                                     */
/*-------------------------------------------------------------------*/
/* Questions or problem reports concerning this material may be      */
/* addressed to the author on github: https://github.com/npr99       */
/*                                                                   */
/*-------------------------------------------------------------------*/
/* Data Source:                                                      */
/*-------------------------------------------------------------------*/
/* Census 2014 Small Area Income and Poverty Estimates (SAIPE)       */
/* http://www.census.gov/did/www/saipe/data/statecounty/data/index.html
/* Retrieved on July 19, 2014

SAIPE are produced for school districts, counties, and states. 
The main objective of this program is to provide updated estimates of 
income and poverty statistics for the administration of federal programs 
and the allocation of federal funds to local jurisdictions. 
Estimates for 2012 were released in December 2013. These estimates 
combine data from administrative records, postcensal population estimates, 
and the decennial census with direct estimates from the 
American Community Survey to provide consistent and reliable single-year 
estimates. These model-based single-year estimates are more 
reflective of current conditions than multi-year survey estimates.
*/

%MACRO MacroSAIPEdata(
   dd_data = , 
   dd_data2 = , 
   dd_SASLib = ,
   Include_prog = ,
   FYear =,
   LYear =);

%Let Dataset = SAIPE;
%LET library = SAIPE;
LIBNAME &library "&dd_SASLib.&library";

* Found these text utilities that might be useful from 
	http://www2.sas.com/proceedings/sugi30/029-30.pdf
	include add_string macro;
%INCLUDE "&Include_prog.Macros_SAS\TextUtilityMacros.sas";
* Found these Tight Looping with Macro Arrays from
	http://www.sascommunity.org/wiki/Tight_Looping_with_Macro_Arrays
	inlcude Array, Do_Over Macros;
%INCLUDE "&Include_prog.Macros_SAS\Clay-TightLooping-macros\NUMLIST.sas";
%INCLUDE "&Include_prog.Macros_SAS\Clay-TightLooping-macros\ARRAY.sas";
%INCLUDE "&Include_prog.Macros_SAS\Clay-TightLooping-macros\DO_OVER.sas";

/*-------------------------------------------------------------------*/
/*  Creating SAIPE Data for First Year to Last Year                  */
/*-------------------------------------------------------------------*/

* This program imports the Excel files, cleans up the files so that they 
can be merged into a signle file with totals for the year by county;

%MACRO ImportAnnualFile(SAIPEyr);

%LET yr = %substr(&SAIPEyr, 3, 2); *SAIPE years are two digit codes;

PROC IMPORT DATAFile = "&dd_data.Census\SAIPE\est&yr.ALL.xls" 
	DBMS = XLS OUT = work.Temp_file REPLACE;
	DATAROW=4;
	GETNAMES = NO;
	MIXED = YES;
RUN;

DATA work.Temp_file REPLACE;
	SET work.Temp_file;
	IF A = "" THEN DELETE;
	IF B = "" THEN DELETE;
	stfips = input(A, Best12.); 
	County = input(B,Best12.);
	State = input(C,$CHAR2.);
	CountyName = input(D,$CHAR20.);
	Year = &SAIPEyr;
	EALL = input(E,comma15.);
	EALLLB = input(F,comma15.);
	EALLUB = input(G,comma15.);
	PALL = input(H,comma15.);
	PALLLB = input(I,comma15.);
	PALLUB = input(J,comma15.);
	E0_17 = input(K,comma15.);
	E0_17LB = input(L,comma15.);
	E0_17UB = input(M,comma15.);
	P0_17 = input(N,comma15.);
	P0_17LB = input(O,comma15.);
	P0_17UB = input(P,comma15.);
	E5_17 = input(Q,comma15.);
	E5_17LB = input(R,comma15.);
	E5_17UB = input(S,comma15.);
	P5_17 = input(T,comma15.);
	P5_17LB = input(U,comma15.);
	P5_17UB = input(V,comma15.);
	Minc = input(W,comma15.);
	MincLB = input(X,comma15.);
	MincUB = input(Y,comma15.);
	E0_4 = input(Z,comma15.);
	E0_4LB = input(AA,comma15.);
	E0_4UB = input(AB,comma15.);
	P0_4 = input(AC,comma15.);
	P0_4LB = input(AD,comma15.);
	P0_4UB = input(AE,comma15.);
RUN;
* Drop the original variables to create an unsorted or messy temp file;
DATA work.Temp_file_messy REPLACE;
	SET work.Temp_file (DROP = A B C D E F G H I J K L M N O P Q R S T U V W X Y Z AA AB AC AD AE);
RUN;

* Perform a simple concatenation to create FIPS_County unique with State; 
DATA work.Temp_file_messy REPLACE;
	SET work.Temp_file_messy;
	 If stfips LT 10 Then do;
	 	StateFP = "0" || PUT(stfips, 1.);
		If County LT 10  Then 
			FIPS_County =  "0" || PUT(stfips, 1.) || "00" || PUT(County, 1.);
		ELSE If County LT 100  Then  
			FIPS_County =  "0" || PUT(stfips, 1.) || "0" || PUT(County, 2.);
		ELSE If County LT 1000  Then  
			FIPS_County =  "0" || PUT(stfips, 1.) || PUT(County, 3.);
		End;
	Else If stfips LT 100 Then do;
		StateFP = PUT(stfips, 2.);
		If County LT 10  Then 
			FIPS_County =  PUT(stfips, 2.) || "00" || PUT(County, 1.);
		ELSE If County LT 100  Then  
			FIPS_County =  PUT(stfips, 2.) || "0" || PUT(County, 2.);
		ELSE If County LT 1000  Then  
			FIPS_County =  PUT(stfips, 2.) || PUT(County, 3.);
		End;
RUN;

* Data needs to be sorted before the files can be merged;
PROC SORT DATA = work.Temp_file_messy OUT = work.&dataset.&SAIPEYr;
	BY FIPS_County;
RUN;

DATA work.&dataset.&SAIPEYr REPLACE;
	Retain
		FIPS_County
		Year;
	SET work.&dataset.&SAIPEYr;
RUN;

DATA work.&dataset.&SAIPEYr REPLACE;
	SET work.&dataset.&SAIPEYr;
	Drop County stfips;
RUN;


/*-------------------------------------------------------------------*/
/* Append Yearly Calculations together for panel                     */
/*-------------------------------------------------------------------*/

PROC APPEND BASE = work.&dataset.&Fyear._&Lyear
	DATA = work.&dataset.&SAIPEYr;
RUN;

PROC SORT DATA = work.&dataset.&Fyear._&Lyear;
	BY FIPS_County;
RUN;
%MEND ImportAnnualFile;
*SAIPE are available for each year 1989, 1993, 1995-2012;
*However it is only reccommended to compare 2006-2012;

* Delete the existing panel dataset before running IMPORT Macro;
PROC datasets library=work NOLIST;
	DELETE &dataset.&Fyear._&Lyear;
Run;

%ARRAY(SAIPyr, VALUES=&Fyear - &Lyear);
%Do_Over(SAIPyr, MACRO=ImportAnnualFile);

/*-------------------------------------------------------------------*/
/* Export County Data to Model                                       */
/*-------------------------------------------------------------------*/

Data &library..&dataset.&Fyear._&Lyear;
	Set work.&dataset.&Fyear._&Lyear (DROP = AF AG);
	LABEL 
		StateFP = "State FIPS"
		FIPS_County = "County FIPS"
		State = "Postal"
		CountyName = "Name"
		EALL = "Estimate of people of all ages in poverty"
		EALLLB = "90% CI LB of estimate of people of all ages in poverty"
		EALLUB = "90% CI UB of estimate of people of all ages in poverty"
		PALL = "Estimated percent of people of all ages in poverty"
		PALLLB = "90% CI LB of estimate of percent of people of all ages in poverty"
		PALLUB = "90% CI UB of estimate of percent of people of all ages in poverty"
		E0_17 = "Estimate of people age 0-17 in poverty"
		E0_17LB = "90% CI LB of estimate of people age 0-17 in poverty"
		E0_17UB = "90% CI UB of estimate of people age 0-17 in poverty"
		P0_17 = "Estimated percent of people age 0-17 in poverty"
		P0_17LB = "90% CI LB of estimate of percent of people age 0-17 in poverty"
		P0_17UB = "90% CI UB of estimate of percent of people age 0-17 in poverty"
		E5_17 = "Estimate of related children age 5-17 in families in poverty"
		E5_17LB = "90% CI LB of estimate of related children age 5-17 in families in poverty"
		E5_17UB = "90% CI UB of estimate of related children age 5-17 in families in poverty"
		P5_17 = "Estimated percent of related children age 5-17 in families in poverty"
		P5_17LB = "90% CI LB of estimate of percent of related children age 5-17 in families in poverty"
		P5_17UB = "90% CI UB of estimate of percent of related children age 5-17 in families in poverty"
		Minc = "Estimate of median household income"
		MincLB = "90% CI LB of estimate of median household income"
		MincUB = "90% CI UB of estimate of median household income"
		E0_4 = "Estimate of people under age 5 in poverty"
		E0_4LB = "90% CI LB of estimate of people under age 5 in poverty"
		E0_4UB = "90% CI UB of estimate of people under age 5 in poverty"
		P0_4 = "Estimated percent of people under age 5 in poverty"
		P0_4LB = "90% CI LB of estimate of percent of people under age 5 in poverty"
		P0_4UB = "90% CI UB of estimate of percent of people under age 5 in poverty";
run;

DATA &library..&dataset.&Fyear._&Lyear REPLACE;
	Retain
		FIPS_County
		Year;
	SET &library..&dataset.&Fyear._&Lyear;
RUN;

Proc Sort data = &library..&dataset.&Fyear._&Lyear
	out = &library..&dataset.&Fyear._&Lyear;
	by FIPS_county year;
Run;


%MEND MacroSAIPEdata;

/*-------------------------------------------------------------------*/
/* Run Macro Here                                                    */
/*-------------------------------------------------------------------*/
/*-------------------------------------------------------------------*/
/* Important Folder Locations                                        */
/*-------------------------------------------------------------------*/

%LET dd_data = C:\Users\Nathanael\Dropbox\MyData\;
%LET dd_data2 = C:\Users\Nathanael\MyData\;
%LET dd_SASLib = C:\Users\Nathanael\MySASLib\;
%LET Include_prog = C:\Users\Nathanael\Dropbox\MyPrograms\;

%MacroSAIPEdata(
   dd_data = &dd_data, 
   dd_data2 = &dd_data2, 
   dd_SASLib = &dd_SASLib,
   Include_prog = &Include_prog,
   FYear = 2001,
   LYear = 2012);
