 /*-------------------------------------------------------------------*/
 /*       Macro for Creating percentage of SNAP participants          */
 /*       that are children or elderly in Texas                       */
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
 /* Date Last Updated: 23Sept 2014                                    */
 /*-------------------------------------------------------------------*/
 /* Questions or problem reports concerning this material may be      */
 /* addressed to the author on github: https://github.com/npr99       */
 /*                                                                   */
 /*-------------------------------------------------------------------*/
 /* Data Source:                                                      */
 /* The Texas Health and Human Services Commission reports 
          on SNAP Cases by county from September 2005 through 
          October 2013;
    http://www.hhsc.state.tx.us/research/TANF-FS-results.asp          */
 /*-------------------------------------------------------------------*/


%MACRO MacroTXHHSData(
   dd_data = , 
   dd_SASLib = ,
   Include_prog = ,
   State = ,
   FYear = ,
   LYear = ,
   GEOLevel = ,
   Library =);

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
/*  Creating TXHHS Data for First Year to Last Year                  */
/*-------------------------------------------------------------------*/

* Procedure to look at The Texas Health and Human Services Commission reports 
statistics on SNAP Cases by county from September 2005 through October 2013;
* Data source: http://www.hhsc.state.tx.us/research/TANF-FS-results.asp;
* Source files are in Excel Format and have a unique format;
* This program imports the Excel files, cleans up the files so that they 
can be merged into a signle file with totals for the year by county;

%MACRO Create_MonthlyTXHHSFile(TXHHSfiles);
PROC IMPORT DATAFile = "&dd_data.TXHHSC\SnapCases\&TXHHSfiles..xls" 
	DBMS = XLS OUT = TXHHSTemp_file REPLACE;
	DATAROW=3;
	GETNAMES = NO;
	MIXED = YES;
RUN;

DATA SASTXHHS_temp REPLACE;
	SET TXHHSTemp_file;
	IF A = "" THEN DELETE;
	IF A =: "MONTHLY" THEN DELETE;
	IF A =: "Denials" THEN DELETE;
	IF A =: "State Total" THEN DELETE;
	IF A = "County Name" Then Delete;
	IF A = "*TIERS 630 Denials" Then Delete;
	IF B = "" THEN DELETE;
	CountyName2 = input(A, $CHAR20.);
	NumCases_&TXHHSfiles = input(B,comma15.);
	NumRecipients_&TXHHSfiles = input(C,comma15.);
	RA01_&TXHHSfiles = input(D,comma15.);
	RA02_&TXHHSfiles = input(E,comma15.);
	RA03_&TXHHSfiles = input(F,comma15.);
	RA04_&TXHHSfiles = input(G,comma15.);
	RA05_&TXHHSfiles = input(H,comma15.);
	TXHHSCNTYBEN&TXHHSfiles = input(I,comma15.);
	APayments_&TXHHSfiles = input(J,comma15.);
	LABEL NumCases_&TXHHSfiles = "Number of Cases &TXHHSfiles"
		RA01_&TXHHSfiles = "Recipients Age <5 &TXHHSfiles"
		RA02_&TXHHSfiles = "Recipients Age 5-17 &TXHHSfiles"
		RA03_&TXHHSfiles = "Recipients Age 18-59 &TXHHSfiles"
		RA04_&TXHHSfiles = "Recipients Age 60-64 &TXHHSfiles"
		RA05_&TXHHSfiles = "Recipients Age 65+ &TXHHSfiles"
		TXHHSCNTYBEN&TXHHSfiles = "Total FB Payments &TXHHSfiles"
		APayments_&TXHHSfiles = "Average Payment/Case &TXHHSfiles";
RUN;
* Drop the original variables to create an unsorted or messy temp file;
DATA SASTXHHS_temp_messy REPLACE;
	SET SASTXHHS_temp (DROP = A B C D E F G H I J);
RUN;
* Data needs to be sorted before the files can be merged;
PROC SORT DATA = SASTXHHS_temp_messy OUT = TXHHS_&TXHHSfiles;
	BY CountyName2;
RUN;

%MEND Create_MonthlyTXHHSFile;

%MACRO Create_YearTXHHSFile(TXHHSYear);
DATA TXHHS_&TXHHSYear REPLACE;
	MERGE 
		TXHHS_&TXHHSYear.01-TXHHS_&TXHHSYear.12;
	BY CountyName2;
RUN;

* Need to take the Mean of the monthly recipients;

