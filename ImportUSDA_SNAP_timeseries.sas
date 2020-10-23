/*-------------------------------------------------------------------*/
/*       Program for Importing the USDA SNAP timeseries Data         */
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
/* Date Last Updated: 28Sept14                                       */
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
/* Data Summary:


Recommended Citation
Economic Research Service (ERS), U.S. Department of Agriculture (USDA). Supplemental Nutrition Assistance Program (SNAP) Data System. http://www.ers.usda.gov/data-products/supplemental-nutrition-assistance-program-(snap)-data-system.aspx.

Codes used for missing or redacted data:
-9991: Data not yet available.
-9992: Data not available for a county unit used by BEA (CODEF=BEA_ONLY).
-9993: Computed variable for which at least one underlying data value is missing.
-9994: Data not available for a county unit used by Census Bureau (CODEF=CEN_ONLY).
-9995: Data not defined for years prior to introduction of the Food Stamp Program (rollout of the FSP began in 1969 and was not fully nationwide until 1976).
-9996: Data missing due to data suppression by BEA or Census.
-9997: Data not available in specific year. Coded as (N) in original data files from BEA or Census.
-9998: Actual value less than 50. Coded as (L) in original data files from BEA or Census.
-9999: Data not available for reasons other than those listed above, including division by a true zero in a computed variable.


%LET dd_data = C:\Users\Nathanael\Dropbox\MyData\;
%LET dd_SASLib = C:\Users\Nathanael\MySASLib\;
%LET Include_macros = C:\Users\Nathanael\Dropbox\MyPrograms\Macros_SAS\;
*/

/*-------------------------------------------------------------------*/
/* Important Folder Locations                                        */
/*-------------------------------------------------------------------*/

%LET dd_data = C:\Users\Nathanael\Dropbox\MyData\;
%LET dd_SASLib = C:\Users\Nathanael\MySASLib\;
%LET Include_prog = C:\Users\Nathanael\Dropbox\MyPrograms\;


%MACRO ImportUSDA_SNAP_timeseries( );

/*-------------------------------------------------------------------*/
/* Define SAS Library                                                */
/*-------------------------------------------------------------------*/
%let library = USDA;
LIBNAME &library "&dd_SASLib.&library";

/*-------------------------------------------------------------------*/
/* Import Primary Files from Original Source                         */
/*-------------------------------------------------------------------*/

* Import SNAP Data System Time Series Data;
* Data includes estimated annual benefits distributed to counties;
* Technical Documentation C:\Users\Nathanael\Dropbox\MyData\USDA\
  SNAP_TimeSeriesDataCounty_Data Documentation.pdf;

PROC IMPORT DATAFile = "&dd_data.USDA_ReadOnly\County_Data.xls" DBMS = XLS 
OUT = work.CountyTimeSeries REPLACE;
	RANGE = "County$A1:DQ3197";
	MIXED = YES;
RUN;

* IMPORT FLAG DATA;
* Flag—identifies States and years in which program benefit data have been imputed by ERS (described below);

PROC IMPORT DATAFile = "&dd_data.USDA_ReadOnly\County_Data.xls" DBMS = XLS 
OUT = work.CountyTimeSeries_FLAGS REPLACE;
	RANGE = "Flag$A1:N52";
	MIXED = YES;
RUN;
/*-------------------------------------------------------------------*/
/*  Transpose Data - One Observation for year county each year       */
/*-------------------------------------------------------------------*/
/* Benefits per county */
Proc transpose data = work.CountyTimeSeries
	out = work.LongCountyTimeSeries_prgben Prefix = USDA_PRGBEN;
	by FIPSTXT CONAME STATE_CD STFIPS CODEF;
	var prgben:;
Run;
/* SNAP participant counts per county */
Proc transpose data = work.CountyTimeSeries
	out = work.LongCountyTimeSeries_prgnum Prefix = USDA_PRGNUM;
	by FIPSTXT CONAME STATE_CD STFIPS CODEF;
	var prgnum:;
Run;
/*-------------------------------------------------------------------*/
/*  Clean up data and convert codes to flags                         */
/*-------------------------------------------------------------------*/
%Macro CleanUSDA_Flags(usda_var, scalefactor);
Data work.Temp_CountyTimeSeries_&usda_var REPLACE;
	Set work.LongCountyTimeSeries_&usda_var;
	year=input(substr(_NAME_, 7, 2), 2.);
	drop _NAME_;
	drop _LABEL_;
	if year >= 69 and year <= 99 then do;
		year = 1900 + year;
		end;
	else if year >= 0 and year <= 12 then do;
		year = 2000 + year;
		end;

