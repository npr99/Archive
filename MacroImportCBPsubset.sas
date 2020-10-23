 /*-------------------------------------------------------------------*/
 /*       Macro for Reading in County Business Patterns Files         */
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
 /* Date Last Updated: 24Aug2014                                      */
 /*-------------------------------------------------------------------*/
 /* Questions or problem reports concerning this material may be      */
 /* addressed to the author on github: https://github.com/npr99       */
 /*                                                                   */
 /*-------------------------------------------------------------------*/
 /* Data Source:                                                      */
 /* US Census Bureau (2013) County Business Patterns 2001-2012        */
 /*     http://www.census.gov/econ/cbp/download/                      */
 /*-------------------------------------------------------------------*/
/*-------------------------------------------------------------------*/
/* Control Symbolgen                                                 */
/*-------------------------------------------------------------------*/

* Turn on SYBMBOLGEN option to see how macro variables are resolved in log;
* global system option MPRINT to view the macro code with the 
macro variables resolved;
options SYMBOLGEN MPRINT;

* SYMBOLGEN option can be turned off with the following command;
* options nosymbolgen;
/*
* use the obs= option to read just a small number of records to test your program; 
options obs=Max;

%LET dd_data = C:\Users\Nathanael\MyData\Census\CBP\;
%LET dd_SASLib = C:\Users\Nathanael\MySASLib\;
%LET Include_prog = C:\Users\Nathanael\Dropbox\MyPrograms\;
*/
%Macro MacroImportCBP(
   dd_data = , 
   dd_SASLib = ,
   Include_prog = ,
   Fyear = ,
   Lyear = ,
   NAICSKeep = ,
   NAICSDigits = ,
   NAICSCBP = ,
   NAICSTitle = );

*  The following line should contain the name of the SAS dataset ;

%let dataset = CBP&NAICSDigits.digits;
%let library = CBP;
* Found these text utilities that might be useful from 
	http://www2.sas.com/proceedings/sugi30/029-30.pdf
	include add_string macro;
%INCLUDE "&Include_prog.Macros_SAS\TextUtilityMacros.sas";
* Found these Tight Looping with Macro Arrays from
	http://www.sascommunity.org/wiki/Tight_Looping_with_Macro_Arrays
	inlcude Array, Do_Over Macros;
%INCLUDE "&Include_prog.Macros_SAS\Clay-TightLooping-macros\NUMLIST.sas";
%INCLUDE "&Include_prog.Macros_SAS\Clay-TightLooping-macros\ARRAY.sas";
%INCLUDE "&Include_prog.Macros_SAS\Clay-TightLooping-macros\DO_OVER.sas";

/*-------------------------------------------------------------------*/
/* Identify NAICS Codes of interest                                  */
/*-------------------------------------------------------------------*/

/*
NAICS CODES IN 2002 of interest
SOURCE: http://www.census.gov/econ/cbp/download/naics.txt 
NOTE: 2 digit NAICS are consistent but 3,5,6 digit codes are different from 2007, 2012 NAICS
/*
------  Total   
11----  Forestry, fishing, hunting, and agriculture support 
21----  Mining
22----  Utilities       
23----  Construction
31----  Manufacturing
42----  Wholesale trade
44----  Retail trade
48----  Transportation & warehousing
51----  Information
52----  Finance & insurance
53----  Real estate & rental & leasing
54----  Professional, scientific & technical services  
55----  Management of companies & enterprises
56----  Admin, support, waste mgt, remediation services
61----  Educational services
62----  Health care and social assistance
71----  Arts, entertainment & recreation 
72----  Accommodation & food services
81----  Other services (except public administration)
95----  Auxiliaries (exc corporate, subsidiary & regional mgt)  
99----  Unclassified establishments
*/

%MACRO MacroImportYearCBP(CBPYear);

LIBNAME CBP "&dd_SASLib.CBP";
%LET yr = %substr(&CBPYear, 3, 2); *CBP years are two digit codes;

/*-------------------------------------------------------------------*/
/* Import Primary Files from Original Source                         */
/*-------------------------------------------------------------------*/

*  The following line should contain the directory
   where the SAS file is to be stored;

%LET dd_SASLib = C:\Users\Nathanael\MySASLib\;
LIBNAME CBP "&dd_SASLib.CBP";

*  The following line should contain
   the complete path and name of the raw data file.
   On a PC, use backslashes in paths as in C:\;
