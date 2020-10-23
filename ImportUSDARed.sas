/*-------------------------------------------------------------------*/
/*       Macro for Importing Redemption Data From USDA               */
/*          by Nathanael Proctor Rosenheim                           */
/*-------------------------------------------------------------------*/
/*                                                                   */
/* This material is provided "as is" by the author.                  */
/* There are no warranties, expressed or implied, as to              */
/* merchantability or fitness for a particular purpose regarding     */
/* the materials or code contained herein. The author is not         */
/* responsible for errors in this material as it now exists or       */
/* will exist, nor does the author provide technical support.        */
/*                                                                   */
/*-------------------------------------------------------------------*/
/* Date Last Updated: 14July2014                                     */
/*-------------------------------------------------------------------*/
/* Questions or problem reports concerning this material may be      */
/* addressed to the author on github: https://github.com/npr99       */
/*                                                                   */
/*-------------------------------------------------------------------*/
/* Data Source:                                                      */
/* Supplemental Nutrition Assistance Program, Retailer Policy and    */
/*       Management Division, Food and Nutrition Service,            */
/*       U.S. Department of Agriculture. (Mar 2014 email             */ 
/*       communication with RPMDHQ-WEB@fns.usda.gov                  */
/*-------------------------------------------------------------------*/

/*-------------------------------------------------------------------*/
/* After running the model in STATA I have found that at least 5
Texas Counties had Redemptions values read incorrectly. This version
of the program will seek to fix this problem.

I believe the problem is with how the program converted Excel Values 
into dollar amounts.

Also this program fixes issues with FIPS Codes that I was not aware of 
earlier. 

---------------------------------------------------------------------*/

* Using INFILE to read in Comma-seperated value files, first 
obseravtion has headers therefore will be skipped (FIRSTOBS = 2)
Going to use Delimiter-Senstive DATA option (DSD) just in case missing 
values exist;
%MACRO ImportUSDARed( );
/*-------------------------------------------------------------------*/
/* Define SAS Library                                                */
/*-------------------------------------------------------------------*/
%let library = USDA;
LIBNAME &library "&dd_SASLib.&library";

/*-------------------------------------------------------------------*/
/* Import Primary Files from Original Source                         */
/*-------------------------------------------------------------------*/

* Import SNAP Redemption data by calendar year by state by county;
* The original SNAP Redemption data had incorrect values for 2005;

PROC IMPORT DATAFile = "&dd_data.USDA_ReadOnly\
CY 2005 - CY 2012 Redemptions by ST-County - Redacted v2.xlsx" DBMS = XLSX 
OUT = CountyRedemptions REPLACE;
	RANGE = "Sheet$A2:E24983";
	MIXED = YES;
RUN;

/*-------------------------------------------------------------------*/
/* Add common County ID count to Redemption files                    */
/*-------------------------------------------------------------------*/

/*-------------------------------------------------------------------*/
/* Import CENSUS FIPS DATA                                           */
/*-------------------------------------------------------------------*/

* Include FIPS Macro;
* Program creates work.FIPS_state, work.FIPS_County datasets;
%INCLUDE "&Include_prog.Macros_SAS\MacroFIPS_County.sas";

%MacroFIPS_County(
   dd_data = &dd_data, 
   dd_SASLib = &dd_SASLib,
   Include_prog = &Include_prog);

 * Add State FIPS code to Redemption data;
PROC SORT DATA = FIPS_State;
	By State; 
RUN;
PROC SORT DATA = CountyRedemptions;
	By State; 
RUN;
DATA CountyRedemptions REPLACE;
	MERGE CountyRedemptions FIPS_State;
	BY State;
RUN;
* Convert County_Code in redemption data to 3 digit character;
* Perform a simple concatenation to create FIPS_County unique with State; 
DATA CountyRedemptions REPLACE;
	SET CountyRedemptions;
	IF County_Code < 10 THEN County_FIPS_Code = "00" || PUT(County_Code, 1.);
		ELSE IF County_Code < 100 THEN 
			County_FIPS_Code = "0" || PUT(County_Code, 2.);
		ELSE IF County_Code < 1000 THEN 
			County_FIPS_Code = PUT(County_Code, 3.);
	 FIPS_County = StateFP || County_FIPS_Code;
RUN;

/*-------------------------------------------------------------------*/
/* Create new Redemption Columns one for money one for redacted flag */
/*-------------------------------------------------------------------*/

* NOTE Some Redemption data does not have decimal information. Therefor
it is not possible to convert values into dollar amounts.
* Create a redacted Flag and replace redacted with Missing;

DATA work.CountyRedemptions REPLACE;
	Set work.CountyRedemptions;
	CheckDecimal = find(Redemptions,'.');
	IF Redemptions = "redacted" THEN RedactedFlag = 1;
		ELSE RedactedFlag = 0;
Run;

DATA work.CountyRedemptions REPLACE;
	Set work.CountyRedemptions;
	If CheckDecimal GT 0 AND RedactedFlag = 0 THEN
		RedAmt = input(Redemptions, Dollar12.2);
	Else If CheckDecimal = 0 AND RedactedFlag = 0 Then
		RedAmt = input(Redemptions, Dollar12.2) * 100;
	Else If CheckDecimal = 0 AND RedactedFlag = 1 Then
		RedAmt = MISSING;
Run;

Data work.CountyRedemptions REPLACE;
	Set work.CountyRedemptions (KEEP =
	 FIPS_County
	 Year
	 State
	 StateFP
	 RedactedFlag
	 RedAmt
	);
Run;


/*-------------------------------------------------------------------*/
/* Save County Data                                                  */
/*-------------------------------------------------------------------*/

Data USDA.USDARed_2005_2012 REPLACE;
	set work.CountyRedemptions;
	yeartxt = put(year,4.); * Year needs to be a string;
Run;

Proc Sort data = USDA.USDARed_2005_2012
	out = USDA.USDARed_2005_2012;
	by FIPS_county year;
Run;

Data USDA.USDARed_2005_2012 REPLACE;
	Retain FIPS_county year;
	Set USDA.USDARed_2005_2012;
	Label 
		RedactedFlag = "USDA SNAP Redemption Data Redacted"
		RedAmt = "USDA SNAP Redemption Data";
run;

%mend;

/*-------------------------------------------------------------------*/
/* Run Macro Here                                                    */
/*-------------------------------------------------------------------*/
/*-------------------------------------------------------------------*/
/* Important Folder Locations                                        */
/*-------------------------------------------------------------------*/

%LET dd_data = C:\Users\Nathanael\Dropbox\MyData\;
%LET dd_SASLib = C:\Users\Nathanael\MySASLib\;
%LET Include_prog = C:\Users\Nathanael\Dropbox\MyPrograms\;

%ImportUSDARed( );
