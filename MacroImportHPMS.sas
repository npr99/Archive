 /*-------------------------------------------------------------------*/
 /* Macro for Reading in Highway Performance Monitoring System (HPMS) */
 /*          by Nathanael Proctor Rosenheim                           */
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
 /* Date Last Updated: 30Jul2014                                      */
 /*-------------------------------------------------------------------*/
 /* Questions or problem reports concerning this material may be      */
 /* addressed to the author on github: https://github.com/npr99       */
 /*                                                                   */
 /*-------------------------------------------------------------------*/
 /* Data Source:                                                      */
 /* Federal Highway Administration (2013) HPMS - email request        */
 /*     https://www.fhwa.dot.gov/policyinformation/hpms.cfm           */
 /*-------------------------------------------------------------------*/

* use the obs= option to read just a small number of records to test your program; 
options obs=Max;

*%Macro MacroImportHPMS(
   dd_data = , 
   dd_data2 = , 
   dd_SASLib = ,
   Include_prog = ,
   Fyear = ,
   Lyear = );

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

*  The following line should contain the directory
   where the SAS file is to be stored;


%let dataset = FHWA;
%let library = FHWA;

LIBNAME &library "&dd_SASLib.&dataset";
/*-------------------------------------------------------------------*/
/* Import Primary Files from Original Source                         */
/*-------------------------------------------------------------------*/

PROC IMPORT DATAFile = "&dd_data2.FHWA\HPMS_2000_2012_NPRmodified.xls" 
	DBMS = XLS
	OUT = work.HPMS_00_08_TEMP1 REPLACE;
	Sheet = "2000_2008";
	Getnames = No;
	MIXED = YES;
RUN;

Data work.HPMS_00_08_TEMP2 Replace;
	Set work.HPMS_00_08_TEMP1;
	If A = "Year" Then Delete;
	If C = "NULL" Then Delete;
	If C = "" Then Delete;
	Year = input(A,Comma20.);
	stfips = input(B,Comma20.);
	County = input(C,Comma20.);
	RoadCode = input(D,Comma20.);
	Miles = input(F,Comma20.);
	DVMT = input(G,Comma20.);
Run;

Data work.HPMS_00_08_TEMP2 Replace;
	Set work.HPMS_00_08_TEMP2
	(DROP = A B C D E F G);
	If Year = . then delete;
Run;

PROC IMPORT DATAFile = "&dd_data2.FHWA\HPMS_2000_2012_NPRmodified.xls" 
	DBMS = XLS
	OUT = work.HPMS_10_12_TEMP1 REPLACE;
	Sheet = "2010_2012";
	Getnames = No;
	MIXED = YES;
RUN;

Data work.HPMS_10_12_TEMP2 Replace;
	Set work.HPMS_10_12_TEMP1;
	If A = "Year" Then Delete;
	If C = "NULL" Then Delete;
	If C = "" Then Delete;
	Year = input(A,Comma20.);
	stfips = input(B,Comma20.);
	County = input(C,Comma20.);
	RoadCode = input(E,Comma20.);
	Miles = input(F,Comma20.);
	DVMT = input(G,Comma20.);
Run;

Data work.HPMS_10_12_TEMP2 Replace;
	Set work.HPMS_10_12_TEMP2
	(DROP = A B C D E F G);
	If Year = . then delete;
Run;
/*-------------------------------------------------------------------*/
/* Append Yearly Calculations together for panel                     */
/*-------------------------------------------------------------------*/
%LET fyear = 2000;
%LET lyear = 2012;
* Delete the existing panel dataset before running IMPORT Macro;
PROC datasets library=work NOLIST;
	DELETE &dataset.&FYear._&LYear;
Run;

PROC APPEND BASE = work.&dataset.&FYear._&LYear
	DATA = work.HPMS_00_08_TEMP2;
RUN;

PROC APPEND BASE = work.&dataset.&FYear._&LYear
	DATA = work.HPMS_10_12_TEMP2;
RUN;

