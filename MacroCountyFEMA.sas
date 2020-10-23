/*-------------------------------------------------------------------*/
/*       Macro for building county level FEMA Disaster Data          */
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
/* Date Last Updated: 15July15                                       */
/*-------------------------------------------------------------------*/
/* Questions or problem reports concerning this material may be      */
/* addressed to the author on github: https://github.com/npr99       */
/*                                                                   */
/*-------------------------------------------------------------------*/

/*-------------------------------------------------------------------*/
/* Important Folder Locations                                        */
/*---------------------------------

%LET dd_data = C:\Users\Nathanael\Dropbox\MyData\;
%LET dd_SASLib = C:\Users\Nathanael\MySASLib\;
%LET Include_prog = C:\Users\Nathanael\Dropbox\MyPrograms\;

----------------------------------*/

/*-------------------------------------------------------------------*/
/* Start Macro Here                                                  */
/*-------------------------------------------------------------------*/

%MACRO MacroCountyFEMA(
   dd_data = , 
   dd_SASLib = ,
   Include_prog = );

%LET dataset = FEMA;
%LET library = FEMA;
LIBNAME &dataset "&dd_SASLib.&dataset.";

/*-------------------------------------------------------------------*/
/*-------------------------------------------------------------------*/
/* Import Variables from Primary Sources                             */
/*-------------------------------------------------------------------*/
/*-------------------------------------------------------------------*/

/*-------------------------------------------------------------------*/
/* Import CENSUS FIPS DATA                                           */
/*-------------------------------------------------------------------*/

* Include FIPS Macro;
* Program creates work.FIPS_state, work.FIPS_County datasets;
%INCLUDE "&Include_prog.Macros_SAS\MacroFIPS_County.sas";

%MacroFIPS_County(
   dd_data = &dd_data, 
   dd_SASLib = &dd_SASLib,
   Include_prog = &Include_prog);


/*-------------------------------------------------------------------*/
/* Dataset defines which geographic areas that experience disasters  */
/*-------------------------------------------------------------------*/
/* FEMA Disaster Declarations Summary
Accessed July 15, 2014
http://www.fema.gov/media-library/assets/documents/28318

FEMA Disaster Declarations Summary - Open Government Dataset
FEMA Disaster Declarations Summary is a summarized dataset describing 
all federally declared disasters. This information begins with the 
first disaster declaration in 1953 and features all three disaster 
declaration types: major disaster, emergency and fire management 
assistance. The dataset includes declared recovery programs and 
geographic areas (county not available before 1964; 
Fire Management records are considered partial due 
to historical nature of the dataset).
*/

PROC IMPORT DATAFile = "&dd_data.FEMA\FEMADeclarations.xlsx" 
	DBMS = XLSX
	OUT = work.FEMADeclarations_TEMP1 REPLACE;
	Sheet = "FEMA Declarations";
	Getnames = No;
	MIXED = YES;
RUN;

Data work.FEMADeclarations_TEMP2 Replace;
	Set work.FEMADeclarations_TEMP1;
	If A = "" Then Delete;
	If A =: "Declaration Data Set" Then Delete;
	If A =: "Disaster Number" Then Delete;
	DisasterNum = input(A,$Char4.);
	IH_Dec = input(B,$Char3.);
	IA_Dec = input(C,$Char3.);
	PA_Dec = input(D,$Char3.);
	HM_Dec = input(E,$Char3.);
	State = input(F,$Char2.);
    XLDeclaration_date = input(G,Comma20.);
    Declaration_date = put((INT(XLDeclaration_date) - 21916), DATE.);
	DisasterType = input(H,$Char2.);
	IncidentType = input(I,$Char20.);
	Title = input(J,$Char80.);
	XLIncidentBeginDate = input(K,Comma20.);
	IncidentBeginDate = put((INT(XLIncidentBeginDate) - 21916), DATE.);
	XLIncidentEndDate = input(L,Comma20.);
	IncidentEndDate = put((INT(XLIncidentEndDate) - 21916), DATE.);
	XLDstCloseOutDate = input(M,Comma20.);
	DstCloseOutDate = put((INT(XLDstCloseOutDate) - 21916), DATE.);
	CountyName = input(N,$Char43.);
	Year = YEAR(INT(XLDeclaration_date)- 21916);
