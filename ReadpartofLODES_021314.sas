 /*-------------------------------------------------------------------*/
 /*       Program for Subsetting LODES Data			                  */
 /* Program also combines LODES data with proximity to SNAP retail	  */
 /*          by Nathanael Proctor Rosenheim				              */
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
 /* Date Last Updated: 13 Feb 2014                                    */
 /*-------------------------------------------------------------------*/
 /* Questions or problem reports concerning this material may be      */
 /* addressed to the author on github: https://github.com/npr99       */
 /*                                                                   */
 /*-------------------------------------------------------------------*/
 /* Data Source:                                                      */
 /* United States Census Bureau (2013) LEHD Origin-Destination        */ 
 /*       Employment Statistics (LODES)Dataset Structure Format       */
 /*       Version 7.0 Retrieved 5/22/2013 from                        */
 /*       http://lehd.ces.census.gov/data/                            */
 /*-------------------------------------------------------------------*/

* Use a trailing @, then keep specific Census Blocks;
* Using INFILE to read in Comma-seperated value files, first obseravtion has headers therefore will be skipped (FIRSTOBS = 2)
Going to use Delimiter-Senstive DATA option (DSD) just in case missing values exist;
%LET dd_data = C:\Users\Nathanael\MyData\;
%LET dd_data2 = C:\Users\Nathanael\qgis\proposal_test\;
%LET dd_SASLib = C:\Users\Nathanael\MySASLib\;

LIBNAME LODES7 "&dd_SASLib.LODES7";

* Generate output OD file for single county;
DATA LODES7.Brazos_od_main_JT00_2010;
	INFILE "&dd_data.LODES\LODES7\tx\tx_od_main_JT00_2010.csv" DLM = ',' FIRSTOBS = 2 DSD;
	INPUT w_geocode $15. +1 h_statefp $2. h_countyfp $3. @17 h_geocode $15. +1 S000 SA01 SA02 SA03 SE01 SE02 SE03 SI01 SI02 SI03 createdate;
	IF h_countyfp = '041'; * Brazos County is 041;
RUN;
PROC EXPORT DATA = LODES7.Brazos_od_main_JT00_2010 OUTFILE = "&dd_data.LODES\LODES7\SASOutput\Brazos_od_main_JT00_2010.csv" REPLACE;
RUN;
 /*-------------------------------------------------------------------*/
* Combine LODES7 County Data with Proximity Data from QGIS File that has Block GeoCode for the origin;
* Bring in CSV File with BlockID, Mean Proximity in Meters;
DATA LODES7.GOProx_temp;
	INFILE "&dd_Data2.proximity\Brazos_groceryProximity.csv" DLM = ',' FIRSTOBS = 2 DSD;
	INPUT STATEFP h_geocode $15. +1 GProxOmean;
RUN;
*PROC PRINT DATA = LODES7.GProx_temp;
*	TITLE 'Test for Importing Block Proximity';
*RUN;

* Need to sort GProx_temp by the h_geocode column;
DATA GOProx_tempmessy;
	SET LODES7.GOProx_temp (keep=h_geocode GProxOmean);
Run;
*PROC PRINT DATA = GProx_tempmessy;
*	TITLE 'Test for Importing Block Proximity';
*RUN;
PROC SORT DATA = GOProx_tempmessy OUT = GOProx;
	BY h_geocode;
RUN;
*PROC PRINT DATA = GProx;
*	TITLE 'Test for Importing Block Proximity';
*RUN;
PROC SORT DATA = LODES7.Brazos_od_main_JT00_2010 OUT = Brazos_o_main_JT00_2010_sort;
	BY h_geocode;
RUN;
* add home Census Block proximity to grocery store;
DATA LODES7.Brazos_od2010withGProx REPLACE;
	MERGE Brazos_o_main_JT00_2010_sort GOprox;
	BY h_geocode;
	LogOGproxmean = LOG(INT(GProxOmean)); *Log of Origin Proximity;
Run;
 /*-------------------------------------------------------------------*/
