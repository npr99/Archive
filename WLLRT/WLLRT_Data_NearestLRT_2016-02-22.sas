/*-------------------------------------------------------------------*/
/* program:		WLLRT_Data_NearestLRT_2015-02-22.sas
/* task:		Determine Nearest LRT by distance from TabBlock2010
/* project:		Wei Li Light Rail WLLRT
/* author:		Nathanael Rosenheim \ August 07 2015
/*-------------------------------------------------------------------*/

/*-------------------------------------------------------------------*/
/* Data Source:                                                      */
/* United States Census Bureau (2015) LEHD Origin-Destination        */ 
/*       Employment Statistics (LODES)Dataset Structure Format       */
/*       Version 7.1 Retrieved 5/22/2013 and 7/26/2015 from          */
/*       http://lehd.ces.census.gov/data/                            */
/*-------------------------------------------------------------------*/
/*-------------------------------------------------------------------*/
/* Data Source:                                                      */
/* Wei Li (2015) Locations and Opening Dates of LRT Stations         */ 
/*       via email with Wei Li                                       */
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

* Restructure folders to save data;

%LET dd_data = Y:\NRLRT\;
%LET dd_SASLib = Y:\NRLRT\Work\;
%LET rootdir = Y:\NRLRT\;

/*-------------------------------------------------------------------*/
/* Important Macro Variables                                         */
/*-------------------------------------------------------------------*/
%LET FYear = 2002; *First year in panel;
%LET LYear = 2015; *Last year in panel;
%LET LYear2 = 2013; *Last year in LODES panel;
%LET TYears = 14; * years between first LRT year and last LRT year;

/*-------------------------------------------------------------------*/
/* Define SAS Library                                                */
/*-------------------------------------------------------------------*/
%let library = WLLRT;
LIBNAME &library "&dd_SASLib";

%let temp = temp;
LIBNAME &temp "&dd_SASLib.\tempSAS";

/*-------------------------------------------------------------------*/
/* Import LRT Station Data WAC File                                  */
/*-------------------------------------------------------------------*/

PROC IMPORT DATAFile = "&rootdir.Work\WLLRT_Station_2016-02-23.xlsx" 
	DBMS = XLSX
	OUT = &temp..WLLRT_Station_temp REPLACE;
	Getnames = Yes;
RUN;

Data &temp..WLLRT_Station_temp2 Replace;
	Set &temp..WLLRT_Station_temp;
	LRT_lat = input(SttnLat,11.);
	LRT_lon = input(SttnLon,11.);
	cbsa = input(compress(CBSACode),$Char5.);
	* Code to convert XLS date to SAS data;
	LRTDate = put((INT(SttnDate)), DATE.);
	LODESYr = input(compress(LODESYear),$Char4.);
	stfips = put(STATEFP,z2.);
	Keep
		LRT_lat
		LRT_lon
		cbsa
		stfips
		LRTID
		LRTDate
		LODESYr
		LnName
		SttnName;
Run;

%Macro CallState(St,StFIPS);
/*-------------------------------------------------------------------*/
/* Clear Log                                                         */
/*-------------------------------------------------------------------*/
DM "clear log";

/*-------------------------------------------------------------------*/
/* Import LODES Data with Centroids                                  */
/*-------------------------------------------------------------------*/

%LET LODES_data = Y:\NRLRT\Posted\WLLRT_D1av1_CSVPanel_LEHDv71_2016-02-18\wac_S000_JT03\;

PROC IMPORT OUT=&temp..WLLRT_&st._wac_S000_JT03
            DATAFILE="&LODES_data.&st._wac_S000_JT03.csv"
            DBMS=DLM REPLACE;
	delimiter=";";
   	Getnames = Yes;
RUN;

Data &temp..WLLRT_&st._blckcntroids Replace;
	Set &temp..WLLRT_&st._wac_S000_JT03;
	year2 = put(year,4.);
	w_blockid = w_geocode;
	* Convert string values to numeric;
	w_lat = input(INTPTLAT10,11.);
	w_lon = input(INTPTLON10,11.);
	stfips = put(st,2.);
Run;



/*-------------------------------------------------------------------*/
/* Macro to create datasets for all panel years                      */
/*-------------------------------------------------------------------*/