Run;

Data &dataset..FEMADeclarations Replace;
	Set work.FEMADeclarations_TEMP2
	(DROP = A B C D E F G H I J K L M N);
Run;

* Fix New England County Names to Match FIPS;
Data &dataset..FEMADeclarations Replace;
	Set &dataset..FEMADeclarations;
	If CountyName NE "" Then 
		Do;
		If State in ("CT" "MA" "ME" "VT" "NH" "RI") AND find(CountyName, ")") GT 0 THEN
			CountyName3 = substr(CountyName,1,find(CountyName, ")"));
		Else CountyName3 = CountyName;
		End;
Run;

/*-------------------------------------------------------------------*/
/* Add FIPS Codes to Declaration Data                                */
/*-------------------------------------------------------------------*/
/* 
Run FIPS_County Macro first to create Work files with FIPS Codes
*/

* Add State FIPS code to Declaration data;
PROC SORT DATA = work.FIPS_State;
	By State; 
RUN;
PROC SORT DATA = &library..FEMADeclarations;
	By State; 
RUN;
DATA &library..FEMADeclarations REPLACE;
	MERGE &library..FEMADeclarations work.FIPS_State;
	BY State;
RUN;

* Add FIPS_County code to Declaration data;
PROC SORT DATA = work.FIPS_county;
	By StateFP CountyName3; 
RUN;
PROC SORT DATA = &library..FEMADeclarations;
	By StateFP CountyName3;
RUN;
DATA &library..FEMADeclarations REPLACE;
	MERGE &library..FEMADeclarations work.FIPS_county 
		(Keep = StateFP CountyName3 FIPS_County);
	BY StateFP CountyName3;
RUN;

/*-------------------------------------------------------------------*/
/* Merge SEER County Pop Estimates 1990-2012                          */
/*-------------------------------------------------------------------*/

* Include County Population Estimates;
* This will help determine the extent of IA, IH, and PA Distributions;
libname SEER "&dd_SASLib.SEER";
* Merge County Declartions with PA Amounts;
PROC SORT DATA = SEER.Seer_totalpopall;
	By FIPS_County Year; 
RUN;
PROC SORT DATA = &library..FEMADeclarations;
	By FIPS_County Year; 
RUN;
DATA &library..FEMADeclarations REPLACE;
	MERGE &library..FEMADeclarations SEER.Seer_totalpopall;
	BY FIPS_County Year;
RUN;
/*-------------------------------------------------------------------*/
/* Dataset quantifies public assistance distributed after disaster   */
/*-------------------------------------------------------------------*/

/* FEMA Public Assistance Funded Projects Detail - Open Government Initiative
http://www.fema.gov/media-library/assets/documents/28331

Through the PA Program (CDFA Number 97.036), FEMA provides supplemental 
Federal disaster grant assistance for debris removal, emergency 
protective measures, and the repair, replacement, or restoration of 
disaster-damaged, publicly owned facilities and the facilities of certain 
Private Non-Profit (PNP) organizations. The PA Program also encourages 
protection of these damaged facilities from future events by providing 
assistance for hazard mitigation measures during the recovery process.  
This dataset lists all public assistance recipients, designated as 
Applicants in the data. The dataset also features a list of every 
funded, individual project, called project worksheets.

All records are derived from the National Emergency Management 
Information System (NEMIS), which went into production in 1998, 
and its successor.
*/
/* NPR - Modified original dataset using Excel.
Using pivot tables I collapsed the 9 sheets into 1 sheet.
For each sheet I had a pivot table the summed the PA amounts 
by state, county and disaster 
C:\Users\Nathanael\MyData\FEMA\PublicAssistanceByCountyByDisaster.xlsx

Converted to xls and saved in Dropbox
*/
PROC IMPORT DATAFile = "&dd_data.FEMA\PublicAssistanceByCountyByDisaster.xls" 
	DBMS = XLS
	OUT = work.FEMAPAbycounty_Temp REPLACE;
	MIXED = YES;
