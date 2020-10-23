/*-------------------------------------------------------------------*/
/* Program accesses the Summary Files produced by SF_ALL_Macro       */
/* and generates Sampling Error Measures and Their Derivations       */
/* for food stamp related proportions                                */
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
/* Date Last Updated: 28 Sept 2014                                   */
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
/* Run SF_All_Macro_NPR_20115yr.sas

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
%LET Include_prog = C:\Users\Nathanael\Dropbox\MyPrograms\;

/*-------------------------------------------------------------------*/
/* Important Macro Variables                                         */
/*-------------------------------------------------------------------*/

%LET ACS_Folder = acs2011_5yr;
%LET ACS_File = 20115;
%LET ACS_Geotype = All_Geographies_Not_Tracts_Block_Groups;
/* Program will load all sequence numbers or a range*/
/* Table 71 covers food stamp infromation */
%LET F_seqnum = 71; /*First sequence number to load */
%LET L_seqnum = 71; /*Last sequence number to load */

/*-------------------------------------------------------------------*/
/* Define SAS Library                                                */
/*-------------------------------------------------------------------*/
/* Set Library that contains the SequenceNumberTableNumberLookup */
/* In the original code this is called Stubs */
%let library = ACS;
LIBNAME &library "&dd_SASLib.&library";

/*-------------------------------------------------------------------*/
/* Start Program                                                     */
/*-------------------------------------------------------------------*/

data acs.Sf0071tx;
	retain name;
	set acs.Sf0071tx;
run;

/*-------------------------------------------------------------------*/
/* Keep only Geography Levels: County, state and urban rural         */
/*-------------------------------------------------------------------*/

data acs.Sf0071tx_county;
	set acs.Sf0071tx;
	if SUMLEVEL = '040' OR SUMLEVEL = '050';
	if COMPONENT = '01' OR COMPONENT = '43' OR COMPONENT = '00'; /* Urban Rural County*/
run;

/*-------------------------------------------------------------------*/
/* Generate Aggregated Proportions                                   */
/*-------------------------------------------------------------------*/

data acs.Sf0071tx_county;
	set acs.Sf0071tx_county;

/* Calculate Percentage of households that are:
- Families
- Families with no workers
- Families single working moms
- At least one person over 60

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
LB = [Estimate ACS] - [MOE CL];

Coefficient of Variation
CV = (SE / [Estimate ACS]) * 100;

Derived Estimates
Calculating MOEs for Aggregated Count Data

Example Families with no workers:
Married Couples No Workers: B22007m4
Male Headed Householders No Wife No Workers: B22007m14
Female Headed Householders No Husbande No Workers: B22007m19

Families no workers
*/
SNAP_noworkers_e = B22007e4 + B22007e14 + B22007e19;
SNAP_noworkers_m = sqrt(B22007m4**2 + B22007m14**2 + B22007m19**2);

attrib 	SNAP_noworkers_e format = 12.0 label = "SNAP Families no workers (e)"
		SNAP_noworkers_m format = 12.0 label = "SNAP Families no workers (m)";
/*
Proportion of SNAP households no workers
Numerator: SNAP_noworkers_e
Denominator: Total Universe households Household received Food Stamps/SNAP in the past 12 months: = B22001e2
*/

prprtn_nowrkrs_e = SNAP_noworkers_e / B22001e2;
prprtn_nowrkrs_m = sqrt(SNAP_noworkers_m**2 - ((prprtn_nowrkrs_e**2)*(B22001m2**2)))/B22001e2;
prprtn_nowrkrs_m95 = (1.960/1.645) * prprtn_nowrkrs_m;

attrib 	prprtn_nowrkrs_e format = 8.2 label = "Proportion of SNAP households no workers (e)"
		prprtn_nowrkrs_m format = 8.2 label = "Proportion of SNAP households no workers (m)"
		prprtn_nowrkrs_m95 format = 8.2 label = "Proportion of SNAP households no workers (m95)";

/*
Proportion of nonfamily households:
B22002e8 "Households With children under 18 years Nonfamily households"
B22002e14 "Households No children under 18 years Nonfamily households"
Nonfamily Households

*/
Nonfamilies_e = B22002e8 + B22002e14;
Nonfamilies_m = sqrt(B22002m8**2 + B22002m14**2);
Nonfamilies_m95 = (1.960/1.645) * Nonfamilies_m;

