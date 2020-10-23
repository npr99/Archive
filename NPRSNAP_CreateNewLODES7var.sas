/*-------------------------------------------------------------------*/
/*       Programs for Creating a new LODES Data Variable             */
/* Program multiplies block data by higher GEOLevel data proportion  */
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
/* Date Last Updated: 9 June 2014                                    */
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


%MACRO CreateNewLODES7Var(
   State = ,
   MainState = ,
   Statefp = ,
   Year = ,
   GEOLevel = ,
   JobType =  ,
   ODType =);
/*-------------------------------------------------------------------*/
/* Calculate Food Stamp Workers By Census Tract                      */
/*-------------------------------------------------------------------*/
* Add Census Tract Proportions;

Proc Sort Data = &library..hw_&state._&mainstate.od_&ODType._&JobType._&year;
	BY h_censustractfp;
RUN;

Proc Sort Data = &lbprptns..sf0074&state._tract_prptns2;
	BY FIPS_Tract;
RUN;
DATA work.prptn_&state._&mainstate.od_&ODType._&JobType._&year REPLACE;
MERGE &library..hw_&state._&mainstate.od_&ODType._&JobType._&year
	  &lbprptns..sf0074&mainstate._tract_prptns2 
				(keep =FIPS_Tract B22007T2_e B22007T2_cv 
				prprtn_snapwrkr_e prprtn_snapwrkr_cv
				rename=(FIPS_Tract=h_censustractfp));
	BY h_censustractfp;
RUN;

* Calculate new worker count;

DATA &library..hwsxxx_&state._&mainstate.od_&ODType._&JobType._&year REPLACE;
	Set work.prptn_&state._&mainstate.od_&ODType._&JobType._&year;
	SXXX = S000 * prprtn_snapwrkr_e;
	attrib SXXX format = 5.4 label = "Estimated number of SNAP workers (e)";
RUN;

%MEND CreateNewLODES7Var;
