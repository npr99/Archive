/*-------------------------------------------------------------------*/
/* Program imports LODES7 data and converts from BlockID to GeoLevel */
/* After importing the program combines LODES7 data into a Panel     */
/* Using Geography Crosswalk                                         */
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
/* Date Last Updated: 13 April 2015                                  */
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
/*-------------------------------------------------------------------*/
/* Clear Log                                                         */
/*-------------------------------------------------------------------*/
DM "clear log";

/*-------------------------------------------------------------------*/
/* Control Symbolgen                                                 */
/*-------------------------------------------------------------------*/

* Turn on SYBMBOLGEN option to see how macro variables are resolved in log;
* global system option MPRINT to view the macro code with the 
macro variables resolved;
* options SYMBOLGEN MPRINT;

* SYMBOLGEN option can be turned off with the following command;
options nosymbolgen;

/*-------------------------------------------------------------------*/
/* Important Folder Locations                                        */
/*-------------------------------------------------------------------*/

%LET dd_data = C:\Users\Nathanael\Dropbox\MyData\;
%LET dd_SASLib = F:\;
%LET Include_prog = C:\Users\Nathanael\Dropbox\MyPrograms\;

/*-------------------------------------------------------------------*/
/* Where are propotion SNAP values located                           */
/*-------------------------------------------------------------------*/
%LET lbprptns = ACS;
LIBNAME &lbprptns "F:\ACS_20125yr_SNAP_Prptns";

/*-------------------------------------------------------------------*/
/* Important Macro Variables                                         */
/*-------------------------------------------------------------------*/

* Set Macro Variables for State and Years;
%LET State = TX; * This state starts as the main state and then will 
					go through all 50 states for the AUX files;
%LET MainState = TX; * Primary state of interest;
%LET Statefp = '48'; *FIPS Code for state;
%LET FYear = 2002; *First year in panel;
%LET LYear = 2011; *Last year in panel;
%LET TYears = 11;

* Set Macro Variables for Level of Geography;
%LET GEOLevel = county;

* Set Macro Varialbes for job type of interest;
%LET JobType = JT01; * Primary Jobs in LODES;


%MACRO ImportLODES7(
   State = ,
   MainState = ,
   StateFP =,
   Year =,
   JobType =,
   GEOLevel =);

/*-------------------------------------------------------------------*/
/* Define SAS Library                                                */
/*-------------------------------------------------------------------*/
%let library = LODES7;
LIBNAME &library "&dd_SASLib.&library";

* Read in file that has macros for importing and summing LODES;
%INCLUDE "&Include_prog.LODES_SAS\ReadandSumLODESv2.sas";

* Read in file that has macro for creating new SNAP work variable;
%INCLUDE "&Include_prog.LODES_SAS\NPRSNAP_CreateNewLODES7var.sas";

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
/* Stack LODES OD Files with OD Main and AUX                         */
/*-------------------------------------------------------------------*/

/* Comment:
Because LODES breaks files into two sets the two sets need to be stacked.
This would create a huge file so before the files are stacked the 
LODES data is aggregated to reduce the number of OD pairs
*/

* Call Macros to import MAIN files for the same year;
* Outputs work.Sort&geolevel&ODType;
%ImportLODESFile(
	State = &mainstate,
	MainState = &mainstate,
	StateFP = &statefp,
	Year = &year,
	GEOLevel = &GEOLevel,
	JobType =  &JobType,
	ODType = Main);

* Create Food Stamp Worker Variable;
%CreateNewLODES7Var(
	State = &mainstate,
	MainState = &mainstate,
	StateFP = &statefp,
	Year = &year,
	GEOLevel = &GEOLevel,
	JobType =  &JobType,
	ODType = Main);

* Call Macros to AggregateLODES MAIN files for the same year;
* Outputs work.SUM&state.&geolevel.&ODType;
%AggregateLODES(
	State = &mainstate,
	Year = &year,
	StateFP = &statefp,
	GEOLevel = &GEOLevel,
	JobType =  &JobType,
	ODType = Main);

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
%MACRO ImportArrayLODES(AUXstates);
	%ImportLODESFile(
		State = &auxstates,
		MainState = &mainstate,
		StateFP = &statefp,
		Year = &year,
		GEOLevel = &GEOLevel,
		JobType =  &JobType,
		ODType = Aux);
	* Create Food Stamp Worker Variable;
	%CreateNewLODES7Var(
		State = &mainstate,
		MainState = &mainstate,
		StateFP = &statefp,
		Year = &year,
		GEOLevel = &GEOLevel,
		JobType =  &JobType,
		ODType = Main);
   * Call Macros to AggregateLODES MAIN and AUX files for the same year;
   * Outputs work.SUM&state.&geolevel.&ODType;
	%AggregateLODES(
		State = &auxstates,
		Year = &year,
		StateFP = &statefp,
		GEOLevel = &GEOLevel,
		JobType =  &JobType,
		ODType = AUX);
   * Stack AUX States;
   * Stacks each new AUX State after aggregation;
	PROC APPEND BASE = work.TotalStackv1&geolevel.&year 
		DATA = work.SUM&auxstates._&mainstate.&geolevel.AUX;
	RUN;

	/*PROC datasets library=work NOLIST;
		DELETE SUM&auxstates._&mainstate.&geolevel.AUX;
	Run;*/