attrib 	Nonfamilies_e format = 12.0 label = "SNAP Households nonfamilies (e)"
		Nonfamilies_m format = 12.0 label = "SNAP Households nonfamilies (m)";
/*
Numerator: Nonfamilies_e
Denominator: Total Universe Houesholds Household received Food Stamps/SNAP in the past 12 months: = B22002e2

*/
prprtn_nnfmls_e = Nonfamilies_e / B22002e2;
prprtn_nnfmls_m = sqrt(Nonfamilies_m**2 - ((prprtn_nnfmls_e**2)*(B22002m2**2)))/B22002e2;


attrib 	prprtn_nnfmls_e format = 8.2 label = "Proportion of SNAP Households nonfamilies (e)"
		prprtn_nnfmls_m format = 8.2 label = "Proportion of SNAP Households nonfamilies (m)";

/*
Proportion of female headed households with workers:
Numerator: B22007e20 "Female householder, no husband present: 1 worker"
		+ B22007e21 "Female householder, no husband present: 2 worker"
		+ B22007e22 "Female householder, no husband present: 3 or more workers"
Denominator: Total Universe Houesholds Household received Food Stamps/SNAP in the past 12 months: = B22002e2

*/
wrkgmom_e = B22007e20 + B22007e21 + B22007e22;
wrkgmom_m = sqrt(B22007m20**2 + B22007m21**2 + B22007m22**2);
wrkgmom_m95 = (1.960/1.645) * wrkgmom_m;

prprtn_wrkgmom_e = wrkgmom_e / B22002e2;
prprtn_wrkgmom_m = sqrt(wrkgmom_m**2 - ((prprtn_wrkgmom_e**2)*(B22002m2**2)))/B22002e2;
prprtn_wrkgmom_m95 = (1.960/1.645) * prprtn_wrkgmom_m;

attrib 	prprtn_wrkgmom_e format = 8.2 label = "Proportion of SNAP Households Single Working Female (e)"
		prprtn_wrkgmom_m format = 8.2 label = "Proportion of SNAP Households Single Working Female (m)"
		prprtn_wrkgmom_m95 format = 8.2 label = "Proportion of SNAP Households Single Working Female (m95)";

/*
Proportion of male headed households with workers:
Numerator: B22007e15 "Male householder, no wife present: 1 worker"
		+ B22007e16 "Male householder, no wife present: 2 worker"
		+ B22007e17 "Male householder, no wife present: 3 or more workers"
Denominator: Total Universe Houesholds Household received Food Stamps/SNAP in the past 12 months: = B22002e2

*/
wrkgdad_e = B22007e15 + B22007e16 + B22007e17;
wrkgdad_m = sqrt(B22007m15**2 + B22007m16**2 + B22007m17**2);
wrkgdad_m95 = (1.960/1.645) * wrkgdad_m;

prprtn_wrkgdad_e = wrkgdad_e / B22002e2;
prprtn_wrkgdad_m = sqrt(wrkgdad_m**2 - ((prprtn_wrkgdad_e**2)*(B22002m2**2)))/B22002e2;
prprtn_wrkgdad_m95 = (1.960/1.645) * prprtn_wrkgdad_m;

attrib 	prprtn_wrkgdad_e format = 8.2 label = "Proportion of SNAP Households Single Working Male (e)"
		prprtn_wrkgdad_m format = 8.2 label = "Proportion of SNAP Households Single Working Male (m)"
		prprtn_wrkgdad_m95 format = 8.2 label = "Proportion of SNAP Households Single Working Male (m95)";

/*
Proportion of Married headed households with one worker:
Numerator: B22007e5 "Married-couple family: 1 worker"
		+ B22007e6 "Married-couple family: 2 worker"
		+ B22007e9 "Married-couple family: 3 or more workers"
Denominator: Total Universe Houesholds Household received Food Stamps/SNAP in the past 12 months: = B22002e2

*/
wrkgmarried_e = B22007e5 + B22007e6 + B22007e9;
wrkgmarried_m = sqrt(B22007m5**2 + B22007m6**2 + B22007m9**2);
wrkgmarried_m95 = (1.960/1.645) * wrkgmarried_m;

