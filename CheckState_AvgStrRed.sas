/*-------------------------------------------------------------------*/
/*       Macro for Checking and looking into State level Store       */
/*       Redemption Averages                                         */
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
/* Date Last Updated: 30Sept2014                                     */
/*-------------------------------------------------------------------*/
/* Questions or problem reports concerning this material may be      */
/* addressed to the author on github: https://github.com/npr99       */
/*                                                                   */
/*-------------------------------------------------------------------*/
/* Data Source:                                                      */
/* Supplemental Nutrition Assistance Program, Retailer Policy and    */
/*       Management Division, Food and Nutrition Service,            */
/*       U.S. Department of Agriculture. (May 2014 email             */ 
/*       communication with RPMDHQ-WEB@fns.usda.gov                  */
/*       Authorized Store Counts by State-County-Store Type CY       */
/*       2005-2012                                                   */
/* Supplemental Nutrition Assistance Program USDA Food and           */
/* 		Nutrition Service Benefit Division Annual Report 2005-2012   */
/*      Files available at:
		http://www.fns.usda.gov/snap/retailers/pdfs/2010-annual-report.pdf
		http://www.fns.usda.gov/sites/default/files/2011-annual-report-revised.pdf
		http://www.fns.usda.gov/sites/default/files/2012-annual-report.pdf
		Muckrosk News (2013) FOIA request:
		https://www.muckrock.com/foi/united-states-of-america-10/supplemental-nutrition-assistance-programs-benefit-redemption-data-1906/
/*-------------------------------------------------------------------*/

/* Data Checking Issues:
Annual reports provide data based on state and number of stores
this allows for some geographic variation in the average 
redemptions per store in a given state. For example the lowest per store
redemption rate as reported by the USDA BRD Annual Reports is Virginia
in 2007 - $5,699.07. The 2007 Virginia numbers is mostly likely an 
error since the next lowest per store average is New Jersey in 2005 at 
$114,802 per store. The average for the country between 2005-2012 was 
$243,979.94 per SNAP retailer. The maximum per store redemptions were in
Hawaii, Arizona, Guam, and Idaho with over $415,000 per store in 2011 and 2012.

This SAS program will try to use national average per store redemption
values to see if the state level variation can be explained using the variation
in store type redemptions. For example the average superstore in 2012 
recieved over $1.9 million while the average convience store in 2012 
recieved over $38 thousand. If Hawaii, Arizano, Guam, and Idaho have more 
Super Centers than convience stores and New Jersey has more convience
stores than super centers then it may be possible to explain the 
difference in average per store redemptions from store type.
Other explanations may be 

*/
/*-------------------------------------------------------------------*/
/* Control Symbolgen                                                 */
/*-------------------------------------------------------------------*/

* Turn on SYBMBOLGEN option to see how macro variables are resolved in log;
* global system option MPRINT to view the macro code with the 
macro variables resolved;
options SYMBOLGEN MPRINT;

* SYMBOLGEN option can be turned off with the following command;
* options nosymbolgen;

/*-------------------------------------------------------------------*/
/* Important Folder Locations                                        */
/*-------------------------------------------------------------------*/

%LET dd_data = C:\Users\Nathanael\Dropbox\MyData\;
%LET dd_SASLib = C:\Users\Nathanael\MySASLib\;
%LET Include_prog = C:\Users\Nathanael\Dropbox\MyPrograms\;

/*-------------------------------------------------------------------*/
/* Important Macro Variables                                         */
/*-------------------------------------------------------------------*/

* Set Macro Variables for State and Years;
%LET FYear = 2005; *First year in panel;
%LET LYear = 2012; *Last year in panel;
%LET State = All;


%Macro ImportUSDAStoreCounts(
   FYear = ,
   LYear = );

/*-------------------------------------------------------------------*/
/* Define SAS Library                                                */
/*-------------------------------------------------------------------*/
%let library = USDA;
LIBNAME &library "&dd_SASLib.&library";

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

* Import SNAP Data Original files mailed to author from 
RPMDHQ-WEB@fns.usda.gov;


