 /*-------------------------------------------------------------------*/
 /*       Program for Reading in Large Economic Census Files          */
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
 /* Date Last Updated: 06Feb2014                                      */
 /*-------------------------------------------------------------------*/
 /* Questions or problem reports concerning this material may be      */
 /* addressed to the author on github: https://github.com/npr99       */
 /*                                                                   */
 /*-------------------------------------------------------------------*/
 /* Data Source:                                                      */
 /* United States Census Bureau (2013) Economic Census 2007           */
 /*       All Sectors 00 Retrieved 2/06/2014 from                     */
 /*       ftp://ftp2.census.gov/econ2007/EC/sector00/EC0700A1.zip     */
 /*-------------------------------------------------------------------*/

* This program is something I just started but have not modified completly;
* Using INFILE to read in .dat value files, 
Options that will be used
FIRSTOBS = 2 : first obseravtion has headers therefore will be skipped
DSD : Going to use Delimiter-Senstive DATA option just in case missing values exist
MISSOVER : there is a chance that missing data exists at the end of data lines;
* The simplest way to assign a value to a macro variable is with the %LET statement;
* Locations on personal computer where data and SAS Libraries are located;
%LET dd_data = C:\Users\Nathanael\MyData\Census\EC2007\;
%LET dd_SASLib = C:\Users\Nathanael\MySASLib\;

LIBNAME EC07 "&dd_SASLib.EC07";
DATA EC07.Readin1;
	INFILE "&dd_data.EC0700A1\EC0700A1.dat" DLM = '|' FIRSTOBS = 2 DSD MISSOVER;
	INPUT ;
RUN;
PROC PRINT DATA = EC07.Readin1;
	TITLE 'Test for reading in first line of EC0700A1 File';
RUN;
PROC EXPORT DATA = EC07.Readin1 OUTFILE = "&dd_data.EC0700A1\EC0700A1\SASOutput\Readin1.csv" REPLACE;
RUN;

*Want a program that gives count of Establishments by Zipcode;
DATA EC07.EstbyZIP;

* NOT MODIFIED From LODES SASProgram

	INFILE "&dd_data.LODES\LODES7\tx\tx_od_main_JT00_2010.csv" DLM = ',' FIRSTOBS = 2 DSD;
	INPUT w_state $2. w_county $3. @1 w_geocode $15. +1 h_state $2. h_county $3. @17 h_geocode $15. +1 S000 SA01 SA02 SA03 SE01 SE02 SE03 SI01 SI02 SI03 createdate;
RUN;
* Procedure to group county data;
PROC REPORT DATA = LODES7.TXByCounty NOWINDOWS;
	COLUMN h_county S000 SE01 SE02 SE03;
	DEFINE h_county / GROUP;
	TITLE 'LODES 7 tx_od_main_JT00_2010 by County';
RUN;
* Procedure to make a data file that has summary of LODES7 data by County ID;
PROC SORT DATA = LODES7.TXByCounty;
	BY h_county;
PROC MEANS NOPRINT DATA = LODES7.TXByCounty SUM;
	BY h_county;
	OUTPUT OUT = LODES7.TXSUMByCounty SUM(S000 SA01 SA02 SA03 SE01 SE02 SE03 SI01 SI02 SI03) =
	S000_TOTAL SA01_TOTAL SA02_TOTAL SA03_TOTAL SE01_TOTAL SE02_TOTAL SE03_TOTAL SI01_TOTAL SI02_TOTAL SI03_TOTAL;
RUN;

	
* Procedure to look at The Texas Health and Human Services Commission reports statistics on SNAP Cases by county from September 2005 through October 2013;
* Data source: http://www.hhsc.state.tx.us/research/TANF-FS-results.asp;
* Source files are in Excel Format and have a unique format;
* This program imports the Excel files, cleans up the files so that they can be merged into a signle file with totals for the year by county;
LIBNAME TXHHS "&dd_SASLib.TXHHS";
%MACRO Create_TXHHSFile(TXHHSfiles=, SASTXHHS_file=, SHEET_name =);
PROC IMPORT DATAFile = "&dd_data.MyData\TXHHSC\SnapCases\&TXHHSfiles..xls" DBMS = XLS OUT = TXHHSTemp_file REPLACE;
	RANGE = "&SHEET_name.$A2:J293";
	MIXED = YES;
RUN;
DATA SASTXHHS_temp REPLACE;
	SET TXHHSTemp_file;
	IF County_Name = "" THEN DELETE;
	IF County_Name =: "MONTHLY" THEN DELETE;
	IF County_Name = "County Name" Then Delete;
	County_Name2 = input(County_Name, $CHAR21.);
	NumCases_&TXHHSfiles = input(Number_of_Cases,comma15.);
	NumRecipients_&TXHHSfiles = input(Number_of_Recipients,comma15.);
	RA01_&TXHHSfiles = input(Recipients____________Ages___5,comma15.);
	RA02_&TXHHSfiles = input(Recipients____________Ages__5__,comma15.);
	RA03_&TXHHSfiles = input(Recipients____________Ages_18__,comma15.);
	RA04_&TXHHSfiles = input(Recipients____________Ages_60__,comma15.);
	RA05_&TXHHSfiles = input(Recipients____________Ages_65__,comma15.);
	TPayments_&TXHHSfiles = input(Total_FB_Payments,comma15.);
	APayments_&TXHHSfiles = input(Avg_Payment___Case,comma15.);
	LABEL NumCases_&TXHHSfiles = "Number of Cases &SASTXHHS_file"
		RA01_&TXHHSfiles = "Recipients Age <5 &SASTXHHS_file"
		RA02_&TXHHSfiles = "Recipients Age 5-17 &SASTXHHS_file"
		RA03_&TXHHSfiles = "Recipients Age 18-59 &SASTXHHS_file"
		RA04_&TXHHSfiles = "Recipients Age 60-64 &SASTXHHS_file"
		RA05_&TXHHSfiles = "Recipients Age 65+ &SASTXHHS_file"
		TPayments_&TXHHSfiles = "Total FB Payments &SASTXHHS_file"
		APayments_&TXHHSfiles = "Average Payment/Case &SASTXHHS_file";
