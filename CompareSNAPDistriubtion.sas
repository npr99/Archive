/*-------------------------------------------------------------------*/
/*       Program for Comparing sources of SNAP Distribution Data     */
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
/* See import Macros                                                 */
/*-------------------------------------------------------------------*/
/* Comment:
There seems to be large descrpenancies in the 2005 and 2011 data
I may need to focus on just 2006-2010

Further review shows that the BEA SNAP data compares closely to the 
TXHHS data. The TXHHS data is lower because TXHHS reports up to the 15th
of the month.
The issue with BEA data is that it appears to apply a statewide weight
to increase county data so that the totals match the state amount.
It is unlikely that every county should recieve the exact same increase.
I will run the models with both WCR based on TXHHS and on BEA data.
I suspect that the coeffients will not change much and that by including 
a year factor for TXHHS the values will models will trend the same.
*/

/*-------------------------------------------------------------------*/
/* Important Folder Locations                                        */
/*-------------------------------------------------------------------*/

%LET dd_data = C:\Users\Nathanael\Dropbox\MyData\;
%LET dd_SASLib = C:\Users\Nathanael\MySASLib\;
%LET Include_prog = C:\Users\Nathanael\Dropbox\MyPrograms\;

/*-------------------------------------------------------------------*/
/* Important Macro Variables                                         */
/*-------------------------------------------------------------------*/

%Let FYear = 2005; * First Year;
%Let LYear = 2012; * Last Year;
%Let State = TX;

/*-------------------------------------------------------------------*/
/* Define SAS Library                                                */
/*-------------------------------------------------------------------*/
%let library = BEA;
LIBNAME &library "&dd_SASLib.&library";

/*-------------------------------------------------------------------*/
/*  Merge BEA with TXHHS and USDA to see if they match               */
/*-------------------------------------------------------------------*/
* Include Macro that imports distribution data from TXHHS;
%INCLUDE "&Include_prog.BEA\ImportBEA.sas";

%LET BEACode = CA35; * BEA Table that includes SNAP data;
%LET D_Select = SNAP; * Data to select in CA35 table;

%ImportBEA(
   FYear = &FYear,
   LYear = &LYear,
   State = &State,
   BEACode = &BEACode,
   D_Select = &D_Select,
   Library = &library);

* Include Macro that imports distribution data from TXHHS;
%INCLUDE "&Include_prog.TXHHS\ImportTXHHSData.sas";

%LET GeoLevel = County;

%ImportTXHHSData(
   FYear = &FYear,
   LYear = &LYear,
   Library = &library);

* Include Macro that imports distribution data from USDA Time Series;
%INCLUDE "&Include_prog.USDA_SAS\ImportUSDA_SNAP_timeseries.sas";

%ImportUSDA_SNAP_timeseries(
   State = &State,
   FYear = &FYear,
   LYear = &LYear,
   Library = &library);


Data &library..Merge&BEACode._&state._&FYear._&LYear REPLACE;
	Merge &library..Txcounty2005_2012txhhsdata
			(Keep=TXHHSCNTYBEN FIPS_County year)
			&library..&BEACode._&state._&FYear._&LYear
			&library..&State.CountyTimeSeries_&FYear._&LYear;
	By FIPS_County year;
	PrctDiff1 = (TXHHSCNTYBEN - BEA_SNAP)/BEA_SNAP;
	PrctDiff2 = (TXHHSCNTYBEN - USDA_PRGBEN)/USDA_PRGBEN;
	PrctDiff3 = (BEA_SNAP - USDA_PRGBEN)/USDA_PRGBEN;
Run; 

Data &library..Merge&BEACode._&state._&FYear._&LYear;
	Retain FIPS_county year CONAME STATE_CD STFIPS CODEF 
			TXHHSCNTYBEN BEA_SNAPflag BEA_SNAP USDA_FLAG 
			USDA_PRGBEN_flag USDA_PRGBEN;
	set &library..Merge&BEACode._&state._&FYear._&LYear;
Run; 

Proc MEANS Data = &library..Merge&BEACode._&state._&FYear._&LYear;
	Class year;
	Var PrctDiff:;
Run;

Proc Sort Data = &library..Merge&BEACode._&state._&FYear._&LYear;
	By PrctDiff3;
Run;

Data &library..Merge&BEACode._&state._2006_2010;
	set &library..Merge&BEACode._&state._&FYear._&LYear;
	If year >= 2006 and year <= 2010;
Run;
