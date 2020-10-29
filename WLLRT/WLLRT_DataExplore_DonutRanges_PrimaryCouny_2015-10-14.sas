/*-------------------------------------------------------------------*/
/* program:		WLLRT_DataExplore_DonutRanges_2015-09-30.sas
/* task:		Explore Job Data based on Donut Ranges
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
/* Codes for Key Variables in LODES Data Files                       */
/*-------------------------------------------------------------------*/
/*

[ST]_rac_[SEG]_[TYPE]_[YEAR]_1.csv.gz where
[ST]_&Dfile._[SEG]_[TYPE]_[YEAR].csv.gz where
[ST] = lowercase, 2-letter postal code for a chosen state
[Dfile] = Data files:
	OD – Origin-Destination data, jobs totals are associated with both a home Census Block and a work Census Block
	RAC – Residence Area Characteristic data, jobs are totaled by home Census Block
	WAC – Workplace Area Characteristic data, jobs are totaled by work Census Block
[SEG] = Segment of the workforce, can have the values of:
	3 	S000 Num Total number of jobs
	4 	SA01 Num Number of jobs of workers age 29 or younger
	5 	SA02 Num Number of jobs for workers age 30 to 54
	6 	SA03 Num Number of jobs for workers age 55 or older
	7 	SE01 Num Number of jobs with earnings $1250/month or less
	8 	SE02 Num Number of jobs with earnings $1251/month to $3333/month
	9 	SE03 Num Number of jobs with earnings greater than $3333/month
	10	SI01 Num Number of jobs in Goods Producing industry sectors [NAICS 11 - 33]
	11 	SI02 Num Number of jobs in Trade, Transportation, and Utilities industry sectors [NAICS 42 - 49]
	12 	SI03 Num Number of jobs in All Other Services industry sectors [NAICS 51 - 92]
[TYPE] = Job Type, can have a value of 
		“JT00” for All Jobs: All beginning-of-quarter (Q2) jobsfrom UI-covered employment(privateandstate- and local-government) plus OPM-sourced Federal employment.
		“JT01” for Primary Jobs: Subset of All Jobs that are classifiedas “primary”or “dominant” jobs.
		“JT02” for All Private Jobs: Privatesector only jobs from UI-coveredemployment.
		“JT03” for Private Primary Jobs: Subset of All Private Jobs that are classified as “primary” or “dominant” jobs.
		“JT04” for All Federal Jobs: OPM-sourced Federal employment.
		“JT05” for Federal Primary Jobs: Subset of All Federal Jobs that are classified as “primary” or “dominant” jobs.
[YEAR] = Year of job data. Can have the value of 2002-2012 for most states.

*/


/*-------------------------------------------------------------------*/
/* Compare Job Types                                                 */
/*-------------------------------------------------------------------*/


/* Define the starting and ending dates  */                                                                                              
/* of recent economic recession periods. */                                                                                              
data recessions;
	input startdate :date7. enddate :date7.;
	format startdate enddate date7.;
	datalines;
01Dec07  01Jun09
;
run;                                                                                                                                    
                                                                                                                                        
/* Create an Annotate data set to shade the background */                                                                               
/* of the graph to highlight the recession periods.    */                                                                               
data annorec;
	length function style color $8;
	retain xsys '2' ysys '1' when 'b';
	set recessions;

	function='move';
	x=startdate;
	y=0;
	output;

	function='bar';
	x=enddate;
	y=100;
	color='ltgray';
	style='solid';
	output;                                                                                                                             
run;                                                                                                                                    

%MACRO MakeGraphs(title1,JobVar,yaxis);
%MACRO MakeGraph(title1,title2,JobVar,cbsaid,LRTOpen_dates,hrefvaluelist,yaxis,min,max,by);
                                                                                                                                   
/* Define a title for the graph */
title1 height = 14pt justify = c ls=0.5 "LODES Job data by &title1 by distance from nearest LRT Station";
title2 height = 12pt justify = c ls=0.5 "for &title2";
 
/* Define legend characteristics */ 
legend1 label=none frame;

/* Define axis characteristics */                                                                                                       
axis1 order=("01APR2002"d to "01APR2013"d by year) offset=(3,3); 
*axis2 order=(&min to &max by &by) label=(angle=90 "&yaxis"); 
axis2 label=(angle=90 "&yaxis"); * remove min max, just let the program choose values;