* Import SNAP Redemption data by calendar year by state by county;
* The original SNAP Redemption data had incorrect values for 2005;

%MACRO ImportStoreTypeData(fileyear);
PROC IMPORT DATAFile = "&dd_data.USDA_ReadOnly\
Store Counts by State-County-Type CY &fileyear..xlsx" DBMS = XLSX 
OUT = work.SNAPRetailTypeCYTemp REPLACE;
	GETNAMES = NO;
	MIXED = YES;
RUN;

/*-------------------------------------------------------------------*/
/* Set Variable Names                                                */
/*-------------------------------------------------------------------*/

DATA work.SNAPRetailTypeCY&fileyear REPLACE;
	SET work.SNAPRetailTypeCYTemp;
	IF B = "" THEN DELETE;
	IF B =: "County" THEN DELETE;
	State = input(A, $CHAR2.);
	County_Code = B;
	Year = &fileyear;
	StoreType = input(C,$CHAR2.);
	If D GE 0 Then MonthD&fileyear = D;
		Else MonthD&fileyear = 0;
	If E GE 0 Then MonthE&fileyear = E;
		Else MonthE&fileyear = 0;
	If F GE 0 Then MonthF&fileyear = F;
		Else MonthF&fileyear = 0;
	If G GE 0 Then MonthG&fileyear = G;
		Else MonthG&fileyear = 0;
	If H GE 0 Then MonthH&fileyear = H;
		Else MonthH&fileyear = 0;
	If I GE 0 Then MonthI&fileyear = I;
		Else MonthI&fileyear = 0;
	If J GE 0 Then MonthJ&fileyear = J;
		Else MonthJ&fileyear = 0;
	If K GE 0 Then MonthK&fileyear = K;
		Else MonthK&fileyear = 0;
	If L GE 0 Then MonthL&fileyear = L;
		Else MonthL&fileyear = 0;
	If M GE 0 Then MonthM&fileyear = M;
		Else MonthM&fileyear = 0;
	If N GE 0 Then MonthN&fileyear = N;
		Else MonthN&fileyear = 0;
	If O GE 0 Then MonthO&fileyear = O;
		Else MonthO&fileyear = 0;
    LABEL State = "State Abbreviation"
	County_Code = "3digit County FIP"
	MonthD&fileyear = "Authorized Store Counts by State-County-Store Type Jan &fileyear"
    MonthE&fileyear = "Authorized Store Counts by State-County-Store Type Feb &fileyear"
	MonthF&fileyear = "Authorized Store Counts by State-County-Store Type Mar &fileyear"
	MonthG&fileyear = "Authorized Store Counts by State-County-Store Type Apr &fileyear"
	MonthH&fileyear = "Authorized Store Counts by State-County-Store Type May &fileyear"
	MonthI&fileyear = "Authorized Store Counts by State-County-Store Type Jun &fileyear"
	MonthJ&fileyear = "Authorized Store Counts by State-County-Store Type Jul &fileyear"
	MonthK&fileyear = "Authorized Store Counts by State-County-Store Type Aug &fileyear"
	MonthL&fileyear = "Authorized Store Counts by State-County-Store Type Sep &fileyear"
	MonthM&fileyear = "Authorized Store Counts by State-County-Store Type Oct &fileyear"
	MonthN&fileyear = "Authorized Store Counts by State-County-Store Type Nov &fileyear"
	MonthO&fileyear = "Authorized Store Counts by State-County-Store Type Dec &fileyear"
*/
RUN;
* Drop the original variables to create an unsorted or messy temp file;
DATA work.SNAPRetailTypeCY&fileyear REPLACE;
	SET work.SNAPRetailTypeCY&fileyear (DROP = A B C D E F G H I J K L M N O);
RUN;


/*-------------------------------------------------------------------*/
/* Add common State ID Files                                         */
/*-------------------------------------------------------------------*/
* Add State FIPS code to Store Type Data;
PROC SORT DATA = work.FIPS_State;
	By State; 
RUN;
PROC SORT DATA = work.SNAPRetailTypeCY&fileyear;
	By State; 
