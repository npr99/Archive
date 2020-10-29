/*-------------------------------------------------------------------*/
/* program:		WLLRT_Data_ImportLodes7_WAC_2015-07-26.sas
/* task:		Import LODESv7.1 Worker Charactersitics Files
/* project:		Wei Li Light Rail WLLRT
/* author:		Nathanael Rosenheim \ July 26 2015
/*-------------------------------------------------------------------*/

/*-------------------------------------------------------------------*/
/* Data Source:                                                      */
/* United States Census Bureau (2015) LEHD Origin-Destination        */ 
/*       Employment Statistics (LODES)Dataset Structure Format       */
/*       Version 7.1 Retrieved 5/22/2013 and 7/26/2015 from          */
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

%LET dd_data = F:\;
%LET dd_SASLib = F:\;

/*-------------------------------------------------------------------*/
/* Important Macro Variables                                         */
/*-------------------------------------------------------------------*/

%LET FYear = 2002; *First year in panel;
%LET LYear = 2013; *Last year in panel;
%LET TYears = 12;

* Set Macro Varialbes for job type of interest;
%LET JobType = JT03; * for Private Primary Jobs: 
						Subset of All Private Jobs that are classified 
						as “primary” or “dominant” jobs.
						Datasets for 2010 and later contain additional Job Types 
						that cover Federal Employment as supplied by the 
						Office of Personnel Management (OPM).
						Therefore JT03 should be consistent across all years;

* Set Macro Varialbes for segment type of interest;
%LET SegType = S000; * Total number of jobs in LODES;

/*-------------------------------------------------------------------*/
/* Define SAS Library                                                */
/*-------------------------------------------------------------------*/
%let library = LODES71;
LIBNAME &library "&dd_SASLib.&library";

%let temp = temp;
LIBNAME &temp "&dd_SASLib.&library.\temp";

%let delete = delete;
LIBNAME &delete "&dd_SASLib.&library.\delete";


%macro ImportArrayLODES71(state_i);
* Set Macro Variables for State and Years;
%LET State = &state_i; * This state starts as the main state and then will 
					go through all 50 states for the AUX files;


/*-------------------------------------------------------------------*/
/* Codes for Key Variables in LODES WAC Files                         */
/*-------------------------------------------------------------------*/
/*
[ST]_wac_[SEG]_[TYPE]_[YEAR].csv.gz where
[ST] = lowercase, 2-letter postal code for a chosen state
[SEG] = Segment of the workforce, can have the values of:
	3 	S000 Num Total number of jobs
	4 	SA01 Num Number of jobs of workers age 29 or younger
	5 	SA02 Num Number of jobs for workers age 30 to 54
	6 	SA03 Num Number of jobs for workers age 55 or older
	7 	SE01 Num Number of jobs with earnings $1250/month or less
	8 	SE02 Num Number of jobs with earnings $1251/month to $3333/month
	9 	SE03 Num Number of jobs with earnings greater than $3333/month
	10	SI01 Num Number of jobs in Goods Producing industry sectors
	11 	SI02 Num Number of jobs in Trade, Transportation, and Utilities industry sectors
	12 	SI03 Num Number of jobs in All Other Services industry sectors 
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
/* Import LODES WAC File                                             */
/*-------------------------------------------------------------------*/

%MACRO ImportLODES_WAC_File(
   State = ,
   MainState = ,
   Year = ,
   SegType = ,
   JobType =  );

* Macro Variable for the LODES File that will be imported;
%let geoxwalk = &dd_data.onthemap\LODES7\&state.\&state._xwalk.csv.gz;

* Macro Variable for the LODES File that will be imported;
* [ST]_wac_[SEG]_[TYPE]_[YEAR].csv.gz;
%let file1= &dd_data.onthemap\LODES7\&state.\wac\&state._wac_&SegType._&JobType._&year..csv.gz;


*  The following line should contain the directory
  	where the gzip is to be stored  
	use " " around directories with spaces;
* needed to move the gzip file to the F drive;
* May have been an issue with the spaces in the file path;
%LET dd_gzip = &dd_data.onthemap\gzip;