RUN;

Data &library..FEMAPAbycounty;
	Set work.FEMAPAbycounty_Temp;
	DisasterNum = put(Disaster_Number, 4.);
	FIPS_County2 = input(FIPS_County, $char5.);
	Drop FIPS_County;
	Drop State;
	Rename FIPS_County2 = FIPS_County;
Run;

* Merge County Declartions with PA Amounts;
PROC SORT DATA = &library..FEMAPAbycounty;
	By FIPS_County DisasterNum; 
RUN;
PROC SORT DATA = &library..FEMADeclarations;
	By FIPS_County DisasterNum; 
RUN;
DATA &library..FEMADecl_PA REPLACE;
	MERGE &library..FEMADeclarations &library..FEMAPAbycounty;
	BY FIPS_County DisasterNum;
RUN;

/*-------------------------------------------------------------------*/
/* Dataset quantifies FEMA assistance by disaster IA, IH, PA         */
/*-------------------------------------------------------------------*/
/* Data was scraped using the OutWit Program from the FEMA website
Data provide IA and IH totals by disaster.
No source of information could be found that provides IA by county.
This part of the program will allow for PerCapita IA, IH and PA by 
disaster to be calculated.
*/

PROC IMPORT DATAFile = "&dd_data.FEMA\FEMADisasterWebPageData.csv" 
	DBMS = CSV
	OUT = work.FEMADstrWPData_Temp 
	REPLACE;
	GetNames = Yes;
RUN;

Data work.FEMADstrWPData_Temp;
	Set work.FEMADstrWPData_Temp;
	DisasterNum2 = put(DisasterNum, 4.);
	Drop DisasterNum;
	Rename DisasterNum2 = DisasterNum;
Run;
/*-------------------------------------------------------------------*/
/* Organize Disaster Data By DisasterNumber                          */
/*-------------------------------------------------------------------*/
/*
Want to get total population counts and Public Assistance distributed
for each disaster
*/
PROC SORT DATA = &library..FEMADecl_PA;
	By DisasterNum;
RUN;

Data &library..TotalsFEMADisasterNum Replace;
	Set &library..FEMADecl_PA;
	If DisasterNum NE "";
Run;

Data &library..TotalsFEMADisasterNum Replace;
	Set &library..TotalsFEMADisasterNum;
	By DisasterNum;
	If first.DisasterNum Then do;
		Pop_IH = 0;
		Pop_IA = 0;
		Pop_PA = 0;
		Pop_HM = 0;
		SumDNPA_PrjAmnt = 0;
		SumDNPA_FedOblg = 0;
		SumDNPA_TtlOblg = 0;
	End;
	If IH_Dec = "Yes" Then Pop_IH + t_pop;
	If IA_Dec = "Yes" Then Pop_IA + t_pop;
	If PA_Dec = "Yes" Then Pop_PA + t_pop;
	If HM_Dec = "Yes" Then Pop_HM + t_pop;
	If Sum_of_Project_Amount GT 0 Then SumDNPA_PrjAmnt + Sum_of_Project_Amount;
	If Sum_of_Federal_Share_Obligated GT 0 Then SumDNPA_FedOblg + Sum_of_Federal_Share_Obligated;
	If Sum_of_Total_Obligated GT 0 Then SumDNPA_TtlOblg + Sum_of_Total_Obligated;
	If last.DisasterNum then OUTPUT;
Run;

Data &library..TotalsFEMADisasterNum Replace;
	Set &library..TotalsFEMADisasterNum
	(KEEP =
		DisasterNum
		Year
 		Pop_:
		SumDNPA_:);
	If Pop_PA GT 0 Then Do;
		PerCapitaDNPA_PrjAmnt = Round(SumDNPA_PrjAmnt / Pop_PA, 0.01);
		PerCapitaDNPA_FedOblg = Round(SumDNPA_FedOblg / Pop_PA, 0.01);
		PerCapitaDNPA_TtlOblg = Round(SumDNPA_TtlOblg / Pop_PA, 0.01);
		End;
	Else Do;
		PerCapitaDNPA_PrjAmnt = 0;
		PerCapitaDNPA_FedOblg = 0;
		PerCapitaDNPA_TtlOblg = 0;
	End;