RUN;
DATA work.SNAPRetailTypeCY&fileyear REPLACE;
	MERGE work.SNAPRetailTypeCY&fileyear FIPS_State;
	BY State;
RUN;
* Convert County_Code in redemption data to 3 digit character;
* Perform a simple concatenation to create FIPS_County unique with State; 
DATA work.SNAPRetailTypeCY&fileyear REPLACE;
	SET work.SNAPRetailTypeCY&fileyear;
	IF County_Code < 10 THEN County_FIPS_Code = "00" || PUT(County_Code, 1.);
		ELSE IF County_Code < 100 THEN 
			County_FIPS_Code = "0" || PUT(County_Code, 2.);
		ELSE IF County_Code < 1000 THEN 
			County_FIPS_Code = PUT(County_Code, 3.);
	 FIPS_County = StateFP || County_FIPS_Code;
RUN;

/*-------------------------------------------------------------------*/
/* Calculate Average Number of stores by type                        */
/*-------------------------------------------------------------------*/

DATA work.SNAPRetailTypeCY&fileyear REPLACE;
	SET work.SNAPRetailTypeCY&fileyear;
	MeanCount&fileyear = Mean(OF Month:);
RUN;

DATA work.SNAPRetailTypeCY&fileyear REPLACE;
	Retain
		FIPS_County
		Year
		StoreType
		MeanCount&fileyear;
	SET work.SNAPRetailTypeCY&fileyear;
Run;

/*-------------------------------------------------------------------*/
/* Drop variables and transpose by store type                        */
/*-------------------------------------------------------------------*/

DATA work.MeanStoreCnt&fileyear REPLACE;
	SET work.SNAPRetailTypeCY&fileyear
	(Keep = 	
		FIPS_County
		Year
		StoreType
		MeanCount&fileyear
		StateFP);
	If StateFP GT '';
Run;

/*-------------------------------------------------------------------*/
/*  Transpose Based on StoreType Variables                           */
/*-------------------------------------------------------------------*/
PROC SORT DATA = work.MeanStoreCnt&fileyear;
	By FIPS_County StoreType;
RUN;

/* To check data I do not want to transpose the data 
PROC Transpose Data = work.MeanStoreCnt&fileyear
	Out = work.MeanStoreCntWide&fileyear prefix = Mean;
	By FIPS_County;
	ID StoreType;
	Var MeanCount&fileyear;
RUN;

/*-------------------------------------------------------------------*/
/* Add County Name for peace of mind                                 */
/*-------------------------------------------------------------------*/
* Add State FIPS code to Store Type Data;
PROC SORT DATA = work.FIPS_county;
	By FIPS_County; 
RUN;
PROC SORT DATA = work.MeanStoreCnt&fileyear;
	By FIPS_County;
RUN;
DATA work.MeanStoreCnt&fileyear REPLACE;
	MERGE work.MeanStoreCnt&fileyear work.FIPS_county;
	By FIPS_County;
RUN;

Data work.MeanStoreCnt&fileyear Replace;
	Set work.MeanStoreCnt&fileyear;
	year=&fileyear;
	*drop _name_;
run; 

Data work.MeanStoreCnt&fileyear Replace;
	Set work.MeanStoreCnt&fileyear;
	If County_FIPS_Code NE '000';
run; 

Data work.MeanStoreCnt&fileyear Replace;
	Retain
		FIPS_County
		year
		CountyName2
		State
		StateFP
		StoreType
		MeanCount&fileyear;
	Set work.MeanStoreCnt&fileyear;
run; 


Data work.MeanStoreCnt&fileyear Replace;
	Set work.MeanStoreCnt&fileyear
	(KEEP = 
		FIPS_County
		year
		CountyName2
		State
		StateFP
		StoreType
		MeanCount&fileyear);
	StoreCount = MeanCount&fileyear;
	Drop MeanCount&fileyear;
