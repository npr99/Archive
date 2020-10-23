 /*-------------------------------------------------------------------*/
 /*       Program for Createing Within County Redemption wcr          */
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
 /* Date Last Updated: 05MAY2014                                      */
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
 /* Supplemental Nutrition Assistance Program (SNAP) Data System      */
 /*       Retreived from http://www.ers.usda.gov/datafiles/           */
 /*       Supplemental_Nutrition_Assistance_Program_SNAP_Data_System/ */
 /*       County_Data.xls on Oct 19, 2013                             */
 /*-------------------------------------------------------------------*/

* Use a trailing @, then keep specific Census Blocks;
* Using INFILE to read in Comma-seperated value files, first 
obseravtion has headers therefore will be skipped (FIRSTOBS = 2)
Going to use Delimiter-Senstive DATA option (DSD) just in case missing 
values exist;
%LET dd_data = C:\Users\Nathanael\Dropbox\MyData\;
%LET dd_SASLib = C:\Users\Nathanael\MySASLib\;
%LET Include_macros = C:\Users\Nathanael\Dropbox\MyPrograms\Macros_SAS\;

* Found these text utilities that might be useful from 
	http://www2.sas.com/proceedings/sugi30/029-30.pdf
	include add_string macro;
%INCLUDE "&Include_macros.TextUtilityMacros.sas";
* Found these Tight Looping with Macro Arrays from
	http://www.sascommunity.org/wiki/Tight_Looping_with_Macro_Arrays
	inlcude Array, Do_Over Macros;
%INCLUDE "&Include_macros.Clay-TightLooping-macros\NUMLIST.sas";
%INCLUDE "&Include_macros.Clay-TightLooping-macros\ARRAY.sas";
%INCLUDE "&Include_macros.Clay-TightLooping-macros\DO_OVER.sas";

LIBNAME Usda "&dd_SASLib.Usda";

/*-------------------------------------------------------------------*/
/* Import Primary Files from Original Source                         */
/*-------------------------------------------------------------------*/

* Import SNAP Data System Time Series Data;
* Data includes estimated annual benefits distributed to counties;
* Technical Documentation C:\Users\Nathanael\Dropbox\MyData\USDA\
  SNAP_TimeSeriesDataCounty_Data Documentation.pdf;

/*********************************************************************
* Problem to resolve - Benefit data is fiscal year but redemption    *
* data is calendar. May need to use Texas data which is monthly      *

* State-level data through 2006 represent a 12-month average, with a 6-month delay. For instance,
the values presented for 1995 are based on the monthly average between July 1995 and June
1996. Since 2007, the data are based on the Federal fiscal year for example, the values for 2010
are based on the monthly average between October 2009 and September 2010;
**********************************************************************/


PROC IMPORT DATAFile = "&dd_data.USDA_ReadOnly\County_Data.xls" DBMS = XLS 
OUT = USDA.CountyTimeSeries REPLACE;
	RANGE = "County$A1:DQ3197";
	MIXED = YES;
RUN;
* Import SNAP Redemption data by calendar year by state by county;
* The original SNAP Redemption data had incorrect values for 2005;

PROC IMPORT DATAFile = "&dd_data.USDA_ReadOnly\
CY 2005 - CY 2012 Redemptions by ST-County - Redacted v2.xlsx" DBMS = XLSX 
OUT = USDA.CountyRedemptions REPLACE;
	RANGE = "Sheet$A2:E24983";
	MIXED = YES;
RUN;

/*-------------------------------------------------------------------*/
/* Add common County ID count to Redemption files                    */
/*-------------------------------------------------------------------*/

* Need to add a County FIPS code to County Redemptions;
* Import Census FIPS Code list Retreived from
www.census.gov/2010census/xls/fips_codes_website.xls;

PROC IMPORT DATAFile = "&dd_data.Census\fips_codes_website.xlsx" DBMS = XLSX 
OUT = FIPS_Codes_ALL REPLACE;
	MIXED = YES;
RUN;
* Note:
	* LA, AK, CT,DC, RI do not call counties "counties";
	* LA county = Parish;
	* AK county = does not have one name (use unique values);
	* CT county = does not have one entity_description;
	* DC county = city;
	* RI county = does not have one name (use unique values);
* Need to sort FIPS codes so that counties and other entities similar to counties
are first in the list;
PROC SORT DATA = FIPS_Codes_ALL OUT = FIPS_Codes_Sort;
	by State_FIPS_Code County_FIPS_Code FIPS_Entity_Code;
Run;
* Generate table with only unique stae and county FIPS codes;
PROC SORT DATA = FIPS_Codes_Sort NODUPKEY OUT = FIPS_Codes_County;
	by State_FIPS_Code County_FIPS_Code;
