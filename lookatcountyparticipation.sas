 /*-------------------------------------------------------------------*/
 /*       Program for Looking at county participation                 */
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
 /* Date Last Updated: 15 Feb 2014                                    */
 /*-------------------------------------------------------------------*/
 /* Questions or problem reports concerning this material may be      */
 /* addressed to the author on github: https://github.com/npr99       */
 /*                                                                   */
 /*-------------------------------------------------------------------*/
 /* Data Source:                                                      */
 /* Texas Hunger Research Project (2013) TX County-Level Parcipation  */ 
 /*       Retrieved 10/2013 from (no longer availabe)                 */
 /*       http://texashungerresearch.org/data/snapcountymap           */
 /*-------------------------------------------------------------------*/

* Use a trailing @, then keep specific Census Blocks;
* Using INFILE to read in Comma-seperated value files, first obseravtion has headers therefore will be skipped (FIRSTOBS = 2)
Going to use Delimiter-Senstive DATA option (DSD) just in case missing values exist;
%LET dd_data = C:\Users\Nathanael\Dropbox\URSC PhD\My Data\TXHungerResearch\;
%LET dd_SASLib = C:\Users\Nathanael\MySASLib\;

LIBNAME SNAPPart "&dd_SASLib.SNAPPart";
* Bring in Excel File with County Id, Names and 2010 Population;
PROC IMPORT DATAFile = "&dd_Data.Texas County-Level Participation in SNAP 2010.xls" DBMS = XLS OUT = SNAPPart.SNAPCounty2010 REPLACE;
RUN;
* Create a histogram plot of the GProxMean;
PROC SGPLOT DATA = SNAPPart.SNAPCounty2010;
	HISTOGRAM Var3 / NBINS = 14 SHOWBINS SCALE = COUNT;
	TITLE 'Particpation by TX County 2010';
Run;

