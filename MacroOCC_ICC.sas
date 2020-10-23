 /*-------------------------------------------------------------------*/
 /* Program produces variable for jobs within GEOLevel                */
 /* and a varialbe for jobs that have OD outside of GEOlevel          */
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
 /* Date Last Updated: 9 June 2014                                    */
 /*-------------------------------------------------------------------*/
 /* Questions or problem reports concerning this material may be      */
 /* addressed to the author on github: https://github.com/npr99       */
 /*                                                                   */
 /*-------------------------------------------------------------------*/
 /* Data Source:                                                      */
 /* United States Census Bureau (2013) LEHD Origin-Destination        */ 
 /*       Employment Statistics (LODES)Dataset Structure Format       */
 /*       Version 7.0 Retrieved 5/22/2013 from                        */
 /*       http://lehd.ces.census.gov/data/                            */
 /*-------------------------------------------------------------------*/

%MACRO MacroOCC_ICC(
   State = ,
   StateFP =,
   Year =,
   JobType =,
   GEOLevel =);

/*-------------------------------------------------------------------*/
/* Define SAS Library                                                */
/*-------------------------------------------------------------------*/
%let library = LODES;
LIBNAME &library "&dd_SASLib.&library";

* Read in file that has macros for importing and summing LODES;
%INCLUDE "&Include_prog.LODES_SAS\ReadandSumLODES.sas";

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
/* Macro to Stack LODES OD Files with OD Main and AUX                */
/*-------------------------------------------------------------------*/

/* Comment:
Because LODES breaks files into two sets the two sets need to be stacked.
This would create a huge file so before the files are stacked the 
LODES data is aggregated to reduce the number of OD pairs
*/

%MACRO StackLODES(
   State = ,
   Year = ,
   GEOLevel = ,
   JobType =  );

   * Call Macros to import MAIN and AUX files for the same year;
   * Outputs work.Sort&geolevel&ODType;
	%ImportLODES(
		State = &state,
		Year = &year,
		GEOLevel = &GEOLevel,
		JobType =  &JobType,
		ODType = Main);
	%ImportLODES(
		State = &state,
		Year = &year,
		GEOLevel = &GEOLevel,
		JobType =  &JobType,
		ODType = Aux);
   * Call Macros to AggregateLODES MAIN and AUX files for the same year;
   * Outputs work.SUM&state.&geolevel.&ODType;
	%AggregateLODES(
		State = &state,
		Year = &year,
		GEOLevel = &GEOLevel,
		JobType =  &JobType,
		ODType = Main);
	%AggregateLODES(
		State = &state,
		Year = &year,
		GEOLevel = &GEOLevel,
		JobType =  &JobType,
		ODType = Aux);
	DATA work.Stack&state.&geolevel.&year REPLACE;
		Set work.SUM&geolevel.MAIN work.SUM&geolevel.AUX;
	RUN;

	PROC SORT DATA = work.Stack&state.&geolevel.&year;
		By h_&geolevel.fp; 
	RUN;

%MEND StackLODES;

/*-------------------------------------------------------------------*/
/* Codes for Key Variables in LODES OD Files                         */
/*-------------------------------------------------------------------*/

	/* GEOLevel: Level of Geography;
	* State, County, CensusTract, BlockGroup */
	/* Job Type
	JT00 = All Jobs
	JT01 = Primary Jobs
	JT02 = All Private Jobs
	JT03 = Private Primary Jobs
	JT04 = All Federal Jobs (not all years)
	JT05 = Federal Primary Jobs (not all years)*/
	/* ODType;
    Aux = jobs with the workplace in the state and 
	the residence outside of the state;
	Main = jobs with both workplace and residence in the state */


/*-------------------------------------------------------------------*/
/* Stack LODES OD Files to create a total of all jobs in GEOlevel    */
/*-------------------------------------------------------------------*/

%StackLODES(
   State = &state,
   Year = &year,
   GEOLevel = &GeoLevel,
   JobType = &JobType);

