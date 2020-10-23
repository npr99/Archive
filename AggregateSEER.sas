/*-------------------------------------------------------------------*/
/*       Modify SEER data to make county year demographic info       */
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
/* Date Last Updated: 24Jul2014                                      */
/*-------------------------------------------------------------------*/
/* Questions or problem reports concerning this material may be      */
/* addressed to the author on github: https://github.com/npr99       */
/*                                                                   */
/*-------------------------------------------------------------------*/
/* Data Source:                                                      */
/* Surveillance, Epidemiology, and End Results Program (SEER) (2013) */
/* US Population Data - 1969-2012                                    */
/*     http://seer.cancer.gov/popdata/download.html (July 24, 2014)  */
/*-------------------------------------------------------------------*/
/* Note
Using 1990-2012 County-level: Expanded Races 
(White, Black, American Indian/Alaska Native, Asian/Pacific Islander) 
by Origin (Hispanic, Non-Hispanic);
County- and state-level population files with 19 age groups 
(<1, 1-4, ..., 80-84, 85+)
For the All States Combined and four states (Alabama, Louisiana, 
Mississippi, and Texas), two sets of population estimates are available 
for 2005: the standard set based on July 1 populations and a set that has
been adjusted for the population shifts due to hurricanes Katrina 
(August 29) and Rita (September 24). For more information, 
see http://seer.cancer.gov/popdata/hurricane_adj.html

/*-------------------------------------------------------------------*/
/* Important Folder Locations                                        */
/*-------------------------------------------------------------------*/

%LET dd_data = F:\Dropbox\MyData\;

/*-------------------------------------------------------------------*/
/* Import SEER Data                                                  */
/*-------------------------------------------------------------------*/
*If SEER Data not imported use the following program;
* %INCLUDE "&Include_prog.SEER\seer_pop.sas";
* Output seer.seer_pop;
libname SEER "&dd_data.SEER";

/*-------------------------------------------------------------------*/
/* Add FIPS County                                                   */
/*-------------------------------------------------------------------*/
Data seer.seer_FIP Replace;
	Set seer.seer_pop;
	If stfips LT 10 Then do;
		statefp = "0" || PUT(stfips, 1.);
		If County LT 10  Then 
			FIPS_County =  "0" || PUT(stfips, 1.) || "00" || PUT(County, 1.);
		ELSE If County LT 100  Then  
			FIPS_County =  "0" || PUT(stfips, 1.) || "0" || PUT(County, 2.);
		ELSE If County LT 1000  Then  
			FIPS_County =  "0" || PUT(stfips, 1.) || PUT(County, 3.);
		End;
	Else If stfips LT 100 Then do;
		statefp = PUT(stfips, 2.);
		If County LT 10  Then 
			FIPS_County =  PUT(stfips, 2.) || "00" || PUT(County, 1.);
		ELSE If County LT 100  Then  
			FIPS_County =  PUT(stfips, 2.) || "0" || PUT(County, 2.);
		ELSE If County LT 1000  Then  
			FIPS_County =  PUT(stfips, 2.) || PUT(County, 3.);
		End;
Run;

Data seer.seer_FIP Replace;
	Retain FIPS_County Year;
	Set seer.seer_FIP;
Run;

/*-------------------------------------------------------------------*/
/* Aggregate SEER to get total population                            */
/*-------------------------------------------------------------------*/
PROC SORT DATA = seer.seer_FIP OUT = seer.seer_FIP;
	BY FIPS_County Year;
RUN;

%MACRO GroupSEER(
	AgeGroup = ,
	F_age = ,
	L_age = );

* Generate a table that sums county data by year for elderly;
DATA seer.seer_TotalPop&Agegroup;
	Set seer.seer_FIP;
	BY FIPS_County Year;
	IF first.year THEN DO;
		t_pop = 0;
		t_age0_4 = 0;
		t_age5_14 = 0;
		t_age15_29 = 0;
		t_age30_54 = 0;
		t_age55_64 = 0;
		t_age65p = 0;
		t_Hspnc0 = 0;
		t_Hspnc1 = 0;
		t_rc1 = 0;
		t_rc2 = 0;
		t_rc3 = 0;
		t_rc4 = 0;
		t_sex1 = 0;
		t_sex2 = 0;
		cnt = 0;
		END;
	if age GE &F_age AND age LE &L_age then do; 
		t_pop + pop;
		if age GE 0 AND age LE 1 then t_age0_4 + pop;
		if age GE 2 AND age LE 3 then t_age5_14 + pop;
		if age GE 4 AND age LE 6 then t_age15_29 + pop;
		if age GE 7 AND age LE 11 then t_age30_54 + pop;
		if age GE 12 AND age LE 13 then t_age55_64 + pop;
		if age GE 14 then t_age65p + pop;
		if hispanic = 0 then t_Hspnc0 + pop;
		if hispanic = 1 then t_Hspnc1 + pop;
		if race = 1 then t_rc1 + pop;
		if race = 2 then t_rc2 + pop;
		if race = 3 then t_rc3 + pop;
		if race = 4 then t_rc4 + pop;
		if sex = 1 then t_sex1 + pop;
		if sex = 2 then t_sex2 + pop;
		cnt + 1;
	End;
	IF last.year THEN OUTPUT;
	KEEP
		FIPS_County
		Year
		statefp
		t_:
		cnt;
RUN;

DATA seer.seer_TotalPop&Agegroup;
    Set seer.seer_TotalPop&Agegroup;
Label
	t_rc1		=  "White"                         
	t_rc2		=  "Black"                         
	t_rc3		=  "Other (1969+)/American Indian/Alaska Native (1990+)"
	t_rc4		=  "Asian or Pacific Islander (1990+)"
	t_Hspnc0 	=  "Non-Hispanic"                  
	t_Hspnc1	=  "Hispanic"                      
	t_sex1      =  "Male"                          
	t_sex2      =  "Female"                        
	t_age0_4 	= "0-4 years" 
	t_age5_14 	= "5-14 years"
	t_age15_29 	= "15-29 years"
	t_age30_54 	= "30-54 years"
	t_age55_64 	= "55-64 years"
	t_age65p 	= "65+ years";
Run;                
%Mend GroupSEER;

/* Age groups to select from
	00        =  "0 years"                       
	01        =  "1-4 years"                     
	02        =  "5-9 years"                     
	03        =  "10-14 years"                   
	04        =  "15-19 years"                   
	05        =  "20-24 years"                   
	06        =  "25-29 years"                   
	07        =  "30-34 years"                   
	08        =  "35-39 years"                   
	09        =  "40-44 years"                   
	10        =  "45-49 years"                   
	11        =  "50-54 years"                   
	12        =  "55-59 years"                   
	13        =  "60-64 years"                   
	14        =  "65-69 years"                   
	15        =  "70-74 years"                   
	16        =  "75-79 years"                   
	17        =  "80-84 years"                   
	18        =  "85+ years"                     
*/

%GroupSEER(
	AgeGroup = All,
	F_age = 0,
	L_age = 18);
* Total pops seem to match the PopEstimates from the CENSUS;


