/*-------------------------------------------------------------------*/
/*       Program for Importing the SAIPE SNAP Data                   */
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
/* Date Last Updated: 18Feb15                                        */
/*-------------------------------------------------------------------*/
/* Questions or problem reports concerning this material may be      */
/* addressed to the author on github: https://github.com/npr99       */
/*                                                                   */
/*-------------------------------------------------------------------*/
/* Data Source:                                                      */
/* Table with column headers in row 3,,,,,,,,,,,,,,,,,,,,,
"Table:  County SNAP benefits recipients
Source:  U.S. Census Bureau, Small Area Estimates Branch
Release Date:  December 2014
http://www.census.gov/did/www/saipe/inputdata/cntysnap.csv
/*       on Feb 18, 2014                                             */
/*-------------------------------------------------------------------*/
/* Data Summary: http://www.census.gov/did/www/saipe/data/model/snap.html
SNAP Benefits Data

The SNAP benefits data represent the number of participants in the 
Supplemental Nutrition Assistance Program for each county, state, and 
the District of Columbia from 1981 to the latest available year.
The state-level files contain the number of SNAP benefits recipients 
by month, and the county level files contain the number of recipients 
in July of each year.

Outliers of the SNAP benefits data at the state level are smoothed on the
basis of time series analysis, to remove the effects of anomalies,
such as natural disasters, in which the typical relations between 
income and SNAP eligibility do not hold.

Prior to the SAIPE modeling, the number of SNAP benefits recipients 
in Alaska and Hawaii are adjusted downward because the income eligibility 
guidelines for these states are higher than they are for states in the 
continental U.S, whereas the official poverty thresholds are 
the same for all states and the District of Columbia. However, 
in this Excel file, the Alaska and Hawaii figures are pre-adjustment data.

The SNAP data provided for download are the figures used in the production 
of the SAIPE data for the given year and are not updated to reflect
any subsequent corrections that may have been made by the states 
or by the Food and Nutrition Service since that time.

The county SNAP benefits totals are raked (i.e., controlled to add up) 
to the state totals (12-month averages) which are also provided in the 
data files. These values may not match those in the state files 
(except for the most recent years) because these data are used 
in the actual production for the specified year. Also note, for the 
1995 poverty estimates and onward, the state totals in the county
SNAP benefits files are based on the average number of SNAP benefits recipients
over twelve consecutive months. For example, the 2009 SAIPE model 
uses an average over the period July 2008 through June 2009.

More information on how the SAIPE program uses SNAP benefits data in 
the models can be found at SNAP benefits recipients.
*/

/*-------------------------------------------------------------------*/
/* Important Folder Locations                                        */
/*-------------------------------------------------------------------*/

%LET dd_data = C:\Users\Nathanael\Dropbox\MyData\;
%LET dd_SASLib = C:\Users\Nathanael\MySASLib\;
%LET Include_prog = C:\Users\Nathanael\Dropbox\MyPrograms\;


%MACRO ImportSAIPE_SNAP( );

/*-------------------------------------------------------------------*/
/* Define SAS Library                                                */
/*-------------------------------------------------------------------*/
%let library = SAIPE;
LIBNAME &library "&dd_SASLib.&library";

/*-------------------------------------------------------------------*/
/* Import Primary Files from Original Source                         */
/*-------------------------------------------------------------------*/

* Import SNAP Data System Time Series Data;
* Data includes estimated annual benefits distributed to counties;
* Technical Documentation C:\Users\Nathanael\Dropbox\MyData\USDA\
  SNAP_TimeSeriesDataCounty_Data Documentation.pdf;

proc import datafile="&dd_data.Census\SAIPE\cntysnap.csv"
     out=SAIPE_SNAP
     dbms=csv
     replace;
     getnames=no;
	 DATAROW=5;
run;

DATA work.SAIPE_SNAP2 REPLACE;
	SET work.SAIPE_SNAP;
	IF VAR1 = "State FIPS code" THEN DELETE;
	stfips = input(VAR1, $CHAR2.); 
	County = input(VAR2, $CHAR3.);
	FIPS_County = input(VAR1, $CHAR2.) || input(VAR2, $CHAR3.);
	CountyName = input(VAR3,$CHAR20.);
	Jul2012 = input(VAR4,comma15.);
	Jul2011 = input(VAR5,comma15.);
	Jul2010 = input(VAR6,comma15.);
	Jul2009 = input(VAR7,comma15.);
	Jul2008 = input(VAR8,comma15.);
	Jul2007 = input(VAR9,comma15.);
	Jul2006 = input(VAR10,comma15.);
	Jul2005 = input(VAR11,comma15.);
	Jul2004 = input(VAR12,comma15.);
	Jul2003 = input(VAR13,comma15.);
	Jul2002 = input(VAR14,comma15.);
	Jul2001 = input(VAR15,comma15.);
RUN;
* Drop the original variables to create an unsorted or messy temp file;
DATA work.SAIPE_SNAP2 REPLACE;
	SET work.SAIPE_SNAP2 (DROP = VAR1-VAR22);
RUN;

/*-------------------------------------------------------------------*/
/*  Transpose Data - One Observation for year county each year       */
/*-------------------------------------------------------------------*/
/* Benefits per county */
Proc transpose data = work.SAIPE_SNAP2
	out = work.LongSAIPE_SNAP Prefix = SAIPE_SNAP;
	by FIPS_County;
	var Jul:;
Run;

/*-------------------------------------------------------------------*/
/*  Clean up data                                                    */
/*-------------------------------------------------------------------*/

Data work.LongSAIPE_SNAP2 REPLACE;
	Set work.LongSAIPE_SNAP;
	year=input(substr(_NAME_, 4, 4), 4.);
	drop _NAME_;
run;

/*-------------------------------------------------------------------*/
/*  Lable and set attributes of variables                            */
/*-------------------------------------------------------------------*/

Data work.LongSAIPE_SNAP2 REPLACE;
	Set work.LongSAIPE_SNAP2;

attrib 	SAIPE_SNAP1		 format = comma12.0 label = "SAIPE SNAP Participant Data, persons";

Run;
/*-------------------------------------------------------------------*/
/*  Save to Library                                                  */
/*-------------------------------------------------------------------*/

Data SAIPE.SAIPE_SNAP_2001_2012 REPLACE;
	Set work.LongSAIPE_SNAP2;
	yeartxt = put(year,4.); * year needs to be string;
Run;

%mend ImportSAIPE_SNAP;

/*-------------------------------------------------------------------*/
/* Run Macro Here                                                    */
/*-------------------------------------------------------------------*/

%ImportSAIPE_SNAP;