/*-------------------------------------------------------------------*/
/* Read in, SUM and STACK neighboring AUX State Files                */
/*-------------------------------------------------------------------*/
/*
Comment - June 9 2014
NOTE: AUX file has Workplaces within State and residences out of state
In order to see the number of workers that commute to a neighboring state
the AUX files for a set of states needs to be read in, then keep only the 
States with the home GEOIDS of interest
*/

* Macro to read in an array of states;
%MACRO ImportArrayLODES(allstates);
	%ImportLODES(
		State = &allstates,
		Year = &year,
		GEOLevel = &GEOLevel,
		JobType =  &JobType,
		ODType = Aux);
   * Call Macros to AggregateLODES MAIN and AUX files for the same year;
   * Outputs work.SUM&state.&geolevel.&ODType;
	%AggregateLODES(
		State = &allstates,
		Year = &year,
		GEOLevel = &GEOLevel,
		JobType =  &JobType,
		ODType = AUX);
   * Stack AUX States;
   * Stacks each new AUX State after aggregation;
	PROC APPEND BASE = work.TotalStack&geolevel.&year 
		DATA = work.SUM&geolevel.AUX;
	RUN;
%MEND ImportArrayLODES;
* Initialize the data that will have tha stack of state MAIN, AUX, and 
All AUX States;
DATA work.TotalStack&geolevel.&year REPLACE;
    Set work.Stack&state.&geolevel.&year;
RUN;
*LODES files are for each State from 2002 to 2011;
%Let AUXStates = AL AK AZ AR CA CO CT DE FL GA HI ID IL IN IA KS KY LA 
ME MD MA MI MN MS MO MT NE NV NH NJ NM NY NC ND OH OK OR PA RI SC SD 
TN TX UT VT VA WA WV WI WY;
%ARRAY(AllSTATES, VALUES=&AUXStates);
%Do_Over(Allstates, MACRO=ImportArrayLODES);


/*-------------------------------------------------------------------*/
/* Generate a table that sums geolevel by jobs with both OD in area  */
/*-------------------------------------------------------------------*/
* Produces values equal to OnTheMap:
* Employed and Living in the Selection Area;
PROC SORT DATA = work.TotalStack&geolevel.&year;
	By h_&geolevel.fp; 
RUN;
DATA work.HWTotal&state.&geolevel.&year REPLACE;
	Set work.TotalStack&geolevel.&year;
	* Look for observations with same home and work GEOIDS;
	If h_&geolevel.fp = w_&geolevel.fp;
Run;
* Drop variables that are nolonger needed;
DATA work.HWTotal&state.&geolevel.&year REPLACE;
	Set work.HWTotal&state.&geolevel.&year;
	FIPS_&geolevel = h_&geolevel.fp;
	* Keep geoid, total, and income groups = SE;
	KEEP
		FIPS_&geolevel
		sum_S000  
		sum_SE:
		cnt;
Run;

/*-------------------------------------------------------------------*/
/* Generate a table that sums Total number of jobs in area           */
/*-------------------------------------------------------------------*/
* Produces values equal to OnTheMap:
* Living in the Selection Area;
* To reuse code Macro Variable to set home or work total;
%LET HorW = h;
PROC SORT DATA = work.TotalStack&geolevel.&year;
	By &HorW._&geolevel.fp; 
RUN;

