 /*-------------------------------------------------------------------*/
 /*       Program for Subsetting LODES Data			                  */
 /* Program aggregates block data into county data                	  */
 /*          by Nathanael Proctor Rosenheim				              */
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
 /* Date Last Updated: 7 Apr 2014                                     */
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

*  The following line should contain the directory
   where the SAS file is to be stored  ;

%LET dd_SASLib = C:\Users\Nathanael\MySASLib\;

LIBNAME LODES7 "&dd_SASLib.LODES7";

*  The following line should contain
   the complete path and name of the raw data file.
   On a PC, use backslashes in paths as in C:\	 ;
 
%let file1=C:\Users\Nathanael\MyData\onthemap\LODES7\tx\od\tx_od_main_JT00_2010.csv.gz;


*  The following line should contain the directory
  	where the gzip is to be stored  
	use " " around directories with spaces;

%LET dd_gzip = C:\"Program Files (x86)"\GnuWin32\bin\gzip;

*  The following line should contain the name of the SAS dataset ;

%let dataset = tx_od_main_JT00_2010 ;

* Use a trailing @, then keep specific Census Blocks;
* Using INFILE to read in Comma-seperated value files, first obseravtion has headers therefore will be skipped (FIRSTOBS = 2)
Going to use Delimiter-Senstive DATA option (DSD) just in case missing values exist;


* Generate output OD file for select counties;

%LET select_counties = '041','051','477','185','313','289','395','331';
DATA LODES7.Apr7Brazos_od_main_JT00_2010 REPLACE;
	filename datafile pipe %unquote(%str(%'&dd_gzip -cd &file1%')) LRECL = 80;
	* Double check the longest line width of 80 should be long enough hence LRECL = 80;
	INFILE datafile DLM = ',' FIRSTOBS = 2 DSD;
	INPUT 
		w_statefp $2.
		w_countyfp $3. @1
		w_geocode $15. +1
		h_statefp $2. 
		h_countyfp $3. @17
		h_geocode $15. +1 
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
	* Check if origin county is in Brazos Valley Region
		041 = Brazos
		051 = Burleson
		477 = Washington
		185 = Grimes
		313 = Madison
		289 = Leon
		395 = Roberston
		331 = Milam;
	If h_countyfp IN(&select_counties);
RUN;

* Sort data by home county and then by work county
sets data up for grouping by home county then by work county;
PROC SORT DATA = LODES7.Apr7Brazos_od_main_JT00_2010 OUT = LODES7.SortCounty;
	BY h_countyfp w_countyfp;
RUN;

* Generate a table that sums county-to-county data;
DATA LODES7.SUMCounty;
	Set LODES7.SortCounty;
	BY h_countyfp w_countyfp;
	IF first.w_countyfp THEN DO;
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
	cnt + 1; 
	IF last.w_countyfp THEN OUTPUT;
	KEEP
		h_countyfp
		w_countyfp
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
		cnt;
RUN;

* Generate a table that sums county data;
DATA LODES7.TotalCounty;
	Set LODES7.SortCounty;
	BY h_countyfp;
	IF first.h_countyfp THEN DO;
		total_S000 = 0; 
		total_SA01 = 0; 
		total_SA02 = 0; 
		total_SA03 = 0; 
		total_SE01 = 0; 
		total_SE02 = 0; 
		total_SE03 = 0; 
		total_SI01 = 0; 
		total_SI02 = 0; 
		total_SI03 = 0;
		totalcnt = 0;
		END;
	total_S000 + S000; 
	total_SA01 + SA01; 
	total_SA02 + SA02; 
	total_SA03 + SA03; 
	total_SE01 + SE01; 
	total_SE02 + SE02; 
	total_SE03 + SE03; 
	total_SI01 + SI01; 
	total_SI02 + SI02; 
	total_SI03 + SI03;
	totalcnt + 1;
	IF last.h_countyfp THEN OUTPUT;
	KEEP
		h_countyfp
		total_S000 
		total_SA01 
		total_SA02 
		total_SA03
		total_SE01
		total_SE02
		total_SE03
		total_SI01
		total_SI02 
		total_SI03
		totalcnt;
RUN;

* Merge County Job Totals with County-to-County Sums;
DATA MergeTotalCounty REPLACE;;
	MERGE LODES7.SumCounty LODES7.TotalCounty;
	BY h_countyfp;
RUN;

* Generate new table that shows percentage of commuters between counties;
DATA Lodes7.CountyPercent REPLACE;
	SET MergeTotalCounty;
	If w_countyfp IN(&select_counties);
	per_S000 = sum_S000/total_S000;
	per_SE01 = sum_SE01/total_SE01;
	per_SE02 = sum_SE02/total_SE02;
	per_SE03 = sum_SE03/total_SE03;
	KEEP
		h_countyfp
		w_countyfp
		per_S000
		per_SE01
		per_SE02
		per_SE03
RUN;
		


/*
	Attrib	w_statefp label="Work State FIPS";
	Attrib	w_countyfp label="Work County FIPS";
	Attrib 	w_geocode label="Work BlockId";
	Attrib	h_statefp label="Home State FIPS";
	Attrib	h_countyfp label="Home County FIPS";
	Attrib	h_geocode label="Home BlockID";
	Attrib	S000 label="Total Number of Jobs";
	Attrib	SA01 label="Number of jobs of workers age 29 or younger";
	Attrib	SA02 label="Number of jobs for workers age 30 to 54";
	Attrib	SA03 label="Number of jobs for workers age 55 or older";
	Attrib	SE01 label="Number of jobs with earnings $1250/month or less";
	Attrib	SE02 label="Number of jobs with earnings $1251/month to $3333/month";
	Attrib	SE03 label="Num Number of jobs with earnings greater than $3333/month";
	Attrib	SI01 label="Number of jobs in Goods Producing industry sectors";
	Attrib	SI02 label="Number of jobs in Trade, Transportation, and Utilities industry sectors";
	Attrib	SI03 label="Number of jobs in All Other Services industry sectors";
	Attrib	createdate label="Date on which data was created, formatted as YYYYMMDD";
*
