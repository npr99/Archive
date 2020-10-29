/*-------------------------------------------------------------------*/
/* program:		WLLRT_Data_NearestLRT_2015-08-07.sas
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

%LET dd_data = F:\;
%LET dd_SASLib = F:\MyProjects\;
%LET rootdir = F:\Dropbox\MyProjects\WLLRT\Work\;
* Location where shape files with centroids is located;
%LET shp_data = F:\Dropbox\MyProjects\WLLRT\Shapefiles\;

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
LIBNAME &library "&dd_SASLib.&library";

%let temp = temp;
LIBNAME &temp "&dd_SASLib.&library.\temp";

/*-------------------------------------------------------------------*/
/* Import LRT Station Data WAC File                                  */
/*-------------------------------------------------------------------*/

PROC IMPORT DATAFile = "&rootdir.WLLRT_Station_2015-08-05.xlsx" 
	DBMS = XLSX
	OUT = &temp..WLLRT_Station_temp REPLACE;
	Getnames = Yes;
	MIXED = YES;
	SHEET = "WLLRT_Station_2015-08-05";
RUN;

Data &temp..WLLRT_Station_temp2 Replace;
	Set &temp..WLLRT_Station_temp;
	LRT_lat = input(SttnLat,11.);
	LRT_lon = input(SttnLon,11.);
	cbsa = input(compress(CBSACode),$Char5.);
	* Code to convert XLS date to SAS data;
	LRTDate = put((INT(SttnDate) - 21916), DATE.);
	LODESYr = input(compress(LODESYear),$Char4.);
	Keep
		LRT_lat
		LRT_lon
		cbsa
		LRTID
		LRTDate
		LODESYr
		LnName
		SttnName;
Run;

/*-------------------------------------------------------------------*/
/* Import TabBlock Data with Centroids                               */
/*-------------------------------------------------------------------*/


PROC IMPORT OUT=&temp..WLLRT_tabblock2010
            DATAFILE="&shp_data.WLLRT_CBSA_tabblcok2010_centroids_pophu_2015-08-05v2.dbf"
            DBMS=DBF REPLACE;
   GETDEL=NO;
RUN;

Data &temp..tabblock2010Centroids Replace;
	Set &temp..WLLRT_tabblock2010;
	w_blockid = BLOCKID10;
	* Convert string values to numeric;
	w_lat = input(YCOORD,11.);
	w_lon = input(XCOORD,11.);
	cbsa = CBSAFP10;
	Keep
		STATEFP10
		COUNTYFP10
		HOUSING10
		POP10
		w_blockid
		w_lat
		w_lon
		cbsa;
Run;


%Macro CallCBSA(CBSAID);
/*-------------------------------------------------------------------*/
/* Macro to create datasets for all panel years                      */
/*-------------------------------------------------------------------*/