DATA TXHHS_CountyAvgs&TXHHSYear REPLACE;
	SET TXHHS_&TXHHSYear;
	AVGMonthlyCases_&TXHHSYear = MEAN(OF NumCases_:);
	AVGMonthlyRecipients_&TXHHSYear = MEAN(OF NumRecipients_:);
	AVGMonthlyRA01_&TXHHSYear = MEAN(OF RA01_:);
	AVGMonthlyRA02_&TXHHSYear = MEAN(OF RA02_:);
	AVGMonthlyRA03_&TXHHSYear = MEAN(OF RA03_:);
	AVGMonthlyRA04_&TXHHSYear = MEAN(OF RA04_:);
	AVGMonthlyRA05_&TXHHSYear = MEAN(OF RA05_:);
	TXHHSCNTYBEN&TXHHSYear = SUM(OF TXHHSCNTYBEN:);
	AVGMonthlyPayments_&TXHHSYear= MEAN(OF APayments_:);
RUN;

DATA TXHHS_CountyAvgs&TXHHSYear REPLACE;
	SET TXHHS_CountyAvgs&TXHHSYear
	(KEEP=
		CountyName2
		AVGMonthlyCases_&TXHHSYear
		AVGMonthlyRecipients_&TXHHSYear 
		AVGMonthlyRA01_&TXHHSYear
		AVGMonthlyRA02_&TXHHSYear
		AVGMonthlyRA03_&TXHHSYear
		AVGMonthlyRA04_&TXHHSYear
		AVGMonthlyRA05_&TXHHSYear
		TXHHSCNTYBEN&TXHHSYear
		AVGMonthlyPayments_&TXHHSYear);
RUN;

/*-------------------------------------------------------------------*/
/* Calculate Annual Percentage by Age Category                       */
/*-------------------------------------------------------------------*/

DATA TXHHS_CountyPercents&TXHHSYear REPLACE;
	SET TXHHS_CountyAvgs&TXHHSYear;
	Year = &TXHHSYear;
	TXHHSCNTYBEN = TXHHSCNTYBEN&TXHHSYear;
	AVGMonthlyRecipients = AVGMonthlyRecipients_&TXHHSYear;
	AVGMonthlyPayments = AVGMonthlyPayments_&TXHHSYear;
	If AVGMonthlyRecipients_&TXHHSYear GT 0 
    then
		do;
		PercRA01 = AVGMonthlyRA01_&TXHHSYear / AVGMonthlyRecipients_&TXHHSYear;
		PercRA02 = AVGMonthlyRA02_&TXHHSYear / AVGMonthlyRecipients_&TXHHSYear;
		PercRA03 = AVGMonthlyRA03_&TXHHSYear / AVGMonthlyRecipients_&TXHHSYear;
		PercRA04 = AVGMonthlyRA04_&TXHHSYear / AVGMonthlyRecipients_&TXHHSYear;
		PercRA05 = AVGMonthlyRA05_&TXHHSYear / AVGMonthlyRecipients_&TXHHSYear;
		end;
	Else
		do;
		PercRA01 = .;
		PercRA02 = .;
		PercRA03 = .;
		PercRA04 = .;
		PercRA05 = .;
		end;
RUN;

DATA TXHHS_Data&TXHHSYear REPLACE;
	SET TXHHS_CountyPercents&TXHHSYear
	(Keep =
		CountyName2
		Year
		TXHHSCNTYBEN
		AVGMonthlyRecipients
		AVGMonthlyPayments
		Perc:);
RUN;

/*-------------------------------------------------------------------*/
/* Append Yearly Calculations together for panel                     */
/*-------------------------------------------------------------------*/

PROC APPEND BASE = work.TXHHSData2006_2013
	DATA = work.TXHHS_Data&TXHHSYear;
RUN;

PROC SORT DATA = work.TXHHSData2006_2013;
	BY CountyName2;
RUN;


%MEND Create_YearTXHHSFile;

* Delete the existing panel dataset before running IMPORT Macro;
PROC datasets library=work NOLIST;
	DELETE TXHHSData2006_2013;
Run;

*TXHHSFiles are available for each month 2006 to 2013;
*TXHHSFiles are only available starting in Sept 2005;