* Use a trailing @, then keep specific Census Blocks;
* Using INFILE to read in Comma-seperated value files, first obseravtion has headers therefore will be skipped (FIRSTOBS = 2)
Going to use Delimiter-Senstive DATA option (DSD) just in case missing values exist;

/* If you attempt to print or manipulate the non-existent data set */
/* an error will be generated.  To prevent the error, check to see */
/* if the data set exists, then conditionally execute the step(s). */

/*-------------------------------------------------------------------*/
/* Read in LODES Geography Cross Walk File                           */
/*-------------------------------------------------------------------*/

%macro checkds(dsn);
  %if %sysfunc(exist(&dsn)) %then %do;
    data _null_;
		put "Geography Crosswalk Exists";
	Run;
  %end;
  %else %do;
* Generate output Geography crosswalk file;
filename datafile pipe "&dd_gzip -cd &geoxwalk";

DATA &temp..&state.xwalk REPLACE;
	INFILE datafile DLM = ',' LRECL = 2500 FIRSTOBS = 2 DSD;

attrib tabblk2010   length=$15  label="2010 Census Tabulation Block Code"; 
attrib st 			length=$2  	label="FIPS State Code";
attrib stusps   	length=$2 	label="USPS State Code";
attrib stname   	length=$100 label="State Name";
attrib cty   		length=$5 	label="FIPS County Code";
attrib ctyname   	length=$100 label="County or County Equivalent Name";
attrib trct   		length=$11	label="Census Tract Code";
attrib trctname   	length=$100 label="Tract Name, formatted with County and State";
attrib bgrp   		length=$12 	label="Census Blockgroup Code";
attrib bgrpname   	length=$100 label="Census Blockgroup Name, formatted with Tract, County, and State";
attrib cbsa   		length=$5 	label="CBSA (Metropolitan/Micropolitan Area) Code";
attrib cbsaname   	length=$100 label="CBSA (Metropolitan/Micropolitan Area) Name";
attrib zcta   		length=$5 	label="ZIP Code Tabulation Area (ZCTA) Code";
attrib zctaname   	length=$100 label="ZCTA Name";
attrib stplc   		length=$7 	label="Nationally Unique Place Code, (FIPS State + FIPS Place)";
attrib stplcname   	length=$100 label="Place Name";
attrib ctycsub   	length=$10 	label="Nationally Unique County Subdivision Code, (FIPS State + FIPS County + FIPS County Subdivision)";
attrib ctycsubname  length=$100 label="County Subdivision Name";
attrib stcd113   	length=$4 	label="Nationally Unique 113th Congressional District Code, (FIPS State + 2-digit District Number)";
attrib stcd113name  length=$100 label="113th Congressional District Name";
attrib stsldl   	length=$5 	label="Nationally Unique State Legislative District, Lower Chamber, (FIPS State + 3-digit District Number)";
attrib stsldlname   length=$100 label="State Legislative District Chamber, Lower Chamber";
attrib stsldu   	length=$5 	label="Nationally Unique State Legislative District, Upper Chamber, (FIPS State + 3-digit District Number)";
attrib stslduname   length=$100 label="State Legislative District Chamber, Upper Chamber Chamber";
attrib stschool   	length=$7 	label="Nationally Unique Unified/Elementary School District Code, (FIPS State + 5-digit Local Education Agency Code)";
attrib stschoolname length=$100 label="Unified/Elementary School District Name";
attrib stsecon   	length=$7 	label="Nationally Unique Secondary School District Code, (FIPS State + 5-digit Local Education Agency Code)";
attrib stseconname  length=$100 label="Secondary School District Name";
attrib trib   		length=$5 	label="American Indian /Alaska Native/Native Hawaiian Area Census Code";
attrib tribname  	length=$100 label="American Indian /Alaska Native/Native Hawaiian Area Name";
attrib tsub   		length=$7 	label="American Indian Tribal Subdivision Code";
attrib tsubname   	length=$100 label="American Indian Tribal Subdivision Name";
attrib stanrc   	length=$7 	label="Nationally Unique Alaska Native Regional Corporation (ANRC) Code (FIPS State + FIPS ANRC)";
attrib stanrcname   length=$100 label="Alaska Native Regional Corporation Name";
attrib mil   		length=$22 	label="Military Installation Landmark Code";
attrib milname  	length=$100 label="Military Installation Name";
attrib stwib  		length=$8 	label="Nationally Unique Workforce Innovation Board (WIB) Area Code (FIPS State + state-provided 6-digit WIB Area Code)";
attrib stwibname	length=$100 label="Workforce Innovation Board Area Name";
attrib wired1   	length=$2 	label="WIRED Region (1st Gen.) Code";
attrib wired1name   length=$100 label="WIRED Region (1st Gen.) Name";
attrib wired2   	length=$2 	label="WIRED Region (2nd Gen.) Code";
attrib wired2name   length=$100 label="WIRED Region (2nd Gen.) Name";
attrib wired3   	length=$2 	label="WIRED Region (3rd Gen.) Code";
attrib wired3name   length=$100 label="WIRED Region (3rd Gen.) Name";
attrib createdate   length=$8 	label="Date on which data was created, formatted as YYYYMMDD";