* add work Census Block proximity to grocery store;
* Combine LODES7 County Data with Proximity Data from QGIS File that has Block GeoCode for the destination;
* Bring in CSV File with BlockID, Mean Proximity in Meters;
DATA LODES7.GDProx_temp;
	INFILE "&dd_Data2.proximity\Brazos_groceryProximity.csv" DLM = ',' FIRSTOBS = 2 DSD;
	INPUT STATEFP w_geocode $15. +1 GProxDmean;
RUN;

* Need to sort GProx_temp by the w_geocode column;
DATA GDProx_tempmessy;
	SET LODES7.GDProx_temp (keep=w_geocode GProxDmean);
Run;

PROC SORT DATA = GDProx_tempmessy OUT = GDProx;
	BY w_geocode;
RUN;
PROC SORT DATA = LODES7.Brazos_od2010withGProx OUT = Brazos_d_main_JT00_2010_sort;
	BY w_geocode;
RUN;
DATA LODES7.Brazos_od2010withGProx REPLACE;
	MERGE Brazos_d_main_JT00_2010_sort GDprox;
	BY w_geocode;
	LogDGproxmean = LOG(INT(GProxDmean)); *Log of Destination Proximity;
Run;

 /*-------------------------------------------------------------------*/
 /*-------------------------------------------------------------------*/
PROC MEANS DATA = LODES7.Brazos_od2010withGProx MAXDEC = 0;
	VAR GOProxmean;
	TITLE 'Summary of Proximity to Grocery';
RUN;
PROC MEANS DATA = LODES7.Brazos_od2010withGProx MAXDEC = 0 EXCLNPWGT;
* Weight by totla jobs and exclude zero weight;
	WEIGHT S000;
 	VAR GOProxmean;
	TITLE 'Summary of Home Proximity to Grocery with Weight Total Number of Jobs';
RUN;
PROC MEANS DATA = LODES7.Brazos_od2010withGProx MAXDEC = 0 EXCLNPWGT;
	WEIGHT SE01;
 	VAR GOProxmean;
	TITLE 'Summary of Home Proximity to Grocery with Weight Total Number of jobs with earnings $1250/month or less';
RUN;
PROC MEANS DATA = LODES7.Brazos_od2010withGProx MAXDEC = 0 EXCLNPWGT;
	WEIGHT SE02;
 	VAR GOProxmean;
	TITLE 'Summary of Home Proximity to Grocery with Weight Total Number of jobs with earnings $1251/month to $3333/month';
RUN;
PROC MEANS DATA = LODES7.Brazos_od2010withGProx MAXDEC = 0 EXCLNPWGT;
	WEIGHT SE03;
 	VAR GOProxmean;
	TITLE 'Summary of Home Proximity to Grocery with Weight Total Number of jobs with earnings greater than $3333/month';
RUN;

* Create a histogram plot of the GProxMean;
PROC SGPLOT DATA = LODES7.Brazos_od2010withGProx;
	HISTOGRAM LogOGProxmean / NBINS = 10 SHOWBINS SCALE = COUNT;
	TITLE 'Mean Proximity from Home Block to Grocery or Supercenter';
Run;

* Need to see if using a log transform on Gproxmean makes the groups comparable;
* Also need to Group by Origin and Destiantion to see if there is a difference;

PROC MEANS DATA = LODES7.Brazos_od2010withGProx MAXDEC = 3;
	VAR LogOGProxmean;
	TITLE 'Summary of Home Proximity to Grocery';
RUN;
PROC MEANS DATA = LODES7.Brazos_od2010withGProx MAXDEC = 3 EXCLNPWGT;
* Weight by totla jobs and exclude zero weight;
	WEIGHT S000;
 	VAR LogOGProxmean;
	TITLE 'Summary of Home Proximity to Grocery with Weight Total Number of Jobs';
RUN;
PROC MEANS DATA = LODES7.Brazos_od2010withGProx MAXDEC = 3 EXCLNPWGT;
	WEIGHT SE01;
 	VAR LogOGProxmean;
	TITLE 'Summary of Home Proximity to Grocery with Weight Total Number of jobs with earnings $1250/month or less';