Run;
* Perform a simple concatenation to create FIPS_County unique with State;
DATA USDA.FIPS_County;
	SET FIPS_Codes_County;
	State = State_Abbreviation;
    FIPS_County = State_FIPS_Code || County_FIPS_Code;
RUN;
* Generate table with only State FIPS codes;
PROC SORT DATA = USDA.FIPS_County NODUPKEY OUT = USDA.FIPS_State;
	By State_FIPS_Code; 
RUN;
DATA USDA.FIPS_State REPLACE;
	SET USDA.FIPS_State (KEEP = State State_FIPS_Code);
RUN;

* Add FIPS code to Redemption data;
PROC SORT DATA = USDA.FIPS_State;
	By State; 
RUN;
PROC SORT DATA = USDA.CountyRedemptions;
	By State; 
RUN;
DATA USDA.CountyRedemptions REPLACE;
	MERGE USDA.CountyRedemptions USDA.FIPS_State;
	BY State;
RUN;
* Convert County_Code in redemption data to 3 digit character;
* Perform a simple concatenation to create FIPS_County unique with State; 
DATA USDA.CountyRedemptions REPLACE;
	SET USDA.CountyRedemptions;
	IF County_Code < 10 THEN County_FIPS_Code = "00" || PUT(County_Code, 1.);
		ELSE IF County_Code < 100 THEN 
			County_FIPS_Code = "0" || PUT(County_Code, 2.);
		ELSE IF County_Code < 1000 THEN 
			County_FIPS_Code = PUT(County_Code, 3.);
	 FIPS_County = State_FIPS_Code || County_FIPS_Code;
RUN;

/*-------------------------------------------------------------------*/
/* Reorganize Redemption data to match Benefit Time Series Data      */
/*-------------------------------------------------------------------*/

* Transpose CountyRedemptions so years are variables;
* This will match the TimeSeries Data;
PROC SORT DATA = USDA.CountyRedemptions;
	BY FIPS_County State County_Name; 
RUN;
PROC TRANSPOSE DATA = USDA.CountyRedemptions OUT = USDA.CountyRedemptions_Years;
    BY FIPS_County State County_Name;
	ID Year;
	VAR Redemptions;
Run;
* Convert Redemption Data into dollar amounts;
* Replace "redacted" values with code similar to Time Series Data;
* -9996 Data missing due to data suppression by USDA;

* Years covered by redemption data;
%LET YEARS_Red = 05 06 07 08 09 10 11 12;

DATA USDA.CountyRedemptions_Years REPLACE;
	SET USDA.CountyRedemptions_Years (DROP = _NAME_ _LABEL_);
	ARRAY CharYear[*] %add_string(&YEARS_Red, _20, location=prefix);
	ARRAY PRGREDXX[*] %add_string(&YEARS_Red, PRGRED, location=prefix);
	DO i=1 to dim(CharYear); 
	* Check to see if Remption Data was redacted by USDA;
	* Convert CharYear from Character to dollars;
	IF CharYear{i} NE "redacted" THEN PRGREDXX{i} = INPUT(CharYear{i}, DOLLAR12.2);
		ELSE PRGREDXX{i} = -9996;
	END;
Run;
DATA USDA.CountyRedemptions_Years REPLACE;
	SET USDA.CountyRedemptions_Years (DROP = _20:);
Run;

/*-------------------------------------------------------------------*/
/* Merge Redemption data with Benefit Time Series Data by County FIPS*/
/*-------------------------------------------------------------------*/

* Set Time Series data variables to match Redemption data;
* Years that match redemption data;
%LET YEARS_Ben = 05 06 07 08 09 10 11;

DATA USDA.CountyBenefits REPLACE;
	SET USDA.CountyTimeSeries (KEEP = FIPS FIPSTXT COFIPS CODEF CONAME 
	STATE_CD STFIPS URBCODE METRO POP: PRGBEN05 PRGBEN06 PRGBEN07 PRGBEN08
	PRGBEN09 PRGBEN10 PRGBEN11);
	FIPS_County = INPUT(FIPSTXT, $5.);
	ARRAY PRGBENXX[*] %add_string(&YEARS_Ben, PRGBEN, location=prefix);
	ARRAY CNTYBENXX[*] %add_string(&YEARS_Ben, CNTYBEN, location=prefix);
	DO i=1 to dim(PRGBENXX); 
	* Check to see if PRGBENxx has a coding flag;
	* Convert PRGBENxx from (in thousands) to in dollars;
	IF PRGBENXX{i} >= 0 THEN CNTYBENXX{i} = PRGBENXX{i} * 1000;
		ELSE CNTYBENXX{i} = PRGBENXX{i};
	END;
	* The orginal file includes several non-county estimates in
		most of these are in VA but also islands;
	IF COFIPS > 0;
