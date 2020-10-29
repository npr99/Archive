/*-------------------------------------------------------------------*/
/* program:		WLLRT_Data05_ExportCSVPrimaryCounty_2015-10-14.sas
/* task:		Export CSV dataset to explore changes around donut ranges
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

%Macro WLLRT_export(cbsaid=, State=);

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
   outfile="F:\Dropbox\MyProjects\WLLRT\Work\WLLRT_&cbsaid.pc1&Dfile.&SegType.&JobType..csv"
   dbms=csv
   replace;
run;


%MEND WLLRT_export;

%WLLRT_export(cbsaid = 12420, state = tx); *Austin;
%WLLRT_export(cbsaid = 19100, state = tx); *Dallas;
%WLLRT_export(cbsaid = 16740, state = nc); *Charlotte;
%WLLRT_export(cbsaid = 31100, state = ca); *Los Angeles;
%WLLRT_export(cbsaid = 19740, state = co); *Denver;
%WLLRT_export(cbsaid = 26420, state = tx); *Houston;
%WLLRT_export(cbsaid = 38060, state = az); *Pheonix;
%WLLRT_export(cbsaid = 40900, state = ca); *Sacramento;
%WLLRT_export(cbsaid = 41620, state = ut); *Salt Lake;
%WLLRT_export(cbsaid = 41740, state = ca); *San Diego;
%WLLRT_export(cbsaid = 42660, state = wa); *Seattle;


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
