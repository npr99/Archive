/*-------------------------------------------------------------------*/
/* Before Running this program set the default directories           */
/*-------------------------------------------------------------------*/
%LET dd_data = C:\Users\Nathanael\Dropbox\MyData\;
%LET dd_SASLib = C:\Users\Nathanael\MySASLib\;
%LET Include_prog = C:\Users\Nathanael\Dropbox\MyPrograms\;

/* program:    ImportStoreList.sas
// task:       Import USDA store list
// Version:    First Version
// project:    Rosenheim 2015 Dissertation 
// author:     Nathanael Rosenheim \ Feb 11 2015
// Project Planning Details
*/

%Macro ImportStoreList(fileyear = );


/*-------------------------------------------------------------------*/
/* Define SAS Library                                                */
/*-------------------------------------------------------------------*/

* Found these text utilities that might be useful from 
	http://www2.sas.com/proceedings/sugi30/029-30.pdf
	include add_string macro;
%INCLUDE "&Include_prog.Macros_SAS\TextUtilityMacros.sas";
* Found these Tight Looping with Macro Arrays from
	http://www.sascommunity.org/wiki/Tight_Looping_with_Macro_Arrays
	inlcude Array, Do_Over Macros;
%INCLUDE "&Include_prog.Macros_SAS\Clay-TightLooping-macros\NUMLIST.sas";
%INCLUDE "&Include_prog.Macros_SAS\Clay-TightLooping-macros\ARRAY.sas";
%INCLUDE "&Include_prog.Macros_SAS\Clay-TightLooping-macros\DO_OVER.sas";

/*-------------------------------------------------------------------*/
/* Import Excel File                                                 */
/*-------------------------------------------------------------------*/
/*-------------------------------------------------------------------*/
/* Run Import SNAP Retail Count Years from first to last years       */
/*-------------------------------------------------------------------*/

PROC IMPORT DATAFile = "&dd_data.USDA\RPMDHQ\storelist\
CY &fileyear Authorized Store List.xlsx" DBMS = XLSX 
OUT = work.SNAP_StoreListTemp REPLACE;
	GETNAMES = NO;
	MIXED = YES;
RUN;

/*-------------------------------------------------------------------*/
/* Add variable names                                                */
/*-------------------------------------------------------------------*/

/*-------------------------------------------------------------------*/
/* Remove extra commas from Store Name                               */
/*-------------------------------------------------------------------*/


DATA work.SNAP_StoreListTemp2 REPLACE;
	SET work.SNAP_StoreListTemp;
	StoreNameCompressed = compress(upcase(A),'-,#"$().*+','s');
	StreetAddress = trim(B) || " " || trim(C) || " " || trim(D);
	AllFields = trim(StoreNameCompressed) || " " || trim(StreetAddress) 
				|| " " || trim(E) || " " || trim(F);
	StoreName = A;
	StreetNumber = B;
	StreetName = C;
	AddlAddress = D;
	City = E;
	State = F;
	ZIP = G;
	IF StreetNumber NE "Street Number";
	IF StreetAddress NE "";
	CY_&fileyear = 1;
run;

DATA work.SNAP_StoreList&fileyear REPLACE;
	SET  work.SNAP_StoreListTemp2 (DROP = A B C D E F G);
run;

proc sort data = work.SNAP_StoreList&fileyear;
	by AllFields;
run;

%MEND ImportStoreList;

%ImportStoreList(fileyear = 2005);
%ImportStoreList(fileyear = 2006);
%ImportStoreList(fileyear = 2007);
%ImportStoreList(fileyear = 2008);
%ImportStoreList(fileyear = 2009);
%ImportStoreList(fileyear = 2010);
%ImportStoreList(fileyear = 2011);
%ImportStoreList(fileyear = 2012);


data work.SNAP_ALL_Storelists;
	merge work.SNAP_StoreList20:;
	by AllFields;
	TotalCY = sum(of CY_2005-CY_2012);
	if CY_2005 = . then CY_2005 = 0;
	if CY_2006 = . then CY_2006 = 0;
	if CY_2007 = . then CY_2007 = 0;
	if CY_2008 = . then CY_2008 = 0;
	if CY_2009 = . then CY_2009 = 0;
	if CY_2010 = . then CY_2010 = 0;
	if CY_2011 = . then CY_2011 = 0;
	if CY_2012 = . then CY_2012 = 0;
run;

proc sort data = work.SNAP_ALL_Storelists;
	by State City ZIP StreetName StreetNumber;
run;

data work.SNAP_ALL_Storelists;
	Set work.SNAP_ALL_Storelists;
	ID = _N_;
run;

* Use ds2csv macro to add double-quotes around values;
%ds2csv(data=work.SNAP_ALL_Storelists, runmode=b, csvfile=&dd_data.USDA\RPMDHQ\storelist\SNAP_ALL_Storelists_2005_2012.csv);


/*-------------------------------------------------------------------*/
/* Create seperate Table For Walmarts                                */
/*-------------------------------------------------------------------*/

data work.WlmrtSuperCenter Replace;
	set work.SNAP_ALL_Storelists;
	if index(StoreNameCompressed,'WALMART') ge 1;
	WlmrtSuperCenter = 0;
	WlmrtNghrd = 0;
	if index(StoreNameCompressed,'SUPERCENTER') ge 1 then
		WlmrtSuperCenter = 1;	
	if index(StoreNameCompressed,'S/C') ge 1 then
		WlmrtSuperCenter = 1;
	if index(StoreNameCompressed,'NEIGHBORHOOD') ge 1 then
		WlmrtNghrd = 1;
run;

proc sort data = work.SNAP_Walmart;
	by State City ZIP;
run;

/* data work.SNAP_Walmart2 REPLACE;
	set work.SNAP_Walmart;
	if state in("TX","AR","OK","NM","LA");
run;
*/

proc export data = work.SNAP_Walmart2
	outfile = "&dd_data.USDA\RPMDHQ\storelist\WalmartStoreList2005_2012.csv" replace;
Run;

/*-------------------------------------------------------------------*/
/* Create seperate Table For Target                                  */
/*-------------------------------------------------------------------*/
data work.TargetSuperCenter Replace;
	set work.SNAP_ALL_Storelists;
	if index(StoreNameCompressed,'TARGET') ge 1;
	TargetSuperCenter = 0;
	if index(StoreNameCompressed,'SUPER') ge 1 then
		TargetSuperCenter = 1;
	storenumber = substr(StoreNameCompressed,length(StoreNameCompressed)-3,4);
	if substr(storenumber,1,1) in("T","E","S") then 
		storenumber = "0" || substr(storenumber,2,3);
	if substr(storenumber,1,2) in("ET","ES","ST","RE") then 
		storenumber =  "00" || substr(storenumber,3,2);
	if substr(storenumber,1,3) in("ORE","RES","EST","GET") then 
		storenumber =  "000" || substr(storenumber,4,1);
run;

proc sort data = work.TargetSuperCenter ;
	by storenumber;
run;

proc tabulate data = work.TargetSuperCenter ;
	Class CY_:;
	Tables CY_:;
Run;