Run;
PROC SORT DATA = USDA.CountyBenefits;
	By FIPS_County; 
RUN;
PROC SORT DATA = USDA.CountyRedemptions_Years;
	By FIPS_County; 
RUN;

* Table with both benefit and redemption data;
DATA USDA.CountyBenRed REPLACE;
	MERGE USDA.CountyBenefits USDA.CountyRedemptions_Years;
	BY FIPS_County;
RUN;

* Reviewing output notes:
- Missing values such as Glasscock county Texas appear to be b/c there are no
	retailers in the County
- Virginia has many missing values but it looks like that is b/c many VA
	reports in Benefits were done by city. Added line to remove non-counties
	from benefit table;

/*-------------------------------------------------------------------*/
/*  Creating Within County Redemption wcr                            */
/*-------------------------------------------------------------------*/

%LET YEARS_Both = 05 06 07 08 09 10 11;

DATA USDA.CountyWCR REPLACE;
	SET USDA.CountyBenRed (KEEP = FIPS FIPS_COUNTY COFIPS CODEF CONAME 
	STATE_CD STFIPS URBCODE METRO CNTYBEN: PRGRED:);
	ARRAY WCRXX[*] %add_string(&YEARS_Both, WCR, location=prefix);
	ARRAY CNTYBENXX[*] %add_string(&YEARS_Both, CNTYBEN, location=prefix);
	ARRAY PRGRED[*] %add_string(&YEARS_Both, PRGRED, location=prefix);
	DO i=1 to dim(WCRXX); 
	* Check to see if CNTYBENXX PRGRED have real values;
	* If either do not have real values then Within County Redemption is equal to
	the ratio of total within-county redemptions to total within-county benefit 
	distributions in the county in each year;
	IF CNTYBENXX{i} >= 0 AND PRGRED{i} >= 0 THEN WCRXX{i} = PRGRED{i} / CNTYBENXX{i};
		* Check to see if the redemption data was redacted by USDA;
		ELSE IF PRGRED{i} < 0 THEN WCRXX{i} = PRGRED{i};
		* Check to see if the benefit data had a code;
		ELSE IF CNTYBENXX{i} < 0 THEN WCRXX{i} = CNTYBENXX{i};
	END;
RUN;
/*-------------------------------------------------------------------*/
/*  Creating Within County Redemption wcr                            */
/*  For this table I am going to make codes = missing                */
/*-------------------------------------------------------------------*/

%LET YEARS_Both = 05 06 07 08 09 10 11;

DATA USDA.CountyWCR_Missing REPLACE;
	SET USDA.CountyBenRed (KEEP = FIPS FIPS_COUNTY COFIPS CODEF CONAME 
	STATE_CD STFIPS URBCODE METRO CNTYBEN: PRGRED:);
	ARRAY WCRXX[*] %add_string(&YEARS_Both, WCR, location=prefix);
	ARRAY CNTYBENXX[*] %add_string(&YEARS_Both, CNTYBEN, location=prefix);
	ARRAY PRGRED[*] %add_string(&YEARS_Both, PRGRED, location=prefix);
	DO i=1 to dim(WCRXX); 
	* Check to see if CNTYBENXX PRGRED have real values;
	* If either do not have real values then Within County Redemption is equal to
	the ratio of total within-county redemptions to total within-county benefit 
	distributions in the county in each year;
	IF CNTYBENXX{i} >= 0 AND PRGRED{i} >= 0 THEN WCRXX{i} = PRGRED{i} / CNTYBENXX{i};
		* Check to see if the redemption data was redacted by USDA;
		ELSE IF PRGRED{i} < 0 THEN WCRXX{i} = MISSING;
		* Check to see if the benefit data had a code;
		ELSE IF CNTYBENXX{i} < 0 THEN WCRXX{i} = MISSING;
	END;
	* Virginia is causing problems - the inclusion of cities and counties makes the 
	two datasets not match;
	IF STATE_CD NE "VA";
RUN;

/*-------------------------------------------------------------------*/
/*  Create histgrams and summary tables of WCR                       */
/*-------------------------------------------------------------------*/
PROC MEANS DATA = USDA.CountyWCR_Missing MAXDEC = 2 EXCLNPWGT;
* Weight by middle income jobs and exclude zero weight;
	VAR WCR10;
	TITLE 'Within County Redemptions 2010';
RUN;
PROC SGPLOT DATA = USDA.CountyWCR_Missing;
	HISTOGRAM WCR10 / NBINS = 20 SHOWBINS SCALE = COUNT;
Run;


%MACRO HistogramState(HistWCR);
DATA CountyWCR_HistState REPLACE;
	SET USDA.CountyWCR_Missing;
	IF STATE_CD = "TX";
