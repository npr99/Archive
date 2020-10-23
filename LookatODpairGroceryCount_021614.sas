 /*-------------------------------------------------------------------*/
 /*       Program for Looking at Data on Grocery Count                */
 /* Program uses LODES data with SNAP retail 500m buffer			  */
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
 /*  USDA (2014) SNAP Retail Locator. Retrieved from                  */ 
 /*       http://www.fns.usda.gov/snap/retailerlocator                */
 /*  Grocery Count Data produced by author using QGIS 2.1             */
 /*       Count was orginally done using 500 m buffer and join by     */ 
 /*       location to lines between OD block centroids                */
 /*-------------------------------------------------------------------*/

* Use a trailing @, then keep specific Census Blocks;
* Using INFILE to read in Comma-seperated value files, first obseravtion 
	has headers therefore will be skipped (FIRSTOBS = 2)
	Going to use Delimiter-Senstive DATA option (DSD) just in case missing values exist
	Also include MISSOVER because missing values at end of line;
%LET dd_data = C:\Users\Nathanael\MyData\;
%LET dd_data2 = C:\Users\Nathanael\qgis\proposal_test\;
%LET dd_SASLib = C:\Users\Nathanael\MySASLib\;

LIBNAME LODES7 "&dd_SASLib.LODES7";

* Generate output OD file for single county;
DATA LODES7.Grocerycount_BrazosOD REPLACE;
	INFILE "&dd_Data2.proximity\GroceryCountODpairs.csv" DLM = ',' FIRSTOBS = 2 DSD;
	INPUT ODPairID w_geocode :$15. h_statefp h_countyfp	h_geocode :$15. 
	S000 SA01 SA02 SA03 SE01 SE02 SE03 SI01 SI02 SI03 createdate
	geocodeLat geocodeLon SUMRaster COUNT;
	IF COUNT = . THEN COUNT = 0; * change missing values to 0;
RUN;


 /*-------------------------------------------------------------------*/
PROC MEANS DATA = LODES7.Grocerycount_BrazosOD MAXDEC = 2;
	VAR Count;
	TITLE 'Summary of Count of Grocery within 500m of ODPair Line';
RUN;
PROC MEANS DATA = LODES7.Grocerycount_BrazosOD MAXDEC = 2 EXCLNPWGT;
* Weight by totla jobs and exclude zero weight;
	WEIGHT S000;
	VAR Count;
	TITLE 'Summary of Count of Grocery within 500m of ODPair Line Weight All Jobs';
RUN;
PROC MEANS DATA = LODES7.Grocerycount_BrazosOD MAXDEC = 2 EXCLNPWGT;
* Weight by low income jobs and exclude zero weight;
	WEIGHT SE01;
	VAR Count;
	TITLE 'Summary of Count of Grocery within 500m of ODPair Line Weight 
		Total Number of jobs with earnings $1250/month or less';
RUN;
PROC MEANS DATA = LODES7.Grocerycount_BrazosOD MAXDEC = 2 EXCLNPWGT;
* Weight by middle income jobs and exclude zero weight;
	WEIGHT SE02;
	VAR Count;
	TITLE 'Summary of Count of Grocery within 500m of ODPair Line Weight 
		Total Number of jobs with earnings between $1250 and $3333/month';
RUN;
PROC MEANS DATA = LODES7.Grocerycount_BrazosOD MAXDEC = 2 EXCLNPWGT;
* Weight by high income jobs and exclude zero weight;
	WEIGHT SE03;
	VAR Count;
	TITLE 'Summary of Count of Grocery within 500m of ODPair Line Weight 
		Total Number of jobs with earnings greater than $3333/month';
RUN;
* Create a histogram plot of the Count;
PROC SGPLOT DATA = LODES7.Grocerycount_BrazosOD;
	HISTOGRAM Count / NBINS = 10 SHOWBINS SCALE = COUNT;
	TITLE 'Count of Grocery within 500m of ODPair Line';
Run;

PROC FREQ DATA = LODES7.Grocerycount_BrazosOD;
	TABLES COUNT;
RUN;
PROC TABULATE DATA = LODES7.Grocerycount_BrazosOD;
	VAR SE01;
	CLASS COUNT;
	TABLES COUNT, SE01 PCTN;
	TITLE 'Count of Grocery within 500m of ODPair Line jobs with earnings $1250/month or less';
RUN;
PROC TABULATE DATA = LODES7.Grocerycount_BrazosOD;
	VAR SE02;
	CLASS COUNT;
	TABLES COUNT, SE02 PCTN;
	TITLE 'Count of Grocery within 500m of ODPair Line jobs with earnings $1250-$3333/month';
RUN;
PROC TABULATE DATA = LODES7.Grocerycount_BrazosOD;
	VAR SE01 SE02 SE03;
	CLASS COUNT;
	TABLES COUNT, SE03;
	TITLE 'Count of Grocery within 500m of ODPair Line jobs with earnings greater than $3333/month';
RUN;
