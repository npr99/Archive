/*-------------------------------------------------------------------*/
/* program:		WLLRT_Data_DBFCensusTracts_2015-10-08.sas
/* task:		Create dta file for stata from DBF file
/* project:		Wei Li Light Rail WLLRT
/* author:		Nathanael Rosenheim \ Oct 8 2015
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

%LET dd_data = F:\;
%LET dd_SASLib = F:\MyProjects\;
%LET rootdir = F:\Dropbox\MyProjects\WLLRT\Work\;
* Location where shape files with centroids is located;
%LET shp_data = F:\Dropbox\MyProjects\WLLRT\Shapefiles\;

/*-------------------------------------------------------------------*/
/* Define SAS Library                                                */
/*-------------------------------------------------------------------*/
%let library = WLLRT;
LIBNAME &library "&dd_SASLib.&library";

%let temp = temp;
LIBNAME &temp "&dd_SASLib.&library.\temp";

/*-------------------------------------------------------------------*/
/* Import Census Tract DBF                                           */
/*-------------------------------------------------------------------*/


PROC IMPORT OUT=work.US_tract_2010
            DATAFILE="&shp_data.nhgis_tl2010_us_tract_2010\US_tract_2010.dbf"
            DBMS=DBF REPLACE;
   GETDEL=NO;
RUN;

/*-------------------------------------------------------------------*/
/* Export to Stata                                                   */
/*-------------------------------------------------------------------*/


proc export data=work.US_tract_2010
outfile= "&rootdir.WLLRT_US_tract_2010.dta"
REPLACE;
run;