INPUT
tabblk2010 st stusps stname cty ctyname trct trctname bgrp bgrpname cbsa cbsaname 
zcta zctaname stplc stplcname ctycsub ctycsubname stcd113 stcd113name stsldl stsldlname 
stsldu stslduname stschool stschoolname stsecon stseconname trib tribname 
tsub tsubname stanrc stanrcname mil milname stwib stwibname wired1 wired1name 
wired2 wired2name wired3 wired3name createdate;

RUN;

* Sort Geography crosswalk;
Proc Sort Data =  &temp..&state.xwalk;
	BY tabblk2010;
RUN;  
%end;
%mend checkds;

/* Invoke the macro, pass a non-existent data set name to test */

%checkds(&temp..&state.xwalk);

/*-------------------------------------------------------------------*/
/* Read in LODES WAC File                                            */
/*-------------------------------------------------------------------*/

%macro checkds2(dsn);
  %if %sysfunc(exist(&dsn)) %then %do;
    data _null_;
		put "LODES Data has already been uzipped and merged with crosswalk";
	Run;
	* Sort data by home GEOLevel and then by work GEOLevel
	sets data up for grouping by home GEOLevel then by work GEOLevel;
	PROC SORT DATA = &dsn;
		BY w_blockid;
	RUN;
  %end;

  %else %do;
	  %if %sysfunc(exist(&temp..&state._wac_&SegType._&JobType._&year)) 
		%then %do;
	    data _null_;
			put "LODES WAC Data has already been uzipped";
		RUN;

	  %end;
	  %else %do;
		filename datafile pipe "&dd_gzip -cd &file1" LRECL = 500;
	  
		DATA &temp..&state._wac_&SegType._&JobType._&year REPLACE;
		* Double check the longest line width of 80 should be long enough hence LRECL = 80;
		INFILE datafile DLM = ',' FIRSTOBS = 2 DSD;
		INPUT 
			w_blockid $15. +1
			C000&JobType 
			CA01&JobType 
			CA02&JobType 
			CA03&JobType 
			CE01&JobType 
			CE02&JobType 
			CE03&JobType 
			CNS01&JobType 
			CNS02&JobType
			CNS03&JobType 
			CNS04&JobType 
			CNS05&JobType 
			CNS06&JobType 
			CNS07&JobType 
			CNS08&JobType 
			CNS09&JobType 
			CNS10&JobType 
			CNS11&JobType 
			CNS12&JobType 
			CNS13&JobType 
			CNS14&JobType 
			CNS15&JobType 
			CNS16&JobType 
			CNS17&JobType 
			CNS18&JobType 
			CNS19&JobType 
			CNS20&JobType 
			CR01&JobType 
			CR02&JobType 
			CR03&JobType 
			CR04&JobType 
			CR05&JobType 
			CR07&JobType 
			CT01&JobType
			CT02&JobType
			CD01&JobType 
			CD02&JobType 
			CD03&JobType 
			CD04&JobType 
			CS01&JobType 
			CS02&JobType 
			CFA01&JobType 
			CFA02&JobType 
			CFA03&JobType 
			CFA04&JobType 
			CFA05&JobType 
			CFS01&JobType 
			CFS02&JobType 
			CFS03&JobType 
			CFS04&JobType 
			CFS05&JobType 
			createdate;
		RUN;
		%end; 