%MACRO NearestLRT_Panel(
   StFIPS = ,
   Fyear = ,
   TYears =);

%Do i = 1 %to &TYears;
	Data _NULL_;
		CALL SYMPUT("panelyear",put(&Fyear+&i-1,4.));
	RUN;
/*-------------------------------------------------------------------*/
/* Calculate Distance between LRT stations and TabBlock              */
/*-------------------------------------------------------------------*/

* Sort Metadata with Second Order Variables to Aggregate;
PROC SORT DATA = &temp..WLLRT_Station_temp2;
	BY stfips;
RUN;


data _null_;
  set &temp..WLLRT_Station_temp2;
  /*Save code to FILE statement below*/
    FILE "&rootdir.Work\TempSAS\MinDistCalculations\WLLRT_DistMatrix\WLLRT_DistMatrix_&st._&panelyear..sas" ;
	BY stfips;
    /*For the first observation of the metadata dataset start */
	if _n_ =1 then do;
		put "Data &temp..WLLRT_LRTDist_&st._&panelyear Replace;" ;
		put "Set &temp..WLLRT_&st._blckcntroids;";
		put "/* Add distance between census tracts in miles;";
		put "Geodist works well, use options:";
		put "D since values in degrees";
		put "M to return distance in miles */";
		put "* Look only at one year;";
		put "Where year2 = put(&panelyear,4.);";
	end;
	IF stfips = &StFIPS THEN DO;
		If LODESYr LE &panelyear Then Do;
			lineout=  "d"||compress(LRTID)||" = Geodist(w_lat,w_lon,"||compress(LRT_lat)||","||compress(LRT_lon)||",'DM');";
		    put	lineout;
		end;
		Else Do;
			* If LRT station did not exist in panel year;
			lineout=  "d"||compress(LRTID)||" = 99999;";
		    put	lineout;
		end;
	end;
run;

data _null_;
   *Finish up the program;
   FILE "&rootdir.Work\TempSAS\MinDistCalculations\WLLRT_DistMatrix\WLLRT_DistMatrix_&st._&panelyear..sas" MOD;
   		put "RUN;";
run;

%include "&rootdir.Work\TempSAS\MinDistCalculations\WLLRT_DistMatrix\WLLRT_DistMatrix_&st._&panelyear..sas";

/*-------------------------------------------------------------------*/
/* Append Panel Years                                                */
/*-------------------------------------------------------------------*/

PROC APPEND BASE = &temp..WLLRT_LRTDist_&st._&fyear._&lyear 
	DATA = &temp..WLLRT_LRTDist_&st._&panelyear;
RUN;

%end;
%MEND NearestLRT_Panel;

* Delete the existing panel dataset before running IMPORT Macro;
PROC datasets library=&temp NOLIST;
	DELETE Data WLLRT_LRTDist_&st._&fyear._&lyear;
Run;

/*-------------------------------------------------------------------*/
/* Run Macro                                                        */
/*-------------------------------------------------------------------*/

%NearestLRT_Panel(
   StFIPS = &StFIPS,
   Fyear = &Fyear,
   TYears = &Tyears);

Proc Sort Data = &temp..WLLRT_LRTDist_&st._&fyear._&lyear;
	by w_blockid year2;
Run;


/*-------------------------------------------------------------------*/
/* Find the LRT station with the Minimum Distance                    */
/*-------------------------------------------------------------------*/
                                                                                                                                                                                                                                               
data &temp..WLLRT_MinDist0_&st._&fyear._&lyear REPLACE;                                                                                                                  
 set &temp..WLLRT_LRTDist_&st._&fyear._&lyear;                                                                                                                              
  array list(*) d:;                                                                                                                  
  mindLRTID = input(substr(vname(list[whichn(min(of list[*]), of list[*])]),2,8),$char8.);
  mindLRT = list[whichn(min(of list[*]), of list[*])]; 

  * Count the number of stations within 1/4 and 1/2 mile;
  LRTcnt1=0;
  LRTcnt2=0;
  do i=1 to dim(list);
  	if list(i) <= 0.25 LRTcnt1= 1 + LRTcnt1;
	if list(i) <= 0.5 LRTcnt2= 1 + LRTcnt1;
  end;
run;