%MEND ImportArrayLODES;
* Initialize the data that will have tha stack of state MAIN, AUX, and 
All AUX States;
DATA work.TotalStackv1&geolevel.&year REPLACE;
    Set work.SUM&mainstate._&mainstate.&geolevel.MAIN;
RUN;
*LODES files are for each State from 2002 to 2011;
%Let AllStates = AL AK AZ AR CA CO CT DE FL GA HI ID IL IN IA KS KY LA 
ME MD MA MI MN MS MO MT NE NV NH NJ NM NY NC ND OH OK OR PA RI SC SD 
TN TX UT VT VA WA WV WI WY;
%LET year = 2002;
%ARRAY(AUXstates, VALUES=&AllStates);
%Do_Over(AUXstates, MACRO=ImportArrayLODES);

* Keep OD pairs that have workplace or origin in main state;
DATA &library..TotalStack&mainstate.&geolevel.&year REPLACE;
	Set work.TotalStackv1&geolevel.&year;
	* Look for observations with same home and work GEOIDS;
	If h_statefp = &Statefp OR w_statefp = &Statefp;
	year = &year;
Run;
/*-------------------------------------------------------------------*/
/* Aggregate OnTheMap Statistics by GeoLevel                         */
/*-------------------------------------------------------------------*/
/*
Need to produce the following statistics for each of the 3 job categories
Earnings, Age, Industry.
Each county and each year needs to have one observation.
Employed in the Selection Area
Employed in the Selection Area but Living Outside
Employed and Living in the Selection Area
Living in the Selection Area
Living in the Selection Area but Employed Outside
Living and Employed in the Selection Area
*/
* Calculate totals for Employed in Selection Area;
PROC SORT DATA = &library..TotalStack&mainstate.&geolevel.&year;
	By w_&geolevel.fp h_&geolevel.fp; 
RUN;

%LET HorW = w;
DATA work.EmployedIn&mainstate.&geolevel.&year REPLACE;
	Set &library..TotalStack&mainstate.&geolevel.&year;
	BY &HorW._&geolevel.fp;
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
		&HorW.total_SXXX = 0;
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
	&HorW.total_SXXX + sum_SXXX;
	&HorW.totalcnt + 1;
	IF last.&HorW._&geolevel.fp THEN OUTPUT;
RUN;
* Drop variables that are nolonger needed;
DATA work.EmployedIn&mainstate.&geolevel.&year REPLACE;
	Set work.EmployedIn&mainstate.&geolevel.&year;
	FIPS_&geolevel = &HorW._&geolevel.fp;
	If &HorW._statefp = &statefp;
	* Keep geoid, total, and income groups = SE;
	KEEP
		FIPS_&geolevel
		&HorW._cbsa
		&HorW._statefp
		&HorW._countyfp
		year
		wtotal:;
Run;

Data work.EmployedIn&mainstate.&geolevel.&year;
	Retain FIPS_&geolevel year;
	Set work.EmployedIn&mainstate.&geolevel.&year;
run;

Proc Sort Data = work.EmployedIn&mainstate.&geolevel.&year;
	by FIPS_&geolevel;
Run;

* Calculate totals for Living in Selection Area;
PROC SORT DATA = &library..TotalStack&mainstate.&geolevel.&year;
	By h_&geolevel.fp w_&geolevel.fp; 
RUN;
%LET HorW = h;
DATA work.LivingIn&mainstate.&geolevel.&year REPLACE;
	Set &library..TotalStack&mainstate.&geolevel.&year;
	BY &HorW._&geolevel.fp;
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
		&HorW.total_SXXX = 0;
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
	&HorW.total_SXXX + sum_SXXX;
	&HorW.totalcnt + 1;
	IF last.&HorW._&geolevel.fp THEN OUTPUT;