DATA work.&HorW.Total&state.&geolevel.&year REPLACE;
	Set work.TotalStack&geolevel.&year;
	BY &HorW._&geolevel.fp;
	Where &HorW._statefp = &statefp;
	IF first.&HorW._&geolevel.fp THEN DO;
		&HorW.total_S000 = 0; 
		&HorW.total_SA01 = 0; 
		&HorW.total_SA02 = 0; 
		&HorW.total_SA03 = 0; 
		&HorW.total_SE01 = 0; 
		&HorW.total_SE02 = 0; 
		&HorW.total_SE03 = 0; 
		&HorW.total_SI01 = 0; 
		&HorW.total_SI02 = 0; 
		&HorW.total_SI03 = 0;
		&HorW.totalcnt = 0;
		END;
	&HorW.total_S000 + sum_S000; 
	&HorW.total_SA01 + sum_SA01; 
	&HorW.total_SA02 + sum_SA02; 
	&HorW.total_SA03 + sum_SA03; 
	&HorW.total_SE01 + sum_SE01; 
	&HorW.total_SE02 + sum_SE02; 
	&HorW.total_SE03 + sum_SE03; 
	&HorW.total_SI01 + sum_SI01; 
	&HorW.total_SI02 + sum_SI02; 
	&HorW.total_SI03 + sum_SI03;
	&HorW.totalcnt + 1;
	IF last.&HorW._&geolevel.fp THEN OUTPUT;
RUN;
* Drop variables that are nolonger needed;
DATA work.&HorW.Total&state.&geolevel.&year REPLACE;
	Set work.&HorW.Total&state.&geolevel.&year;
	FIPS_&geolevel = &HorW._&geolevel.fp;
	* Keep geoid, total, and income groups = SE;
	KEEP
		FIPS_&geolevel
		&HorW.total_S000  
		&HorW.total_SE:
		&HorW.totalcnt;
Run;


/*-------------------------------------------------------------------*/
/* Generate a table that sums county data by work location           */
/*-------------------------------------------------------------------*/
* Produces values equal to OnTheMap:
* Employed in the Selection Area but Living Outside;
* NOTE: For some reason these values are slightly off from OnTheMap
        The values are very close but unlike sum_S and htotal_S 
		wtotal tends to be higher;
* To reuse code Macro Variable to set home or work total;
%LET HorW = w;
PROC SORT DATA = work.TotalStack&geolevel.&year;
	By &HorW._&geolevel.fp; 
RUN;

DATA work.&HorW.Total&state.&geolevel.&year REPLACE;
	Set work.TotalStack&geolevel.&year;
	BY &HorW._&geolevel.fp;
	* Look for observations with different home and work GEOIDS;
	* Jobs with residence out side of geoid;
	Where &HorW._statefp = &statefp AND 
		h_&geolevel.fp NE w_&geolevel.fp;
	IF first.&HorW._&geolevel.fp THEN DO;
		&HorW.total_S000 = 0; 
		&HorW.total_SA01 = 0; 
		&HorW.total_SA02 = 0; 
		&HorW.total_SA03 = 0; 
		&HorW.total_SE01 = 0; 
		&HorW.total_SE02 = 0; 
		&HorW.total_SE03 = 0; 
		&HorW.total_SI01 = 0; 
		&HorW.total_SI02 = 0; 
		&HorW.total_SI03 = 0;
		&HorW.totalcnt = 0;
		END;
	&HorW.total_S000 + sum_S000; 
	&HorW.total_SA01 + sum_SA01; 
	&HorW.total_SA02 + sum_SA02; 
	&HorW.total_SA03 + sum_SA03; 
	&HorW.total_SE01 + sum_SE01; 
	&HorW.total_SE02 + sum_SE02; 
	&HorW.total_SE03 + sum_SE03; 
	&HorW.total_SI01 + sum_SI01; 
	&HorW.total_SI02 + sum_SI02; 
	&HorW.total_SI03 + sum_SI03;
	&HorW.totalcnt + 1;
	IF last.&HorW._&geolevel.fp THEN OUTPUT;
RUN;
* Drop variables that are nolonger needed;
DATA work.&HorW.Total&state.&geolevel.&year REPLACE;
	Set work.&HorW.Total&state.&geolevel.&year;
	FIPS_&geolevel = &HorW._&geolevel.fp;
	* Keep geoid, total, and income groups = SE;
	KEEP
		FIPS_&geolevel
		&HorW.total_S000  
		&HorW.total_SE:
		&HorW.totalcnt;
Run;


