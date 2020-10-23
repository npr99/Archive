/*-------------------------------------------------------------------*/
/* Program add Census Tract Centroids to LODES7 data                 */
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
/* Date Last Updated: 25 Oct 2014                                    */
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
/* United States Census Bureau (2013) Demographic Profile 1 -        */
/*       Shapefile Format Census Tracts. Retrieved 10/25/2014 from   */
/*       http://www2.census.gov/geo/tiger/TIGER2010DP1/              */
/*       Tract_2010Census_DP1.zip                                    */
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
%LET dd_SASLib = C:\Users\Nathanael\MySASLib\;
%LET Include_prog = C:\Users\Nathanael\Dropbox\MyPrograms\;
* Location where shape files with centroids is located;
%LET shp_data = C:\Users\Nathanael\Dropbox\qgis\shapefiles\Tract_2010Census_DP1\;
/*-------------------------------------------------------------------*/
/* Important Macro Variables                                         */
/*-------------------------------------------------------------------*/

* Set Macro Variables for State and Years;
%LET State = TX;
%LET Statefp = '48'; *FIPS Code for state;
%LET FYear = 2010; *First year in panel;
%LET LYear = 2010; *Last year in panel;
%LET TYears = 1;

* Set Macro Variables for Level of Geography;
%LET GEOLevel = censustract;

* Set Macro Varialbes for job type of interest;
%LET JobType = JT01; * Primary Jobs in LODES;


* %MACRO AddCentroidLODES7(
   State = ,
   StateFP =,
   Year =,
   JobType =,
   GEOLevel =);

* For this first program just include first year, future versions will iterate;
%LET Year = &FYear;
/*-------------------------------------------------------------------*/
/* Define SAS Library                                                */
/*-------------------------------------------------------------------*/
%let library = LODES7;
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
/* Import Census Tract Centroid File                                 */
/*-------------------------------------------------------------------*/

PROC IMPORT OUT=WORK.CensusTractDP12010
            DATAFILE="&shp_data.Tract_2010Census_DP1.dbf"
            DBMS=DBF REPLACE;
   GETDEL=NO;
RUN;

Data WORK.H_CensusTractCentroids2010 Replace;
	Set WORK.CensusTractDP12010;
	h_censustractfp = GEOID10;
	* Convert string values to numeric;
	h_lat = input(INTPTLAT10,11.);
	h_lon = input(INTPTLON10,11.);
	Keep 
		h_censustractfp
		h_lat
		h_lon;
Run;

Data WORK.W_CensusTractCentroids2010 Replace;
	Set WORK.CensusTractDP12010;
	w_censustractfp = GEOID10;
	* Convert string values to numeric;
	w_lat = input(INTPTLAT10,11.);
	w_lon = input(INTPTLON10,11.);
	Keep 
		w_censustractfp
		w_lat
		w_lon;
Run;
/*-------------------------------------------------------------------*/
/* Merge Census Tract Centroid File with LODES File                  */
/*-------------------------------------------------------------------*/

* Add Work Census Tract Centroid;
Proc Sort Data = WORK.W_CensusTractCentroids2010;
	by w_censustractfp;
Run;

Proc Sort Data = &library..TotalStack&state.&geolevel.&year;
	by w_censustractfp;
Run;

Data work.W_Centroids&state.&geolevel.&year;
	merge
		WORK.W_CensusTractCentroids2010
		&library..TotalStack&state.&geolevel.&year;
	By w_censustractfp;
Run;

* Add Home Census Tract Centroid;
Proc Sort Data = WORK.H_CensusTractCentroids2010;
	by h_censustractfp;
Run;

Proc Sort Data = work.W_Centroids&state.&geolevel.&year;
	by h_censustractfp;
Run;

Data &library..HW_Centroids&state.&geolevel.&year;
	merge
		work.H_CensusTractCentroids2010
		work.W_Centroids&state.&geolevel.&year;
	By h_censustractfp;
Run;
%MEND AddCentroidLODES7;



/*-------------------------------------------------------------------*/
/* Drop Observations                                                 */
/*-------------------------------------------------------------------*/
* Drop long distance commuters...
* Drop intercounty commuters
* Drop censustracts not in LODES Pairs;

