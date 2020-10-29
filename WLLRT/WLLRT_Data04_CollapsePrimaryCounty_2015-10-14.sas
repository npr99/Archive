/*-------------------------------------------------------------------*/
/* program:		WLLRT_Data04_CollapsePrimaryCounty_2015-10-14.sas
/* task:		Create dataset to explore changes around donut ranges
/* project:		Wei Li Light Rail WLLRT
/* author:		Nathanael Rosenheim \ Oct 14 2015
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
%LET dd_SASLib = F:\myprojects\;
%LET rootdir = F:\Dropbox\MyProjects\WLLRT\Work\;
* Location where shape files with centroids is located;
%LET shp_data = F:\Dropbox\MyProjects\WLLRT\Shapefiles\;

/*-------------------------------------------------------------------*/
/* Important Macro Variables                                         */
/*-------------------------------------------------------------------*/

%Macro WLLRT_merge(cbsaid=, State=);

%LET FYear = 2002; *First year in panel;
%LET LYear = 2013; *Last year in panel LODES;
%LET JobType = JT03; * Primary Private Sector Jobs;
%LET SegType = S000; * Total number of jobs in LODES;

* Set Macro Variable for Data file of interest;
%LET DFile = WAC; * Residence Area Characteristic;
%LET w_h = w; * H for RAC, W for WAC;
%LET w_h2 = Work; 

/*-------------------------------------------------------------------*/
/* Define SAS Library                                                */
/*-------------------------------------------------------------------*/
%let library = WLLRT;
LIBNAME &library "&dd_SASLib.&library";

%let state_i = &state;
%let LODES71 = LODES71;
LIBNAME &LODES71 "&dd_data.&LODES71";

%let st_lib = &state_i;
LIBNAME &st_lib "&dd_data.&LODES71.\&state_i";

%let D_lib = &Dfile.&state_i;
LIBNAME &D_lib "&dd_data.&LODES71.\&state_i.\&Dfile";

%let WLLRT = WLLRT;
LIBNAME &WLLRT "&dd_SASLib.&WLLRT";


* Keep only primary county;
DATA work.WLLRT_&cbsaid.pc1&Dfile.&SegType.&JobType REPLACE;
	Set &WLLRT..WLLRT_&cbsaid.&Dfile.&SegType.&JobType.&fyear._&lyear;
	if primarycounty = 1;
RUN;

/*-------------------------------------------------------------------*/
/* Export file for mapping in QGIS                                   */
/*-------------------------------------------------------------------*/

proc export data=work.WLLRT_&cbsaid.pc1&Dfile.&SegType.&JobType
   outfile='&rootdir.WLLRT_&cbsaid.pc1&Dfile.&SegType.&JobType.csv'
   dbms=csv
   replace;
run;

/*-------------------------------------------------------------------*/
/* Collapse Data By Donut Range                                      */
/*-------------------------------------------------------------------*/
* Group data by year for the entire study area;
proc sql;
create table  work.WLLRT_&cbsaid.pc1&Dfile.&SegType.&JobType._cllps1 as
select        year,
				count(w_blockid) as countid,
              	sum(C000&JobType) as C000&JobType,
				sum(CA01&JobType) as CA01&JobType,
				sum(CA02&JobType) as CA02&JobType,
				sum(CA03&JobType) as CA03&JobType,
				sum(CE01&JobType) as CE01&JobType,
				sum(CE02&JobType) as CE02&JobType,
				sum(CE03&JobType) as CE03&JobType,
				sum(CNS01&JobType) as CNS01&JobType,
				sum(CNS02&JobType) as CNS02&JobType,
				sum(CNS03&JobType) as CNS03&JobType,
				sum(CNS04&JobType) as CNS04&JobType,
				sum(CNS05&JobType) as CNS05&JobType,
				sum(CNS06&JobType) as CNS06&JobType,
				sum(CNS07&JobType) as CNS07&JobType,
				sum(CNS08&JobType) as CNS08&JobType,
				sum(CNS09&JobType) as CNS09&JobType,
				sum(CNS10&JobType) as CNS10&JobType,
				sum(CNS11&JobType) as CNS11&JobType,
				sum(CNS12&JobType) as CNS12&JobType,
				sum(CNS13&JobType) as CNS13&JobType,
				sum(CNS14&JobType) as CNS14&JobType,
				sum(CNS15&JobType) as CNS15&JobType,
				sum(CNS16&JobType) as CNS16&JobType,
				sum(CNS17&JobType) as CNS17&JobType,
				sum(CNS18&JobType) as CNS18&JobType,
				sum(CNS19&JobType) as CNS19&JobType,
				sum(CNS20&JobType) as CNS20&JobType
