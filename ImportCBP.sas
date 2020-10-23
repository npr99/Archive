 /*-------------------------------------------------------------------*/
 /*       Program for Reading in County Business Patterns Files       */
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
 /* Date Last Updated: 07Jul2014                                      */
 /*-------------------------------------------------------------------*/
 /* Questions or problem reports concerning this material may be      */
 /* addressed to the author on github: https://github.com/npr99       */
 /*                                                                   */
 /*-------------------------------------------------------------------*/
 /* Data Source:                                                      */
 /* United States Census Bureau (2002) County Business Patterns 2002  */
 /*     http://www.census.gov/econ/cbp/download/02_data/              */
 /*     ftp://ftp.census.gov/econ2002/CBP_CSV/cbp02co.zip             */
 /*-------------------------------------------------------------------*/

%LET dd_data = C:\Users\Nathanael\MyData\Census\CBP\;
%LET dd_SASLib = C:\Users\Nathanael\MySASLib\;

LIBNAME CBP "&dd_SASLib.CBP";

/*-------------------------------------------------------------------*/
/* Import Primary Files from Original Source                         */
/*-------------------------------------------------------------------*/

%LET CBPYear = 02;
DATA  CBP.CBP&CBPYear.co Replace;
	Infile "&dd_data.cbp&CBPYear.co\cbp&CBPYear.co.txt" DLM = ',' 
	DSD MISSOVER FIRSTOBS = 2;
    INPUT 
		FIPSTATE $
		FIPSCTY $
		NAICS $
		EMPFLAG $
		EMP QP1 AP EST N1_4 N5_9 N10_19 N20_49 N50_99 N100_249 
		N250_499 N500_999 N1000 N1000_1 N1000_2 N1000_3 N1000_4 
		CENSTATE $
		CENCTY $;
RUN;

/*-------------------------------------------------------------------*/
/* Lable Variables Primary Files from Original Source                */
/*-------------------------------------------------------------------*/

DATA  CBP.CBP&CBPYear.co REPLACE;
	Set CBP.CBP&CBPYear.co;
	Year = 20&CBPYEAR;
	GEOID = input(FIPSTATE,$2.) || input(FIPSCTY,$3.); /*Need a 5 digit GEOID to Merge with Tiger */
    LABEL  
		FIPSTATE = "FIPS State Code"
		FIPSCTY = "FIPS County Code"
		NAICS = "Industry Code - 6-digit NAICS code"
		EMPFLAG = "Data Suppression Flag"
		EMP = "Total Mid-March Employees"
		QP1 = "First Quarter Payroll ($1,000)"
		AP = "Total Annual Payroll ($1,000)"
		EST = "Total Number of Establishments"
		N1_4 = "1-4 Employees"
		N5_9 = "5-9 Employees"
		N10_19 =  "10-19 Employees"
		N20_49 = "20-49 Employees"
		N50_99 = "50-99 Employees"
		N100_249 = "100-249 Employees"
		N250_499 = "250-499 Employees"
		N500_999 = "500-999 Employees"
		N1000 = "1,000 Or More Employees"
		N1000_1 = "1,000-1,499 Employees"
		N1000_2 = "1,500-2,499 Employees"
		N1000_3 = "2,500-4,999 Employees"
		N1000_4 = "5,000 or More Employees"
		CENSTATE = "Census State Code"
		CENCTY = "Census County Code";
RUN;

/*-------------------------------------------------------------------*/
/* Identify NAICS Codes of interest                                  */
/*-------------------------------------------------------------------*/

/*
NAICS CODES IN 2002 of interest
SOURCE: http://www.census.gov/econ/cbp/download/naics.txt 
NOTE: Different from 2007, 2012 NAICS
23----  Construction
233///  Building, developing & general contracting
234///  Heavy construction
235///  Special trade contractors
44----  Retail trade
441///  Motor vehicle & parts dealers
442///  Furniture & home furnishing stores
443///  Electronics & appliance stores
444///  Bldg material & garden equip & supp dealers
445///  Food & beverage stores
446///  Health & personal care stores
447///  Gasoline stations
448///  Clothing & clothing accessories stores
451///  Sporting goods, hobby, book & music stores
452///  General merchandise stores
453///  Miscellaneous store retailers
454///  Nonstore retailers
53----  Real estate & rental & leasing
531///  Real estate
532///  Rental & leasing services
533///  Lessors of other nonfinancial intangible asset
72----  Accommodation & food services   
721///  Accommodation
722///  Food services & drinking places
*/
%LET NAICSKeep44 = 
	'441///', /* Motor vehicle & parts dealers */
	'442///', /* Furniture & home furnishing stores */
	'443///', /* Electronics & appliance stores */
	'444///', /* Bldg material & garden equip & supp dealers */
	'445///', /* Food & beverage stores */
	'446///', /* Health & personal care stores */
	'447///', /* Gasoline stations */
	'448///', /* Clothing & clothing accessories stores */
	'451///', /* Sporting goods, hobby, book & music stores */
	'452///', /* General merchandise stores */
	'453///', /* Miscellaneous store retailers */
	'454///', /* Nonstore retailers */;

%LET NAICSKeep72 = 
	'721///', /* Accommodation */
	'722///', /* Food services & drinking places */;