%MACRO NearestLRT_Panel(
   cbsaid = ,
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
	BY cbsa;
RUN;


data _null_;
  set &temp..WLLRT_Station_temp2;
  /*Save code to FILE statement below*/
    FILE "&rootdir.MinDistCalculations\WLLRT_DistMatrix\WLLRT_DistMatrix_&cbsaid._&panelyear..sas" ;
	BY cbsa;
    /*For the first observation of the metadata dataset start */
	if _n_ =1 then do;
		put "Data &temp..WLLRT_LRTDist_&cbsaid._&panelyear Replace;" ;
		put "Set &temp..tabblock2010Centroids;";
		put "/* Add distance between census tracts in miles;";
		put "Geodist works well, use options:";
		put "D since values in degrees";
		put "M to return distance in miles */";
		put "* Look only at one CBSA;";
		put "Where cbsa = ""&cbsaid"";";
		put "year = &panelyear;";
	end;
	IF cbsa = &cbsaid THEN DO;
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
   FILE "&rootdir.MinDistCalculations\WLLRT_DistMatrix\WLLRT_DistMatrix_&cbsaid._&panelyear..sas" MOD;
   		put "RUN;";
run;

%include "&rootdir.MinDistCalculations\WLLRT_DistMatrix\WLLRT_DistMatrix_&cbsaid._&panelyear..sas";

/*-------------------------------------------------------------------*/
/* Append Panel Years                                                */
/*-------------------------------------------------------------------*/

PROC APPEND BASE = &temp..WLLRT_LRTDist_&cbsaid._&fyear._&lyear 
	DATA = &temp..WLLRT_LRTDist_&cbsaid._&panelyear;
RUN;

%end;
%MEND NearestLRT_Panel;

* Delete the existing panel dataset before running IMPORT Macro;
PROC datasets library=&temp NOLIST;
	DELETE Data WLLRT_LRTDist_&cbsaid._&fyear._&lyear;
Run;

/*-------------------------------------------------------------------*/
/* Run Macro                                                        */
/*-------------------------------------------------------------------*/

%NearestLRT_Panel(
   cbsaid = &cbsaid,
   Fyear = &Fyear,
   TYears = &Tyears);

Proc Sort Data = &temp..WLLRT_LRTDist_&cbsaid._&fyear._&lyear;
	by w_blockid year;
Run;


/*-------------------------------------------------------------------*/
/* Find the LRT station with the Minimum Distance                    */
/*-------------------------------------------------------------------*/
                                                                                                                                                                                                                                               
data &temp..WLLRT_MinDist0_&cbsaid._&fyear._&lyear REPLACE;                                                                                                                  
 set &temp..WLLRT_LRTDist_&cbsaid._&fyear._&lyear;                                                                                                                              
  array list(*) d:;                                                                                                                  
  mindLRTID = input(substr(vname(list[whichn(min(of list[*]), of list[*])]),2,8),$char8.);
  mindLRT = list[whichn(min(of list[*]), of list[*])]; 
run;

data &temp..WLLRT_MinDist1_&cbsaid._&fyear._&lyear REPLACE;                                                                                                                  
 set &temp..WLLRT_MinDist0_&cbsaid._&fyear._&lyear;                                                                                                                              
  drop d:;
  if mindLRT = 99999 then mindLRTID = .;
run;

/*-------------------------------------------------------------------*/
/* Add LRT Name and Opening Date                                     */
/*-------------------------------------------------------------------*/

data &temp..WLLRT_Station_&cbsaid REPLACE;                                                                                                                  
 set &temp..WLLRT_Station_temp2;                                                                                                                              
  if cbsa = &cbsaid;
Run;


PROC SORT DATA = &temp..WLLRT_Station_&cbsaid;
	BY LRTID;
RUN;

PROC SORT DATA = &temp..WLLRT_MinDist1_&cbsaid._&fyear._&lyear;
	BY mindLRTID;
RUN;

DATA &temp..WLLRT_MinDist1_&cbsaid._&fyear._&lyear REPLACE;
	MERGE &temp..WLLRT_MinDist1_&cbsaid._&fyear._&lyear
		  &temp..WLLRT_Station_&cbsaid
				(rename=(LRTID=mindLRTID));
	BY mindLRTID;
RUN;

PROC SORT DATA = &temp..WLLRT_MinDist1_&cbsaid._&fyear._&lyear;
	BY w_blockid year;
RUN;

/*-------------------------------------------------------------------*/
/* Add Min Max Distances during panel range                          */
/*-------------------------------------------------------------------*/
* Structured on https://communities.sas.com/message/135797;

* look at min and max distance only for LODES years;
data &temp..WLLRT_MinDist1_&cbsaid._&fyear._&lyear2 REPLACE;
	set &temp..WLLRT_MinDist1_&cbsaid._&fyear._&lyear;
	if year LE &lyear2;
run;

proc sql;
create table  &temp..WLLRT_MinDist2_&cbsaid._&fyear._&lyear2 as
select        DISTINCT w_blockid,
              min(mindLRT) as mindLRT_min,
              max(mindLRT)as mindLRT_max
from          &temp..WLLRT_MinDist1_&cbsaid._&fyear._&lyear2
group by      w_blockid;
quit;

* merge min max distances with min distance;
data &temp..WLLRT_MinDist3_&cbsaid._&fyear._&lyear2 REPLACE;
	merge &temp..WLLRT_MinDist1_&cbsaid._&fyear._&lyear2 
		&temp..WLLRT_MinDist2_&cbsaid._&fyear._&lyear2;
	by w_blockid;
run;

/*-------------------------------------------------------------------*/
/* Lable Variables                                                   */
/*-------------------------------------------------------------------*/

DATA &temp..WLLRT_MinDist3_&cbsaid._&fyear._&lyear2 REPLACE;
	Set &temp..WLLRT_MinDist3_&cbsaid._&fyear._&lyear2;
	label 
		STATEFP10 = "State FIPS Census 2010"
		COUNTYFP10 = "County FIPS Census 2010"
		HOUSING10 = "Housing Units Census 2010"
		POP10  = "Population Census 2010"
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

%MEND CallCBSA;

%CallCBSA(12420); *Austin;
%CallCBSA(16740); *Charlotte;
%CallCBSA(19100); *Dallas;
%CallCBSA(19740); *Denver;
%CallCBSA(26420); *Houston;
%CallCBSA(31100); *Los Angeles;
%CallCBSA(38060); *Pheonix;
%CallCBSA(38900); *Portland;
%CallCBSA(40900); *Sacramento;
%CallCBSA(41620); *Salt Lake;
%CallCBSA(41740); *San Diego;
%CallCBSA(42660); *Seattle;




%Macro AddVariables(CBSAID);


/*-------------------------------------------------------------------*/
/* Add Distance Ranges                                               */
/*-------------------------------------------------------------------*/

DATA &temp..WLLRT_MinDist4_&cbsaid._&fyear._&lyear2 REPLACE;
	Set &temp..WLLRT_MinDist3_&cbsaid._&fyear._&lyear2;
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
DATA  &temp..WLLRT_MinDist4_&cbsaid._&fyear._&lyear2 REPLACE;
	Set  &temp..WLLRT_MinDist4_&cbsaid._&fyear._&lyear2;
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

Proc TABULATE DATA=&temp..WLLRT_MinDist4_&cbsaid._&fyear._&lyear2;
	CLASS donutrange;
	VAR range:;
	Tables donutrange*(sum*f=comma16.) ALL*(sum*f=comma18.),
			range:;
RUN;


	
/*-------------------------------------------------------------------*/
/* Add Primary County Variable                                       */
/*-------------------------------------------------------------------*/
* Structured on https://communities.sas.com/message/135797;
* SQL Help: http://support.sas.com/resources/papers/proceedings13/257-2013.pdf;
/*
sum by county of blocks within each range group
primary county is the county with the most blocks
*/

proc sql;
create table  &temp..WLLRT_primarycounty as
select        STATEFP10, COUNTYFP10,
              sum(range1) as range1_sum,
			  sum(range2) as range2_sum,
			  sum(range3) as range3_sum,
			  sum(range4) as range4_sum,
              sum(range5) as range5_sum
from          &temp..WLLRT_MinDist4_&cbsaid._&fyear._&lyear2
group by      STATEFP10, COUNTYFP10;
quit;

* create binary for primary county;
* Primay county has the most number of blocks within 1/4 mile of station;
proc sql;
create table  &temp..WLLRT_primarycounty2 as
select        STATEFP10, COUNTYFP10,
			  case 
			  	when range1_sum = max(range1_sum) then 1
			  	when range1_sum ^= max(range1_sum) then 0
				else .
			  end as primarycounty 'Primary County'
from          &temp..WLLRT_primarycounty
quit;

* Merge primary county variable with data set;
PROC SORT DATA = &temp..WLLRT_MinDist4_&cbsaid._&fyear._&lyear2;
	BY STATEFP10 COUNTYFP10;
RUN;


data &library..WLLRT_MinDist5_&cbsaid._&fyear._&lyear2 REPLACE;
	merge &temp..WLLRT_primarycounty2 
		&temp..WLLRT_MinDist4_&cbsaid._&fyear._&lyear2;
	by STATEFP10 COUNTYFP10;
run;

* Check number of blocks by range of station;
Proc TABULATE DATA=&library..WLLRT_MinDist5_&cbsaid._&fyear._&lyear2;
	CLASS SttnName LODESYr;
	VAR range:;
	Tables SttnName*LODESYr*(sum*f=comma16.) ALL*(sum*f=comma18.),
			range:;
RUN;
* stations with no blocks nearby are most likely duplicate locations,
same station different name for different lines;

%MEND AddVariables;

%AddVariables(12420); *Austin;
%AddVariables(16740); *Charlotte;
%AddVariables(19100); *Dallas;
%AddVariables(19740); *Denver;
%AddVariables(26420); *Houston;
%AddVariables(31100); *Los Angeles;
%AddVariables(38060); *Pheonix;
%AddVariables(38900); *Portland;
%AddVariables(40900); *Sacramento;
%AddVariables(41620); *Salt Lake;
%AddVariables(41740); *San Diego;
%AddVariables(42660); *Seattle;


* Notes
1 Oct 2015:
I just noticed that for Charlotte the open date for one of the stations is 1995.
This is clearl the opening date for the tranist center, not the LRT
What should we do? Change the open date to match the LRT or leave it since it was a transpo center
Should we note a difference between new LRT stations vs LRT stations co-located with historic
bus stations?
Charlotte	16740	Lynx Rapid Transit Services -Blue Line	Charlotte Transportation Center	12/11/1995