%if &yr GE 07 %then
%let file1=&dd_data.\Census\CBP\noiselayout\cbp&yr.co.zip;
%else 
%let file1=&dd_data.\Census\CBP\full_layout\cbp&yr.co.zip;

*  The following line should contain the directory
  	where the gzip is to be stored  
	use " " around directories with spaces;

%LET dd_gzip = C:\"Program Files (x86)"\GnuWin32\bin\gzip;

DATA work.&dataset._temp REPLACE;
filename datafile pipe %unquote(%str(%'&dd_gzip -cd &file1%')) LRECL = 100;
INFILE datafile DLM = ',' FIRSTOBS = 2 MISSOVER DSD;
attrib	FIPSTATE 	length=$2	label="FIPS State Code";
attrib	FIPSCTY 	length=$3	label="FIPS County Code";
attrib	NAICS 		length=$6	label="Industry Code - 6-digit NAICS code";
attrib	EMPFLAG 	length=$1	label="Data Suppression Flag";
attrib	EMP 		length=8	label="Total Mid-March Employees";
attrib	QP1 		length=8	label="First Quarter Payroll ($1,000)";
attrib	AP 			length=8	label="Total Annual Payroll ($1,000)";
attrib	EST 		length=8	label="Total Number of Establishments";
attrib	N1_4 		length=8	label="1-4 Employees (Estab)";
attrib	N5_9 		length=8	label="5-9 Employees  (Estab)";
attrib	N10_19 		length=8	label="10-19 Employees (Estab)";
attrib	N20_49 		length=8	label="20-49 Employees (Estab)";
attrib	N50_99 		length=8	label="50-99 Employees (Estab)";
attrib	N100_249 	length=8	label="100-249 Employees (Estab)";
attrib	N250_499 	length=8	label="250-499 Employees (Estab)";
attrib	N500_999 	length=8	label="500-999 Employees (Estab)";
attrib	N1000 		length=8	label="1,000 Or More Employees (Estab)";
attrib	N1000_1 	length=8	label="1,000-1,499 Employees (Estab)";
attrib	N1000_2 	length=8	label="1,500-2,499 Employees (Estab)";
attrib	N1000_3 	length=8	label="2,500-4,999 Employees (Estab)";
attrib	N1000_4 	length=8	label="5,000 or More Employees (Estab)";
attrib	CENSTATE 	length=$2	label="Census State Code";
attrib	CENCTY 		length=$2	label="Census County Code";

* The format for the CBP changes in 2007, noise flags were added;
If &yr GE 07 Then do;
	attrib	EMP_NF  	length=$1	label="EMP Noise Flag";
	attrib	QP1_NF  	length=$1	label="QP1 Noise Flag";
	attrib	AP_NF  		length=$1	label="AP Noise Flag";

	Input
	FIPSTATE $
	FIPSCTY $
	NAICS $
	EMPFLAG $
	EMP_NF $
	EMP 
	QP1_NF $
	QP1
	AP_NF $
	AP 
	EST N1_4 N5_9 N10_19 N20_49 N50_99 N100_249 
	N250_499 N500_999 N1000 N1000_1 N1000_2 N1000_3 N1000_4 
	CENSTATE $
	CENCTY $;
End;

Else IF &yr LT 07 Then do;
	INPUT 
	FIPSTATE $
	FIPSCTY $
	NAICS $
	EMPFLAG $
	EMP QP1 AP EST N1_4 N5_9 N10_19 N20_49 N50_99 N100_249 
	N250_499 N500_999 N1000 N1000_1 N1000_2 N1000_3 N1000_4 
	CENSTATE $
	CENCTY $;
End;

If &NAICSCBP NE 'All' Then do;
	* Where input(substr(NAICS,1,&NAICSDigits)) in (&NAICSKeep);
	If &NAICSDigits = 2 Then do;
		If substr(NAICS,3,4) = '----';  
		/*2 digit NAICS format ##----*/
		end;
	Else If &NAICSDigits = 3 Then do;
		If substr(NAICS,4,3) = '///';
		/*3 digit NAICS format ###///*/
		end;
	Else If &NAICSDigits = 4 Then do;
		If substr(NAICS,5,2) = '//';
		/*4 digit NAICS format ####//*/
		end;
	Else If &NAICSDigits = 5 Then do;
		If substr(NAICS,6,1) = '/';
		/*5 digit NAICS format #####/*/
		end;
	Else If &NAICSDigits = 6 Then do;
		If find(NAICS,'/') = 0;
		If find(NAICS,'-') = 0; 
		/*6 digit NAICS format ######*/
		end;
	Else do;
		If index(NAICS,&NAICSCBP) ge 1; /* Single NAICS code set in Macro code*/ 
		end;
	end;