/*-------------------------------------------------------------------*/
/* Add FIPS County                                                   */
/*-------------------------------------------------------------------*/
Data work.&dataset.&FYear._&LYear._FIP Replace;
	Set work.&dataset.&FYear._&LYear;
	If stfips LT 10 Then do;
		If County LT 10  Then 
			FIPS_County =  "0" || PUT(stfips, 1.) || "00" || PUT(County, 1.);
		ELSE If County LT 100  Then  
			FIPS_County =  "0" || PUT(stfips, 1.) || "0" || PUT(County, 2.);
		ELSE If County LT 1000  Then  
			FIPS_County =  "0" || PUT(stfips, 1.) || PUT(County, 3.);
		End;
	Else If stfips LT 100 Then do;
		If County LT 10  Then 
			FIPS_County =  PUT(stfips, 2.) || "00" || PUT(County, 1.);
		ELSE If County LT 100  Then  
			FIPS_County =  PUT(stfips, 2.) || "0" || PUT(County, 2.);
		ELSE If County LT 1000  Then  
			FIPS_County =  PUT(stfips, 2.) || PUT(County, 3.);
		End;
	If stfips = "72" then delete; *Delete Puerto Rico;
	If stfips = "2" then delete; *Delete Alaska;
Run;

Data work.&dataset.&FYear._&LYear._FIP Replace;
	Retain FIPS_County Year;
	Set work.&dataset.&FYear._&LYear._FIP;
	Drop stfips County;
Run;

/*-------------------------------------------------------------------*/
/* Convert Data so that each county has 1 obs for each year          */
/*-------------------------------------------------------------------*/

PROC SORT DATA = work.&dataset.&FYear._&LYear._FIP OUT = work.&dataset._temp;
	BY FIPS_County Year;
RUN;

%Let WideVar = Miles;
Proc Transpose data = work.&dataset._temp OUT = work.&dataset._tW&WideVar prefix = &WideVar;
	by FIPS_County Year;
	id RoadCode;
	var &WideVar;
run;

Data work.&dataset._tW&WideVar REPLACE;
	Set work.&dataset._tW&WideVar;
	Drop _NAME_;
	Drop _LABEL_;
Run;

%Let WideVar = DVMT;
Proc Transpose data = work.&dataset._temp OUT = work.&dataset._tW&WideVar prefix = &WideVar;
	by FIPS_County Year;
	id RoadCode;
	var &WideVar;
run;

Data work.&dataset._tW&WideVar REPLACE;
	Set work.&dataset._tW&WideVar;
	Drop _NAME_;
	Drop _LABEL_;
Run;

Data work.&dataset._Wide Replace;
	Merge work.&dataset._tW:;
	By FIPS_County Year;
Run;

Data work.&dataset._Wide Replace;
	Retain FIPS_County Year;
	Set work.&dataset._Wide;
Run;

/*-------------------------------------------------------------------*/
/* Convert RoadCodes to make comparable across all years             */
/*-------------------------------------------------------------------*/
/* 
Between 2000-2008 Roadcodes=
	F_SYSTEM codes:
	1=Rural Interstate
	2=Rural OPA
	11=Urban Interstate
	12=Urban OF&E
	14=Urban OPA
Between 2010-2012 Roadcodes=
Note: Functional System Codes
	1=Interstate
	2=Other Freeways & Expressways
	3=Other Principal Arterial
*/
/* New Road codes
Interstate Miles = 2000-2008: Miles1 + Miles11, 20010-2012: Miles1
Interstate DVMT
Other Miles = 2000-2008: Miles2 + Miles12 + Miles14, 2010-2012: Miles2 + Miles3
Other DVMT 
*/

Data work.&dataset._NewRoadCodes Replace;
	Set work.&dataset._Wide;
	If year >= 2000 and year <= 2008 then do;
		IntrstMi = sum(Miles1,Miles11,0);
		IntrstDVMT = sum(DVMT1,DVMT11,0);
		OtherMi = sum(Miles2,Miles12,Miles14,0);
		OtherDVMT = sum(DVMT2,DVMT12,DVMT14,0);
		end;
	Else if year >= 2010 and year <= 2012 then do;
		IntrstMi = sum(Miles1,0);
		IntrstDVMT = sum(DVMT1,0);
		OtherMi = sum(Miles2,Miles3,0);
		OtherDVMT = sum(DVMT2,DVMT3,0);
		end;
Run;