/* 
Codes used for missing or redacted data:
-9991: Data not yet available.
-9992: Data not available for a county unit used by BEA (CODEF=BEA_ONLY).
-9993: Computed variable for which at least one underlying data value is missing.
-9994: Data not available for a county unit used by Census Bureau (CODEF=CEN_ONLY).
-9995: Data not defined for years prior to introduction of the Food Stamp Program (rollout of the FSP began in 1969 and was not fully nationwide until 1976).
-9996: Data missing due to data suppression by BEA or Census.
-9997: Data not available in specific year. Coded as (N) in original data files from BEA or Census.
-9998: Actual value less than 50. Coded as (L) in original data files from BEA or Census.
-9999: Data not available for reasons other than those listed above, including division by a true zero in a computed variable.
*/
	if USDA_&usda_var.1 < 0 then do;
		USDA_&usda_var._flag = USDA_&usda_var.1;
		USDA_&usda_var = .;
		end;
	Else do;
		USDA_&usda_var._flag = 0;
		USDA_&usda_var = USDA_&usda_var.1*&scalefactor;
		end;
	drop USDA_&usda_var.1;
	* Make STFIPS length 2;
	STFIPS2 = put(STFIPS,2.);
	drop STFIPS;
	rename STFIPS2 = STFIPS;
run;
%Mend CleanUSDA_Flags;

/* Clean up Benefit Data, multiply by $1,000 */
%CleanUSDA_Flags(prgben, 1000);
/* Clean up Pariticpant number data, no scale */
%CleanUSDA_Flags(prgnum, 1);
/*-------------------------------------------------------------------*/
/*  Transpose Data - FLAG DATA                                       */
/*-------------------------------------------------------------------*/

Proc transpose data = work.CountyTimeSeries_FLAGS
	out = work.LongCountyTimeSeries_FLAGS Prefix = USDA_FLAG;
	by STFIPS STATE_CD;
	var benflg:;
Run;

/*-------------------------------------------------------------------*/
/*  Clean up data and convert codes to flags                         */
/*-------------------------------------------------------------------*/

Data work.Temp_CountyTimeSeries_FLAGS REPLACE;
	Set work.LongCountyTimeSeries_FLAGS;
	year=input(substr(_NAME_, 7, 2), 2.);
	drop _NAME_;
	drop _LABEL_;
	if year >= 69 and year <= 99 then do;
		year = 1900 + year;
		end;
	else if year >= 0 and year <= 12 then do;
		year = 2000 + year;
		end;
	If STFIPS < 10 then do;
		STFIPS2 = "0" || put(STFIPS,1.);
		end;
	Else STFIPS2 = put(STFIPS,2.);
	drop STFIPS;
	rename STFIPS2 = STFIPS;
	USDA_FLAG = put(compress(USDA_FLAG1," "),1.);
	drop USDA_FLAG1;
run;

/*-------------------------------------------------------------------*/
/*  Merge State Flag data with County Benefit Data                   */
/*-------------------------------------------------------------------*/

Proc Sort Data = work.Temp_CountyTimeSeries_prgben;
	by FIPSTXT year;
Run;

Proc Sort Data = work.Temp_CountyTimeSeries_prgnum;
	by FIPSTXT year;
Run;

DATA work.CountyTimeSeries_Long REPLACE;
	merge 
		work.Temp_CountyTimeSeries_prgben
		work.Temp_CountyTimeSeries_prgnum;
	by FIPSTXT year;
Run;

Proc Sort Data = work.CountyTimeSeries_Long;
	by STFIPS year;
Run;

Proc Sort Data = work.Temp_CountyTimeSeries_FLAGS;
	by STFIPS year;
Run;

DATA work.CountyTimeSeries_wFlag REPLACE;
	merge 
		work.Temp_CountyTimeSeries_FLAGS
		work.CountyTimeSeries_Long;
	by STFIPS year;
Run;

Proc Sort Data = work.CountyTimeSeries_wFlag;
	by FIPSTXT year;
Run;

/*-------------------------------------------------------------------*/
/*  Lable and set attributes of variables                            */
/*-------------------------------------------------------------------*/

Data work.CountyTimeSeries_wFlag REPLACE;
	Set work.CountyTimeSeries_wFlag;

attrib 	USDA_prgben_flag format = 8.0 label = "USDA SNAP participant benefits Data Flag"
		USDA_prgben		 format = comma16.2 label = "USDA SNAP participant benefits,($)"
		USDA_prgnum_flag format = 8.0 label = "USDA SNAP Participant Data Flag"
		USDA_prgnum		 format = comma12.0 label = "USDA SNAP Participant Data, persons";

Run;
/*-------------------------------------------------------------------*/
/*  Save to Library                                                  */
/*-------------------------------------------------------------------*/

Data &library..USDA_CountyTimeSeries_1969_2012 REPLACE;
	Set work.CountyTimeSeries_wFlag;
	yeartxt = put(year,4.); * year needs to be string;
	FIPS_County = FIPSTXT;
	Drop FIPSTXT;
Run;

Data &library..USDA_CountyTimeSeries_1969_2012 REPLACE;
	Retain FIPS_County STFIPS Year;
	Set &library..USDA_CountyTimeSeries_1969_2012;
Run; 

%mend ImportUSDA_SNAP_timeseries;

/*-------------------------------------------------------------------*/
/* Run Macro Here                                                    */
/*-------------------------------------------------------------------*/

%ImportUSDA_SNAP_timeseries;