RUN;
PROC SGPLOT DATA = CountyWCR_HistState;
	HISTOGRAM &HistWCR / NBINS = 20 SHOWBINS SCALE = Count;
	TITLE 'Texas Within County Redemptions &HistWCR';
Run;
%MEND HistogramState;
* Going to try %ARRAY %DO_OVER found on http://www2.sas.com/proceedings/sugi31/040-31.pdf;
%ARRAY(WCRYEARS,VALUES=WCR05-WCR10);
%DO_OVER(WCRYEARS,MACRO=HistogramState);


%MACRO HistogramState(HistWCR=, HistState=, StateTitle=);
DATA CountyWCR_HistState REPLACE;
	SET USDA.CountyWCR_Missing;
	IF STATE_CD = &HistState;
RUN;
%ARRAY(WCRYEARS,VALUES=&HistWCR);
%DO I=1 %to &WCRYEARSN;
	PROC SGPLOT DATA = CountyWCR_HistState;
		HISTOGRAM &&WCRYEARS&I / NBINS = 20 SHOWBINS SCALE = Count;
		TITLE '&StateTitle Within County Redemptions &&WCRYEARS&I';
	Run;
%END;
PROC SGPLOT DATA = CountyWCR_HistState;
	Density WCR05 / LEGENDLABEL = "2005";
	Density WCR06 / LEGENDLABEL = "2006";
	Density WCR07 / LEGENDLABEL = "2007";
	Density WCR08 / LEGENDLABEL = "2008";
	Density WCR09 / LEGENDLABEL = "2009";
	Density WCR10 / LEGENDLABEL = "2010";
	Density WCR11 / LEGENDLABEL = "2011";
	Density WCR12 / LEGENDLABEL = "2012";
	TITLE '&StateTitle Within County Redemptions 2005-2012';
Run;
PROC SGPLOT DATA = CountyWCR_HistState;
	Density WCR05 / Type = kernel LEGENDLABEL = "2005";
	Density WCR06 / Type = kernel LEGENDLABEL = "2006";
	Density WCR07 / Type = kernel LEGENDLABEL = "2007";
	Density WCR08 / Type = kernel LEGENDLABEL = "2008";
	Density WCR09 / Type = kernel LEGENDLABEL = "2009";
	Density WCR10 / Type = kernel LEGENDLABEL = "2010";
	Density WCR11 / Type = kernel LEGENDLABEL = "2011";
	Density WCR12 / Type = kernel LEGENDLABEL = "2012";
	TITLE '&StateTitle Within County Redemptions 2005-2012';
Run;
%MEND HistogramState;
* Going to try %ARRAY %DO_OVER found on http://www2.sas.com/proceedings/sugi31/040-31.pdf;
%HistogramState(HistWCR=WCR05-WCR10, HistState = "PA", StateTitle= Pennsylvania);
%HistogramState(HistWCR=WCR05-WCR10, HistState = "TX", StateTitle= Texas);
%HistogramState(HistWCR=WCR05-WCR10, HistState = "OK", StateTitle= Oklahoma);
%HistogramState(HistWCR=WCR05-WCR10, HistState = "LA", StateTitle= Louisana);
%HistogramState(HistWCR=WCR05-WCR10, HistState = "NY", StateTitle= New York);
%HistogramState(HistWCR=WCR05-WCR10, HistState = "CA", StateTitle= California);
%HistogramState(HistWCR=WCR05-WCR10, HistState = "LA", StateTitle= Louisana);
%HistogramState(HistWCR=WCR05-WCR10, HistState = "OR", StateTitle= Oregon);
%HistogramState(HistWCR=WCR05-WCR10, HistState = "NM", StateTitle= New Mexico);
%HistogramState(HistWCR=WCR05-WCR10, HistState = "TN", StateTitle= Tennessee);

/*-------------------------------------------------------------------*/
/*  Creating TXHHS Data for 2005-2012                               */
/*-------------------------------------------------------------------*/

/*********************************************************************
* Problem to resolve - Benefit data is fiscal year but redemption    *
* data is calendar. May need to use Texas data which is monthly      *

* State-level data through 2006 represent a 12-month average, with a 6-month delay. For instance,
the values presented for 1995 are based on the monthly average between July 1995 and June
1996. Since 2007, the data are based on the Federal fiscal year for example, the values for 2010
are based on the monthly average between October 2009 and September 2010;
**********************************************************************/

	
* Procedure to look at The Texas Health and Human Services Commission reports 
statistics on SNAP Cases by county from September 2005 through October 2013;
* Data source: http://www.hhsc.state.tx.us/research/TANF-FS-results.asp;
* Source files are in Excel Format and have a unique format;
* This program imports the Excel files, cleans up the files so that they 
can be merged into a signle file with totals for the year by county;

