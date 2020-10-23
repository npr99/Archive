/*-------------------------------------------------------------------*/
/* Program accesses the Summary Files produced by SF_ALL_Macro       */
/* and generates Sampling Error Measures and Their Derivations       */
/* for Worker and Poverty related proportions                        */
/*          Modified by Nathanael Proctor Rosenheim                  */
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
/* Date Last Updated: 23 Oct 2014                                    */
/*-------------------------------------------------------------------*/
/* Questions or problem reports concerning this material may be      */
/* addressed to the author on github: https://github.com/npr99       */
/*                                                                   */
/*-------------------------------------------------------------------*/
/* Data Source:                                                      */
/* Rosenheim (2014) Modified Summary File All Macro                  */ 
/* Based on:
/* United States Census Bureau (2013) Summary File All Macro         */ 
/*    For ACS 2011 5yr Retrieved 9/27/2014 from                                    
ftp://ftp2.census.gov/acs2011_5yr/summaryfile/UserTools/SF_All_Macro.sas
/* The 2011 SF_All_Macro is unique.

/* See 2008-2012 ACS 5-Year Summary File Technical Documentation 
/* Appendix D.2 Creating a Table Using SAS 
/* Source:
http://www2.census.gov/acs2012_5yr/summaryfile/ACS_2008-2012_SF_Tech_Doc.pdf
/*-------------------------------------------------------------------*/

/*-------------------------------------------------------------------*/
/* Steps to follow to setup program                                  */
/*-------------------------------------------------------------------*/
/*
/* Run SF_All_Macro_NPR_20105yr.sas
/* Sequence Numbers
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
/* Important Macro Variables                                         */
/*-------------------------------------------------------------------*/

%LET year = 2010;
%LET ACS_Folder = acs&year._5yr;
%LET ACS_File = &year.5;

/* Program will load all sequence numbers or a range*/
/* Table 71 covers food stamp infromation */
/* Tables 44-52 have porverty data */
%LET F_seqnum = 44; /*First sequence number to load */
%LET L_seqnum = 44; /*Last sequence number to load */
%LET F_state = 48; /*First state to load */
%LET L_state = 48; /*Last state to load */

/* Census Tract, Block Group or Higher Geographies */
%LET GeographyLevel = Texas_Tracts_Block_Groups_Only;
* %LET GeographyLevel = Texas_All_Geographies_Not_Tracts_Block_Groups;

/* Level of geography interested in retaining */
%LET FinalGeo = CensusTract;
/*-------------------------------------------------------------------*/
/* Important Folder Locations                                        */
/*-------------------------------------------------------------------*/

/* Set Library that contains the SequenceNumberTableNumberLookup */
%LET dd_SASLib = C:\Users\Nathanael\Dropbox\MyData\Census\ACS\acs2010_5yr\;
/* Library for SAS Output Table */
%LET dd_SASLibOutput = &dd_SASLib.\SASOutput\&GeographyLevel.\;
/* Location where ReadDataFile Macro will save sas code */
%LET Include_Prog = &dd_SASLib.\usertools\SF_All_Macro_Output\;
/* Location for state level sequence files */
%LET dd_ACSSeqFiles = &dd_SASLib.\2006-2010_ACSSF_By_State_All_Tables\&GeographyLevel.\;
/* Loction for Geography files */
%LET dd_Geography_files = &dd_SASLib.\2006-2010_ACSSF_By_State_All_Tables\&GeographyLevel.\;

/*Folder for Constructed Tabels */
%LET dd_SASLibOutput2 = &dd_SASLib.\SASOutput\NPR_Tables\;

/*-------------------------------------------------------------------*/
/* Define SAS Library                                                */
/*-------------------------------------------------------------------*/
/* Set Library that contains the SequenceNumberTableNumberLookup */
LIBNAME ACS "&dd_SASLib";
/* Library for SAS Output Table */
LIBNAME ACSOut "&dd_SASLibOutput";
/* Library for Constructed SAS Output Table */
LIBNAME ACSOut2 "&dd_SASLibOutput2";
/*-------------------------------------------------------------------*/
/* Start Program                                                     */
/*-------------------------------------------------------------------*/
/* Set State Abbrevtion - for future use in program that runs for multiple states */
%LET geo = tx;
%let var=000&F_seqnum;
%let seq = %substr(&var,%length(&var)-3,4);

data acsout2.&ACS_Folder.SF&seq&geo&FinalGeo;
	retain name;
	set acsout.SF&seq&geo;
run;

