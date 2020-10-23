 /*-------------------------------------------------------------------*/
 /*       Program for Merging ACS 5yr Estimates for Food Stamps       */
 /*       with Census Tract ID Data for Mapping with TIGER Files      */
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
 /* Date Last Updated: 08June014                                      */
 /*-------------------------------------------------------------------*/
 /* Questions or problem reports concerning this material may be      */
 /* addressed to the author on github: https://github.com/npr99       */
 /*                                                                   */
 /*-------------------------------------------------------------------*/
 /* Data Source:
 Census, 2012 ACS 5yr Summary File e20125tx0074000.txt Retrieved from 
 ftp://ftp2.census.gov/acs2012_5yr/summaryfile/2008-2012_ACSSF_By_State_By_Sequence_Table_Subset/Texas
 on June 8, 2014

 Census, 2012 ACS 5yr Geography File tx.xls Retrieved from
 ftp://ftp2.census.gov/acs2012_5yr/summaryfile/UserTools/Geography
 on June 8, 2014
 
 Census, 2012 ACS 5yr SAS Programs Retrieved from
 ftp://ftp2.census.gov/acs2012_5yr/summaryfile/UserTools/SF_All_Macro.sas
 on Jun 8, 2014
 NOTE: This file contains over 12,000 individual SAS programs 130+MB unzipped.

/*-------------------------------------------------------------------*/
/*-------------------------------------------------------------------*/
/* Clear Log                                                         */
/*-------------------------------------------------------------------*/
DM "clear log";

/*-------------------------------------------------------------------*/
/* Control Symbolgen                                                 */
/*-------------------------------------------------------------------*/

* Turn on SYBMBOLGEN option to see how macro variables are resolved in log;
* global system option MPRINT to view the macro code with the 
macro variables resolved;
* options SYMBOLGEN MPRINT;

* SYMBOLGEN option can be turned off with the following command;
options nosymbolgen;

/*-------------------------------------------------------------------*/
/* Important Folder Locations                                        */
/*-------------------------------------------------------------------*/

%LET dd_data = C:\Users\Nathanael\Dropbox\MyData\;
%LET dd_SASLib = C:\Users\Nathanael\MySASLib\;
%LET Include_prog = C:\Users\Nathanael\MyPrograms\SF20125YR_SAS\;

/*-------------------------------------------------------------------*/
/* Important Macro Variables                                         */
/*-------------------------------------------------------------------*/

* Set Macro Variables for ACS State and Year;
%LET State = tx;
%LET Year = 2012;

* Set Macro Variables for ACS Estimate or Margin of error file;
* e = estimate, m = margin of error;
%LET EorMOE = e;

* Set Macro Variable for ACS Summary File Sequence Number of interest;
* Seq Num 0074 contains varaibles related to SNAP participation;
%LET SeqNum = 0074;

LIBNAME ACS "&dd_SASLib.ACS";

/*-------------------------------------------------------------------*/
/* Import Primary Files from Original Source                         */
/*-------------------------------------------------------------------*/

* Import ACS 5yr Summary Files for 2008-2012;
* Oringinal program from Census
* Program creates temporary work file named SFe0074(state id);

* Data from Summary file needs to be inside subfolders
c:/tab4/sumfile/prod/2008thru2012/data/;
* See SAS program from Census to confirm folder structure;

%INCLUDE "&Include_prog.&EorMOE.&State._&SeqNum..sas";


* Import Census, 2012 ACS 5yr Geography File;

PROC IMPORT DATAFile = "&dd_Data.Census\ACSGEO\&State.geo&Year._5yr" 
	DBMS = XLS OUT = ACS.&State.geo&Year._5yr REPLACE;
RUN;

/*-------------------------------------------------------------------*/
/* Merge NHIS with ACS file with Geography GeoID                     */
/*-------------------------------------------------------------------*/

* Sort ACS file and GEO File by LOGRECNO;
PROC SORT DATA = ACS.&State.geo&Year._5yr;
	By LOGRECNO; 
RUN;

/* Sort Summary File by Logical Record Number */
PROC SORT DATA = work.sf&EorMOE.&SeqNum.&State;
	By LOGRECNO; 
RUN;

DATA ACS.sf&EorMOE.&SummaryFile.&State.GEO REPLACE;
	MERGE ACS.&State.geo&Year._5yr work.sf&EorMOE.&SeqNum.&State;
	BY LOGRECNO;
RUN;

/*-------------------------------------------------------------------*/
/* Create a new GEOID Field to Match TIGER GEOID                     */
/*-------------------------------------------------------------------*/

* ACS GEOID includes identifiers for level of geography and territory;
* TIGER GEOID only includes FIP data;
* TIGER GEOID is a String Length 11;

DATA ACS.sf&EorMOE.&SummaryFile.&State.GEO REPLACE;
	Set ACS.sf&EorMOE.&SummaryFile.&State.GEO;
	length TigerGEOID $11;
	* Delimit GEOID by “S” and keep the second part of the scan;
    TigerGEOID = scan(GEOID,2,'S');
RUN;

/*-------------------------------------------------------------------*/
/* Create a new Variable that estimates the number of workers        */
/*-------------------------------------------------------------------*/

* Reviewing the Sequence Number and Table Number Lookup File 
provides list of estimates for number of workers B22007. 
Will compare this to LODES Data;
* Variables are listed as no workers in household, 1, 2 or 3 or more
workers in household;
* For variables with 3 or more workers chose to simply multiply by 3
this could lead to an undercount of workers;

DATA ACS.sf&EorMOE.&SummaryFile.&State.GEO REPLACE;
	Set ACS.sf&EorMOE.&SummaryFile.&State.GEO;
	* Total workers estimate for Npn-SNAP households;
    B22007T1 = B22007e26 + B22007e27 * 2 + B22007e30 * 3 +
	B22007e36 + B22007e37*2 + B22007e38*3 +
	B22007e41 + B22007e42*2 + B22007e42*3;
	* Total workers estimate for SNAP households;
    B22007T2 = B22007e5 + B22007e6 * 2 + B22007e9 * 3 +
	B22007e15 + B22007e16*2 + B22007e17*3 +
	B22007e20 + B22007e21*2 + B22007e22*3;
	* Total Non workers estimate for SNAP households;

* PICK UP HERE.... Need to estimate nonworkers and also add labels to these new variabels;

    B22007T3 = B22007e5 + B22007e6 * 2 + B22007e9 * 3 +
	B22007e15 + B22007e16*2 + B22007e17*3 +
	B22007e20 + B22007e21*2 + B22007e22*3;
RUN;

/*-------------------------------------------------------------------*/
/* Prepare file for export to excel to view in QGIS                  */
/*-------------------------------------------------------------------*/

* NEED To finish export command;

DATA sf&EorMOE.&SummaryFile.&State.export REPLACE;
	Set ACS.sf&EorMOE.&SummaryFile.&State.GEO
	(KEEP = TigerGEOID B22001e1 B22001e2)
    
RUN;