Data work.&dataset._NewRoadCodes Replace;
	Set work.&dataset._NewRoadCodes;
	Drop Miles: DVMT:;
Run;

/*-------------------------------------------------------------------*/
/* Import CENSUS FIPS DATA                                           */
/*-------------------------------------------------------------------*/

* Include FIPS Macro;
* Program creates work.FIPS_state, work.FIPS_County datasets;
%INCLUDE "&Include_prog.Macros_SAS\MacroFIPS_County.sas";

%MacroFIPS_County(
   dd_data = &dd_data, 
   dd_data2 = &dd_data2, 
   dd_SASLib = &dd_SASLib,
   Include_prog = &Include_prog);

*Fix errors in FIPS_County;
Data work.&dataset._NewRoadCodes Replace;
	Set work.&dataset._NewRoadCodes;
	If FIPS_County = "12025" Then FIPS_County = "12086";
	* Dade County in 2000 but should be 12086 Miami-Dade County;
	If FIPS_County = "29193" Then FIPS_County = "29186";
	*In 1979 in order to achieve alphabetical consistency, 
	the FIPS code for Ste. Genevieve, Missouri was changed from 29193 to 29186;
Run;

PROC SORT DATA = work.&dataset._NewRoadCodes OUT = work.&dataset._NewRoadCodes;
	BY FIPS_County;
RUN;

Data work.&dataset._NewRoadCodes Replace;
	Merge work.&dataset._NewRoadCodes work.FIPS_County(Keep =FIPS_County CountyName State);
	By FIPS_County;
Run;

PROC SORT DATA = work.&dataset._NewRoadCodes OUT = work.&dataset._NewRoadCodes;
	BY FIPS_County Year;
RUN;

Data work.&dataset._NewRoadCodes Replace;
	Set work.&dataset._NewRoadCodes;
	If State in("AK","PR","UM","VI","GU","AS","MP") then Delete;	
Run;

Data work.&dataset._MissingCounty Replace;
	Set work.&dataset._NewRoadCodes;
	If CountyName = "";	
Run;

/*
FIPS 01150 in 2010 must be an error
Alaska is a problem state for merging FIPS codes
12025 is Dade County in 2000 but should be 12086 Miami-Dade County
In 1979 in order to achieve alphabetical consistency, the FIPS code for Ste. Genevieve, Missouri was changed from 29193 to 29186
Beginning in 1999, Yellowstone National Park County, Montana (FIPS code 30113) was incorporated into Gallatin County, Montana (FIPS code 30031) and Park County, Montana (FIPS code 30067).
51	560	CLIFTON FORGE
51	780	SOUTH BOSTON
56	47	YELLOWSTONE PARK

*/
/*-------------------------------------------------------------------*/
/* Combine District of Columbia to FIPS                              */
/*-------------------------------------------------------------------*/
/* Not sure what to do with DC - the FHWA splits the 1 county equivalent
into 5 regions.
STATE_CODE	COUNTY_CODE	COUNTY_NAME
11	1	NORTHWEST
11	2	NORTHEAST
11	3	SOUTHEAST
11	4	SOUTHWEST
11	5	BOUNDARY
It looks like I should collapse all of the values into one observation.
But this is not clear
*/

/*-------------------------------------------------------------------*/
/* Export panel to Library                                           */
/*-------------------------------------------------------------------*/
Data &library..&dataset.&FYear._&LYear Replace;
	Set work.&dataset._NewRoadCodes;
	If CountyName NE "";
Run;

/*-------------------------------------------------------------------*/
/* Label Variables                                                   */
/*-------------------------------------------------------------------*/

Data &library..&dataset.&FYear._&LYear Replace;
	Set &library..&dataset.&FYear._&LYear;
Label
		IntrstMi = "Interstate Miles"
		IntrstDVMT = "Interstate Daily VMT"
		OtherMi = "Freeways, Expressways, & Principal Arterial Miles"
		OtherDVMT = "Freeways, Expressways, & Principal Arterial Daily VMT";
Run;

%mend MacroImportHPMS;

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

%MacroImportHPMS(
   dd_data = &dd_data, 
   dd_data2 = &dd_data2, 
   dd_SASLib = &dd_SASLib,
   Include_prog = &Include_prog,
   Fyear = 2000,
   Lyear = 2012);