%LET NAICSKeep23 = 
	'23----', /* Construction */
	'233///', /* Building, developing & general contracting */
	'234///', /* Heavy construction */
	'235///', /* Special trade contractors */;

%LET NAICSKeep53 = 
	/* '53----', /* Real estate & rental & leasing */
	'531///', /* Real estate */
	'532///', /* Rental & leasing services */
	'533///', /* Lessors of other nonfinancial intangible asset */;

/*-------------------------------------------------------------------*/
/* Macro for Creating Summary Statistics                             */
/*-------------------------------------------------------------------*/

%LET NAICSCode = 44;

/*-------------------------------------------------------------------*/
/* Create Dataset with State and NAICS of interest                   */
/*-------------------------------------------------------------------*/

Data CBP.CBP&CBPYear.co&NAICSCode REPLACE;
	Set CBP.CBP&CBPYear.co; 
	Where NAICS in(&&NAICSKeep&NAICSCode);
Run;
/*-------------------------------------------------------------------*/
/* Sum Establishments for County Summary Statistics                  */
/*-------------------------------------------------------------------*/

PROC SORT DATA = CBP.CBP&CBPYear.co&NAICSCode;
	By GEOID; 
RUN;

DATA CBP.SumCtyCBP&CBPYear.co&NAICSCode REPLACE;
	Set CBP.CBP&CBPYear.co&NAICSCode;
	BY GEOID;
	IF first.GEOID THEN DO;
		EMPtotal_&NAICSCode = 0; 
		QP1total_&NAICSCode = 0; 
		APtotal_&NAICSCode = 0; 
		ESTtotal_&NAICSCode = 0;
		N1_4Total_&NAICSCode = 0; /* Interested in small emplolyee size */
		N5_9Total_&NAICSCode = 0;
		N1_9Total_&NAICSCode = 0;
		END;
	EMPtotal_&NAICSCode + EMP; 
	QP1total_&NAICSCode + QP1; 
	APtotal_&NAICSCode + AP; 
	ESTtotal_&NAICSCode + EST;
	N1_4Total_&NAICSCode + N1_4;
	N5_9Total_&NAICSCode + N5_9;
	N1_9Total_&NAICSCode + N1_4 + N5_9; /* Interested 1 - 9 emplolyee */
	Totalcnt + 1;
	IF last.GEOID THEN OUTPUT;
RUN;

* Drop variables that are nolonger needed;
DATA CBP.SumCtyCBP&CBPYear.co&NAICSCode REPLACE;
	Set CBP.SumCtyCBP&CBPYear.co&NAICSCode;
	KEEP
		FIPSTATE
		FIPSCTY
		GEOID
		Year
		EMPtotal_&NAICSCode
		QP1total_&NAICSCode
		APtotal_&NAICSCode
		ESTtotal_&NAICSCode
		N1_4Total_&NAICSCode
		N5_9Total_&NAICSCode
		N1_9Total_&NAICSCode
		Totalcnt;
Run;

/*-------------------------------------------------------------------*/
/* Sum Establishments for State Summary Statistics                   */
/*-------------------------------------------------------------------*/


PROC SORT DATA = CBP.CBP&CBPYear.co&NAICSCode;
	By FIPSTATE; 
RUN;

DATA CBP.SumStCBP&CBPYear.co&NAICSCode REPLACE;
	Set CBP.CBP&CBPYear.co&NAICSCode;
	BY FIPSTATE;
	IF first.FIPSTATE THEN DO;
		EMPtotal_&NAICSCode = 0; 
		QP1total_&NAICSCode = 0; 
		APtotal_&NAICSCode = 0; 
		ESTtotal_&NAICSCode = 0; 
		N1_4Total_&NAICSCode = 0;
		N5_9Total_&NAICSCode = 0; 
		END;
	EMPtotal_&NAICSCode + EMP; 
	QP1total_&NAICSCode + QP1; 
	APtotal_&NAICSCode + AP; 
	ESTtotal_&NAICSCode + EST;
	N1_4Total_&NAICSCode + N1_4;
	N5_9Total_&NAICSCode + N5_9;
	Totalcnt + 1;
	IF last.FIPSTATE THEN OUTPUT;
RUN;

* Drop variables that are nolonger needed;
DATA CBP.SumStCBP&CBPYear.co&NAICSCode REPLACE;
	Set CBP.SumStCBP&CBPYear.co&NAICSCode;
	GEOID = input(FIPSTATE,$2.) || "000";
	KEEP
		FIPSTATE
		FIPSCTY
		GEOID
		Year
		EMPtotal_&NAICSCode
		QP1total_&NAICSCode 
		APtotal_&NAICSCode
		ESTtotal_&NAICSCode
		N1_4Total_&NAICSCode
		N5_9Total_&NAICSCode
		Totalcnt;
Run;

/*-------------------------------------------------------------------*/
/* Export County file to Excel                                       */
/*-------------------------------------------------------------------*/

Proc Export
	Data = CBP.SumCtyCBP&CBPYear.co&NAICSCode
	DBMS = excel
	OUTFILE = "&dd_data.XLSOutput\SumCBP&CBPYear.co&NAICSCode..xls"
	Replace;
	Sheet = Cty&CBPYear.co&NAICSCode;
Run;
