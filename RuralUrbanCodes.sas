/*-------------------------------------------------------------------*/
/* Data Source:
USDA (2013)
2013 Rural-Urban Continuum Codes
http://www.ers.usda.gov/data-products/rural-urban-continuum-codes.aspx#.U9GaNPldWt1
(July 24, 2014)
/*-------------------------------------------------------------------*/
/* Code Descriptions
2013 Rural-Urban Continuum Codes
Code	Description
Metro counties:
1	Counties in metro areas of 1 million population or more
2	Counties in metro areas of 250,000 to 1 million population
3	Counties in metro areas of fewer than 250,000 population
Nonmetro counties:
4	Urban population of 20,000 or more, adjacent to a metro area
5	Urban population of 20,000 or more, not adjacent to a metro area
6	Urban population of 2,500 to 19,999, adjacent to a metro area
7	Urban population of 2,500 to 19,999, not adjacent to a metro area
8	Completely rural or less than 2,500 urban population, adjacent to a metro area
9	Completely rural or less than 2,500 urban population, not adjacent to a metro area

2003 Rural-Urban Continuum Codes
Code	Description
Metro counties:
1	Counties in metro areas of 1 million population or more
2	Counties in metro areas of 250,000 to 1 million population
3	Counties in metro areas of fewer than 250,000 population
Nonmetro counties:
4	Urban population of 20,000 or more, adjacent to a metro area
5	Urban population of 20,000 or more, not adjacent to a metro area
6	Urban population of 2,500 to 19,999, adjacent to a metro area
7	Urban population of 2,500 to 19,999, not adjacent to a metro area
8	Completely rural or less than 2,500 urban population, adjacent to a metro area
9	Completely rural or less than 2,500 urban population, not adjacent to a metro area

Description of the Rural-Urban Continuum Codes prior to 2003
Code	Description
Metro counties:
0	Central counties of metro areas of 1 million population or more.
1	Fringe counties of metro areas of 1 million population or more.
2	Counties in metro areas of 250,000 to 1 million population.
3	Counties in metro areas of fewer than 250,000 population.
Nonmetro counties:
4	Urban population of 20,000 or more, adjacent to a metro area.
5	Urban population of 20,000 or more, not adjacent to a metro area.
6	Urban population of 2,500 to 19,999, adjacent to a metro area.
7	Urban population of 2,500 to 19,999, not adjacent to a metro area.
8	Completely rural or less than 2,500 urban population, adjacent to a metro area.
9	Completely rural or less than 2,500 urban population, not adjacent to a metro area.
*/
/*-------------------------------------------------------------------*/
/* Important Folder Locations                                        */
/*-------------------------------------------------------------------*/

%LET dd_data = C:\Users\Nathanael\Dropbox\MyData\;
%LET dd_SASLib = C:\Users\Nathanael\MySASLib\;
%LET Include_prog = C:\Users\Nathanael\Dropbox\MyPrograms\;

/*-------------------------------------------------------------------*/
/* Import Rural Urban Codes                                          */
/*-------------------------------------------------------------------*/

PROC IMPORT DATAFile = "&dd_data.USDA\ruralurbancodes2003.xls" 
	DBMS = XLS
	OUT = work.ruralurbancodes2003_TEMP1 REPLACE;
	Getnames = Yes;
	MIXED = YES;
RUN;

PROC IMPORT DATAFile = "&dd_data.USDA\ruralurbancodes2013.xls" 
	DBMS = XLS
	OUT = work.ruralurbancodes2013_TEMP1 REPLACE;
	Getnames = Yes;
	MIXED = YES;
RUN;

/*-------------------------------------------------------------------*/
/* Prep Data for merge                                               */
/*-------------------------------------------------------------------*/
Data work.ruralurbancodes2013_TEMP2 REPLACE;
	Set work.ruralurbancodes2013_TEMP1
	(Keep = FIPS RUCC_2013 County_Name);
	FIPS_County = input(FIPS,$5.);
	Drop FIPS;
RUN;

Data work.ruralurbancodes2003_TEMP2 REPLACE;
	Set work.ruralurbancodes2003_TEMP1;
	RUCC_1993 = input(_1993_Rural_urban_Continuum_Code,Best12.);
	RUCC_2003 = input(_2003_Rural_urban_Continuum_Code,Best12.);
	FIPS_County = input(FIPS_Code,$5.);
RUN;

Data work.ruralurbancodes2003_TEMP2 REPLACE;
	Set work.ruralurbancodes2003_TEMP2
	(Keep = FIPS_County RUCC_1993 RUCC_2003 County_Name);
RUN;

/*-------------------------------------------------------------------*/
/* Merge 2003 and 2013 Urban Rural Codes                             */
/*-------------------------------------------------------------------*/
PROC SORT DATA = work.ruralurbancodes2003_TEMP2;
	By FIPS_County;
RUN;
PROC SORT DATA = work.ruralurbancodes2013_TEMP2;
	By FIPS_County;
RUN;
Data work.ruralurbancodes Replace;
	Merge work.ruralurbancodes2003_TEMP2 work.ruralurbancodes2013_TEMP2;
	By FIPS_County;
Run;

Data work.ruralurbancodes Replace;
	Retain
		FIPS_County;
	Set  work.ruralurbancodes;
Run;

Data work.ruralurbancodes Replace;
	Set  work.ruralurbancodes;
	/* Create Dummy Variables for Metro Status */
	statefp = substr(FIPS_county,1,2);
	If RUCC_1993 in(0,1,2,3) Then M_1993 = 1;
	Else IF RUCC_1993 GE 4 Then M_1993 = 0;
	If RUCC_2003 in(0,1,2,3) Then M_2003 = 1;
	Else IF RUCC_2003 GE 4 Then M_2003 = 0;
	If RUCC_2013 in(0,1,2,3) Then M_2013 = 1;
	Else IF RUCC_2013 GE 4 Then M_2013 = 0;
	/* Create Dummy Variables for Not Adjacent to Metro Status */
	If RUCC_1993 in(5,7,9) Then A_1993 = 1;
	Else If RUCC_1993 in(0,1,2,3,4,6,8) then A_1993 = 0;
	If RUCC_2003 in(5,7,9) Then A_2003 = 1;
	Else If RUCC_2003 in(0,1,2,3,4,6,8) then A_2003 = 0;
	If RUCC_2013 in(5,7,9) Then A_2013 = 1;
	Else If RUCC_2013 in(0,1,2,3,4,6,8) then  A_2013 = 0;
Run;
/*-------------------------------------------------------------------*/
/* Export Rural Urban Codes to USDA Library                          */
/*-------------------------------------------------------------------*/
libname USDA "&dd_SASLib.USDA";
DATA USDA.ruralurbancodes Replace;
	Set  work.ruralurbancodes;
	attrib  FIPS_county  length=$5    label="FIPS Code";  
	attrib  statefp 	 length=$2    label="State FIPS";
	attrib  County_Name  length=$43   label="County Name";            
	attrib  RUCC_1993    length=3     label="Rural/Urban Code 1993";
	attrib  RUCC_2003    length=3     label="Rural/Urban Code 2003";
	attrib  RUCC_2013    length=3     label="Rural/Urban Code 2013";
	attrib  m_1993       length=3     label="Metro 1993";
	attrib  m_2003       length=3     label="Metro 2003";
	attrib  m_2013       length=3     label="Metro 2013";
	attrib  a_1993       length=3     label="Not Adjacent to Metro 1993";
	attrib  a_2003       length=3     label="Not Adjacent to Metro 2003";
	attrib  a_2013       length=3     label="Not Adjacent to Metro 2013";
Run;
