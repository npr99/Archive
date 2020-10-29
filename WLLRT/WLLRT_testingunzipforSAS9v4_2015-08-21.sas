%let year = 2013;
%let state = az;

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

/* http://www.ats.ucla.edu/stat/sas/faq/readgz.htm */

		filename datafile pipe "&dd_gzip -cd &file1" LRECL = 500;
	  
		DATA work.&state._wac_&SegType._&JobType._&year REPLACE;
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