LIBNAME TXHHS "&dd_SASLib.TXHHS";
%MACRO Create_MonthlyTXHHSFile(TXHHSfiles);
PROC IMPORT DATAFile = "&dd_data.TXHHSC\SnapCases\&TXHHSfiles..xls" 
	DBMS = XLS OUT = TXHHSTemp_file REPLACE;
	DATAROW=3;
	GETNAMES = NO;
	MIXED = YES;
RUN;

DATA SASTXHHS_temp REPLACE;
	SET TXHHSTemp_file;
	IF A = "" THEN DELETE;
	IF A =: "MONTHLY" THEN DELETE;
	IF A =: "Denials" THEN DELETE;
	IF A =: "State Total" THEN DELETE;
	IF A = "County Name" Then Delete;
	IF A = "*TIERS 630 Denials" Then Delete;
	IF B = "" THEN DELETE;
	County_Name2 = input(A, $CHAR21.);
	NumCases_&TXHHSfiles = input(B,comma15.);
	NumRecipients_&TXHHSfiles = input(C,comma15.);
	RA01_&TXHHSfiles = input(D,comma15.);
	RA02_&TXHHSfiles = input(E,comma15.);
	RA03_&TXHHSfiles = input(F,comma15.);
	RA04_&TXHHSfiles = input(G,comma15.);
	RA05_&TXHHSfiles = input(H,comma15.);
	CNTYBEN&TXHHSfiles = input(I,comma15.);
	APayments_&TXHHSfiles = input(J,comma15.);
	LABEL NumCases_&TXHHSfiles = "Number of Cases &TXHHSfiles"
		RA01_&TXHHSfiles = "Recipients Age <5 &TXHHSfiles"
		RA02_&TXHHSfiles = "Recipients Age 5-17 &TXHHSfiles"
		RA03_&TXHHSfiles = "Recipients Age 18-59 &TXHHSfiles"
		RA04_&TXHHSfiles = "Recipients Age 60-64 &TXHHSfiles"
		RA05_&TXHHSfiles = "Recipients Age 65+ &TXHHSfiles"
		CNTYBEN&TXHHSfiles = "Total FB Payments &TXHHSfiles"
		APayments_&TXHHSfiles = "Average Payment/Case &TXHHSfiles";
RUN;
* Drop the original variables to create an unsorted or messy temp file;
DATA SASTXHHS_temp_messy REPLACE;
	SET SASTXHHS_temp (DROP = A B C D E F G H I J);
RUN;
* Data needs to be sorted before the files can be merged;
PROC SORT DATA = SASTXHHS_temp_messy OUT = TXHHS_&TXHHSfiles;
	BY County_Name2;
RUN;

%MEND Create_MonthlyTXHHSFile;

%MACRO Create_YearTXHHSFile(TXHHSYear);
DATA TXHHS_&TXHHSYear REPLACE;
	MERGE 
		TXHHS_&TXHHSYear.01-TXHHS_&TXHHSYear.12;
	BY County_Name2;
RUN;
DATA TXHHS.TXHHS_CountyTotals&TXHHSYear REPLACE;
	SET TXHHS_&TXHHSYear;
	NumCases_&TXHHSYear = SUM(OF NumCases_:);
	NumRecipients_&TXHHSYear = SUM(OF NumRecipients_:);
	RA01_&TXHHSYear = SUM(OF RA01_:);
	RA02_&TXHHSYear = SUM(OF RA02_:);
	RA03_&TXHHSYear = SUM(OF RA03_:);
	RA04_&TXHHSYear = SUM(OF RA04_:);
	RA05_&TXHHSYear = SUM(OF RA05_:);
	CNTYBEN&TXHHSYear = SUM(OF CNTYBEN:);
	APayments_&TXHHSYear= SUM(OF APayments_:);
RUN;
DATA TXHHS.TXHHS_CountyTotals&TXHHSYear REPLACE;
	SET TXHHS.TXHHS_CountyTotals&TXHHSYear
	(KEEP=County_Name2 RA01_&TXHHSYear RA02_&TXHHSYear RA03_&TXHHSYear
	RA04_&TXHHSYear RA05_&TXHHSYear CNTYBEN&TXHHSYear
	APayments_&TXHHSYear);
RUN;
%MEND Create_YearTXHHSFile;