Run;
/*-------------------------------------------------------------------*/
/* Merge Disaster Data By DisasterNumber                             */
/*-------------------------------------------------------------------*/
/* This part of the program will bring together the PA data from
OpenFEMA with the Scraped webdata. Combining IA and IH data with 
Categorical PA Data;
*/
PROC SORT DATA = &library..TotalsFEMADisasterNum;
	By DisasterNum; 
RUN;
PROC SORT DATA = work.FEMADstrWPData_Temp;
	By DisasterNum; 
RUN;
DATA &library..FEMADisasterNumTotals REPLACE;
	MERGE &library..TotalsFEMADisasterNum work.FEMADstrWPData_Temp;
	BY DisasterNum;
RUN;

* Add Percapita For IA, IH, Other;
Data &library..FEMADisasterNumTotals Replace;
	Set &library..FEMADisasterNumTotals;
	If Year GE 2000 AND Year LE 2013; * Years with Pop Data;
	Pop_IAIH = Max(Pop_IA,POP_IH);
	If Pop_IAIH GT 0 AND Total_IAIH GT 0 THEN DO;
		PerCapitaIAIH = Round(Total_IAIH / Pop_IAIH, 0.01);
		PctPop_IA_Applications = Round(Total_IA_Applications / Pop_IAIH, 0.01);
		PerApplication = Round(Total_IAIH / Total_IA_Applications, 0.01);
		PerCapitaHA = Round(Total_HA / Pop_IAIH, 0.01);
		PerCapitaOtherIA = Round(Total_OtherIA / Pop_IAIH, 0.01);
		End;
	Else Do;
		PerCapitaIAIH = 0;
		PctPop_IA_Applications = 0;
		PerApplication = 0;
		PerCapitaHA = 0;
		PerCapitaOtherIA = 0;
	End;
	If Pop_PA GT 0 THEN DO;
		PerCapitaTotal_PAGrants = Round(Total_PAGrants / Pop_PA, 0.01);
		PerCapitaPACATAB = Round(PA_CAT_AB / Pop_PA, 0.01);
		PerCapitaPACATCG = Round(PA_CAT_CG / Pop_PA, 0.01);
		End;
	Else Do;
		PerCapitaTotal_PAGrants = 0;
		PerCapitaPACATAB = 0;
		PerCapitaPACATCG = 0;
	End;
Run;

PROC SORT DATA = &dataset..FEMADisasterNumTotals;
	By DisasterNum; 
RUN;
/*-------------------------------------------------------------------*/
/* Merge Disaster Data By DisasterNumber IA with PA data             */
/*-------------------------------------------------------------------*/
/* This part of the program will bring together the PA data from
OpenFEMA with the Scraped webdata. Combining IA and IH data with 
Categorical PA Data;
This will be compared with county level data that has PA info but no IA
data.
*/
PROC SORT DATA = &library..FEMADisasterNumTotals;
	By DisasterNum; 
RUN;
PROC SORT DATA = &library..FEMADecl_PA;
	By DisasterNum; 
RUN;
DATA &library..FEMADecl_PAwithIA REPLACE;
	MERGE &library..FEMADisasterNumTotals &library..FEMADecl_PA;
	BY DisasterNum;
RUN;
PROC SORT DATA = &library..FEMADecl_PAwithIA;
	By FIPS_County Year; 
RUN;
/*-------------------------------------------------------------------*/
/* Convert Declaration data so that is one county one year           */
/*-------------------------------------------------------------------*/

PROC SORT DATA = &library..FEMADecl_PAwithIA;
	By FIPS_County Year;
RUN;