/*-------------------------------------------------------------------*/
/* Merge GeoLevels by FIPS for Total Workers, OD within County and   */
/* Origins outside of county                                         */
/*-------------------------------------------------------------------*/

PROC SORT DATA = work.HTotal&state.&geolevel.&year 
	OUT = work.HTotal&state.&geolevel.&year;
	by FIPS_&geolevel;
Run;
PROC SORT DATA = work.WTotal&state.&geolevel.&year 
	OUT = work.WTotal&state.&geolevel.&year;
	by FIPS_&geolevel;
Run;
PROC SORT DATA = work.HWTotal&state.&geolevel.&year OUT = 
	work.HWTotal&state.&geolevel.&year;
	by FIPS_&geolevel;
Run;

* Merge  Sums;
DATA work.Merge&state.&geolevel.&year REPLACE;;
	MERGE   work.HWTotal&state.&geolevel.&year 
			work.HTotal&state.&geolevel.&year
			work.WTotal&state.&geolevel.&year;
	BY FIPS_&geolevel;
RUN;

/*-------------------------------------------------------------------*/
/* Create Ratios of Workers by Origin and Desitination               */
/*-------------------------------------------------------------------*/

* OCC represents the proportion of jobs that commute 
out-of-county in county i and in year t;

DATA work.&state.&JobType.OCC&year REPLACE;
	SET work.Merge&state.&geolevel.&year;
	OCCHtotal&year = htotal_S000;
	if htotal_S000 GT 0 
		then OCCS000&year = 
		(htotal_S000 -sum_S000)/htotal_S000;
		else OCCS000&year = .;
	if htotal_SE01 GT 0 
		then OCCSE01&year = 
		(htotal_SE01 -sum_SE01)/htotal_SE01;
		else OCCSE01&year = .;
	if htotal_SE02 GT 0 
		then OCCSE02&year = 
		(htotal_SE02 -sum_SE02)/htotal_SE02;
		else OCCSE02&year = .;
	if htotal_SE03 GT 0 
		then OCCSE03&year = 
		(htotal_SE03 -sum_SE03)/htotal_SE03;
		else OCCSE03&year = .;
RUN;

* ICC represents the proportion of jobs that commute 
into-county in county i and in year t;

DATA work.&state.&JobType.ICC&year REPLACE;
	SET work.Merge&state.&geolevel.&year;
	ICCHtotal&year = htotal_S000;
	ICCS000&year = wtotal_S000/htotal_S000;
	ICCSE01&year = wtotal_SE01/htotal_SE01;
	ICCSE02&year = wtotal_SE02/htotal_SE02;
	ICCSE03&year = wtotal_SE03/htotal_SE03;
RUN;

/*-------------------------------------------------------------------*/
/* Export Results to SASLibrary Work                                 */
/*-------------------------------------------------------------------*/

DATA work.&state.&JobType.OCC&year REPLACE;
	SET work.&state.&JobType.OCC&year;
	KEEP
		FIPS_&geolevel
		OCC:;
RUN;

DATA Work.&state.&JobType.ICC&year REPLACE;
	SET work.&state.&JobType.ICC&year;
    KEEP
		FIPS_&geolevel
		ICC:;
RUN;

%MEND MacroOCC_ICC;

/*-------------------------------------------------------------------*/
/* Macro to create datasets for all panel years                      */
/*-------------------------------------------------------------------*/

%MACRO OCC_ICCpanel(
   State = ,
   StateFP = ,
   JobType = ,
   geolevel = , 
   Fyear = ,
   TYears =);

%Do i = 1 %to &TYears;
	Data _NULL_;
		CALL SYMPUT("panelyear",&Fyear+&i-1);
	RUN;
	%MacroOCC_ICC(
		State = &state,
		StateFP = &StateFP,
		Year = &panelyear,
		JobType = &JobType,
 		GEOLevel = &GEOLevel);
	%end;
%MEND OCC_ICCpanelpart1;