*TXHHSFiles are available for each month 2006 to 2013;
%ARRAY(TXHHSYearsMonths, VALUES=200601-200612);
%Do_Over(TXHHSYearsMonths, MACRO=Create_MonthlyTXHHSFile);
%ARRAY(TXHHSYearsMonths, VALUES=200701-200712);
%Do_Over(TXHHSYearsMonths, MACRO=Create_MonthlyTXHHSFile);
%ARRAY(TXHHSYearsMonths, VALUES=200801-200812);
%Do_Over(TXHHSYearsMonths, MACRO=Create_MonthlyTXHHSFile);
%ARRAY(TXHHSYearsMonths, VALUES=200901-200912);
%Do_Over(TXHHSYearsMonths, MACRO=Create_MonthlyTXHHSFile);
%ARRAY(TXHHSYearsMonths, VALUES=201001-201012);
%Do_Over(TXHHSYearsMonths, MACRO=Create_MonthlyTXHHSFile);
%ARRAY(TXHHSYearsMonths, VALUES=201101-201112);
%Do_Over(TXHHSYearsMonths, MACRO=Create_MonthlyTXHHSFile);
%ARRAY(TXHHSYearsMonths, VALUES=201201-201212);
%Do_Over(TXHHSYearsMonths, MACRO=Create_MonthlyTXHHSFile);
%ARRAY(TXHHSYearsMonths, VALUES=201301-201312);
%Do_Over(TXHHSYearsMonths, MACRO=Create_MonthlyTXHHSFile);
%ARRAY(TXHHSYears, VALUES=2006-2013);
%Do_Over(TXHHSYears, MACRO=Create_YearTXHHSFile);

* Creat one file with each year total benefits by county;
* Will Merge this file with USDA Redemption Data;
DATA TXHHS.TXHHS_Benefits REPLACE;
	MERGE 
		TXHHS.TXHHS_CountyTotals2006-TXHHS.TXHHS_CountyTotals2013;
	BY County_Name2;
RUN;
DATA TXHHS.TXHHS_Benefits REPLACE;
	SET TXHHS.TXHHS_Benefits
	(KEEP = County_Name2 CNTYBEN:);
	IF CNTYBEN2006 GE 0;
RUN;

*Add FIPS_CODE to TXHHS County Data;
DATA TXHHS.FIPS_County;
	SET USDA.FIPS_County (KEEP = GU_Name State_FIPS_Code FIPS_County);
	IF State_FIPS_Code = 48;
	County_Name2 = GU_Name;
RUN;
* Data needs to be sorted before the files can be merged;
PROC SORT DATA = TXHHS.FIPS_County OUT = TXHHS.FIPS_County;
	BY County_Name2;
RUN;
DATA TXHHS.TXHHS_FIPSBenefits REPLACE;
	MERGE 
		TXHHS.FIPS_County TXHHS.TXHHS_Benefits;
	BY County_Name2;
RUN;

/*-------------------------------------------------------------------*/
/*  Merge TXHHS Data for 2006-2013 with Redemptions Data             */
/*-------------------------------------------------------------------*/

* Create Redemption Table for Texas Only;
DATA USDA.TXCountyRedemptions_Years;
	SET USDA.CountyRedemptions_Years;
	IF State = "TX";
RUN;

PROC SORT DATA = TXHHS.TXHHS_FIPSBenefits;
	By FIPS_County; 
RUN;
PROC SORT DATA = USDA.TXCountyRedemptions_Years;
	By FIPS_County; 
RUN;

* Table with both benefit and redemption data;
DATA USDA.TXCountyBenRed REPLACE;
	MERGE TXHHS.TXHHS_FIPSBenefits USDA.TXCountyRedemptions_Years;
	BY FIPS_County;
RUN;

/*-------------------------------------------------------------------*/
/*  Creating Within County Redemption wcr                            */
/*  For this table I am going to make codes = missing                */
/*-------------------------------------------------------------------*/
%LET YEARS_Both = 06 07 08 09 10 11 12;
DATA USDA.TXCountyWCR_Missing REPLACE;
	SET USDA.TXCountyBenRed (KEEP = State_FIPS_Code FIPS_County County_Name2
		CNTYBEN: PRGRED:);
	ARRAY WCRXX[*] %add_string(&YEARS_Both, WCR, location=prefix);
	ARRAY CNTYBENXX[*] %add_string(&YEARS_Both, CNTYBEN20, location=prefix);
	ARRAY PRGRED[*] %add_string(&YEARS_Both, PRGRED, location=prefix);
	DO i=1 to dim(WCRXX); 
	* Check to see if CNTYBENXX PRGRED have real values;
	* If either do not have real values then Within County Redemption is equal to
	the ratio of total within-county redemptions to total within-county benefit 
	distributions in the county in each year;
	IF CNTYBENXX{i} >= 0 AND PRGRED{i} >= 0 THEN WCRXX{i} = PRGRED{i} / CNTYBENXX{i};
		* Check to see if the redemption data was redacted by USDA;
		ELSE IF PRGRED{i} < 0 THEN WCRXX{i} = MISSING;
		* Check to see if the benefit data had a code;
		ELSE IF CNTYBENXX{i} < 0 THEN WCRXX{i} = MISSING;
	END;
