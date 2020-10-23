 /*-------------------------------------------------------------------*/
 /*       Program for making point file with OD_pair IDs              */
 /* Program combines LODES data with Block Centroids            	  */
 /* With Origin and Destination Centroids a line file can be created  */
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
 /* Date Last Updated: 16 Feb 2014                                    */
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
 /* Census TabBlock 2013 for Texas                                    */
 /*-------------------------------------------------------------------*/

* Use a trailing @, then keep specific Census Blocks;
* Using INFILE to read in Comma-seperated value files, first obseravtion 
	has headers therefore will be skipped (FIRSTOBS = 2)
Going to use Delimiter-Senstive DATA option (DSD) just in case missing 
	values exist;
%LET dd_data = C:\Users\Nathanael\MyData\;
%LET dd_qgis = C:\Users\Nathanael\qgis\;
%LET dd_data2 = C:\Users\Nathanael\qgis\proposal_test\;
%LET dd_SASLib = C:\Users\Nathanael\MySASLib\;

LIBNAME LODES7 "&dd_SASLib.LODES7";

* Generate output OD file for single county;
DATA LODES7.Brazos_od_main_JT00_2010;
	ODPairID+1; * ID is Important for creating lines for each pair;
	INFILE "&dd_data.LODES\LODES7\tx\tx_od_main_JT00_2010.csv" 
		DLM = ',' FIRSTOBS = 2 DSD;
	INPUT w_geocode $15. +1 h_statefp $2. h_countyfp $3. @17 
		h_geocode $15. +1 S000 SA01 SA02 SA03 SE01 SE02 
		SE03 SI01 SI02 SI03 createdate;
	IF h_countyfp = '041'; * Brazos County is 041;
RUN;

 /*-------------------------------------------------------------------*/
* Combine LODES7 Data with Centroid Data from QGIS File that has Block 
Centroids for Texas;
* Bring in CSV File with Centroids for Texas;
DATA OCentroids_temp (keep=h_geocode geocodeLat geocodeLon) REPLACE;
	INFILE "&dd_qgis.shapefiles\tl_2013_48_tabblock\tl_2013_48_tabblock_centroids.csv" 
		DLM = ',' FIRSTOBS = 2 DSD;
	INPUT STATEFP COUNTYFP STATEFP10 COUNTYFP10 TRACTCE10 BLOCKCE10 
		SUFFIX1CE $ h_geocode :$15. NAME $ MTFCC $ UR10 $ UACE10 $ FUNCSTAT $ 
		ALAND AWATER geocodeLat geocodeLon;
	IF SUFFIX1CE = 'B' THEN DELETE; *Some GeoIDs are subsets of Blocks that 
		are not included in LODES;
RUN;

* Need to sort Centroids_temp by the h_geocode column;
PROC SORT DATA = OCentroids_temp OUT = OCentroidsGEOIDsort;
	BY h_geocode;
RUN;

PROC SORT DATA = LODES7.Brazos_od_main_JT00_2010 OUT = Brazos_o_main_JT00_2010_sort;
	BY h_geocode;
RUN;
* add home Census Block Centroids;
DATA LODES7.Brazos_2010withOcentroid REPLACE;
	MERGE Brazos_o_main_JT00_2010_sort OCentroidsGEOIDsort;
	BY h_geocode;
	IF ODPairID < 1 THEN DELETE;
Run;
 /*-------------------------------------------------------------------*/
* Combine LODES7 Data with Centroid Data from QGIS File that has Block 
Centroids for Texas;
* Bring in CSV File with Centroids for Texas;
* This run is to add work centroids;
DATA DCentroids_temp (keep=w_geocode geocodeLat geocodeLon) REPLACE;
	INFILE "&dd_qgis.shapefiles\tl_2013_48_tabblock\tl_2013_48_tabblock_centroids.csv" 
		DLM = ',' FIRSTOBS = 2 DSD;
	INPUT STATEFP COUNTYFP STATEFP10 COUNTYFP10 TRACTCE10 BLOCKCE10 
		SUFFIX1CE $ w_geocode :$15. NAME $ MTFCC $ UR10 $ UACE10 $ FUNCSTAT $ 
		ALAND AWATER geocodeLat geocodeLon;
	IF SUFFIX1CE = 'B' THEN DELETE; *Some GeoIDs are subsets of Blocks that 
		are not included in LODES;
RUN;

* Need to sort Centroids_temp by the h_geocode column;
PROC SORT DATA = DCentroids_temp OUT = DCentroidsGEOIDsort;
	BY w_geocode;
RUN;

PROC SORT DATA = LODES7.LODES7.Brazos_od_main_JT00_2010 OUT = Brazos_d_main_JT00_2010_sort;
	BY w_geocode;
RUN;
* add work Census Block Centroids;
DATA LODES7.Brazos_2010withDcentroid REPLACE;
	MERGE Brazos_d_main_JT00_2010_sort DCentroidsGEOIDsort;
	BY w_geocode;
	IF ODPairID < 1 THEN DELETE;
Run;
* Stack the two Origin Centroid file with the dest centroid file;
Data LODES7.Brazos_2010withODcentroid REPLACE;
	SET LODES7.Brazos_2010withOcentroid LODES7.Brazos_2010withDcentroid;
RUN;

PROC EXPORT DATA = LODES7.Brazos_2010withODcentroid OUTFILE = "&dd_data.LODES\LODES7\SASOutput\Brazos_2010withODcentroid.csv" REPLACE;
RUN;
