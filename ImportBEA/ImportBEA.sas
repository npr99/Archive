/*-------------------------------------------------------------------*/
/*       Program for Reading in Bureau of Economic Analysis (BEA)    */
/*          by Nathanael Proctor Rosenheim				             */
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
/* Date Last Updated: 23 Sept 2014                                   */
/*-------------------------------------------------------------------*/
/* Questions or problem reports concerning this material may be      */
/* addressed to the author on github: https://github.com/npr99       */
/*                                                                   */
/*-------------------------------------------------------------------*/
/* Data Source:                                                      */
/* Bureau of Economic Analysis (BEA) (May 30 2014)                   */ 
/*       CA35: Personal Current Transfer Receipts                    */
/*       Retrieved 7/29/2014 from                                    */
/*       http://www.bea.gov/regional/downloadzip.cfm                 */
/*-------------------------------------------------------------------*/
/* Data Summary:
The U.S. Department of Commerce Bureau of Economic Analysis (BEA) 
regional economic accounts describe county-level distribution of 
U.S. economic activity and growth. 
Data are reported annually based on calender years. 
Data are reported on place of residence.
Dollar estimates are in current dollars (not adjusted for inflation).
Dollar amounts reported in thousands of dollars.
BEA data is based information provided by state agencies, 
when data is not available BEA imputes, interpolates or extrapolates 
to provide data for all years. 
BEA does not flag imputed data however the documentation states that 
75% of the county level data are derived from direct measures (BEA 2013). 
The Personal Current Transfer Receipts Accounts (CA35) covers 
1969 to 2012.

Data for Personal current transfer receipts - Table CA35

Codes used for missing or redacted data:
(L) Less than $50,000, but the estimates for this item are included in the totals.
(NA) Data not available for this year.
(NM) Not meaningful.

Reference:
BEA (Dec 2013) Local Area Personal Income Methodology
Retrieved on Sept 23 2014 from
http://www.bea.gov/regional/pdf/lapi2012.pdf
*/
/*-------------------------------------------------------------------*/
/* Important Folder Locations                                        */
/*-------------------------------------------------------------------*/

%LET dd_data = C:\Users\Nathanael\Dropbox\MyData\;
%LET dd_SASLib = C:\Users\Nathanael\MySASLib\;
%LET Include_prog = C:\Users\Nathanael\Dropbox\MyPrograms\;


/*-------------------------------------------------------------------*/
/* Import BEA File                                                   */
/*-------------------------------------------------------------------*/

%MACRO ImportBEA(
	State = ,
	BEACode = ,
	D_Select = );

/*-------------------------------------------------------------------*/
/* Define SAS Library                                                */
/*-------------------------------------------------------------------*/
%let library = BEA;
LIBNAME &library "&dd_SASLib.&library";

* Macro Variable for the LODES File that will be imported;
%let file1= "&dd_data.&library.\&BEACode.\&BEACode._&state..csv";

* Use a trailing @, then keep specific Census Blocks;
* Using INFILE to read in Comma-seperated value files, first obseravtion has headers therefore will be skipped (FIRSTOBS = 2)
Going to use Delimiter-Senstive DATA option (DSD) just in case missing values exist;

* Generate output OD file for select counties;

DATA work.temp_&BEACode._&state REPLACE;
	filename datafile &file1 LRECL = 2000;
	* Double check the longest line width of 2000 should be long enough hence LRECL = 80;
	INFILE datafile DLM = ',' FIRSTOBS = 2 DSD;
	attrib FIPS_County	length=$5		label="County FIPS Code";
	attrib GeoName		length=$40		label="County Name";
	attrib Region		length=$1		label="BEA Region";
	attrib Table		length=$5		label="BEA Table Code";
	attrib LCode		length=$4		label="BEA Industry Line Code";
	attrib IndClss		length=$3		label="BEA Industry Classification";
	attrib Dscrptn		length=$80		label="BEA Data Description";
	attrib yr1969-yr2012			length=$24; * some year data has alpha codes;

	INPUT 
		FIPS_County
		GeoName
		Region
		Table
		LCode
		IndClss
		Dscrptn
		yr1969-yr2012;
RUN;

/*-------------------------------------------------------------------*/
/* Select Variable of interest - Drop other observations             */
/*-------------------------------------------------------------------*/

DATA work.temp2_&BEACode._&state REPLACE;
	Set work.temp_&BEACode._&state;
	If FIND(Dscrptn,"&D_Select");
Run;

/*-------------------------------------------------------------------*/
/*  Transpose Data - One Observation for year county each year       */
/*-------------------------------------------------------------------*/