RUN;
* Drop variables that are nolonger needed;
DATA work.LivingIn&mainstate.&geolevel.&year REPLACE;
	Set work.LivingIn&mainstate.&geolevel.&year;
	FIPS_&geolevel = &HorW._&geolevel.fp;
	If &HorW._statefp = &statefp;
	* Keep geoid, total, and income groups = SE;
	KEEP
		FIPS_&geolevel
		year
		&HorW._cbsa
		&HorW._statefp
		&HorW._countyfp
		htotal:;
Run;

Data work.LivingIn&mainstate.&geolevel.&year;
	Retain FIPS_&geolevel year;
	Set work.LivingIn&mainstate.&geolevel.&year;
run;

Proc Sort Data = work.LivingIn&mainstate.&geolevel.&year;
	by FIPS_&geolevel;
Run;

/*-------------------------------------------------------------------*/
/* Merge Primary Data Sets for On The Map Numbers                    */
/*-------------------------------------------------------------------*/
DATA work.Emplyd_LvngN&mainstate.&geolevel.&year REPLACE;
	Set &library..TotalStack&mainstate.&geolevel.&year;
	FIPS_&geolevel = h_&geolevel.fp;
	If h_&geolevel.fp = w_&geolevel.fp;
	If w_statefp = &statefp;
	* Keep geoid, total, and income groups = SE;
	KEEP
		FIPS_&geolevel
		year
		h_cbsa
		h_statefp
		h_countyfp
		h_censustractfp
		w_cbsa
		w_statefp
		w_countyfp
		w_censustractfp
		sum_:;
Run;

Data work.Emplyd_LvngN&mainstate.&geolevel.&year;
	Retain FIPS_&geolevel year;
	Set work.Emplyd_LvngN&mainstate.&geolevel.&year;
run;

Proc Sort Data = work.Emplyd_LvngN&mainstate.&geolevel.&year;
	by FIPS_&geolevel;
Run;

Data work.OnTheMap&mainstate.&geolevel.&year;
	merge
		work.LivingIn&mainstate.&geolevel.&year
		work.EmployedIn&mainstate.&geolevel.&year
		work.Emplyd_LvngN&mainstate.&geolevel.&year;
	By FIPS_&geolevel;
Run;
	PROC datasets library=work NOLIST;
		DELETE LivingIn&mainstate.&geolevel.&year;
		DELETE EmployedIn&mainstate.&geolevel.&year;
		DELETE Emplyd_LvngN&mainstate.&geolevel.&year;
		DELETE TotalStackv1&geolevel.&year;
	Run;

%MEND ImportLODES7;

/*-------------------------------------------------------------------*/
/* Macro to create datasets for all panel years                      */
/*-------------------------------------------------------------------*/

%MACRO LODES7Panel(
   State = ,
   MainState = ,
   StateFP = ,
   JobType = ,
   geolevel = , 
   Fyear = ,
   TYears =);

%Do i = 1 %to &TYears;
	Data _NULL_;
		CALL SYMPUT("panelyear",put(&Fyear+&i-1,4.));
	RUN;
	%ImportLODES7(
		State = &state,
		StateFP = &StateFP,
		MainState = &mainstate,
		Year = &panelyear,
		JobType = &JobType,
 		GEOLevel = &GEOLevel);

	PROC APPEND BASE = work.OnTheMap&mainstate.&geolevel.&fyear._&lyear 
		DATA = work.OnTheMap&mainstate.&geolevel.&panelyear;
	RUN;

	PROC datasets library=work NOLIST;
		DELETE OnTheMap&mainstate.&geolevel.&panelyear;
	Run;

	%end;


%MEND LODES7Panel;
* Delete the existing panel dataset before running IMPORT Macro;
PROC datasets library=work NOLIST;
	DELETE OnTheMap&mainstate.&geolevel.&fyear._&lyear;
Run;


/*-------------------------------------------------------------------*/
/* Run Macro                                                        */
/*-------------------------------------------------------------------*/

%LODES7Panel(
   State = &State,
   MainState = &mainstate,
   StateFP = &StateFp,
   JobType = &JobType,
   geolevel = &GEOlevel,
   Fyear = &Fyear,
   TYears = &Tyears);

Proc Sort Data = work.OnTheMap&mainstate.&geolevel.&fyear._&lyear;
	by FIPS_&geolevel year;
Run;

/*-------------------------------------------------------------------*/
/* Order and Label Variables                                         */
/*-------------------------------------------------------------------*/

%MACRO labelvariables( );
%IF &JobType = JT00 %THEN %LET JobLabel = " (All Jobs)";
%IF &JobType = JT01 %THEN %LET JobLabel = " (Primary Jobs)";
%IF &JobType = JT02 %THEN %LET JobLabel = " (All Private Jobs)";
%IF &JobType = JT03 %THEN %LET JobLabel = " (Private Primary Jobs)";
%IF &JobType = JT04 %THEN %LET JobLabel = " (All Federal Jobs)";
%IF &JobType = JT05 %THEN %LET JobLabel = " (Federal Primary Jobs)";