RUN;

DATA  work.&dataset._temp REPLACE;
	Set work.&dataset._temp;
	Year = &CBPYEAR;
	FIPS_County = input(FIPSTATE,$2.) || input(FIPSCTY,$3.); /*Need a 5 digit FIPS_County to Merge with Tiger */
	N1_9 = N1_4 + N5_9; /*interested in small employee establishments */
	If NAICS = "------" Then NAICS3d = "ALL";
	Else NAICS3d = substr(NAICS,1,3);
	If EMPFLAG NE "" AND EMP = 0 Then Do; /*Check Employment Flag and change 0 values to MISSING */
		EMP = .;
		QP1 = .;
		AP = .;
		End;
Run;

/*-------------------------------------------------------------------*/
/* Convert Data so that each county has 1 obs for each year          */
/*-------------------------------------------------------------------*/

PROC SORT DATA = work.&dataset._temp OUT = work.&dataset._temp;
	BY FIPS_County;
RUN;

%Macro TransposeCBP(WideVar);
Proc Transpose data = work.&dataset._temp OUT = work.&dataset._tW&WideVar prefix = &WideVar;
	by FIPS_County;
	id NAICS3d;
	var &WideVar;
run;
Data work.&dataset._tW&WideVar REPLACE;
	Set work.&dataset._tW&WideVar;
	Drop _NAME_;
	Drop _LABEL_;
	Year = &CBPYEAR; 
Run;
%mend TransposeCBP;

%ARRAY(WideVar, VALUES=EMP EST N1_9);
%Do_Over(WideVar, MACRO=TransposeCBP);

Data work.&dataset._Wide Replace;
	Merge work.&dataset._tW:;
	By FIPS_County;
Run;

Data work.&dataset._Wide Replace;
	Retain FIPS_County Year EMPALL ESTALL N1_9ALL;
	Set work.&dataset._Wide;
Run;
/*-------------------------------------------------------------------*/
/* Append Yearly Calculations together for panel                     */
/*-------------------------------------------------------------------*/

PROC APPEND BASE = work.&dataset.&FYear._&LYear
	DATA = work.&dataset._Wide;
RUN;

PROC SORT DATA = work.&dataset.&FYear._&LYear;
	BY FIPS_County Year;
RUN;

%mend MacroImportYearCBP;

/*-------------------------------------------------------------------*/
/* Setup and call Macro to import CBP from First to Last Year        */
/*-------------------------------------------------------------------*/

* Delete the existing panel dataset before running IMPORT Macro;
PROC datasets library=work NOLIST;
	DELETE &dataset.&FYear._&LYear;
Run;


%ARRAY(CBPYear, VALUES=&FYear - &LYear);
%Do_Over(CBPYear, MACRO=MacroImportYearCBP);

/*-------------------------------------------------------------------*/
/* Export panel to Library                                           */
/*-------------------------------------------------------------------*/
Data &library..&dataset.&FYear._&LYear Replace;
	Set work.&dataset.&FYear._&LYear;
Run;

/*-------------------------------------------------------------------*/
/* Label Variables                                                   */
/*-------------------------------------------------------------------*/
/*
Data &library..&dataset.&FYear._&LYear Replace;
	Set &library..&dataset.&FYear._&LYear;
Label
EMP&NAICSKeep = &NAICSTitle. "(Employees)"
EST&NAICSKeep = &NAICSTitle. "(Estab)"
N1_9&NAICSKeep = &NAICSTitle. "(1-9 Emp Estab)";
Run;
*/
%mend MacroImportCBP;

/*-------------------------------------------------------------------*/
/* Run Macro Here                                                    */
/*-------------------------------------------------------------------*/
/*-------------------------------------------------------------------*/
/* Important Folder Locations                                        */
/*-------------------------------------------------------------------*/

%LET dd_data = C:\Users\Nathanael\Dropbox\MyData\;
%LET dd_SASLib = C:\Users\Nathanael\MySASLib\;
%LET Include_prog = C:\Users\Nathanael\Dropbox\MyPrograms\;

%MacroImportCBP(
   dd_data = &dd_data,  
   dd_SASLib = &dd_SASLib,
   Include_prog = &Include_prog,
   Fyear = 2001,
   Lyear = 2001,
   NAICSKeep = 445:452,
   NAICSDigits = 6,
   NAICSCBP = '445///',
   NAICSTitle = "Food and Beverage Stores");