RUN;
* Drop the original variables to create an unsorted or messy temp file;
DATA SASTXHHS_temp_messy REPLACE;
	SET SASTXHHS_temp (DROP = County_Name Number_of_Cases Number_of_Recipients Recipients____________Ages___5 Recipients____________Ages__5__ Recipients____________Ages_18__ 
		Recipients____________Ages_60__ Recipients____________Ages_65__ Total_FB_Payments Avg_Payment___Case);
RUN;
* Data needs to be sorted before the files can be merged;
PROC SORT DATA = SASTXHHS_temp_messy OUT = TXHHS.&SASTXHHS_file;
	BY County_Name2;
RUN;
%MEND Create_TXHHSFile;

%Create_TXHHSFile(TXHHSfiles= 201001, SASTXHHS_file= Jan2010, SHEET_name = TEMPLATE FS Cnty WEB data);
%Create_TXHHSFile(TXHHSfiles= 201002, SASTXHHS_file= Feb2010, SHEET_name = TEMPLATE FS Cnty WEB data);
%Create_TXHHSFile(TXHHSfiles= 201003, SASTXHHS_file= Mar2010, SHEET_name = TEMPLATE FS Cnty WEB data);
%Create_TXHHSFile(TXHHSfiles= 201004, SASTXHHS_file= Apr2010, SHEET_name = TEMPLATE FS Cnty WEB data);
%Create_TXHHSFile(TXHHSfiles= 201005, SASTXHHS_file= May2010, SHEET_name = TEMPLATE FS Cnty WEB data);
%Create_TXHHSFile(TXHHSfiles= 201006, SASTXHHS_file= Jun2010, SHEET_name = TEMPLATE FS Cnty WEB data);
%Create_TXHHSFile(TXHHSfiles= 201007, SASTXHHS_file= Jul2010, SHEET_name = TEMPLATE FS Cnty WEB data);
%Create_TXHHSFile(TXHHSfiles= 201008, SASTXHHS_file= Aug2010, SHEET_name = TEMPLATE FS Cnty WEB data);
%Create_TXHHSFile(TXHHSfiles= 201009, SASTXHHS_file= Sept2010, SHEET_name = TEMPLATE FS Cnty WEB data);
%Create_TXHHSFile(TXHHSfiles= 201010, SASTXHHS_file= Oct2010, SHEET_name = TEMPLATE FS Cnty WEB data);
%Create_TXHHSFile(TXHHSfiles= 201011, SASTXHHS_file= Nov2010, SHEET_name = TEMPLATE FS Cnty WEB data);
%Create_TXHHSFile(TXHHSfiles= 201012, SASTXHHS_file= Dec2010, SHEET_name = TEMPLATE FS Cnty WEB data);

DATA TXHHS.TXHHS_2010 REPLACE;
	MERGE TXHHS.Jan2010 TXHHS.Feb2010 TXHHS.Mar2010 TXHHS.Apr2010 TXHHS.May2010 TXHHS.Jun2010 TXHHS.Jul2010 TXHHS.Aug2010 TXHHS.Sept2010
	TXHHS.Oct2010 TXHHS.Nov2010 TXHHS.Dec2010;
	BY County_Name2;
RUN;
DATA TXHHS.TXHHS_CountyTotals2010 REPLACE;
	SET TXHHS.TXHHS_2010;
	NumCases_TOTAL = SUM(OF NumCases_:);
	NumRecipients_TOTAL = SUM(OF NumRecipients_:);
	RA01_TOTAL = SUM(OF RA01_:);
	RA02_TOTAL = SUM(OF RA02_:);
	RA03_TOTAL = SUM(OF RA03_:);
	RA04_TOTAL = SUM(OF RA04_:);
	RA05_TOTAL = SUM(OF RA05_:);
	TPayments_TOTAL = SUM(OF TPayments_:);
	APayments_TOTAL = SUM(OF APayments_:);
RUN;



* Procedure to group county data;
PROC REPORT DATA = TXHHS.TXHHS_2010 NOWINDOWS;
	COLUMN County_Name NumCases NumRecipients RA01 RA02 RA03 RA04 RA05 TPayments;
	DEFINE County_Name / GROUP;
	TITLE 'SNAP Data 2010 by County';
RUN;

* Combine LODES7 County Data with TXHHS County Data with File that has County FIPS Code, Name, and 2010 Population;
* Bring in Excel File with County Id, Names and 2010 Population;
PROC IMPORT DATAFile = "&dd_Data.Census\Texas_and_Texas_Counties\TX2010PopCounty.xls" DBMS = XLS OUT = TXCountyName_temp REPLACE;
RUN;
DATA TXCOUNTYNAME_tempmessy;
	SET TXCountyName_temp;
	COUNTY_NAME2 = NAME;
Run;
PROC SORT DATA = TXCOUNTYNAME_tempmessy OUT = TXCOUNTYNAME;
	BY County_Name2;
RUN;
DATA TXHHS.TXHHS_CountywithPop REPLACE;
	MERGE TXHHS.TXHHS_CountyTotals2010 TXCOUNTYNAME;
	BY County_Name2;
Run;
DATA 
