/*-------------------------------------------------------------------*/
/*       Programs for Subsetting LODES Data                          */
/* Program aggregates block data into higher GEOLevel data           */
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
/* Date Last Updated: 15 Apr 2014                                    */
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
/* Import LODES OD File                                              */
/*-------------------------------------------------------------------*/

%MACRO ImportLODESFile(
   State = ,
   MainState = ,
   Statefp = ,
   Year = ,
   GEOLevel = ,
   JobType =  ,
   ODType =);

* Macro Variable for the LODES File that will be imported;
%let geoxwalk = &dd_data.onthemap\LODES7\&state.\&state._xwalk.csv.gz;

* Macro Variable for the LODES File that will be imported;
%let file1= &dd_data.onthemap\LODES7\&state.\od\&state._od_&ODType._&JobType._&year..csv.gz;


*  The following line should contain the directory
  	where the gzip is to be stored  
	use " " around directories with spaces;

%LET dd_gzip = C:\"Program Files (x86)"\GnuWin32\bin\gzip;

* Use a trailing @, then keep specific Census Blocks;
* Using INFILE to read in Comma-seperated value files, first obseravtion has headers therefore will be skipped (FIRSTOBS = 2)
Going to use Delimiter-Senstive DATA option (DSD) just in case missing values exist;

/* If you attempt to print or manipulate the non-existent data set */
/* an error will be generated.  To prevent the error, check to see */
/* if the data set exists, then conditionally execute the step(s). */


%macro checkds(dsn);
  %if %sysfunc(exist(&dsn)) %then %do;
    data _null_;
		put "Geography Crosswalk Exists";
	Run;
  %end;
  %else %do;
* Generate output Geography crosswalk file;
DATA &library..&state.xwalk REPLACE;
	filename datafile pipe %unquote(%str(%'&dd_gzip -cd &geoxwalk%')) LRECL = 800;
	* Double check the longest line width of 80 should be long enough hence LRECL = 80;
	INFILE datafile DLM = ',' FIRSTOBS = 2 DSD;

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
Proc Sort Data =  &library..&state.xwalk;
	BY tabblk2010;
RUN;  
%end;
%mend checkds;

/* Invoke the macro, pass a non-existent data set name to test */

%checkds(&library..&state.xwalk)

%macro checkds2(dsn);
  %if %sysfunc(exist(&dsn)) %then %do;
    data _null_;
		put "LODES Data has already been uzipped and merged with crosswalk";
	Run;
	* Sort data by home GEOLevel and then by work GEOLevel
	sets data up for grouping by home GEOLevel then by work GEOLevel;
	PROC SORT DATA = &dsn;
		BY h_&geolevel.fp w_&geolevel.fp;
	RUN;
  %end;

  %else %do;
	  %if %sysfunc(exist(&library..&state.od_&ODType._&JobType._&year)) 
		%then %do;
	    data _null_;
			put "LODES Data has already been uzipped";
		RUN;

	  %end;
	  %else %do;
	  
		DATA &library..&state.od_&ODType._&JobType._&year REPLACE;
		filename datafile pipe %unquote(%str(%'&dd_gzip -cd &file1%')) LRECL = 80;
		* Double check the longest line width of 80 should be long enough hence LRECL = 80;
		INFILE datafile DLM = ',' FIRSTOBS = 2 DSD;
		INPUT 
			w_blockid $15. +1
			h_blockid $15. +1 
			S000 
			SA01 
			SA02 
			SA03 
			SE01 
			SE02 
			SE03 
			SI01 
			SI02 
			SI03 
			createdate;
		RUN;
		%end; 
/*-------------------------------------------------------------------*/
/* Merge Geography Crosswalk with OD Data                            */
/*-------------------------------------------------------------------*/

* First merge by work blockid;
Proc Sort Data = &library..&state.od_&ODType._&JobType._&year;
	BY w_blockid;
RUN;

* Merge work locations with Aux State. This is for AUX files which
provide data on workers in the aux State who live in the main state.;

DATA work.&state.xwalkod_&ODType._&JobType._&year REPLACE;
	MERGE &library..&state.od_&ODType._&JobType._&year
		  &library..&state.xwalk 
				(keep =tabblk2010 st cty trct bgrp cbsa zcta 
				rename=(tabblk2010=w_blockid));
	BY w_blockid;
RUN;

DATA work.&state.w_xwalkod_&ODType._&JobType._&year REPLACE; 
	Set work.&state.xwalkod_&ODType._&JobType._&year;
		rename st  =  w_statefp;
		rename cty =  w_countyfp;
		rename trct = w_censustractfp;
		rename bgrp  = w_bgrp;
		rename cbsa = w_cbsa;
		rename zcta = w_zcta;
RUN;
DATA work.&state.w_xwalkod_&ODType._&JobType._&year REPLACE;
	Set work.&state.w_xwalkod_&ODType._&JobType._&year;
	label w_blockid ="Work 2010 Census Tabulation Block Code"; 
	label w_statefp ="Work FIPS State Code";
	label w_countyfp="Work FIPS County Code";
	label w_censustractfp ="Work Census Tract Code";
	label w_bgrp="Work Census Blockgroup Code";
	label w_cbsa="Work CBSA (Metropolitan/Micropolitan Area) Code";
	label w_zcta="Work ZIP Code Tabulation Area (ZCTA) Code";