footnote1 height = 8pt justify = l ls=0.5 "Grey Bar = Econmic Recession: 1 Dec 07-1 Jun 09, Red Lines = LRT Open Date: &LRTOpen_dates";
footnote2 height = 8pt justify = l ls=0.5 "data=WLLRT_&cbsaid.pc1&Dfile.&SegType.&JobType._index";

   proc gplot data=&library..WLLRT_&cbsaid.pc1&Dfile.&SegType.&JobType._index;
      symbol i=join h=2 width = 6;
      plot I_&JobVar.&JobType*lodesdate=donutrange / 
	  	haxis=axis1 vaxis=axis2
		href = &hrefvaluelist chref= depk lhref=2 WHREF=4
		annotate=annorec; ; 
		/* SAS Date calculator http://www.sastipsbyhal.com/2012/01/sas-date-calculator-now-available.html */
   run;
 

%mend;

%MakeGraph(&title1,Austin TX - Travis County,&JobVar,12420,22 Mar 2010,"22MAR2010"d,&yaxis,80,180,20);
%MakeGraph(&title1,Los Angeles CA - Los Angeles County,&JobVar,31100,26 July 2003 15 Nov 2009 28 Apr 2012 20 Jun 2012,15912 18216 19111 19164,&yaxis,80,180,20);
%MakeGraph(&title1,Dallas TX - Dallas County,&JobVar,19100,1 July 2002 9 Dec 2002 14 Sep 2009 6 Dec 2010 30 Jul 2012,15522 15683 18154 18602 19204,&yaxis,80,180,20);
%MakeGraph(&title1,Charlotte NC Mecklenburg County,&JobVar,16740,24 Nov 2007,"24Nov2007"d,&yaxis,80,180,20);


%mend;

* Best help on GPLOT Procedure:
https://support.sas.com/documentation/cdl/en/graphref/65389/HTML/default/viewer.htm#n0l4536v5ljgrvn1875la9n7gjjp.htm;

options orientation=landscape;
ods pdf file="F:\Dropbox\MyProjects\WLLRT\Work\WLLRT_DataExplore_DonutRanges_PrimaryCounty_2015-10-14_&Dfile.&SegType.&JobType._index.pdf" ;


%let yaxis = Index of  Primary Private Jobs (2002 = 100);
%let title1 = Primary Private Jobs;
%let JobVar = C000;
%MakeGraphs(&title1,&JobVar,&yaxis);
/*
%let yaxis = Index of Primary Private Retail Trade Jobs (2002 = 100);
%let title1 = Retail Trade Jobs;
%let JobVar = CNS07;
%MakeGraphs(&title1,&JobVar,&yaxis);

%let yaxis = Index of Primary Private Accommodation Food Services Jobs (2002 = 100);
%let title1 = Accommodation Food Services Jobs;
%let JobVar = CNS18;
%MakeGraphs(&title1,&JobVar,&yaxis);

%let yaxis = Index of Primary Private Construction Jobs (2002 = 100);
%let title1 = Construction Jobs;
%let JobVar = CNS04;
%MakeGraphs(&title1,&JobVar,&yaxis);

%let yaxis = Index of Primary Private Manufacturing Jobs (2002 = 100);
%let title1 = Manufacturing Jobs;
%let JobVar = CNS05;
%MakeGraphs(&title1,&JobVar,&yaxis);

%let yaxis = Index of Primary Private Jobs (2002 = 100);
%let title1 = Workers Age 29 or younger;
%let JobVar = CA01;
%MakeGraphs(&title1,&JobVar,&yaxis);

%let yaxis = Index of Primary Private Jobs (2002 = 100);
%let title1 = Workers Age 30 to 54;
%let JobVar = CA02;
%MakeGraphs(&title1,&JobVar,&yaxis);

%let yaxis = Index of Primary Private Jobs (2002 = 100);
%let title1 = Workers Age 55 and older;
%let JobVar = CA03;
%MakeGraphs(&title1,&JobVar,&yaxis);

%let yaxis = Index of Primary Private Jobs (2002 = 100);
%let title1 = Workers earning $1250 or less per month;
%let JobVar = CE01;
%MakeGraphs(&title1,&JobVar,&yaxis);

%let yaxis = Index of Primary Private Jobs (2002 = 100);
%let title1 = Workers earning $1251 to $3333 per month;
%let JobVar = CE02;
%MakeGraphs(&title1,&JobVar,&yaxis);

%let yaxis = Index of Primary Private Jobs (2002 = 100);
%let title1 = Workers earning Greater than $3333 per month;
%let JobVar = CE03;
%MakeGraphs(&title1,&JobVar,&yaxis);
*/
ods pdf close;