data &temp..WLLRT_MinDist1_&st._&fyear._&lyear REPLACE;                                                                                                                  
 set &temp..WLLRT_MinDist0_&st._&fyear._&lyear;                                                                                                                              
  drop d:;
  if mindLRT = 99999 then mindLRTID = .;
run;

/*-------------------------------------------------------------------*/
/* Add LRT Name and Opening Date                                     */

/* Does not appear to have worked....
/* Also need to rethink the process - What I am looking for is the area around
A station. Create a 1/4 mile, 1/2 mile circle around each station
and then collect the tabblock ids that are within that circle
The merge the LODES data to these tabblocks by year and collapse the values
for each year

/*-------------------------------------------------------------------*/

data &temp..WLLRT_Station_&st REPLACE;                                                                                                                  
 set &temp..WLLRT_Station_temp2;                                                                                                                              
  if stfips = &StFIPS;
Run;


PROC SORT DATA = &temp..WLLRT_Station_&st;
	BY LRTID;
RUN;

PROC SORT DATA = &temp..WLLRT_MinDist1_&st._&fyear._&lyear;
	BY mindLRTID;
RUN;

DATA &temp..WLLRT_MinDist1_&st._&fyear._&lyear REPLACE;
	MERGE &temp..WLLRT_MinDist1_&st._&fyear._&lyear
		  &temp..WLLRT_Station_&st
				(rename=(LRTID=mindLRTID));
	BY mindLRTID;
RUN;

PROC SORT DATA = &temp..WLLRT_MinDist1_&st._&fyear._&lyear;
	BY w_blockid year2;
RUN;

/*-------------------------------------------------------------------*/
/* Add Min Max Distances during panel range                          */
/*-------------------------------------------------------------------*/
* Structured on https://communities.sas.com/message/135797;

* look at min and max distance only for LODES years;
data &temp..WLLRT_MinDist1_&st._&fyear._&lyear2 REPLACE;
	set &temp..WLLRT_MinDist1_&st._&fyear._&lyear;
	if year2 LE &lyear2;
run;

proc sql;
create table  &temp..WLLRT_MinDist2_&st._&fyear._&lyear2 as
select        DISTINCT w_blockid,
              min(mindLRT) as mindLRT_min,
              max(mindLRT)as mindLRT_max
from          &temp..WLLRT_MinDist1_&st._&fyear._&lyear2
group by      w_blockid;
quit;

* merge min max distances with min distance;
data &temp..WLLRT_MinDist3_&st._&fyear._&lyear2 REPLACE;
	merge &temp..WLLRT_MinDist1_&st._&fyear._&lyear2 
		&temp..WLLRT_MinDist2_&st._&fyear._&lyear2;
	by w_blockid;
run;

/*-------------------------------------------------------------------*/
/* Lable Variables                                                   */
/*-------------------------------------------------------------------*/

DATA &temp..WLLRT_MinDist3_&st._&fyear._&lyear2 REPLACE;
	Set &temp..WLLRT_MinDist3_&st._&fyear._&lyear2;
	label 
		stfips = "State FIPS Census 2010"
		cty = "County FIPS Census 2010"
		w_lat = "TABBLOCK Centroid Latitude"
		w_lon = "TABBLOCK Centroid Longitude"
		cbsa = "Core Based Statistical Area (CBSA) Code"
		mindLRTID = "Nearest LRT ID"
		mindLRT = "Distance to LRT (miles)"
		LnName = "LRT Line Name"
		SttnName = "LRT Station Name"
		LRT_lat = "LRT Station Latitude"
		LRT_lon = "LRT Station Longitude"
		LRTDate = "LRT Station Open Date"
		LODESYr = "First Year LRT Station expected on LODES Data"
		mindLRT_min = "Min Distance in LODES Panel"
		mindLRT_max = "Max Distance in LODES Panel";
run;

%MEND CallState;

%CallState(az,"04"); *Arizona;
%CallState(ar,"05"); *Arkansas;
%CallState(ca,"06"); *California;
%CallState(co,"08"); *California;
%CallState(il,"17"); *Illinois;
%CallState(mn,"27"); *Minnesota;
%CallState(mo,"29"); *Missouri;
%CallState(nj,"34"); *New Jersey;
%CallState(nc,"37"); *North Carolina;
%CallState(or,"41"); *Oregon;
%CallState(tx,"48"); *Texas;
%CallState(ut,"49"); *Utah;
%CallState(va,"51"); *Virginia;
%CallState(wa,"53"); *Washington;