/*-------------------------------------------------------------------*/
/* Keep only Geography Levels: County, state and urban rural         */
/*-------------------------------------------------------------------*/

data acsout2.&ACS_Folder.SF&seq&geo&FinalGeo REPLACE;
	set acsout2.&ACS_Folder.SF&seq&geo&FinalGeo;
	if &FinalGeo = CensusTract then do;
		if SUMLEVEL = '140';
	end;
	FIPS_CensusTract = STATE || COUNTY || TRACT;
run;

/*-------------------------------------------------------------------*/
/* Generate Aggregated Propotions                                    */
/*-------------------------------------------------------------------*/

/* Calculate Percentage of persons in poverty

Notes:
Census 2009 A Compass for Understanding and Using ACS Data What Researchers need to know
http://www.census.gov/acs/www/Downloads/handbooks/ACSResearch.pdf

Margin of Error (m) is 90% Confidence interval
To convert to 95% CI 
m95 = (1.960/1.645) * [MOE ACS];

Calculate Standard Error
SE = [MOE ACS] / 1.645;

Confidence Interval
Using the ACS MOE would be a 90-percent CI;
LB = [Estimate ACS] - [MOE CL];
UB = [Estimate ACS] + [MOE CL];

Coefficient of Variation
CV = (SE / [Estimate ACS]) * 100;

Derived Estimates
Calculating MOEs for Aggregated Count Data

Universe:  Population for whom poverty status is determined 
Total: (e) B17001e1
Income in the past 12 months below poverty level: B17001e2 
*/

/*
Proportion of population in poverty
Numerator: B17001e2
Denominator: B17001e1
*/
%LET VarName = pvrty;
%LET VarLabel = 'Persons below poverty';

%LET Est_Num = B17001e2; /* Estimate Numerator */
%LET Est_Den = B17001e1; /* Estimate denominator */
%LET MOE_NUM = B17001m2; /* Margin of error numerator */
%LET MOE_DEN = B17001m1; /* Margin of error denominator */


data acsout2.NPR_&ACS_Folder.SF&seq&geo REPLACE;
	set acsout2.&ACS_Folder.SF&seq&geo&FinalGeo;

/* Calculate proportion for nonzero denominators */
If &Est_Den NE 0 then 
	prprtn_&varname._e = &Est_Num / &Est_Den;
* Check to make sure that the Margin of error is less than the denominator;
If &Est_Den = 0 OR &Est_Num = 0 then do;
	prprtn_&varname._e = 0;
	prprtn_&varname._m = 0;
	prprtn_&varname._m95 = 0;
	prprtn_&varname._lb = 0;
	prprtn_&varname._ub = 0;
	end;
Else if (&MOE_NUM.**2 - ((prprtn_&varname._e**2)*(&MOE_DEN.**2))) LT 0 then do;
	prprtn_&varname._m = 1;
	prprtn_&varname._m95 = 1;
	prprtn_&varname._lb = 0;
	prprtn_&varname._ub = 1;
	end;
Else do;
	prprtn_&varname._m = sqrt(&MOE_NUM.**2 - ((prprtn_&varname._e**2)*(&MOE_DEN.**2)))/ &Est_Den.;
	prprtn_&varname._m95 = (1.960/1.645) * prprtn_&varname._m;
	prprtn_&varname._lb = prprtn_&varname._e - prprtn_&varname._m95;
	prprtn_&varname._ub = prprtn_&varname._e + prprtn_&varname._m95;
end;

attrib 	prprtn_&varname._e format = 8.2 label = "Proportion of &VarLabel. (e)"
		prprtn_&varname._m format = 8.2 label = "Proportion of &VarLabel. (m)"
		prprtn_&varname._m95 format = 8.2 label = "Proportion of &VarLabel. m95)"
		prprtn_&varname._lb format = 8.2 label = "Proportion of &VarLabel. (lb)"
		prprtn_&varname._ub format = 8.2 label = "Proportion of &VarLabel. (ub)";

run;


data acsout2.NPR_&ACS_Folder.SF&seq&geo REPLACE;
	Set acsout2.NPR_&ACS_Folder.SF&seq&geo;
	Keep
		Name
		FIPS_CensusTract
		&Est_Num
		&Est_Den
		&MOE_NUM
		&MOE_DEN
		prprtn_&varname.:;
run;

data acsout2.NPR20_&ACS_Folder.SF&seq&geo REPLACE;
	Set acsout2.NPR_&ACS_Folder.SF&seq&geo;
	if prprtn_&varname._lb GT .2;
run;