run; 
/*-------------------------------------------------------------------*/
/*  Convert Missing Means to 0                                       */
/*-------------------------------------------------------------------*/
Data work.MeanStoreCnt&fileyear Replace;
	Set work.MeanStoreCnt&fileyear;
	If StoreCount = . THEN StoreCount = 0;
	/*
	If MeanSS = . THEN MeanSS = 0;
	If MeanSM = . THEN MeanSM = 0;
	If MeanCS = . THEN MeanCS = 0;
	If MeanCO = . THEN MeanCO = 0;
	If MeanDR = . THEN MeanDR = 0;
	If MeanFV = . THEN MeanFV = 0;
	If MeanSE = . THEN MeanSE = 0;
	If MeanSG = . THEN MeanSG = 0;
	If MeanBB = . THEN MeanBB = 0;
	If MeanLG = . THEN MeanLG = 0;
	If MeanME = . THEN MeanME = 0;
	If MeanMG = . THEN MeanMG = 0;
	If MeanUU = . THEN MeanUU = 0;
	If MeanMC = . THEN MeanMC = 0;
	If MeanDF = . THEN MeanDF = 0;
	If MeanBC = . THEN MeanBC = 0;
	If MeanFM = . THEN MeanFM = 0;
	If MeanWH = . THEN MeanWH = 0;
	If RetailTotal = . THEN RetailTotal = 0;
	*/
run; 

/*-------------------------------------------------------------------*/
/*  Append File to Master List                                       */
/*-------------------------------------------------------------------*/

PROC APPEND BASE = work.SNAPStoreCount&FYear._&LYear
	DATA = work.MeanStoreCnt&fileyear FORCE;
RUN;

PROC SORT DATA = work.SNAPStoreCount&FYear._&LYear;
	BY FIPS_County Year;
RUN;

%mend ImportStoreTypeData;
/*-------------------------------------------------------------------*/
/* Delete the existing panel dataset before running IMPORT Macro     */
/*-------------------------------------------------------------------*/

PROC datasets library=work NOLIST;
	DELETE SNAPStoreCount&FYear._&LYear;
Run;
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

/*-------------------------------------------------------------------*/
/* Run Import SNAP Retail Count Years from first to last years       */
/*-------------------------------------------------------------------*/

%ARRAY(StoreCountYears, VALUES=&FYEAR-&LYEAR);
%Do_Over(StoreCountYears, MACRO=ImportStoreTypeData);

/*-------------------------------------------------------------------*/
/* Export Data to USDA SAS Libary                                    */
/*-------------------------------------------------------------------*/

Data work.SNAPStoreCount&FYear._&LYear Replace;
	Retain 
		FIPS_county
		year
		State
		StateFP
		CountyName2
		StoreType
		StoreCount;
	Set work.SNAPStoreCount&FYear._&LYear;
run;

/*-------------------------------------------------------------------*/
/* Label Variables                                                   */
/*-------------------------------------------------------------------*/
/*
Data USDA.SNAPStoreCount&FYear._&LYear Replace;
	Set work.SNAPStoreCount&FYear._&LYear;
	Label
		MeanSS = "Super Store/Chain Store"
		MeanSM = "Supermarket"
	    MeanCS = "Convenience Store"
	    MeanCO = "Combination Grocery/Other"
	    MeanDR = "Delivery Route"
		MeanFV = "Specialty Food Store - Fruits/Vegetables"
		MeanSE = "Specialty Food Store - Seafood Products"
		MeanSG = "Small Grocery Store"
		MeanBB = "Specialty Food Store - Bakery/Bread"
		MeanLG = "Large Grocery Store"
		MeanME = "Specialty Food Store – Meat/Poultry Products"
		MeanMG = "Medium Grocery Store"
		MeanUU = "Unkown" 
		MeanMC = "Military Commissary"
		MeanDF = "Direct Marketing Farmer"
		MeanBC = "Non-Profit Food Buying Cooperative"
		MeanFM = "Farmers’ Market"
		MeanWH = "Wholesaler"
run; 
*Not clear How UU should be labeled;

Proc Sort data = USDA.SNAPStoreCount&FYear._&LYear
	out = USDA.SNAPStoreCount&FYear._&LYear;
	by FIPS_county year;
Run;
*/
%MEND ImportSDAStoreCounts;