RUN;
PROC MEANS DATA = LODES7.Brazos_od2010withGProx MAXDEC = 3 EXCLNPWGT;
	WEIGHT SE02;
 	VAR LogOGProxmean;
	TITLE 'Summary of Home Proximity to Grocery with Weight Total Number of jobs with earnings $1251/month to $3333/month';
RUN;
PROC MEANS DATA = LODES7.Brazos_od2010withGProx MAXDEC = 3 EXCLNPWGT;
	WEIGHT SE03;
 	VAR LogOGProxmean;
	TITLE 'Summary of Home Proximity to Grocery with Weight Total Number of jobs with earnings greater than $3333/month';
RUN;

 /*-------------------------------------------------------------------*/
* Look at summary statistics for destination proximity;
PROC MEANS DATA = LODES7.Brazos_od2010withGProx MAXDEC = 0;
	VAR GDProxmean;
	TITLE 'Summary of Work Proximity to Grocery';
RUN;
PROC MEANS DATA = LODES7.Brazos_od2010withGProx MAXDEC = 0 EXCLNPWGT;
* Weight by totla jobs and exclude zero weight;
	WEIGHT S000;
 	VAR GDProxmean;
	TITLE 'Summary of Work Proximity to Grocery with Weight Total Number of Jobs';
RUN;
PROC MEANS DATA = LODES7.Brazos_od2010withGProx MAXDEC = 0 EXCLNPWGT;
	WEIGHT SE01;
 	VAR GDProxmean;
	TITLE 'Summary of Work Proximity to Grocery with Weight Total Number of jobs with earnings $1250/month or less';
RUN;
PROC MEANS DATA = LODES7.Brazos_od2010withGProx MAXDEC = 0 EXCLNPWGT;
	WEIGHT SE02;
 	VAR GDProxmean;
	TITLE 'Summary of Work Proximity to Grocery with Weight Total Number of jobs with earnings $1251/month to $3333/month';
RUN;
PROC MEANS DATA = LODES7.Brazos_od2010withGProx MAXDEC = 0 EXCLNPWGT;
	WEIGHT SE03;
 	VAR GDProxmean;
	TITLE 'Summary of Work Proximity to Grocery with Weight Total Number of jobs with earnings greater than $3333/month';
RUN;

* Create a histogram plot of the GProxMean;
PROC SGPLOT DATA = LODES7.Brazos_od2010withGProx;
	HISTOGRAM LogDGProxmean / NBINS = 10 SHOWBINS SCALE = COUNT;
	TITLE 'Mean Proximity from Work Block to Grocery or Supercenter';
Run;

* Need to see if using a log transform on Gproxmean makes the groups comparable;
* Also need to Group by Origin and Destiantion to see if there is a difference;

PROC MEANS DATA = LODES7.Brazos_od2010withGProx MAXDEC = 3;
	VAR LogDGProxmean;
	TITLE 'Summary of Work Proximity to Grocery';
RUN;
PROC MEANS DATA = LODES7.Brazos_od2010withGProx MAXDEC = 3 EXCLNPWGT;
* Weight by totla jobs and exclude zero weight;
	WEIGHT S000;
 	VAR LogDGProxmean;
	TITLE 'Summary of Work Proximity to Grocery with Weight Total Number of Jobs';
RUN;
PROC MEANS DATA = LODES7.Brazos_od2010withGProx MAXDEC = 3 EXCLNPWGT;
	WEIGHT SE01;
 	VAR LogDGProxmean;
	TITLE 'Summary of Work Proximity to Grocery with Weight Total Number of jobs with earnings $1250/month or less';
RUN;
PROC MEANS DATA = LODES7.Brazos_od2010withGProx MAXDEC = 3 EXCLNPWGT;
	WEIGHT SE02;
 	VAR LogDGProxmean;
	TITLE 'Summary of Work Proximity to Grocery with Weight Total Number of jobs with earnings $1251/month to $3333/month';
RUN;
PROC MEANS DATA = LODES7.Brazos_od2010withGProx MAXDEC = 3 EXCLNPWGT;
	WEIGHT SE03;
 	VAR LogDGProxmean;
	TITLE 'Summary of Work Proximity to Grocery with Weight Total Number of jobs with earnings greater than $3333/month';
RUN;