Data &library..TotalsFEMADcls_PAwithIAv1 Replace;
	Set &library..FEMADecl_PAwithIA;
	If FIPS_County NE "";
	If Year NE "";
Run;

Data &library..TotalsFEMADcls_PAwithIAv2 Replace;
	Set &library..TotalsFEMADcls_PAwithIAv1;
	By FIPS_County Year;
	If first.Year Then do;
		Sum_DisasterNum = 0;
		Sum_IH_Dec = 0;
		Sum_IA_Dec = 0;
		Sum_PA_Dec = 0;
		Sum_HM_Dec = 0;
		Sum_DR = 0;
		Sum_EM = 0;
		Sum_FM = 0;
		Sum_FS = 0;
		DR_Earthquake = 0;
		DR_Fire = 0;
		DR_Flood = 0;
		DR_Hurricane = 0;
		DR_SevereIceStorm = 0;
		DR_SevereStorm = 0;
		DR_Snow = 0;
		DR_Tornado = 0;
		DR_Other = 0;
		It_Earthquake = 0;
		It_Fire = 0;
		It_Flood = 0;
		It_Hurricane = 0;
		It_SevereIceStorm = 0;
		It_SevereStorm = 0;
		It_Snow = 0;
		It_Tornado = 0;
		It_Other = 0;
		Duration_DR = 0;
		Duration_EM = 0;
		Duration_FM = 0;
		Duration_FS = 0;
		SumPA_PrjAmnt = 0;
		SumPA_FedOblg = 0;
		SumPA_TtlOblg = 0;
		* Add data on which part of the year dr occured;
		Q1 = 0;
		Q2 = 0;
		Q3 = 0;
		Q4 = 0;
		DN_PerCapitaIAIH = 0;
		DN_PerApplication = 0;
		DN_PerCapitaHA = 0;
		DN_PerCapitaOtherIA = 0;
		DN_PerCapitaTotal_PAGrants = 0;
		DN_PerCapitaPACATAB = 0;
		DN_PerCapitaPACATCG = 0;	
 		End;
	If DisasterNum NE "" Then Sum_DisasterNum + 1;
	If IH_Dec = "Yes" Then Sum_IH_Dec + 1;
	If IA_Dec = "Yes" Then Sum_IA_Dec + 1;
	If PA_Dec = "Yes" Then Sum_PA_Dec + 1;
	If HM_Dec = "Yes" Then Sum_HM_Dec + 1;
	If DisasterType = "DR" Then do;
		Sum_DR + 1;
		If IncidentType = "Earthquake" Then DR_Earthquake + 1;
		Else If IncidentType = "Fire" Then DR_Fire + 1;
		Else If IncidentType = "Flood" Then DR_Flood + 1;
		Else If IncidentType = "Hurricane" Then DR_Hurricane + 1;
		Else If IncidentType = "Severe Ice Storm" Then DR_SevereIceStorm + 1;
		Else If IncidentType = "Severe Storm(s)" Then DR_SevereStorm + 1;
		Else If IncidentType = "Tornado" Then DR_Tornado + 1;
		Else If IncidentType = "Snow" Then DR_Snow + 1;
		Else If IncidentType NE "" Then DR_Other + 1;
		end;
	If DisasterType = "EM" Then Sum_EM + 1;
	If DisasterType = "FM" Then Sum_FM + 1;
	If DisasterType = "FS" Then Sum_FS + 1;
	If IncidentType = "Earthquake" Then IT_Earthquake + 1;
	Else If IncidentType = "Fire" Then IT_Fire + 1;
	Else If IncidentType = "Flood" Then IT_Flood + 1;
	Else If IncidentType = "Hurricane" Then IT_Hurricane + 1;
	Else If IncidentType = "Severe Ice Storm" Then IT_SevereIceStorm + 1;
	Else If IncidentType = "Severe Storm(s)" Then IT_SevereStorm + 1;
	Else If IncidentType = "Tornado" Then IT_Tornado + 1;
	Else If IncidentType = "Snow" Then IT_Snow + 1;
	Else If IncidentType NE "" Then IT_Other + 1;
	* Calculate days between begin and end;
	If DisasterType = "DR" Then Duration_DR +
		((INT(XLIncidentEndDate) - 21916) - (INT(XLIncidentBeginDate) - 21916)) + 1;
	If DisasterType = "EM" Then Duration_EM +
		((INT(XLIncidentEndDate) - 21916) - (INT(XLIncidentBeginDate) - 21916)) + 1;
	If DisasterType = "FM" Then Duration_FM +
		((INT(XLIncidentEndDate) - 21916) - (INT(XLIncidentBeginDate) - 21916)) + 1;
	If DisasterType = "FS" Then Duration_FS +
		((INT(XLIncidentEndDate) - 21916) - (INT(XLIncidentBeginDate) - 21916)) + 1;
	If Sum_of_Project_Amount GT 0 Then SumPA_PrjAmnt + Sum_of_Project_Amount;
	If Sum_of_Federal_Share_Obligated GT 0 Then SumPA_FedOblg + Sum_of_Federal_Share_Obligated;
	If Sum_of_Total_Obligated GT 0 Then SumPA_TtlOblg + Sum_of_Total_Obligated;
	If QTR(INT(XLDeclaration_date)- 21916) = 1 Then Q1 + 1;
	If QTR(INT(XLDeclaration_date)- 21916) = 2 Then Q2 + 1;
	If QTR(INT(XLDeclaration_date)- 21916) = 3 Then Q3 + 1;
	If QTR(INT(XLDeclaration_date)- 21916) = 4 Then Q4 + 1;
	If PerCapitaIAIH GT 0 Then DN_PerCapitaIAIH + PerCapitaIAIH;
	If PerApplication GT 0 Then DN_PerApplication +PerApplication;
	If PerCapitaHA GT 0 Then DN_PerCapitaHA + PerCapitaHA;
	If PerCapitaOtherIA GT 0 Then DN_PerCapitaOtherIA + PerCapitaOtherIA;
	If PerCapitaTotal_PAGrants GT 0 Then DN_PerCapitaTotal_PAGrants + PerCapitaTotal_PAGrants;
	If PerCapitaPACATAB GT 0 Then DN_PerCapitaPACATAB + PerCapitaPACATAB;
	If PerCapitaPACATCG GT 0 Then DN_PerCapitaPACATCG + PerCapitaPACATCG;
	If last.year then OUTPUT;
