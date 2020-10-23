 /*-------------------------------------------------------------------*/
 /*       Macro for Organizing County Unemployment Data		          */
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
 /* Date Last Updated: 11 June 2014                                   */
 /*-------------------------------------------------------------------*/
 /* Questions or problem reports concerning this material may be      */
 /* addressed to the author on github: https://github.com/npr99       */
 /*                                                                   */
 /*-------------------------------------------------------------------*/
 /* Data Source:                                                      */
 /* Bureau of Labor Statistics (2014) Local Area Unemployment 
		Statistics Annual Average County Data Tables. 
		Retrieved from 
		http://www.bls.gov/lau/#tables on June 11, 2014.
                                                                      */
 /*-------------------------------------------------------------------*/

%MACRO MacroBLSLAUS(
   dd_data = , 
   Include_prog = ,
   State = ,
   Statefp = ,
   FYear = ,
   LYear = );

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
/* Import Primary Files from Original Source                         */
/*-------------------------------------------------------------------*/
* Will generate a panel file for designated first and last years;
* Import BLS LAUS Annual County Average Data;
* Data includes estimated labor force, employed, unemployement 
 and unemployement rate for all counties in US;
* Data available online from states, labor market areas, and county.
* Data available online from 1990-2013 for counties;

%MACRO IMPORT_LAUSYEARS(LAUSYears);
%LET yr = %substr(&LAUSYears, 3, 2); *LAUS years are two digit codes;

PROC IMPORT DATAFile = "&dd_data.BLS\LAUS\laucnty&yr..xlsx" 
	DBMS = XLSX OUT = work.lausimport REPLACE;
	GETNAMES = NO;
	MIXED = YES;
RUN;

DATA work.SASlauscnty_temp REPLACE;
	SET work.lausimport (FIRSTOBS = 7);
	LAUSCode = input(A, $CHAR15.);
	Statefp = input(B,$CHAR2.);
	Countyfp = input(C,$CHAR3.);
    FIPS_County = Statefp || Countyfp;
	CountyName = input(D,$CHAR37.);
	LAUSYear = input(E,$char4.);
	LaborForce = input(G,comma15.);
	Employed = input(H,comma15.);
	Unemployed = input(I,comma15.);
	URate = input(J,comma5.);
RUN;

* Drop the original variables to create an unsorted or messy temp file;
DATA work.SASlauscnty_temp_messy REPLACE;
	SET work.SASlauscnty_temp (DROP = A B C D E F G H I J);
	IF Statefp NE "";
RUN;
* Data needs to be sorted before the files can be merged;
PROC SORT DATA = work.SASlauscnty_temp_messy OUT = work.lauscnty&LAUSYears;
	BY FIPS_County;
RUN;

PROC APPEND BASE = work.laus&FYear._&LYear
	DATA = work.lauscnty&LAUSYears;
RUN;

PROC SORT DATA = work.laus&FYear._&LYear;
	BY Statefp FIPS_County;
RUN;

%MEND IMPORT_LAUSYEARS;

* Delete the existing panel dataset before running IMPORT Macro;
PROC datasets library=work NOLIST;
	DELETE laus&FYear._&LYear;
Run;

*Run Import LAUS Years from first to last years in panel;
%ARRAY(LAUSYears, VALUES=&FYEAR-&LYEAR);
%Do_Over(LAUSYears, MACRO=IMPORT_LAUSYEARS);

/*-------------------------------------------------------------------*/
/* Export Data to Model SAS Libary                                   */
/*-------------------------------------------------------------------*/

Data model1.&state.&geolevel.&Fyear._&Lyear.LAUS;
   Set work.laus&FYear._&LYear;
   If statefp = &StateFp;
   Year = LAUSYear;
   Drop LAUSYear
        LAUSCode
        Statefp
        Countyfp
        CountyName;
run; 

Data model1.&state.&geolevel.&Fyear._&Lyear.LAUS;
	Retain FIPS_county year;
	Set model1.&state.&geolevel.&Fyear._&Lyear.LAUS;
run;

Proc Sort data = model1.&state.&geolevel.&Fyear._&Lyear.LAUS
	out = model1.&state.&geolevel.&Fyear._&Lyear.LAUS;
	by FIPS_county year;
Run;

%mend MacroBLSLAUS;