* Drop observations that have blank LODES data;
Data work.Cntrds&state.&geolevel.&year._Drop1 Replace;
	Set &library..HW_Centroids&state.&geolevel.&year;
	If sum_S000 NE .;
	* Add county fips;
	h_county = substr(h_censustractfp,1,5);
	w_county = substr(w_censustractfp,1,5);
Run;

* Drop observations where the h and w are in the same county;
Data work.Cntrds&state.&geolevel.&year._Drop2 Replace;
	Set work.Cntrds&state.&geolevel.&year._Drop1;
	If h_county NE w_county;
Run;

* Drop observations where the h and w pairs are greater than X distance;
* Add distance between census tracts in miles;
Data work.Dist&state.&geolevel.&year._Drop Replace;
	Set work.Cntrds&state.&geolevel.&year._Drop2;
	/* Geodist works well, use options:
		D since values in degrees
		M to return distance in miles */	
	Dist = Geodist(h_lat,h_lon,w_lat,w_lon,'DM');
Run;

%LET FarthestDistance = 50;
Data work.Dist&state.&geolevel.&year._&FarthestDistance.Miles Replace;
	Set work.Dist&state.&geolevel.&year._Drop;
	If Dist LT &FarthestDistance;
Run;

%LET FarthestDistance = 25;
Data work.Dist&state.&geolevel.&year._&FarthestDistance.Miles Replace;
	Set work.Dist&state.&geolevel.&year._Drop;
	If Dist LT &FarthestDistance;
Run;

/*-------------------------------------------------------------------*/
/* Export Files to be mapped in GIS                                  */
/*-------------------------------------------------------------------*/

%Let cnty = ALL;
%Let MinSE01 = 50;
%Let FarthestDistance = 50;
Data work.&state.&cnty.&geolevel.&year._&FarthestDistance.Miles Replace;
	Set work.Dist&state.&geolevel.&year._&FarthestDistance.Miles;
	* If w_county = &cnty;
	If sum_SE01 GT &MinSE01;
	* add string that QGIS can use to draw a line;
	GISDATA = "LINESTRING(" || h_lon || " " || h_lat || ", " 
							|| w_lon || " " || w_lat || ")";
Run;

proc export data= work.&state.&cnty.&geolevel.&year._&FarthestDistance.Miles 
    outfile= "&dd_data.TEST\&state.&cnty.&geolevel.&year._&FarthestDistance.Miles.csv"
	Replace;
run;




/*-------------------------------------------------------------------*/
/* Macro to create datasets for all panel years                      */
/*-------------------------------------------------------------------*/

%MACRO LODES7Panel(
   State = ,
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
		Year = &panelyear,
		JobType = &JobType,
 		GEOLevel = &GEOLevel);

	PROC APPEND BASE = work.OnTheMap&state.&geolevel.&fyear._&lyear 
		DATA = work.OnTheMap&state.&geolevel.&panelyear;
	RUN;
	%end;


%MEND LODES7Panel;
* Delete the existing panel dataset before running IMPORT Macro;
PROC datasets library=work NOLIST;
	DELETE OnTheMap&state.&geolevel.&fyear._&lyear;
Run;


/*-------------------------------------------------------------------*/
/* Run Macro                                                        */
/*-------------------------------------------------------------------*/

%LODES7Panel(
   State = &State,
   StateFP = &StateFp,
   JobType = &JobType,
   geolevel = &GEOlevel,
   Fyear = &Fyear,
   TYears = &Tyears);

Proc Sort Data = work.OnTheMap&state.&geolevel.&fyear._&lyear;
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

Data Lodes7.OnTheMap&state.&geolevel.&fyear._&lyear;
	Retain FIPS_&geolevel year
	wtotal_S000 htotal_S000 sum_S000
	wtotal_SE01 htotal_SE01 sum_SE01
	wtotal_SE02 htotal_SE02 sum_SE02
	wtotal_SE03 htotal_SE03 sum_SE03;
	Set work.OnTheMap&state.&geolevel.&fyear._&lyear;
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
		sum_SE03	= "Living & Employed in the &geolevel &JobLabel Workers Earning More than $3,333 per month";
Run;

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
