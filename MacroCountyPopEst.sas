 /*-------------------------------------------------------------------*/
 /*       Macro for Creating Dataset with County population Estimates */
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
 /* Date Last Updated: 15July2014                                     */
 /*-------------------------------------------------------------------*/
 /* Questions or problem reports concerning this material may be      */
 /* addressed to the author on github: https://github.com/npr99       */
 /*                                                                   */
 /*-------------------------------------------------------------------*/
 /* Data Source:                                                      */
 /* https://www.census.gov/popest/data/intercensal/county/county2010.html
 /*-------------------------------------------------------------------*/


%MACRO MacroCountyPopEst(
   dd_data = , 
   dd_data2 = , 
   dd_SASLib = ,
   Include_prog = ,
   EndYear =);

/*-------------------------------------------------------------------*/
/* Import Primary Files from Original Source                         */
/*-------------------------------------------------------------------*/

* Import Census 2000-2010 Population Estimates list Retreived from
https://www.census.gov/popest/data/intercensal/county/county2010.html;

Proc import datafile = "&dd_data.Census\Intercensal\CO-EST00INT-TOT.csv"
	DBMS = DLM
	Out = Work.CountyEst2000_2009 REPLACE; 
	Delimiter = ',';
	Getnames = yes;
RUN;

*Add Five Digit FIPSCODE;
DATA Work.CountyEst2000_2009 REPLACE;
	SET Work.CountyEst2000_2009;
	IF County < 10 THEN County_FIPS_Code = "00" || PUT(County, 1.);
		ELSE IF County < 100 THEN 
			County_FIPS_Code = "0" || PUT(County, 2.);
		ELSE IF County < 1000 THEN 
			County_FIPS_Code = PUT(County, 3.);
	IF State < 10 THEN StateFP = "0" || PUT(State, 1.);
	ELSE IF State < 100 THEN 
		StateFP = PUT(State, 2.);
	 FIPS_County = StateFP || County_FIPS_Code;
RUN;

*Transpose on year;
Proc Transpose data = Work.CountyEst2000_2009 
	OUT = Work.CountyEst2000_2009Long;
	by FIPS_County;
	var POPESTIMATE2000-POPESTIMATE2009;
Run;

DATA Work.CountyEst2000_2009Long2 REPLACE;
	Set Work.CountyEst2000_2009Long;
	year=input(substr(_name_, 12, 4), 4.);
	Drop _name_;
	Rename COL1 = POPESTIMATE;
Run;


* Import Census 2010-2013 Population Estimates list Retreived from
https://www.census.gov/popest/data/historical/2010s/vintage_2013/datasets.html
https://www.census.gov/popest/data/counties/totals/2013/files/CO-EST2013-Alldata.csv;
Proc import datafile = "&dd_data.Census\Intercensal\CO-EST&EndYear.-Alldata.csv"
	DBMS = DLM
	Out = Work.CountyEst2010_&EndYear REPLACE; 
	Delimiter = ',';
	Getnames = yes;
RUN;

*Add Five Digit FIPSCODE;
DATA Work.CountyEst2010_&EndYear REPLACE;
	SET Work.CountyEst2010_&EndYear;
	IF County < 10 THEN County_FIPS_Code = "00" || PUT(County, 1.);
		ELSE IF County < 100 THEN 
			County_FIPS_Code = "0" || PUT(County, 2.);
		ELSE IF County < 1000 THEN 
			County_FIPS_Code = PUT(County, 3.);
	IF State < 10 THEN StateFP = "0" || PUT(State, 1.);
	ELSE IF State < 100 THEN 
		StateFP = PUT(State, 2.);
	 FIPS_County = StateFP || County_FIPS_Code;
RUN;

*Transpose on year;
Proc Transpose data = Work.CountyEst2010_&EndYear 
	OUT = Work.CountyEst2010_&EndYear.Long;
	by FIPS_County;
	var POPESTIMATE2010-POPESTIMATE&EndYear;
Run;

DATA Work.CountyEst2010_&EndYear.Long2 REPLACE;
	Set Work.CountyEst2010_&EndYear.Long;
	year=input(substr(_name_, 12, 4), 4.);
	Drop _name_;
	Rename COL1 = POPESTIMATE;
Run;

/*-------------------------------------------------------------------*/
/* Append 2000-2010 to 2010-&EndYear                                     */
/*-------------------------------------------------------------------*/
* Delete the existing dataset before appending;
PROC datasets library=work NOLIST;
	DELETE CountyEst2000_&EndYear;
Run;

PROC APPEND BASE = work.CountyEst2000_&EndYear
	DATA = Work.CountyEst2010_&EndYear.Long2;
RUN;

PROC APPEND BASE = work.CountyEst2000_&EndYear
	DATA = Work.CountyEst2000_2009Long2;
RUN;

PROC SORT DATA = work.CountyEst2000_&EndYear;
	BY FIPS_County Year;
RUN;
/*-------------------------------------------------------------------*/
/* Import CENSUS FIPS DATA                                           */
/*-------------------------------------------------------------------*/

* Include FIPS Macro;
* Program creates work.FIPS_state, work.FIPS_County datasets;
%INCLUDE "&Include_prog.Macros_SAS\MacroFIPS_County.sas";

%MacroFIPS_County(
   dd_data = &dd_data, 
   dd_data2 = &dd_data2, 
   dd_SASLib = &dd_SASLib,
   Include_prog = &Include_prog);

* Add CountyName to PopEstimates;
PROC SORT DATA = work.FIPS_county;
	By FIPS_county; 
RUN;
PROC SORT DATA = work.CountyEst2000_&EndYear;
	By FIPS_county;
RUN;
DATA work.CountyEst2000_&EndYear REPLACE;
	MERGE work.CountyEst2000_&EndYear work.FIPS_county 
		(Keep = StateFP CountyName3 FIPS_County);
	BY FIPS_county;
RUN;

Data work.CountyEst2000_&EndYear REPLACE;
	Set work.CountyEst2000_&EndYear;
	If POPESTIMATE NE "";
	If substr(FIPS_County, 3, 3) = "000" Then 
		Do; 
		StateFP = substr(FIPS_County, 1, 2);
		CountyName3 = "StateTotal";
		End;
Run;

* Add StateAbbr to PopEstimates;
PROC SORT DATA = work.FIPS_state;
	By StateFP; 
RUN;
PROC SORT DATA = work.CountyEst2000_&EndYear;
	By StateFP;
RUN;
DATA work.CountyEst2000_&EndYear REPLACE;
	MERGE work.CountyEst2000_&EndYear work.FIPS_state;
	BY StateFP;
RUN;

Data work.CountyEst2000_&EndYear REPLACE;
	Set work.CountyEst2000_&EndYear;
	If POPESTIMATE NE "";
Run;
%MEND;