Run;

Data &library..TotalsFEMADcls_PAwithIAv3 Replace;
	Set &library..TotalsFEMADcls_PAwithIAv2
	(KEEP =
		FIPS_County
		Year
		CountyName3
		t_pop
		State
		STATEFP
 		Sum_:
		IT_: DR_:
		Duration_:
		SumPA_:
		Q:
		DN_Per:
	Drop = Sum_of:);
	PerCapitaPA_PrjAmnt = Round(SumPA_PrjAmnt / t_pop, 0.01);
	PerCapitaPA_FedOblg = Round(SumPA_FedOblg / t_pop, 0.01);
	PerCapitaPA_TtlOblg = Round(SumPA_TtlOblg / t_pop, 0.01);
Run;
*Label PAwithIA variables;
Data &library..TotalsFEMADcls_PAwithIAv3 Replace;
	Set &library..TotalsFEMADcls_PAwithIAv3;
	Label
		Sum_DisasterNum = "Total Number of Disasters Declared"
		Sum_IH_Dec = "Total Individual and Household programs declared for this County"
		Sum_IA_Dec = "Total Individual Assistance programs declared for this County"
		Sum_PA_Dec = "Total Public Assistance programs declared for this County"
		Sum_HM_Dec = "Total Hazard Mitigation programs declared for this County"
		Sum_DR = "Total Major Disasters declared for this county"
		Sum_EM = "Total Emergency declarations declared for this county"
		Sum_FM = "Total fire managements declared for this county"
		Sum_FS = "Total fire managements declared for this county"
		DR_Earthquake = "Earthquake"
		DR_Fire = "Major Disaster Fire"
		DR_Flood = "Major Disaster Flood"
		DR_Hurricane = "Major Disaster Hurricane"
		DR_SevereIceStorm = "Major Disaster SevereIceStorm"
		DR_SevereStorm = "Major Disaster SevereStorm"
		DR_Tornado = "Major Disaster Tornado"
		DR_Snow = "Major Disaster Snow"
		DR_Other = "Major Disaster Other"
		IT_Earthquake = "Earthquake"
		IT_Fire = "Fire"
		IT_Flood = "Flood"
		IT_Hurricane = "Hurricane"
		IT_SevereIceStorm = "SevereIceStorm"
		IT_SevereStorm = "SevereStorm"
		IT_Tornado = "Tornado"
		IT_Snow = "Snow"
		IT_Other = "Other"
		Duration_DR = "Total Number of days with Major Disaster Declared" 
		Duration_EM = "Total Number of days with Emergency declarations Declared"
		Duration_FM = "Total Number of days with fire managements Declared"
		Duration_FS = "Total Number of days with fire managements Declared"
		SumPA_PrjAmnt = "Sum of the estimated total cost of the Public Assistance Grant project, without administrative costs."
		SumPA_FedOblg = "Sum of The Public Assistance Grant funding available to the grantee (State), for subgrantee’s approved Project Worksheets."
		SumPA_TtlOblg = "Sum of The federal share of the Public Assistance Grant eligible project amount, plus grantee (State) and subgrantee (applicant) administrative costs. The federal share is typically 75% of the total cost of the project."
		Q1 = "Disaster Declared in First Quarter"
		Q2 = "Disaster Declared in Second Quarter"
		Q3 = "Disaster Declared in Third Quarter"
		Q4 = "Disaster Declared in Fourth Quarter"
		DN_PerCapitaIAIH = "Individuals & Household Program Dollars Approved Divided By Populations in All Designated Counties by Disaster"
		DN_PerApplication = "Individuals & Household Program Dollars Approved Divided By Total Approved Applications by Disaster"
		DN_PerCapitaHA = "Housing Assistance Dollars Approved Divided By Populations in All Designated Counties by Disaster"
		DN_PerCapitaOtherIA = "Other Needs Assistance Dollars Approved Divided By Populations in All Designated Counties by Disaster. (Furnishings, transportation, and medical)"
		DN_PerCapitaTotal_PAGrants = "Public Assistance Grants Divided By Populations in All Designated Counties by Disaster"
		DN_PerCapitaPACATAB = "Emergency Work (Categories A-B) PA Grants Divided By Populations in All Designated Counties by Disaster"
		/*Emergency Work (Categories A-B): Work that must be performed to 
		reduce or eliminate an immediate threat to life, protect public 
		health and safety, and to protect improved property that is 
		significantly threatened due to disasters or emergencies 
		declared by the President */
		DN_PerCapitaPACATCG = "Permanent Work (Categories C-G) PA Grants Divided By Populations in All Designated Counties by Disaster"
		/*Permanent Work (Categories C-G): Work that is required to restore 
		a damaged facility, through repair or restoration, to its pre-disaster
		design, function, and capacity in accordance with applicable codes
		and standards */	
		PerCapitaPA_PrjAmnt = "County Level Public Assistance Grants Divided By Estimated County Population"
		PerCapitaPA_FedOblg = "County Level federal share of PA Divided By Estimated County Population"
		PerCapitaPA_TtlOblg = "County Level Total Available PA Divided By Estimated County Population";