from          work.WLLRT_&cbsaid.pc1&Dfile.&SegType.&JobType
group by      year;
quit;

* add donut range variable that represents the entire study area;
DATA work.WLLRT_&cbsaid.pc1&Dfile.&SegType.&JobType._cllps1 REPLACE;
	Set work.WLLRT_&cbsaid.pc1&Dfile.&SegType.&JobType._cllps1;
	if year NE .;
	donutrange = 9999;
RUN;

PROC SORT DATA = work.WLLRT_&cbsaid.pc1&Dfile.&SegType.&JobType._cllps1;
	BY donutrange year;
RUN;

* Group data by year and donut range;
proc sql;
create table  work.WLLRT_&cbsaid.pc1&Dfile.&SegType.&JobType._cllps2 as
select        year, donutrange,
				count(w_blockid) as countid,
              	sum(C000&JobType) as C000&JobType,
				sum(CA01&JobType) as CA01&JobType,
				sum(CA02&JobType) as CA02&JobType,
				sum(CA03&JobType) as CA03&JobType,
				sum(CE01&JobType) as CE01&JobType,
				sum(CE02&JobType) as CE02&JobType,
				sum(CE03&JobType) as CE03&JobType,
				sum(CNS01&JobType) as CNS01&JobType,
				sum(CNS02&JobType) as CNS02&JobType,
				sum(CNS03&JobType) as CNS03&JobType,
				sum(CNS04&JobType) as CNS04&JobType,
				sum(CNS05&JobType) as CNS05&JobType,
				sum(CNS06&JobType) as CNS06&JobType,
				sum(CNS07&JobType) as CNS07&JobType,
				sum(CNS08&JobType) as CNS08&JobType,
				sum(CNS09&JobType) as CNS09&JobType,
				sum(CNS10&JobType) as CNS10&JobType,
				sum(CNS11&JobType) as CNS11&JobType,
				sum(CNS12&JobType) as CNS12&JobType,
				sum(CNS13&JobType) as CNS13&JobType,
				sum(CNS14&JobType) as CNS14&JobType,
				sum(CNS15&JobType) as CNS15&JobType,
				sum(CNS16&JobType) as CNS16&JobType,
				sum(CNS17&JobType) as CNS17&JobType,
				sum(CNS18&JobType) as CNS18&JobType,
				sum(CNS19&JobType) as CNS19&JobType,
				sum(CNS20&JobType) as CNS20&JobType
from          work.WLLRT_&cbsaid.pc1&Dfile.&SegType.&JobType
group by      year, donutrange;
quit;

PROC SORT DATA = work.WLLRT_&cbsaid.pc1&Dfile.&SegType.&JobType._cllps2;
	BY donutrange year;
RUN;

PROC APPEND BASE = work.WLLRT_&cbsaid.pc1&Dfile.&SegType.&JobType._cllps1
	DATA = work.WLLRT_&cbsaid.pc1&Dfile.&SegType.&JobType._cllps2;
RUN;

* add donut range variable that represents the entire study area;
DATA work.WLLRT_&cbsaid.pc1&Dfile.&SegType.&JobType._cllps1 REPLACE;
	Set work.WLLRT_&cbsaid.pc1&Dfile.&SegType.&JobType._cllps1;
	if year NE .;
	if donutrange NE .;;
RUN;

%MACRO labelvariables( );
%IF &JobType = JT00 %THEN %LET JobLabel = All Jobs;
%IF &JobType = JT01 %THEN %LET JobLabel = Primary Jobs;
%IF &JobType = JT02 %THEN %LET JobLabel = All Private Jobs;
%IF &JobType = JT03 %THEN %LET JobLabel = Private Primary Jobs;
%IF &JobType = JT04 %THEN %LET JobLabel = All Federal Jobs;
%IF &JobType = JT05 %THEN %LET JobLabel = Federal Primary Jobs;