%OCC_ICCpanel(
   State = &State,
   StateFP = &StateFp,
   JobType = &JobType,
   geolevel = &GEOlevel,
   Fyear = &Fyear,
   TYears = &Tyears);

/*-------------------------------------------------------------------*/
/*  Transpose Data To Be in Panel Form                               */
/*-------------------------------------------------------------------*/

%MACRO OUTPUT_OCC_ICC(
   State = ,
   JobType = ,
   geolevel = ,
   Fyear = ,
   Lyear =,
   XCC = );

DATA work.Merge&state.&JobType.&XCC REPLACE;;
	MERGE   work.&state.&JobType.&XCC.&FYear -
            work.&state.&JobType.&XCC.&LYear;
	BY FIPS_&geolevel;
RUN;

%LET LODESVAR = htotal;
Proc transpose data = work.Merge&state.&JobType.&XCC
	out = work.Merge&state.&JobType.&XCC.Long&LODESVAR Prefix = &XCC.&LODESVAR;
	by FIPS_&geolevel;
	var &XCC.&LODESVAR.&fyear-&XCC.&LODESVAR.&lyear;
Run;

%LET LODESVAR = SE01;
Proc transpose data = work.Merge&state.&JobType.&XCC
	out = work.Merge&state.&JobType.&XCC.Long&LODESVAR Prefix = &XCC.&LODESVAR;
	by FIPS_&geolevel;
	var &XCC.&LODESVAR.&fyear-&XCC.&LODESVAR.&lyear;
Run;

%LET LODESVAR = SE02;
Proc transpose data = work.Merge&state.&JobType.&XCC
	out = work.Merge&state.&JobType.&XCC.Long&LODESVAR Prefix = &XCC.&LODESVAR;
	by FIPS_&geolevel;
	var &XCC.&LODESVAR.&fyear-&XCC.&LODESVAR.&lyear;
Run;

%LET LODESVAR = SE03;
Proc transpose data = work.Merge&state.&JobType.&XCC
	out = work.Merge&state.&JobType.&XCC.Long&LODESVAR Prefix = &XCC.&LODESVAR;
	by FIPS_&geolevel;
	var &XCC.&LODESVAR.&fyear-&XCC.&LODESVAR.&lyear;
Run;

%LET LODESVAR = S000;
Proc transpose data = work.Merge&state.&JobType.&XCC
	out = work.Merge&state.&JobType.&XCC.Long&LODESVAR Prefix = &XCC.&LODESVAR;
	by FIPS_&geolevel;
	var &XCC.&LODESVAR.&fyear-&XCC.&LODESVAR.&lyear;
Run;

/*-------------------------------------------------------------------*/
/* Export Data to Model SAS Libary                                   */
/*-------------------------------------------------------------------*/

Data model1.&state.&geolevel.&Fyear._&Lyear.&XCC;
	merge work.Merge&state.&JobType.&XCC.Longhtotal (rename=(&XCC.htotal1=&XCC.htotal))
		  work.Merge&state.&JobType.&XCC.LongS000 (rename=(&XCC.S0001=&XCC.S000))
		  work.Merge&state.&JobType.&XCC.LongSE01 (rename=(&XCC.SE011=&XCC.SE01))
		  work.Merge&state.&JobType.&XCC.LongSE02 (rename=(&XCC.SE021=&XCC.SE02)) 
	      work.Merge&state.&JobType.&XCC.LongSE03 (rename=(&XCC.SE031=&XCC.SE03));
	by FIPS_&geolevel;
	year=input(substr(_name_, 8, 4), $char4.);
	drop _name_;
run;

Data model1.&state.&geolevel.&Fyear._&Lyear.&XCC;
	Retain FIPS_county year;
	Set model1.&state.&geolevel.&Fyear._&Lyear.&XCC;
run;

Proc Sort data = model1.&state.&geolevel.&Fyear._&Lyear.&XCC
	out = model1.&state.&geolevel.&Fyear._&Lyear.&XCC;
	by FIPS_county year;
Run;

%MEND OUTPUT_OCC_ICC; 