%Macro AddVariables(st);


/*-------------------------------------------------------------------*/
/* Add Distance Ranges                                               */
/*-------------------------------------------------------------------*/

DATA &temp..WLLRT_MinDist4_&st._&fyear._&lyear2 REPLACE;
	Set &temp..WLLRT_MinDist3_&st._&fyear._&lyear2;
	* Binary values for distance from station;
	range1 = 0;
	range2 = 0;
	range3 = 0;
	range4 = 0;
	range5 = 0;
	If mindLRT_min GT 0 AND mindLRT_min LE 0.25 then range1 = 1;
	If mindLRT_min GT 0 AND mindLRT_min LE 0.5 then range2 = 1;
	If mindLRT_min GT 0 AND mindLRT_min LE 1 then range3 = 1;
	If mindLRT_min GT 1 then range4 = 1;
	If mindLRT_min = 99999 then range5 = 1;
	* Exclusive groups with donut ranges;
	donutrange = 0;
	If mindLRT_min GT 0 AND mindLRT_min LE 0.25 then donutrange = 1;
	If mindLRT_min GT .25 AND mindLRT_min LE 0.5 then donutrange = 2;
	If mindLRT_min GT .5 AND mindLRT_min LE 1 then donutrange = 3;
	If mindLRT_min GT 1 then donutrange = 4;
	If mindLRT_min = 99999 then donutrange = 5;

	* Exclusive groups with donut ranges for specific year;
	* Binary values for distance from station for specific year;
	r1 = 0;
	r2 = 0;
	r3 = 0;
	r4 = 0;
	r5 = 0;
	If mindLRT GT 0 AND mindLRT LE 0.25 then r1 = 1;
	If mindLRT GT .25 AND mindLRT LE 0.5 then r2 = 1;
	If mindLRT GT .5 AND mindLRT LE 1 then r3 = 1;
	If mindLRT GT 1 AND mindLRT NE 99999 then r4 = 1;
	If mindLRT = 99999 then r5 = 1;


run;

* check range cross tab;
DATA  &temp..WLLRT_MinDist4_&st._&fyear._&lyear2 REPLACE;
	Set  &temp..WLLRT_MinDist4_&st._&fyear._&lyear2;
	label 
		range1 = "Dist 0 to 1/4 mile (min over panel)"
		range2 = "Dist 0 to 1/2 mile (min over panel)"
		range3 = "Dist 0 to 1 mile (min over panel)"
		range4 = "Dist 1+ mile (min over panel)"
		range5 = "No station in CBSA (min over panel)"
		donutrange = "Donut Ranges (min over panel)"

		r1 = "Dist 0 to 1/4 mile"
		r2 = "Dist 1/4 to 1/2 mile"
		r3 = "Dist 1/2 to 1 mile"
		r4 = "Dist 1+ mile"
		r5 = "No station in CBSA";
run;

Proc TABULATE DATA=&temp..WLLRT_MinDist4_&st._&fyear._&lyear2;
	CLASS donutrange;
	VAR range:;
	Tables donutrange*(sum*f=comma16.) ALL*(sum*f=comma18.),
			range:;
RUN;

%MEND AddVariables;

%AddVariables(az); *Arizona;
%AddVariables(ar); *Arkansas;
%AddVariables(ca); *California;
%AddVariables(co); *California;
%AddVariables(il); *Illinois;
%AddVariables(mn); *Minnesota;
%AddVariables(mo); *Missouri;
%AddVariables(nj); *New Jersey;
%AddVariables(nc); *North Carolina;
%AddVariables(or); *Oregon;
%AddVariables(tx); *Texas;
%AddVariables(ut); *Utah;
%AddVariables(va); *Virginia;
%AddVariables(wa); *Washington;

* Notes
1 Oct 2015:
I just noticed that for Charlotte the open date for one of the stations is 1995.
This is clearl the opening date for the tranist center, not the LRT
What should we do? Change the open date to match the LRT or leave it since it was a transpo center
Should we note a difference between new LRT stations vs LRT stations co-located with historic
bus stations?
Charlotte	16740	Lynx Rapid Transit Services -Blue Line	Charlotte Transportation Center	12/11/1995