Data work.WLLRT_&cbsaid.pc1&Dfile.&SegType.&JobType._cllps1;
	Set work.WLLRT_&cbsaid.pc1&Dfile.&SegType.&JobType._cllps1;
	Label
		countid = "Number of Blocks"
		C000&JobType =  "&JobLabel"
		donutrange = "Distance to nearest LRT station"
		CA01&JobType =  "Age 29 or younger"
		CA02&JobType =  "Age 30 to 54"
		CA03&JobType =  "Age 55 or older"
		CE01&JobType =  "$1250 or less"
		CE02&JobType =  "$1251 to $3333"
		CE03&JobType =  "Greater than $3333"
		CNS01&JobType =  "Agriculture Forestry Fishing Hunting"
		CNS02&JobType =  "Mining Quarrying Oil Gas Extraction"
		CNS03&JobType =  "Utilities"
		CNS04&JobType =  "Construction"
		CNS05&JobType =  "Manufacturing"
		CNS06&JobType =  "Wholesale Trade"
		CNS07&JobType =  "Retail Trade"
		CNS08&JobType =  "Transportation Warehousing"
		CNS09&JobType =  "Information"
		CNS10&JobType =  "Finance Insurance"
		CNS11&JobType =  "Real Estate Rental Leasing"
		CNS12&JobType =  "Professional Scientific Technical Services"
		CNS13&JobType =  "Management of Companies Enterprises"
		CNS14&JobType =  "Administrative Support Waste Management Remediation Services"
		CNS15&JobType =  "Educational Services"
		CNS16&JobType =  "Health Care Social Assistance"
		CNS17&JobType =  "Arts Entertainment Recreation"
		CNS18&JobType =  "Accommodation Food Services"
		CNS19&JobType =  "Other Services"
		CNS20&JobType =  "Public Administration";
		/* Race, ethicnicity, gender only start in 2010
		CR01&JobType =  "White Alone"
		CR02&JobType =  "Black or African American Alone"
		CR03&JobType =  "American Indian or Alaska Native Alone"
		CR04&JobType =  "Asian Alone"
		CR05&JobType =  "Native Hawaiian or Other Pacific Islander Alone"
		CR07&JobType =  "Two or More Race Groups"
		CT01&JobType =  "Not Hispanic or Latino"
		CT02&JobType =  "Hispanic or Latino"
		CD01&JobType =  "Less than high school"
		CD02&JobType =  "High school or equivalent, no college"
		CD03&JobType =  "Some college or Associate degree"
		CD04&JobType =  "Undergrad or advanced degree"
		CS01&JobType =  "Male"
		CS02&JobType =  "Female"; */
Run;
%MEND labelvariables;

%labelvariables( );
/*-------------------------------------------------------------------*/
/* Create Variable list - Variables to Index                         */
/*-------------------------------------------------------------------*/
/*
The resulting data set (METACLASS) will have one row for each 
variable that was found in the original data set
Instructions found at http://caloxy.com/papers/58-028-30.pdf
Carpenter (nd) Storing and Using a List of Values in a Macro Variable
*/
/* Keep Variable to total */
DATA work.WLLRT_indexvars
	(Keep =
		C:
	)
	REPLACE;
	Set work.WLLRT_&cbsaid.pc1&Dfile.&SegType.&JobType._cllps1;
RUN;


Proc Contents data=work.WLLRT_indexvars noprint out=metaclass;
run;

 proc sql noprint;
 select name, label
 into :varslist separated by ' ',
 	  :varslabel separated by ';'
 from metaclass;
 quit;
%let cntvars = &sqlobs;
%put &cntvars;
%put &varslist;
%put "&varslabel";

/*-------------------------------------------------------------------*/
/* STEPPING THROUGH THE LIST USING THE %SCAN FUNCTION                */
/*-------------------------------------------------------------------*/

/*-------------------------------------------------------------------*/
/* Create Index for Each Variable                                    */
/*-------------------------------------------------------------------*/

%macro CreateIndex(datafile);

PROC SORT DATA = work.&datafile._cllps1;
	BY donutrange year;
RUN;

DATA work.&datafile._index REPLACE;
	Set work.&datafile._cllps1;
	by donutrange year;
		IF first.donutrange THEN DO;
			%do i = 1 %to &cntvars;
				retain firstobs_%scan(&varslist,&i);
				firstobs_%scan(&varslist,&i) = %scan(&varslist,&i);
				* Create index where 2002 = 100;
				I_%scan(&varslist,&i) = 100;
				attrib 	I_%scan(&varslist,&i) format = 6.2 label = "%scan(&varslabel,&i,;)";
				* Look at perecent of total jobs;
				If C000&JobType NE 0 THEN DO;
					P_%scan(&varslist,&i) = %scan(&varslist,&i) / C000&JobType;
				End;
				Else do;
					P_%scan(&varslist,&i) = 0;
				end;
				attrib 	P_%scan(&varslist,&i) format = percent7.2 label = "%scan(&varslabel,&i,;)";

			%end;
			cnt = 0;
		end;
		%do i = 1 %to &cntvars;
			IF firstobs_%scan(&varslist,&i) NE 0 THEN DO;
				I_%scan(&varslist,&i) = %scan(&varslist,&i) / firstobs_%scan(&varslist,&i) * 100;
				If C000&JobType NE 0 THEN DO;
					P_%scan(&varslist,&i) = %scan(&varslist,&i) / C000&JobType;
				End;
				Else do;
					P_%scan(&varslist,&i) = 0;
				end;
			end;
			Else do;
				I_%scan(&varslist,&i) = 0;
				If C000&JobType NE 0 THEN DO;
					P_%scan(&varslist,&i) = %scan(&varslist,&i) / C000&JobType;
				End;
				Else do;
					P_%scan(&varslist,&i) = 0;
				end;
			end;
		%end;
		cnt + 1;
		drop firstobs:;