RUN;

* Merge home locations with Main State. This is for AUX files which
provide data on workers in the aux State who live in the main state.;
* First sort by home blockid;
Proc Sort Data = work.&state.w_xwalkod_&ODType._&JobType._&year;
	BY h_blockid;
RUN;

DATA work.hw_&state.od_&ODType._&JobType._&year REPLACE;
	MERGE work.&state.w_xwalkod_&ODType._&JobType._&year
		  &library..&mainstate.xwalk 
				(keep =tabblk2010 st cty trct bgrp cbsa zcta 
				rename=(tabblk2010=h_blockid));
	BY h_blockid;
RUN;

DATA work.hw_&state.od_&ODType._&JobType._&year REPLACE; 
	Set work.hw_&state.od_&ODType._&JobType._&year;
		rename st  =  h_statefp;
		rename cty =  h_countyfp;
		rename trct = h_censustractfp;
		rename bgrp  = h_bgrp;
		rename cbsa = h_cbsa;
		rename zcta = h_zcta;
RUN;


DATA work.hw_&state._&mainstate.od_&ODType._&JobType._&year REPLACE;
	Set work.hw_&state.od_&ODType._&JobType._&year;
	label h_blockid ="Home 2010 Census Tabulation Block Code"; 
	label h_statefp ="Home FIPS State Code";
	label h_countyfp="Home FIPS County Code";
	label h_censustractfp ="Home Census Tract Code";
	label h_bgrp="Home Census Blockgroup Code";
	label h_cbsa="Home CBSA (Metropolitan/Micropolitan Area) Code";
	label h_zcta="Home ZIP Code Tabulation Area (ZCTA) Code";
	If h_statefp = &Statefp OR w_statefp = &Statefp;
	If h_statefp NE "";
	If w_statefp NE "";
RUN;

PROC SORT DATA = work.hw_&state._&mainstate.od_&ODType._&JobType._&year
	OUT = &library..hw_&state._&mainstate.od_&ODType._&JobType._&year;
	BY h_&geolevel.fp w_&geolevel.fp;
RUN;

%end;
%mend checkds2;

/* Invoke the macro, pass a non-existent data set name to test */

%checkds2(&library..hw_&state._&mainstate.od_&ODType._&JobType._&year)



%MEND ImportLODESFile;




/*-------------------------------------------------------------------*/
/* Aggregate LODES OD File                                           */
/*-------------------------------------------------------------------*/

%MACRO AggregateLODES(
   State = ,
   Year = ,
   StateFP = ,
   GEOLevel = ,
   JobType =  ,
   ODType =);

PROC SORT DATA = &library..hwsxxx_&state._&mainstate.od_&ODType._&JobType._&year;
	BY h_&geolevel.fp w_&geolevel.fp;
RUN;

* Generate a table that sums GEOLevel-to-GEOLevel data;
DATA work.SUM&state._&mainstate.&geolevel.&ODType REPLACE;
	Set &library..hwsxxx_&state._&mainstate.od_&ODType._&JobType._&year;
	BY h_&geolevel.fp w_&geolevel.fp;
	IF first.w_&geolevel.fp THEN DO;
		sum_S000 = 0; 
		sum_SA01 = 0; 
		sum_SA02 = 0; 
		sum_SA03 = 0; 
		sum_SE01 = 0; 
		sum_SE02 = 0; 
		sum_SE03 = 0; 
		sum_SI01 = 0; 
		sum_SI02 = 0; 
		sum_SI03 = 0;
		sum_SXXX = 0;
		cnt = 0;
		END;
	sum_S000 + S000; 
	sum_SA01 + SA01; 
	sum_SA02 + SA02; 
	sum_SA03 + SA03; 
	sum_SE01 + SE01; 
	sum_SE02 + SE02; 
	sum_SE03 + SE03; 
	sum_SI01 + SI01; 
	sum_SI02 + SI02; 
	sum_SI03 + SI03;
	sum_SXXX + SXXX;
	cnt + 1; 
	IF last.w_&geolevel.fp THEN OUTPUT;
RUN;
* Drop variables that are nolonger needed;
DATA work.SUM&state._&mainstate.&geolevel.&ODType REPLACE;
	Set work.SUM&state._&mainstate.&geolevel.&ODType;
	KEEP
		h_statefp
		h_countyfp
		h_cbsa
		h_&geolevel.fp
		w_statefp
		w_countyfp
		w_cbsa
		w_&geolevel.fp
		sum_S000 
		sum_SA01 
		sum_SA02 
		sum_SA03
		sum_SE01
		sum_SE02
		sum_SE03
		sum_SI01
		sum_SI02 
		sum_SI03
		sum_SXXX
		cnt;
RUN;

	PROC datasets library=work NOLIST;
		DELETE hw_&state.od_&ODType._&JobType._&year;
		DELETE hw_&state._&mainstate.od_&ODType._&JobType._&year;
		DELETE &state.w_xwalkod_&ODType._&JobType._&year;
		DELETE &state.xwalkod_&ODType._&JobType._&year;
	Run;

%MEND AggregateLODES;