/*-------------------------------------------------------------------*/
/* Merge Geography Crosswalk with WAC Data                           */
/*-------------------------------------------------------------------*/

* First merge by work blockid;
Proc Sort Data = &temp..&state._wac_&SegType._&JobType._&year;
	BY w_blockid;
RUN;

DATA &delete..&state.xwalkwac_&SegType._&JobType._&year REPLACE;
	MERGE &temp..&state._wac_&SegType._&JobType._&year
		  &temp..&state.xwalk 
				(keep =tabblk2010 st cty trct bgrp cbsa zcta 
				rename=(tabblk2010=w_blockid));
	BY w_blockid;
RUN;

DATA &delete..&state.xwalkwac_&SegType._&JobType._&year REPLACE; 
	Set &delete..&state.xwalkwac_&SegType._&JobType._&year;
		rename st  =  w_statefp;
		rename cty =  w_countyfp;
		rename trct = w_censustractfp;
		rename bgrp  = w_bgrp;
		rename cbsa = w_cbsa;
		rename zcta = w_zcta;
		* Add year;
		year = &year;
RUN;

DATA &delete..&state.xwalkwac_&SegType._&JobType._&year REPLACE;
	Set &delete..&state.xwalkwac_&SegType._&JobType._&year;
	label w_blockid ="Work 2010 Census Tabulation Block Code"; 
	label w_statefp ="Work FIPS State Code";
	label w_countyfp="Work FIPS County Code";
	label w_censustractfp ="Work Census Tract Code";
	label w_bgrp="Work Census Blockgroup Code";
	label w_cbsa="Work CBSA (Metropolitan/Micropolitan Area) Code";
	label w_zcta="Work ZIP Code Tabulation Area (ZCTA) Code";
RUN;


PROC SORT DATA = &delete..&state.xwalkwac_&SegType._&JobType._&year
	OUT = &temp..&state.xwalkwac_&SegType._&JobType._&year;
	BY w_blockid;
RUN;

%end;
%mend checkds2;

/* Invoke the macro, pass a non-existent data set name to test */

%checkds2(&temp..&state.xwalkwac_&SegType._&JobType._&year);


%MEND ImportLODES_WAC_File;


/*-------------------------------------------------------------------*/
/* Macro to create datasets for all panel years                      */
/*-------------------------------------------------------------------*/

%MACRO LODES7_wac_Panel(
   State = ,
   SegType = ,
   JobType = ,
   Fyear = ,
   TYears =);

%Do i = 1 %to &TYears;
	Data _NULL_;
		CALL SYMPUT("panelyear",put(&Fyear+&i-1,4.));
	RUN;
	%ImportLODES_WAC_File(
		State = &state,
		Year = &panelyear,
		SegType = &SegType,
		JobType = &JobType);

	PROC APPEND BASE = &delete..&state.wac_&SegType._&JobType.&fyear._&lyear 
		DATA = &temp..&state.xwalkwac_&SegType._&JobType._&panelyear;
	RUN;

	%end;


%MEND LODES7_wac_Panel;
* Delete the existing panel dataset before running IMPORT Macro;
PROC datasets library=&delete NOLIST;
	DELETE &state.wac_&SegType._&JobType.&fyear._&lyear;
Run;


/*-------------------------------------------------------------------*/
/* Run Macro                                                        */
/*-------------------------------------------------------------------*/

%LODES7_wac_Panel(
   State = &State,
   JobType = &JobType,
   SegType = &SegType,
   Fyear = &Fyear,
   TYears = &Tyears);

Proc Sort Data = &delete..&state.wac_&SegType._&JobType.&fyear._&lyear;
	by w_blockid year;
Run;

/*-------------------------------------------------------------------*/
/* Order and Label Variables                                         */
/*-------------------------------------------------------------------*/

%MACRO labelvariables( );
%IF &JobType = JT00 %THEN %LET JobLabel = "(All Jobs)";
%IF &JobType = JT01 %THEN %LET JobLabel = "(Primary Jobs)";
%IF &JobType = JT02 %THEN %LET JobLabel = "(All Private Jobs)";
%IF &JobType = JT03 %THEN %LET JobLabel = "(Private Primary Jobs)";
%IF &JobType = JT04 %THEN %LET JobLabel = "(All Federal Jobs)";
%IF &JobType = JT05 %THEN %LET JobLabel = "(Federal Primary Jobs)";