RUN;
%mend CreateIndex;

%CreateIndex(WLLRT_&cbsaid.pc1&Dfile.&SegType.&JobType.);

/*-------------------------------------------------------------------*/
/* Format Variables                                                  */
/*-------------------------------------------------------------------*/

proc format;
value donutrange_f
	1 = "Dist 0 to 1/4 mile"
	2 = "Dist 1/4 to 1/2 mile"
	3 = "Dist 1/2 to 1 mile"
	4 = "Dist 1+ mile"
	5 = "No station in CBSA"
	9999 = "Entire County";
run;

DATA  work.WLLRT_&cbsaid.pc1&Dfile.&SegType.&JobType._index REPLACE;
	Set work.WLLRT_&cbsaid.pc1&Dfile.&SegType.&JobType._index;
	format
  donutrange   donutrange_f.
;
RUN;


* drop obsevarations with missing data;
data work.WLLRT_&cbsaid.pc1&Dfile.&SegType.&JobType._index REPLACE;                                                                                                                  
 set work.WLLRT_&cbsaid.pc1&Dfile.&SegType.&JobType._index;                                                                                                                              
  where donutrange NE . AND year NE .;
Run;


* Add lodes date which is actually April 1 of the year;
DATA &WLLRT..WLLRT_&cbsaid.pc1&Dfile.&SegType.&JobType._index REPLACE;
	set work.WLLRT_&cbsaid.pc1&Dfile.&SegType.&JobType._index;

	lodesdate = mdy(4,1,year);
	format lodesdate mmddyy10.;
	
	Label
		lodesdate = "April 1 Jobs";
RUN;

%MEND WLLRT_merge;

%WLLRT_merge(cbsaid = 12420, state = tx); *Austin;
%WLLRT_merge(cbsaid = 19100, state = tx); *Dallas;
%WLLRT_merge(cbsaid = 16740, state = nc); *Charlotte;
%WLLRT_merge(cbsaid = 31100, state = ca); *Los Angeles;
%WLLRT_merge(cbsaid = 19740, state = co); *Denver;
%WLLRT_merge(cbsaid = 26420, state = tx); *Houston;
%WLLRT_merge(cbsaid = 38060, state = az); *Pheonix;
%WLLRT_merge(cbsaid = 40900, state = ca); *Sacramento;
%WLLRT_merge(cbsaid = 41620, state = ut); *Salt Lake;
%WLLRT_merge(cbsaid = 41740, state = ca); *San Diego;
%WLLRT_merge(cbsaid = 42660, state = wa); *Seattle;


/* These CBSA's cover 2 states, need to adjust the program to make this work
%WLLRT_merge(cbsaid = 38900, state = or); *Portland;
%WLLRT_merge(cbsaid = 16740, state = nc); *Charlotte;



/* Reports

 title "LODES total Jobs Data Percent Change Year to Year";
   proc sgplot data=work.WLLRT_databyyear3;
   	  STYLEATTRS
			datasymbols=(circle square triangle star)
			datacontrastcolors=(red green blue black)
			datalinepatterns=(solid dot);
      series x=year y=pctchngy2y / group = donutrange;

	  XAXIS label='Year';
      YAXIS label='Percent Change';
   run;

 title "LODES total Jobs Data Percent Change from 2002";
   proc sgplot data=work.WLLRT_databyyear3;
   	  STYLEATTRS
			datasymbols=(circle square triangle star)
			datacontrastcolors=(red green blue black)
			datalinepatterns=(solid dot);
      series x=year y=pctchng2002 / group = donutrange markers;
	  XAXIS label='Year';
      YAXIS label='Percent Change';
   run;