/*-------------------------------------------------------------------*/
/* Run Macro Here                                                    */
/*-------------------------------------------------------------------*/
/*-------------------------------------------------------------------*/
/* Important Folder Locations                                        */
/*-------------------------------------------------------------------*/

%LET dd_data = C:\Users\Nathanael\Dropbox\MyData\;
%LET dd_SASLib = C:\Users\Nathanael\MySASLib\;
%LET Include_prog = C:\Users\Nathanael\Dropbox\MyPrograms\;

%ImportUSDAStoreCounts(
   FYear = 2005,
   LYear = 2012);


/*-------------------------------------------------------------------*/
/* Aggregate Store Count Data by Year and Store Type                 */
/*-------------------------------------------------------------------*/

/* Drop Missing Store Type Data */
DATA work.ST_Totals&FYear._&LYear REPLACE;
	Set work.SNAPStoreCount&FYear._&LYear;
	If storetype = "" then delete;
Run;

PROC SORT DATA = work.ST_Totals&FYear._&LYear;
	BY Year StoreType;
RUN;

* Generate a table that sums GEOLevel-to-GEOLevel data;
DATA work.ST_Totals&FYear._&LYear REPLACE;
	Set work.ST_Totals&FYear._&LYear;
	BY Year StoreType;
	IF first.year THEN DO;
		total_retail = 0;
		END;
		IF first.StoreType THEN DO;
			sum_storecount = 0; 
		END;
	sum_storecount + storecount;
	total_retail + storecount;
	If last.storeType Then Output; 
RUN;

DATA work.ST_Totals&FYear._&LYear REPLACE;
	Set work.ST_Totals&FYear._&LYear
	(Keep =
		year
		StoreType
		sum_storecount
		total_retail);
   attrib 	sum_storecount format = comma12.0 label = "Calender Year Store Count by Type"
			total_retail format = comma12.0 label = "Calender Year Store Count";
RUN;

/*-------------------------------------------------------------------*/
/*  Transpose Based on Year Variables                                */
/*-------------------------------------------------------------------*/
/* Want to compare the data that was emailed from RPDMHQ to the data
published in the annual reports */

PROC SORT DATA = work.ST_Totals&FYear._&LYear;
	By StoreType year;
RUN;

PROC Transpose Data = work.ST_Totals&FYear._&LYear
	Out = work.ST_TotalsWide&FYear._&LYear prefix = CY;
	By StoreType;
	ID Year;
	Var sum_storecount;
RUN;

Data work.ST_TotalsWide&FYear._&LYear Replace;
	Set work.ST_TotalsWide&FYear._&LYear;
	drop _name_;
	drop _LABEL_;
run; 
/*-------------------------------------------------------------------*/
/* Aggregate Store Count Data by Year, Region and Store Type         */
/*-------------------------------------------------------------------*/

/* USDA BRD Regions
Region	StateABBR	State
MARO	Delaware
MARO	District of Columbia
MARO	Maryland
MARO	New Jersey
MARO	Pennsylvania
MARO	Virgin Islands
MARO	Virginia
MARO	West Virginia
MPRO	Colorado
MPRO	Iowa
MPRO	Kansas
MPRO	Missouri
MPRO	Montana
MPRO	Nebraska
MPRO	North Dakota
MPRO	South Dakota
MPRO	Utah
MPRO	Wyoming
MWRO	Illinois
MWRO	Indiana
MWRO	Michigan
MWRO	Minnesota
MWRO	Ohio
MWRO	Wisconsin
NERO	Connecticut
NERO	Maine
NERO	Massachusetts
NERO	New Hampshire
NERO	New York
NERO	Rhode Island
NERO	Vermont
SERO	Alabama
SERO	Florida
SERO	Georgia
SERO	Kentucky
SERO	Mississippi
SERO	North Carolina
SERO	South Carolina
SERO	Tennessee
SWRO	Arkansas
SWRO	Louisiana
SWRO	New Mexico
SWRO	Oklahoma
SWRO	Texas
WRO		Alaska
WRO		Arizona
WRO		California
WRO		Guam
WRO		Hawaii
WRO		Idaho
WRO		Nevada
WRO		Oregon
WRO		Washington