Data &delete..&state.wac_&SegType._&JobType.&fyear._&lyear;
	Retain year w_blockid;
	Set &delete..&state.wac_&SegType._&JobType.&fyear._&lyear;
	Label
		w_blockid  =  "Workplace Census Block Code"
		C000&JobType =  "Total number of jobs &JobLabel"
		CA01&JobType =  "Age 29 or younger &JobLabel"
		CA02&JobType =  "Age 30 to 54 &JobLabel"
		CA03&JobType =  "Age 55 or older &JobLabel"
		CE01&JobType =  "$1250/month or less &JobLabel"
		CE02&JobType =  "$1251/month to $3333/month &JobLabel"
		CE03&JobType =  "Greater than $3333/month &JobLabel"
		CNS01&JobType =  "SI01 NAICS 11 (Agriculture, Forestry, Fishing and Hunting) &JobLabel"
		CNS02&JobType =  "SI01 NAICS 21 (Mining, Quarrying, and Oil and Gas Extraction) &JobLabel"
		CNS03&JobType =  "SI01 NAICS 22 (Utilities) &JobLabel"
		CNS04&JobType =  "SI01 NAICS 23 (Construction) &JobLabel"
		CNS05&JobType =  "SI01 NAICS 31-33 (Manufacturing) &JobLabel"
		CNS06&JobType =  "SI02 NAICS 42 (Wholesale Trade) &JobLabel"
		CNS07&JobType =  "SI02 NAICS 44-45 (Retail Trade) &JobLabel"
		CNS08&JobType =  "SI02 NAICS 48-49 (Transportation and Warehousing) &JobLabel"
		CNS09&JobType =  "SI03 NAICS 51 (Information) &JobLabel"
		CNS10&JobType =  "SI03 NAICS 52 (Finance and Insurance) &JobLabel"
		CNS11&JobType =  "SI03 NAICS 53 (Real Estate and Rental and Leasing) &JobLabel"
		CNS12&JobType =  "SI03 NAICS 54 (Professional, Scientific, and Technical Services) &JobLabel"
		CNS13&JobType =  "SI03 NAICS 55 (Management of Companies and Enterprises) &JobLabel"
		CNS14&JobType =  "SI03 NAICS 56 (Administrative and Support and Waste Management and Remediation Services) &JobLabel"
		CNS15&JobType =  "SI03 NAICS 61 (Educational Services) &JobLabel"
		CNS16&JobType =  "SI03 NAICS 62 (Health Care and Social Assistance) &JobLabel"
		CNS17&JobType =  "SI03 NAICS 71 (Arts, Entertainment, and Recreation) &JobLabel"
		CNS18&JobType =  "SI03 NAICS 72 (Accommodation and Food Services) &JobLabel"
		CNS19&JobType =  "SI03 NAICS 81 (Other Services [except Public Administration]) &JobLabel"
		CNS20&JobType =  "SI03 NAICS 92 (Public Administration) &JobLabel"
		CR01&JobType =  "Race: White, Alone &JobLabel (2009+)"
		CR02&JobType =  "Race: Black or African American Alone &JobLabel (2009+)"
		CR03&JobType =  "Race: American Indian or Alaska Native Alone &JobLabel (2009+)"
		CR04&JobType =  "Race: Asian Alone &JobLabel (2009+)"
		CR05&JobType =  "Race: Native Hawaiian or Other Pacific Islander Alone &JobLabel (2009+)"
		CR07&JobType =  "Race: Two or More Race Groups &JobLabel (2009+)"
		CT01&JobType =  "Ethnicity: Not Hispanic or Latino &JobLabel (2009+)"
		CT02&JobType =  "Ethnicity: Hispanic or Latino &JobLabel (2009+)"
		CD01&JobType =  "Educational Attainment: Less than high school &JobLabel (2009+ for Workers age 30+)"
		CD02&JobType =  "Educational Attainment: High school or equivalent, no college &JobLabel (2009+ for Workers age 30+)"
		CD03&JobType =  "Educational Attainment: Some college or Associate degree &JobLabel (2009+ for Workers age 30+)"
		CD04&JobType =  "Educational Attainment: Bachelor's degree or advanced degree &JobLabel (2009+ for Workers age 30+)"
		CS01&JobType =  "Sex: Male &JobLabel (2009+)"
		CS02&JobType =  "Sex: Female &JobLabel (2009+)"
		CFA01&JobType =  "Firm Age: 0-1 Years &JobLabel (2011+, JT02)"
		CFA02&JobType =  "Firm Age: 2-3 Years &JobLabel (2011+, JT02)"
		CFA03&JobType =  "Firm Age: 4-5 Years &JobLabel (2011+, JT02)"
		CFA04&JobType =  "Firm Age: 6-10 Years &JobLabel (2011+, JT02)"
		CFA05&JobType =  "Firm Age: 11+ Years &JobLabel (2011+, JT02)"
		CFS01&JobType =  "Firm Size: 0-19 Employees &JobLabel (2011+, JT02, Footnote 15)"
		CFS02&JobType =  "Firm Size: 20-49 Employees &JobLabel (2011+, JT02, Footnote 15)"
		CFS03&JobType =  "Firm Size: 50-249 Employees &JobLabel (2011+, JT02, Footnote 15)"
		CFS04&JobType =  "Firm Size: 250-499 Employees &JobLabel (2011+, JT02, Footnote 15)"
		CFS05&JobType =  "Firm Size: 500+ Employees &JobLabel (2011+, JT02, Footnote 15)";