RUN;

/*-------------------------------------------------------------------*/
/*  Create histgrams and summary tables of WCR                       */
/*-------------------------------------------------------------------*/
%MACRO HistogramTX(HistWCR);
%ARRAY(WCRYEARS,VALUES=&HistWCR);
%DO I=1 %to &WCRYEARSN;
	PROC SGPLOT DATA = USDA.TXCountyWCR_Missing;
		HISTOGRAM &&WCRYEARS&I / NBINS = 40 SHOWBINS SCALE = Count;
		TITLE 'Texas Within County Redemptions using TXHHS Data &&WCRYEARS&I';
	Run;
%END;
%MEND HistogramTX;
* Going to try %ARRAY %DO_OVER found on http://www2.sas.com/proceedings/sugi31/040-31.pdf;
%HistogramTX(HistWCR=WCR06-WCR12);

/*-------------------------------------------------------------------*/
/*  Transpose Data So that Years can be on one histogram             */
/*-------------------------------------------------------------------*/

Proc transpose data = USDA.TXCountyWCR_Missing out = TXCountyWCR_LongN Prefix = CNTYName;
	by FIPS_County;
	var County_Name2;
Run;

Proc transpose data = USDA.TXCountyWCR_Missing out = TXCountyWCR_LongB Prefix = CNTYBEN;
	by FIPS_County;
	var CNTYBEN2006-CNTYBEN2012;
Run;

Proc transpose data = USDA.TXCountyWCR_Missing out = TXCountyWCR_LongR Prefix = PRGRED;
	by FIPS_County;
	var PRGRED06-PRGRED12;
Run;

Proc transpose data = USDA.TXCountyWCR_Missing out = TXCountyWCR_LongW Prefix = WCR;
	by FIPS_County;
	var WCR06-WCR12;
Run;

Data USDA.TXCountyWCR_Long;
	merge TXCountyWCR_LongN (rename=(CNTYName1=County_Name) drop=_name_) 
	      TXCountyWCR_LongB (rename=(CNTYBEN1=CNTYBEN)) 
	      TXCountyWCR_LongR (rename=(PRGRED1=PRGRED) drop=_name_)
		  TXCountyWCR_LongW (rename=(WCR1=WCR) drop=_name_);
	by FIPS_County;
	year=input(substr(_name_, 8, 4), 4.);
	drop _name_;
run; 

/*-------------------------------------------------------------------*/
/*  Create histgram by years with density plots for WCR              */
/*-------------------------------------------------------------------*/

proc sort data = USDA.TXCountyWCR_Long;
  by Year;
run;

proc sgpanel data=USDA.TXCountyWCR_Long;
	Title 'Texas Within County Redemptions By Year';
 	panelby Year;
	colaxis label = "Within County Redemptions";
 	histogram WCR / NBINS = 40 SCALE = Count;
	density WCR;
	density WCR / type=kernel;
run;

/*********************************************************************
* Problem to resolve - Randall County Texas is a significant outlier
  In 2006 it seems to have 450% more redemptions than benefits
  Randall county splits Amarillo in half so it might be that the south 
  side of Amarillo had more stores and fewer SNAP participants
**********************************************************************/

	
* Procedure to look at The Texas Health and Human Services Commission reports 
statistics on SNAP Cases by county from September 2005 through October 2013;
* Data source: http://www.hhsc.state.tx.us/research/TANF-FS-results.asp;
* Source files are in Excel Format and have a unique format;
* This program imports the Excel files, cleans up the files so that they 
can be merged into a signle file with totals for the year by county;

LIBNAME TXHHS "&dd_SASLib.TXHHS";
%MACRO Create_MonthlyTXHHSFile(TXHHSfiles);
PROC IMPORT DATAFile = "&dd_data.TXHHSC\SnapCases\&TXHHSfiles..xls" 
	DBMS = XLS OUT = TXHHSTemp_file REPLACE;
	DATAROW=3;
	GETNAMES = NO;
	MIXED = YES;
RUN;