%ARRAY(TXHHSYearsMonths, VALUES=200601-200612);
%Do_Over(TXHHSYearsMonths, MACRO=Create_MonthlyTXHHSFile);
%ARRAY(TXHHSYearsMonths, VALUES=200701-200712);
%Do_Over(TXHHSYearsMonths, MACRO=Create_MonthlyTXHHSFile);
%ARRAY(TXHHSYearsMonths, VALUES=200801-200812);
%Do_Over(TXHHSYearsMonths, MACRO=Create_MonthlyTXHHSFile);
%ARRAY(TXHHSYearsMonths, VALUES=200901-200912);
%Do_Over(TXHHSYearsMonths, MACRO=Create_MonthlyTXHHSFile);
%ARRAY(TXHHSYearsMonths, VALUES=201001-201012);
%Do_Over(TXHHSYearsMonths, MACRO=Create_MonthlyTXHHSFile);
%ARRAY(TXHHSYearsMonths, VALUES=201101-201112);
%Do_Over(TXHHSYearsMonths, MACRO=Create_MonthlyTXHHSFile);
%ARRAY(TXHHSYearsMonths, VALUES=201201-201212);
%Do_Over(TXHHSYearsMonths, MACRO=Create_MonthlyTXHHSFile);
%ARRAY(TXHHSYearsMonths, VALUES=201301-201312);
%Do_Over(TXHHSYearsMonths, MACRO=Create_MonthlyTXHHSFile);
%ARRAY(TXHHSYears, VALUES=2006-2013);
%Do_Over(TXHHSYears, MACRO=Create_YearTXHHSFile);

/*-------------------------------------------------------------------*/
/* Add common County ID TXHHS County Data                            */
/*-------------------------------------------------------------------*/


/*-------------------------------------------------------------------*/
/* Import CENSUS FIPS DATA                                           */
/*-------------------------------------------------------------------*/

* Include FIPS Macro;
* Program creates work.FIPS_state, work.FIPS_County datasets;
%INCLUDE "&Include_prog.Macros_SAS\MacroFIPS_County.sas";

%MacroFIPS_County(
   dd_data = &dd_data, 
   dd_SASLib = &dd_SASLib,
   Include_prog = &Include_prog);

/*-------------------------------------------------------------------*/
/* Merge FIPS with TXHHS County Data                                 */
/*-------------------------------------------------------------------*/


DATA TXHHSFIPS_County;
	SET FIPS_County (KEEP = CountyName2 Statefp FIPS_County);
	IF StateFP = "48";
RUN;
* Data needs to be sorted before the files can be merged;
PROC SORT DATA = TXHHSFIPS_County OUT = TXHHSFIPS_County;
	BY CountyName2;
RUN;

PROC SORT DATA = work.TXHHSData2006_2013 OUT = work.TXHHSData2006_2013;
	BY CountyName2;
RUN;

DATA TXHHS_FIPSData2006_2013 REPLACE;
	MERGE 
		work.TXHHSFIPS_County work.TXHHSData2006_2013;
	BY CountyName2;
RUN;

/*-------------------------------------------------------------------*/
/* Export County Data to Model                                       */
/*-------------------------------------------------------------------*/


Data &library..&state.&geolevel.&Fyear._&Lyear.TXHHSData;
	Set work.TXHHS_FIPSData2006_2013
	(DROP = Statefp CountyName2);
	If year GE &Fyear AND year LE &Lyear;
	If FIPS_County NE "";
	mergeyear = put(year,4.); * year needs to be string;
	drop year;
	rename mergeyear = year;
	LABEL 
		TXHHSCNTYBEN = "TXHHS Benefits Distributed"
		AVGMonthlyRecipients = "Annual Monthly Average of Number of Recipients"
		AVGMonthlyPayments = "Annual Monthly Average of Average Payment/Case"
		PercRA01 = "Percentage of Recipients Age <5 within year based on monthly average"
		PercRA02 = "Percentage of Recipients Age 5-17 within year based on monthly average"
		PercRA03 = "Percentage of Recipients Age 18-59 within year based on monthly average"
		PercRA04 = "Percentage of Recipients Age 60-64 within year based on monthly average"
		PercRA05 = "Percentage of Recipients Age 65+ within year based on monthly average";
run; 

Data &library..&state.&geolevel.&Fyear._&Lyear.TXHHSData;
	Retain FIPS_county year;
	Set &library..&state.&geolevel.&Fyear._&Lyear.TXHHSData;
run;

Proc Sort data = &library..&state.&geolevel.&Fyear._&Lyear.TXHHSData
	out = &library..&state.&geolevel.&Fyear._&Lyear.TXHHSData;
	by FIPS_county year;
Run;


%MEND MacroTXHHSData;