Run;

%MEND labelvariables;

%labelvariables( );

/*-------------------------------------------------------------------*/
/* Reports to check accuracy                                         */
/*-------------------------------------------------------------------*/

/*-------------------------------------------------------------------*/
/* Identify Study Area CBSA                                          */
/*-------------------------------------------------------------------*/

Data &library..&state.wac_&SegType._&JobType.&fyear._&lyear;
	set &delete..&state.wac_&SegType._&JobType.&fyear._&lyear;
	if w_cbsa = 38060 then WL_CBSA = 1; * Phoenix-Mesa-Glendale, AZ Metropolitan Statistical Area;
	else if w_cbsa = 31100 then WL_CBSA = 2; * Los Angeles-Long Beach-Santa Ana, CA Metropolitan Statistical Area;
	else if w_cbsa = 40900 then WL_CBSA = 3; * Sacramento--Arden-Arcade--Roseville, CA Metropolitan Statistical Area;
	else if w_cbsa = 41740 then WL_CBSA = 4; * San Diego-Carlsbad-San Marcos, CA Metropolitan Statistical Area;
	else if w_cbsa = 19740 then WL_CBSA = 5; * Denver-Aurora-Broomfield, CO Metropolitan Statistical Area;
	else if w_cbsa = 16740 then WL_CBSA = 6; * Charlotte-Gastonia-Rock Hill, NC-SC Metropolitan Statistical Area;
	else if w_cbsa = 38900 then WL_CBSA = 7; * Portland-Vancouver-Hillsboro, OR-WA Metropolitan Statistical Area;
	else if w_cbsa = 26420 then WL_CBSA = 8; * Houston-Sugar Land-Baytown, TX Metropolitan Statistical Area;
	else if w_cbsa = 12420 then WL_CBSA = 9; * Austin-Round Rock-San Marcos, TX Metropolitan Statistical Area;
	else if w_cbsa = 19100 then WL_CBSA = 10; * Dallas-Fort Worth-Arlington, TX Metropolitan Statistical Area;
	else if w_cbsa = 41620 then WL_CBSA = 11; * Salt Lake City, UT Metropolitan Statistical Area;
	else if w_cbsa = 42660 then WL_CBSA = 12; * Seattle-Tacoma-Bellevue, WA Metropolitan Statistical Area;
	else WL_CBSA = 99; * not in study area;
Run;


* Delete files in Work Directory;
*proc datasets library=&delete kill noprint;
*run;

%MEND ImportArrayLODES71;


%ImportArrayLODES71(AZ);
%ImportArrayLODES71(CA);
%ImportArrayLODES71(CO);
%ImportArrayLODES71(NC);
%ImportArrayLODES71(OR);
%ImportArrayLODES71(SC);
%ImportArrayLODES71(TX);
%ImportArrayLODES71(UT);
%ImportArrayLODES71(WA);