Proc transpose data = work.temp2_&BEACode._&state 
	out = work.tempLong_&BEACode._&state Prefix = BEA_&D_Select;
	by FIPS_County;
	var yr:;
Run;

/*-------------------------------------------------------------------*/
/*  Clean up data and convert codes to flags                         */
/*-------------------------------------------------------------------*/

Data work.temp3_&BEACode._&state REPLACE;
	Set work.tempLong_&BEACode._&state;
	year=input(substr(_name_, 3, 4), 4.);
	drop _name_;

/* 
Codes used for missing or redacted data:
(L) Less than $50,000, but the estimates for this item are included in the totals.
(NA) Data not available for this year.
(NM) Not meaningful.
*/
	if BEA_&D_Select.1 = "(L)" then do;
		BEA_&D_Select.flag = 1;
		BEA_&D_Select = .;
		end;
	Else if BEA_&D_Select.1 = "(NA)" then do;
		BEA_&D_Select.flag = 2;
		BEA_&D_Select = .;
		end;
	Else if BEA_&D_Select.1 = "(NM)" then do;
		BEA_&D_Select.flag = 3;
		BEA_&D_Select = .;
		end;
	Else do;
		BEA_&D_Select.flag = 0;
		BEA_&D_Select = put(BEA_&D_Select.1,12.)*1000;
		end;
	drop BEA_&D_Select.1;
run; 
/*-------------------------------------------------------------------*/
/*  Keep First to Last Year and save to Library                      */
/*-------------------------------------------------------------------*/

Data &library..&BEACode._&state._1969_2012 REPLACE;
	Set work.temp3_&BEACode._&state;
	yeartxt = put(year,4.); * year needs to be string;
Run; 

/*-------------------------------------------------------------------*/
/* Order and Label Variables                                         */
/*-------------------------------------------------------------------*/

Data &library..&BEACode._&state._1969_2012 REPLACE;
	Set &library..&BEACode._&state._1969_2012;
	Label 
		BEA_SNAPflag = "BEA Distribution Data Missing or Redacted"
		BEA_SNAP = "BEA SNAP Distribution Data";
run;


%MEND ImportBEA;

/*-------------------------------------------------------------------*/
/* Run Macro Here                                                    */
/*-------------------------------------------------------------------*/

/*-------------------------------------------------------------------*/
/* Import All States and Make One Large File                         */
/*-------------------------------------------------------------------*/

%macro AllStates(State);
/*The AllStates Macro serves as a control to read in data for a single geography 	
  by passing in the two digit alpha state abbreviation */

%ImportBEA(
   State = &State,
   BEACode = &BEACode,
   D_Select = &D_Select);
/*-------------------------------------------------------------------*/
/* Append Yearly Calculations together for panel                     */
/*-------------------------------------------------------------------*/

PROC APPEND BASE = &library..&BEACode._AllStates_1969_2012
	DATA = &library..&BEACode._&state._1969_2012;
RUN;

%MEND;

%LET BEACode = CA35; * BEA Table that includes SNAP data;
%LET D_Select = SNAP; * Data to select in CA35 table;

* Delete the existing panel dataset before running IMPORT Macro;
PROC datasets library=&library NOLIST;
	DELETE &BEACode._AllStates_1969_2012;
Run;

%macro CallSt;
/*The CallSt macro is used to generate State 2 digit abbreviations 
/*The BEA file contains state 2 digit numeric codes from 1 to 72  
  Note:  FIPS codes are NOT sequential so if a code does not exist such as 71  
		 The call execute statement will NOT run because there is no state abbrev	*/
/*If you want just a single state, such as Alabama set the do statement to start 
  and end at that state code such as %do i=1 %to 1; for Alabama 					*/
%do i=1 %to 72;
	data _null_;
  	  stabbrv=compress(trim(lowcase(FIPSTATE(&i))));
  	  	/*Note:  DC and PR are not covered in FIPS state function, and the two digit 
  		function is not required to be 0 filled		*/
	    if &i=0  then stabbrv = 'us';
  		if &i=11 then stabbrv = 'dc';
  		if &i=72 then stabbrv = 'pr';
  		/*FIPS Codes 60 and 66 are fpr American Samoa and Guam */
  		if &i>56 and &i<72 then stabbrv = "--";
  		/*If the function returns a state abbreviation then run the AllSeqs macro			*/
  		if stabbrv ^= "--" then do;
  			call execute('%AllStates(' || compress(stabbrv) || ')');				
       	end;
	run;
%end;
%mend;

%CallSt;