DATA SASTXHHS_temp REPLACE;
	SET TXHHSTemp_file;
	IF A NE "Randall" THEN DELETE; /* Checking to see why Randall County is an outlier */
	County_Name2 = input(A, $CHAR21.);
	NumCases_&TXHHSfiles = input(B,comma15.);
	NumRecipients_&TXHHSfiles = input(C,comma15.);
	RA01_&TXHHSfiles = input(D,comma15.);
	RA02_&TXHHSfiles = input(E,comma15.);
	RA03_&TXHHSfiles = input(F,comma15.);
	RA04_&TXHHSfiles = input(G,comma15.);
	RA05_&TXHHSfiles = input(H,comma15.);
	CNTYBEN&TXHHSfiles = input(I,comma15.);
	APayments_&TXHHSfiles = input(J,comma15.);
	LABEL NumCases_&TXHHSfiles = "Number of Cases &TXHHSfiles"
		RA01_&TXHHSfiles = "Recipients Age <5 &TXHHSfiles"
		RA02_&TXHHSfiles = "Recipients Age 5-17 &TXHHSfiles"
		RA03_&TXHHSfiles = "Recipients Age 18-59 &TXHHSfiles"
		RA04_&TXHHSfiles = "Recipients Age 60-64 &TXHHSfiles"
		RA05_&TXHHSfiles = "Recipients Age 65+ &TXHHSfiles"
		CNTYBEN&TXHHSfiles = "Total FB Payments &TXHHSfiles"
		APayments_&TXHHSfiles = "Average Payment/Case &TXHHSfiles";
RUN;
* Drop the original variables to create an unsorted or messy temp file;
DATA SASTXHHS_temp_messy REPLACE;
	SET SASTXHHS_temp (DROP = A B C D E F G H I J);
RUN;
* Data needs to be sorted before the files can be merged;
PROC SORT DATA = SASTXHHS_temp_messy OUT = TXHHS_&TXHHSfiles;
	BY County_Name2;
RUN;

%MEND Create_MonthlyTXHHSFile;

%MACRO Create_YearTXHHSFile(TXHHSYear);
DATA TXHHS_&TXHHSYear REPLACE;
	MERGE 
		TXHHS_&TXHHSYear.01-TXHHS_&TXHHSYear.12;
	BY County_Name2;
RUN;
DATA TXHHS.TXHHS_CountyTotals&TXHHSYear REPLACE;
	SET TXHHS_&TXHHSYear;
	NumCases_&TXHHSYear = SUM(OF NumCases_:);
	NumRecipients_&TXHHSYear = SUM(OF NumRecipients_:);
	RA01_&TXHHSYear = SUM(OF RA01_:);
	RA02_&TXHHSYear = SUM(OF RA02_:);
	RA03_&TXHHSYear = SUM(OF RA03_:);
	RA04_&TXHHSYear = SUM(OF RA04_:);
	RA05_&TXHHSYear = SUM(OF RA05_:);
	CNTYBEN&TXHHSYear = SUM(OF CNTYBEN:);
	APayments_&TXHHSYear= SUM(OF APayments_:);
RUN;
DATA TXHHS.TXHHS_CountyTotals&TXHHSYear REPLACE;
	SET TXHHS.TXHHS_CountyTotals&TXHHSYear
	(KEEP=County_Name2 RA01_&TXHHSYear RA02_&TXHHSYear RA03_&TXHHSYear
	RA04_&TXHHSYear RA05_&TXHHSYear CNTYBEN&TXHHSYear
	APayments_&TXHHSYear);
RUN;
%MEND Create_YearTXHHSFile;

*TXHHSFiles are available for each month 2006 to 2013;
%ARRAY(TXHHSYearsMonths, VALUES=200601-200612);
%Do_Over(TXHHSYearsMonths, MACRO=Create_MonthlyTXHHSFile);
%ARRAY(TXHHSYearsMonths, VALUES=200701-200712);
%Do_Over(TXHHSYearsMonths, MACRO=Create_MonthlyTXHHSFile);
%ARRAY(TXHHSYearsMonths, VALUES=200801-200812);
%Do_Over(TXHHSYearsMonths, MACRO=Create_MonthlyTXHHSFile);
%ARRAY(TXHHSYearsMonths, VALUES=200901-200912);
%Do_Over(TXHHSYearsMonths, MACRO=Create_MonthlyTXHHSFile);
%ARRAY(TXHHSYearsMonths, VALUES=201001-201012);
%Do_Over(TXHHSYearsMonths, MACRO=Create_MonthlyTXHHSFile);
%ARRAY(TXHHSYearsMonths, VALUES=201101-201112);
%Do_Over(TXHHSYearsMonths, MACRO=Create_MonthlyTXHHSFile);
%ARRAY(TXHHSYearsMonths, VALUES=201201-201212);
%Do_Over(TXHHSYearsMonths, MACRO=Create_MonthlyTXHHSFile);
%ARRAY(TXHHSYearsMonths, VALUES=201301-201312);
%Do_Over(TXHHSYearsMonths, MACRO=Create_MonthlyTXHHSFile);
%ARRAY(TXHHSYears, VALUES=2006-2013);
%Do_Over(TXHHSYears, MACRO=Create_YearTXHHSFile);