Run;

/*-------------------------------------------------------------------*/
/* Add SSA County Codes                                              */
/*-------------------------------------------------------------------*/
* CMS's SSA to FIPS State and County Crosswalk;
* http://www.nber.org/data/ssa-fips-state-county-crosswalk.html;

* Import SSA County Codes;
libname NBER "&dd_data.NBER";
Data &library..cbsatocountycrosswalk_fy13 Replace;
	Set NBER.cbsatocountycrosswalk_fy13 (keep=ssacounty fipscounty state);
	CNTY_CD = ssacounty;
	FIPS_COUNTY = fipscounty;
	STATE_CD = state;
Run;
Data &library..cbsatocountycrosswalk_fy13 Replace;
	Set &library..cbsatocountycrosswalk_fy13 (keep=CNTY_CD FIPS_COUNTY STATE_CD);
Run;

* Sort Data files;
PROC SORT DATA = &library..TotalsFEMADcls_PAwithIAv3;
	By FIPS_County; 
RUN;
PROC SORT DATA = &library..cbsatocountycrosswalk_fy13;
	By FIPS_County; 
RUN;
DATA &library..TotalsFEMADcls_PAwithIAv3_SSA REPLACE;
	MERGE &library..TotalsFEMADcls_PAwithIAv3 &library..cbsatocountycrosswalk_fy13;
	BY FIPS_County;