prprtn_wrkgmarried_e = wrkgmarried_e / B22002e2;
prprtn_wrkgmarried_m = sqrt(wrkgmarried_m**2 - ((prprtn_wrkgmarried_e**2)*(B22002m2**2)))/B22002e2;
prprtn_wrkgmarried_m95 = (1.960/1.645) * prprtn_wrkgmarried_m;

attrib 	prprtn_wrkgmarried_e format = 8.2 label = "Proportion of SNAP Married Working Households (e)"
		prprtn_wrkgmarried_m format = 8.2 label = "Proportion of SNAP Married Working Households (m)"
		prprtn_wrkgmarried_m95 format = 8.2 label = "Proportion of SNAP Married Working Households (m95)";

prprtn_wrkgmrd1wrkr_e = B22007e5 / B22002e2;
prprtn_wrkgmrd1wrkr_m = sqrt(B22007m5**2 - ((prprtn_wrkgmrd1wrkr_e**2)*(B22002m2**2)))/B22002e2;
prprtn_wrkgmrd1wrkr_m95 = (1.960/1.645) * prprtn_wrkgmrd1wrkr_m;

attrib 	prprtn_wrkgmrd1wrkr_e format = 8.2 label = "Proportion of SNAP Married Working Households 1 worker (e)"
		prprtn_wrkgmrd1wrkr_m format = 8.2 label = "Proportion of SNAP Married Working Households 1 worker (m)"
		prprtn_wrkgmrd1wrkr_m95 format = 8.2 label = "Proportion of SNAP Married Working Households 1 worker (m95)";

/* See if totals represent most of the SNAP households */

ttl_hshlds_e = wrkgmarried_e + wrkgdad_e + wrkgmom_e + Nonfamilies_e + SNAP_noworkers_e;
ttl_hshlds_m = sqrt(wrkgmarried_m**2 + wrkgdad_m**2 + wrkgmom_m**2 + Nonfamilies_m**2 + SNAP_noworkers_m**2);
ttl_hshlds_m95 = (1.960/1.645) * ttl_hshlds_m;

prprtn_ttl_hshlds_e = ttl_hshlds_e / B22002e2;
prprtn_ttl_hshlds_m = sqrt(ttl_hshlds_m**2 - ((prprtn_ttl_hshlds_e**2)*(B22002m2**2)))/B22002e2;
prprtn_ttl_hshlds_m95 = (1.960/1.645) * prprtn_ttl_hshlds_m;

ttl_prptn = prprtn_wrkgmom_e + prprtn_wrkgdad_e + prprtn_wrkgmarried_e + prprtn_nnfmls_e + prprtn_nowrkrs_e;
attrib 	prprtn_ttl_hshlds_e format = 8.2 label = "Proportion of Total Households (e)"
		prprtn_ttl_hshlds_m format = 8.2 label = "Proportion of Total Households (m)"
		prprtn_ttl_hshlds_m95 format = 8.2 label = "Proportion of Total Households (m95)";

run;

data acs.Sf0071tx_county;
	retain name
	B22001e1
	B22001m1
	B22002e2
	B22002m2
	B22007e2
	B22007m2
	prprtn_ttl_hshlds_e
	prprtn_ttl_hshlds_m95
	prprtn_wrkgmom_e
	prprtn_wrkgmom_m95
	prprtn_wrkgmarried_e
	prprtn_wrkgmarried_m95
	prprtn_wrkgmrd1wrkr_e
	prprtn_wrkgmrd1wrkr_m95
	prprtn_nowrkrs_e
	prprtn_nowrkrs_m95
	prprtn_wrkgdad_e
	prprtn_wrkgdad_m95
	prprtn_nnfmls_e
	prprtn_nnfmls_m
	SNAP_noworkers_e
	SNAP_noworkers_m;
	set acs.Sf0071tx_county;
run;

Proc Sort Data = acs.Sf0071tx_county;
   * by descending prprtn_ttl_hshlds_m95;
	by prprtn_ttl_hshlds_m95;
run;