Data &library..OnTheMap&mainstate.&geolevel.&fyear._&lyear;
	Retain FIPS_&geolevel year
	wtotal_SXXX htotal_SXXX sum_SXXX
	wtotal_S000 htotal_S000 sum_S000
	wtotal_SE01 htotal_SE01 sum_SE01
	wtotal_SE02 htotal_SE02 sum_SE02
	wtotal_SE03 htotal_SE03 sum_SE03;
	Set work.OnTheMap&mainstate.&geolevel.&fyear._&lyear;
	Label
		wtotal_S000 = "Employed in the &geolevel &JobLabel All Workers"
		htotal_S000 = "Living in the &geolevel &JobLabel  All Workers"
		sum_S000	= "Living & Employed in the &geolevel &JobLabel  All Workers"
		wtotal_SE01 = "Employed in the &geolevel &JobLabel Workers Earning $1,250 per month or less"
		htotal_SE01 = "Living in the &geolevel &JobLabel Workers Earning $1,250 per month or less"
		sum_SE01	= "Living & Employed in the &geolevel &JobLabel Workers Earning $1,250 per month or less"
		wtotal_SE02 = "Employed in the &geolevel &JobLabel Workers Earning $1,251 to $3,333 per month"
		htotal_SE02 = "Living in the &geolevel &JobLabel Workers Earning $1,251 to $3,333 per month"
		sum_SE02	= "Living & Employed in the &geolevel &JobLabel Workers Earning $1,251 to $3,333 per month"
		wtotal_SE03 = "Employed in the &geolevel &JobLabel Workers Earning More than $3,333 per month"
		htotal_SE03 = "Living in the &geolevel &JobLabel Workers Earning More than $3,333 per month"
		sum_SE03	= "Living & Employed in the &geolevel &JobLabel Workers Earning More than $3,333 per month"
		wtotal_SXXX = "Employed in the &geolevel &JobLabel SNAP Workers (e)"
		htotal_SXXX = "Living in the &geolevel &JobLabel  SNAP Workers (e)"
		sum_SXXX	= "Living & Employed in the &geolevel &JobLabel  SNAP Workers (e)";
	Attrib
		wtotal_SXXX format = 16.0
		htotal_SXXX format = 16.0
		sum_SXXX	format =  16.0;
Run;
/*
PROC datasets library=work NOLIST;
	DELETE OnTheMap&state.&geolevel.&fyear._&lyear;
Run;
*/

%MEND labelvariables;

%labelvariables( );

/*-------------------------------------------------------------------*/
/* State FIPS Codes                                                  */
/*-------------------------------------------------------------------*/
/*
State Abbreviation	FIPS Code	State Name
AK	02	ALASKA
AL	01	ALABAMA
AR	05	ARKANSAS
AS	60	AMERICAN SAMOA
AZ	04	ARIZONA
CA	06	CALIFORNIA
CO	08	COLORADO
CT	09	CONNECTICUT
DC	11	DISTRICT OF COLUMBIA
DE	10	DELAWARE
FL	12	FLORIDA
GA	13	GEORGIA
GU	66	GUAM
HI	15	HAWAII
IA	19	IOWA
ID	16	IDAHO
IL	17	ILLINOIS
IN	18	INDIANA
KS	20	KANSAS
KY	21	KENTUCKY
LA	22	LOUISIANA
MA	25	MASSACHUSETTS
MD	24	MARYLAND
ME	23	MAINE
MI	26	MICHIGAN
MN	27	MINNESOTA
MO	29	MISSOURI
MS	28	MISSISSIPPI
MT	30	MONTANA
NC	37	NORTH CAROLINA
ND	38	NORTH DAKOTA
NE	31	NEBRASKA
NH	33	NEW HAMPSHIRE
NJ	34	NEW JERSEY
NM	35	NEW MEXICO
NV	32	NEVADA
NY	36	NEW YORK
OH	39	OHIO
OK	40	OKLAHOMA
OR	41	OREGON
PA	42	PENNSYLVANIA
PR	72	PUERTO RICO
RI	44	RHODE ISLAND
SC	45	SOUTH CAROLINA
SD	46	SOUTH DAKOTA
TN	47	TENNESSEE
TX	48	TEXAS
UT	49	UTAH
VA	51	VIRGINIA
VI	78	VIRGIN ISLANDS
VT	50	VERMONT
WA	53	WASHINGTON
WI	55	WISCONSIN
WV	54	WEST VIRGINIA
WY	56	WYOMING
*/