RUN;
PROC SORT DATA = &library..TotalsFEMADcls_PAwithIA_SSA;
	By FIPS_County Year; 
RUN;

* Add FEMA Region
Region I: CT, ME, MA, NH, RI, VT
Region II: NJ, NY, PR, VI
Region III: DC, DE, MD, PA, VA, WV
Region IV: AL, FL, GA, KY, MS, NC, SC, TN
Region V: IL, IN, MI, MN, OH, WI
Region VI: Arkansas, Louisiana, New Mexico, Oklahoma, & Texas
Region VII: IA, KS, MO, NE
Region VIII: CO, MT, ND, SD, UT, WY
FEMA Region IX: Arizona, California, Hawaii, Nevada, & the Pacific Islands
Region X: AK, ID, OR, WA;

DATA &library..TotalsFEMADcls_PAwithIA_Region REPLACE;
	MERGE &library..TotalsFEMADcls_PAwithIA_SSA;
	FEMAREGION = "RegionXX";
	If STATE_CD in ('CT','ME','MA','NH','RI','VT') then FEMAREGION = "Region1";
	If STATE_CD in ('NJ','NY','PR','VI') then FEMAREGION = "Region2";
	If STATE_CD in ('DC','DE','MD','PA','VA','WV') then FEMAREGION = "Region3";
	If STATE_CD in ('AL','FL','GA','KY','MS','NC','SC','TN') then FEMAREGION = "Region4";
	If STATE_CD in ('IL','IN','MI','MN','OH','WI') then FEMAREGION = "Region5";
	If STATE_CD in ('AR','LA','NM','OK','TX') then FEMAREGION = "Region6";
	If STATE_CD in ('IA','KS','MO','NE') then FEMAREGION = "Region7";
	If STATE_CD in ('CO','MT','ND','SD','UT','WY') then FEMAREGION = "Region8";
	If STATE_CD in ('AZ','CA','HI','NV') then FEMAREGION = "Region9";
	If STATE_CD in ('AK','ID','OR','WA') then FEMAREGION = "Region10";
RUN;

* Reorder variables;

Data &library..TotalsFEMADcls_PAwithIA Replace;
	Retain 
		STATE_CD
		CNTY_CD
		Year
		FIPS_County
		FEMAREGION
 		Sum_:
		IT_: DR_:
		Duration_:
		SumPA_:
		Q:
		DN_Per:
		PerCapitaPA:;
	Set &library..TotalsFEMADcls_PAwithIA_Region
Run;

%mend MacroCountyFEMA;

/*-------------------------------------------------------------------*/
/* Run Macro Here                                                    */
/*-------------------------------------------------------------------*/
/*-------------------------------------------------------------------*/
/* Important Folder Locations                                        */
/*-------------------------------------------------------------------*/

%LET dd_data = C:\Users\Nathanael\Dropbox\MyData\;
%LET dd_SASLib = C:\Users\Nathanael\MySASLib\;
%LET Include_prog = C:\Users\Nathanael\Dropbox\MyPrograms\;

%MacroCountyFEMA(
   dd_data = &dd_data, 
   dd_SASLib = &dd_SASLib,
   Include_prog = &Include_prog);
