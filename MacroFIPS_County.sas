 /*-------------------------------------------------------------------*/
 /*       Macro for Createing FIPS_County Codes                       */
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
 /* Date Last Updated: 11July2014                                     */
 /*-------------------------------------------------------------------*/
 /* Questions or problem reports concerning this material may be      */
 /* addressed to the author on github: https://github.com/npr99       */
 /*                                                                   */
 /*-------------------------------------------------------------------*/
 /* Data Source:                                                      */
 /*-------------------------------------------------------------------*/


%MACRO MacroFIPS_County(
   dd_data = , 
   dd_SASLib = ,
   Include_prog = );

/*-------------------------------------------------------------------*/
/* Import Primary Files from Original Source                         */
/*-------------------------------------------------------------------*/

* Import Census FIPS Code list Retreived from
http://www.census.gov/geo/reference/codes/cou.html;

Data FIPS_County_Import REPLACE;
	filename datafile "&dd_data.Census\ANSI_FIPS\national_county.txt"; 
	INFILE datafile DLM = ',' FIRSTOBS = 2 DSD;
	Input
		STATE :$2.
		STATEFP :$2.
		COUNTYFP :$3.
		COUNTYNAME :$40.
		CLASSFP :$2.;
RUN;

* Convert County_Code in redemption data to 3 digit character;
* Perform a simple concatenation to create FIPS_County unique with State; 
DATA FIPS_County REPLACE;
	SET FIPS_County_Import;
	Length Last_Word $20
		First_Word $20
		Second_Word $20
		Third_Word $20
		Fourth_Word $20
		Fifth_Word $20;
	FIPS_County = STATEFP || COUNTYFP;
	DashCheck = FIND(COUNTYNAME, "-");
	Last_Word = scan(COUNTYNAME, -1);
	First_Word = scan(COUNTYNAME, +1);
	If First_Word = "St" THEN First_Word = "St.";
	If First_Word = "Ste" THEN First_Word = "Ste.";
	Second_Word = scan(COUNTYNAME, +2);
	Third_Word = scan(COUNTYNAME, +3);
	Fourth_Word = scan(COUNTYNAME, +4);
    Fifth_Word = scan(COUNTYNAME, +5); 
RUN;

DATA FIPS_County REPLACE;
	SET FIPS_County;
	
	If Last_Word in ("County" "Parish" "Municipio") Then do;
		If Second_Word in("County" "Parish" "Municipio") Then
		CountyName2 = First_Word;
			Else If Third_Word in("County" "Parish" "Municipio") Then
				CountyName2 = catx(" ", First_Word, Second_Word);
			Else If Fourth_Word in("County" "Parish" "Municipio") Then
				CountyName2 = catx(" ", First_Word, Second_Word, Third_Word);
			Else If Fifth_Word in("County" "Parish" "Municipio") Then
				CountyName2 = catx(" ", First_Word, Second_Word, Third_Word, Fourth_Word);
		CountyName3 = trim(CountyName2) || " (" || trim(Last_Word) || ")";
		End;
	Else Do;
		CountyName2 = COUNTYNAME;
		If Last_Word = "city" AND State in ("VA", "MD") Then
			Do;
			If Second_Word = "city" Then
				CountyName3 = First_Word;
				Else If Third_Word = "city" Then
					CountyName3 = catx(" ", First_Word, Second_Word);
				Else If Fourth_Word = "city" Then
					CountyName3 = catx(" ", First_Word, Second_Word, Third_Word);
				Else If Fifth_Word = "city" Then
					CountyName3 = catx(" ", First_Word, Second_Word, Third_Word, Fourth_Word);
			End;
		Else If First_Word = "District" AND Last_Word = "Columbia" Then
			CountyName3 = "District of Columbia (County-equivalent)";
		Else CountyName3 = COUNTYNAME;
	End;
	If First_Word = "Miami" AND Second_Word = "Dade" Then
		CountyName3 = "Miami-Dade (County)";
	If First_Word = "LaSalle" Then
		CountyName3 = "La Salle (County)";
	If First_Word = "De" AND Second_Word = "Baca" Then
		CountyName3 = "DeBaca (County)";
Run;	

* Generate table with only State FIPS codes;
PROC SORT DATA = FIPS_County NODUPKEY OUT = FIPS_State;
	By STATEFP; 
RUN;
DATA FIPS_State REPLACE;
	SET FIPS_State (KEEP = State STATEFP);
RUN;

%mend;