%MACRO ExtractCBSA(state,CBSAID);

Data &library..&state.&CBSAID._wac_&SegType._&JobType.&fyear._&lyear;
	set &library..&state.wac_&SegType._&JobType.&fyear._&lyear;
	if w_cbsa = &CBSAID;
run;

%MEND ExtractCBSA;

%ExtractCBSA(TX,12420); *Austin;
%ExtractCBSA(NC,16740); *Charlotte;
%ExtractCBSA(SC,16740); *Charlotte;
%ExtractCBSA(TX,19100); *Dallas;
%ExtractCBSA(CO,19740); *Denver;
%ExtractCBSA(TX,26420); *Houston;
%ExtractCBSA(CA,31100); *Los Angeles;
%ExtractCBSA(AZ,38060); *Pheonix;
%ExtractCBSA(OR,38900); *Portland;
%ExtractCBSA(WA,38900); *Portland;
%ExtractCBSA(CA,40900); *Sacramento;
%ExtractCBSA(UT,41620); *Salt Lake;
%ExtractCBSA(CA,41740); *San Diego;
%ExtractCBSA(WA,42660); *Seattle;

%Macro GenerateLODES71Report(state,JobType);
%let state = tx;

proc format cntlout = &library..&state.wac_&SegType._&JobType.&fyear._&lyear._f;
value wl_cbsa_f
	1 = "Phoenix-Mesa-Glendale, AZ MSA"
	2 = "Los Angeles-Long Beach-Santa Ana, CA MSA"
	3 = "Sacramento--Arden-Arcade--Roseville, CA MSA"
	4 = "San Diego-Carlsbad-San Marcos, CA MSA"
	5 = "Denver-Aurora-Broomfield, CO MSA"
	6 = "Charlotte-Gastonia-Rock Hill, NC-SC MSA"
	7 = "Portland-Vancouver-Hillsboro, OR-WA MSA"
	8 = "Houston-Sugar Land-Baytown, TX MSA"
	9 = "Austin-Round Rock-San Marcos, TX MSA"
	10 = "Dallas-Fort Worth-Arlington, TX MSA"
	11 = "Salt Lake City, UT MSA"
	12 = "Seattle-Tacoma-Bellevue, WA MSA"
	99 = "Not in study area";
run;

Data &library..&state.wac_&SegType._&JobType.&fyear._&lyear;
	set &library..&state.wac_&SegType._&JobType.&fyear._&lyear;
	format WL_CBSA wl_cbsa_f.; 
	label WL_CBSA = "CBSA in WLLRT Study Area";
Run;
%LET SummaryVars1 = C000&JobType CA01&JobType CA02&JobType CA03&JobType CE01&JobType CE02&JobType CE03&JobType;

ODS RTF FILE = "&dd_data.&temp.&state.wac_&SegType._&JobType.&fyear._&lyear..RTF";
ODS RTF STYLE=JOURNAL;


Proc TABULATE DATA=&library..&state.wac_&SegType._&JobType.&fyear._&lyear;
	CLASS WL_CBSA year;
	VAR &SummaryVars1;
	CLASSLEV WL_CBSA 
		/ style=[cellwidth=3in asis=on];
	Tables WL_CBSA*year*(sum*f=comma16.) ALL*year*(sum*f=comma18.),
			&SummaryVars1;
	keylabel all = 'Total';
	TITLE1 "Summary Table for Job (&JobType) Counts by CBSA in &state";
RUN;
ODS rtf CLOSE;

%Mend GenerateLODES71Report;

/*
%GenerateLODES71Report(TX,&JobType);

%GenerateLODES71Report(AZ,&JobType);
%GenerateLODES71Report(CA,&JobType);
%GenerateLODES71Report(CO,&JobType);
%GenerateLODES71Report(NC,&JobType);
%GenerateLODES71Report(OR,&JobType);
%GenerateLODES71Report(SC,&JobType);
%GenerateLODES71Report(TX,&JobType);
%GenerateLODES71Report(UT,&JobType);
%GenerateLODES71Report(WA,&JobType);
*/


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
