/*-------------------------------------------------------------------*/
/*       Program for checking Within County SNAP Redemptions         */
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
/* Date Last Updated: 28Sept14                                       */
/*-------------------------------------------------------------------*/
/* Questions or problem reports concerning this material may be      */
/* addressed to the author on github: https://github.com/npr99       */
/*                                                                   */
/*-------------------------------------------------------------------*/


/*-------------------------------------------------------------------*/
/* Research Question                                                 */
/*-------------------------------------------------------------------*/
/*
Interested in looking at the entire country county level Within County
SNAP Redemptions.  (Hawaii might be an intersting 
case and Alaska may have unique issues. Also Virginia will need to be
checked for county level definitions).

I have chosen to focus on Texas but I need to see if Texas is unique
or if Texas can be generalizable to other states. I am suggesting that
rural counties in Texas may be generalizable to "food desert" neighborhoods
in urban areas. In terms of similar within neighborhood redemption rates
and lack of attractive food retail. In other words do urban residents
convert mobility into greater food choice in similar ways that 
rural residents do?

I am also dealing with a problem with the sampling errors of the ACS
if I want to include unique ACS measures (propotion SNAP households with a
single working parents, no workers, multiple workers) I will need to
increase the geogrpahic range due to large margin of errors in most 
rural counties.

*/
/*-------------------------------------------------------------------*/
/* Model Hypothesis                                                  */
/*-------------------------------------------------------------------*/
/*
Hypothesis 1: Texas (or the southern states) will have larger clusters
of counties with low within county SNAP redemption rates.
*/
/*-------------------------------------------------------------------*/
/* Data Sources                                                      */
/*-------------------------------------------------------------------*/
/*
See included programs for more details on data sources
*/
/*-------------------------------------------------------------------*/
/* Control Symbolgen                                                 */
/*-------------------------------------------------------------------*/

* Turn on SYBMBOLGEN option to see how macro variables are resolved in log;
* global system option MPRINT to view the macro code with the 
macro variables resolved;
options SYMBOLGEN MPRINT;

* SYMBOLGEN option can be turned off with the following command;
* options nosymbolgen;

/*-------------------------------------------------------------------*/
/* Important Folder Locations                                        */
/*-------------------------------------------------------------------*/

%LET dd_data = C:\Users\Nathanael\Dropbox\MyData\;
%LET dd_SASLib = C:\Users\Nathanael\MySASLib\;
%LET Include_prog = C:\Users\Nathanael\Dropbox\MyPrograms\;

/*-------------------------------------------------------------------*/
/* Important Macro Variables                                         */
/*-------------------------------------------------------------------*/

* Set Macro Variables for State and Years;
%LET FYear = 2005; *First year in panel;
%LET LYear = 2012; *Last year in panel;
%LET State = All;

/*-------------------------------------------------------------------*/
/* Define SAS Library                                                */
/*-------------------------------------------------------------------*/
%let main_library = WCRCheck;
LIBNAME &main_library "&dd_SASLib.&main_library";

/*-------------------------------------------------------------------*/
/* Variables in Panel                                                */
/*-------------------------------------------------------------------*/
/*
Dependent Variable 
WCR represents the ratio of SNAP benefits redeemed within a county 
as the ratio of total within-county redemptions to total within-county
benefit distributions for county i and in year t

/*-------------------------------------------------------------------*/
/* Import SNAP Dollars Redemption Data                               */
/*-------------------------------------------------------------------*/
/* Dollars Redeemed at Stores in Counties                            */
/*-------------------------------------------------------------------*/
/* Data Source:                                                      */
/* Supplemental Nutrition Assistance Program, Retailer Policy and    */
/*       Management Division, Food and Nutrition Service,            */
/*       U.S. Department of Agriculture. (Mar 2014 email             */ 
/*       communication with RPMDHQ-WEB@fns.usda.gov                  */
/*-------------------------------------------------------------------*/

* Include Macro that imports redemption data from USDA;
* Data Imported using;
* %INCLUDE "&Include_prog.USDA_SAS\ImportUSDARed.sas";

%let dataset = USDA;
%let library = &main_library;

LIBNAME &dataset "&dd_SASLib.&dataset";
Data &library..&library._&state.&FYear._&LYear._&dataset.Red Replace;
	Set USDA.USDARed_2005_2012;
	Where year between &Fyear and &LYear;
Run;

/*-------------------------------------------------------------------*/
/* Sort SNAP Dollars Redemption Data                                 */
/*-------------------------------------------------------------------*/

Proc Sort Data = &library..&library._&state.&FYear._&LYear._&dataset.Red;
	BY FIPS_County Year;
RUN;

/*-------------------------------------------------------------------*/
/* Import SNAP Dollars Distributed Data                              */
/*-------------------------------------------------------------------*/
/* Dollars distributed to SNAP participants by county                */
/*-------------------------------------------------------------------*/
/* Data Source:                                                      */
/* Bureau of Economic Analysis (BEA) (May 30 2014)                   */ 
/*       CA35: Personal Current Transfer Receipts                    */
/*       Retrieved 7/29/2014 from                                    */
/*       http://www.bea.gov/regional/downloadzip.cfm                 */
/* Years Available: 1969-2012
/* For Texas Years 2006-2010 most reliable
/* Updates expected
/*-------------------------------------------------------------------*/

* Include Macro that imports distribution data from BEA;
* Data Imported using;
* %INCLUDE "&Include_prog.BEA\ImportBEA.sas";

%let dataset = BEA;
%let library = &main_library;

LIBNAME &dataset "&dd_SASLib.&dataset";
Data &library..&library._&state.&FYear._&LYear._&dataset Replace;
	Set &dataset..Ca35_allstates_1969_2012;
	Where year between &Fyear and &LYear;
Run;

/*-------------------------------------------------------------------*/
/* Sort SNAP Dollars Redemption Data                                 */
/*-------------------------------------------------------------------*/

Proc Sort Data = &library..&library._&state.&FYear._&LYear._&dataset;
	BY FIPS_County Year;
RUN;

/*-------------------------------------------------------------------*/
/* Import SNAP Dollars Distributed Data                              */
/*-------------------------------------------------------------------*/
/* Dollars distributed to SNAP participants by county                */
/*-------------------------------------------------------------------*/
/* Data Source:                                                      */
/* Supplemental Nutrition Assistance Program, Retailer Policy and    */
/*       Management Division, Food and Nutrition Service,            */
/*       U.S. Department of Agriculture. (Mar 2014 email             */ 
/*       communication with RPMDHQ-WEB@fns.usda.gov                  */
/* Supplemental Nutrition Assistance Program (SNAP) Data System      */
/*       Retreived from http://www.ers.usda.gov/datafiles/           */
/*       Supplemental_Nutrition_Assistance_Program_SNAP_Data_System/ */
/*       County_Data.xls on Oct 19, 2013                             */
/*-------------------------------------------------------------------*/
/* Updates not clear if USDA will update
/*-------------------------------------------------------------------*/

* Include Macro that imports distribution data from USDA Time Series;
* %INCLUDE "&Include_prog.USDA_SAS\ImportUSDA_SNAP_timeseries.sas";

%let dataset = USDA;
%let library = &main_library;

LIBNAME &dataset "&dd_SASLib.&dataset";
Data &library..&library._&state.&FYear._&LYear._&dataset.Ben Replace;
	Set &dataset..Usda_countytimeseries_1969_2012;
	Where year between &Fyear and &LYear;
Run;

/*-------------------------------------------------------------------*/
/* Import USDA Store Count Data                                      */
/*-------------------------------------------------------------------*/
/*-------------------------------------------------------------------*/
/* Data Source:                                                      */
/* Supplemental Nutrition Assistance Program, Retailer Policy and    */
/*       Management Division, Food and Nutrition Service,            */
/*       U.S. Department of Agriculture. (May 2014 email             */ 
/*       communication with RPMDHQ-WEB@fns.usda.gov                  */
/*       Authorized Store Counts by State-County-Store Type CY       */
/*       2005-2012                                                   */
/*-------------------------------------------------------------------*/

* Include Macro that imports distribution data from TXHHS;
* Data Imported using;
* %INCLUDE "&Include_prog.USDA_SAS\ImportUSDAStoreCounts.sas";

%let dataset = USDA;
%let library = &main_library;

LIBNAME &dataset "&dd_SASLib.&dataset";
Data &library..&library._&state.&FYear._&LYear._&dataset.Cnt Replace;
	Set USDA.SNAPStoreCount2005_2012;
	Where year between &Fyear and &LYear;
Run;

/*-------------------------------------------------------------------*/
/* Import Rural County Codes                                         */
/*-------------------------------------------------------------------*/
/* Data defines if a county is metro, nonmetro, and adjacent to metro
/*-------------------------------------------------------------------*/
/* Data Source:
USDA (2013)
2013 Rural-Urban Continuum Codes
http://www.ers.usda.gov/data-products/rural-urban-continuum-codes.aspx#.U9GaNPldWt1
(July 24, 2014)
/* Years Available: 1993, 2003, 2013
/* Only one observation per county
/*-------------------------------------------------------------------*/
* Data Imported using; 
* %INCLUDE "&Include_prog.USDA_SAS\RuralUrbanCodes.sas";

%let dataset = USDA;
%let library = &main_library;

LIBNAME &dataset "&dd_SASLib.&dataset";
Data &library..ruralurbancodes Replace;
	Set USDA.ruralurbancodes;
Run;

/*-------------------------------------------------------------------*/
/* Sort Rural County Codes                                           */
/*-------------------------------------------------------------------*/

Proc Sort Data = &library..ruralurbancodes;
	BY FIPS_County;
RUN;
/*-------------------------------------------------------------------*/
/* Import Poverty Data                                               */
/*-------------------------------------------------------------------*/
/* Data includes poverty estimates by county by year
/*-------------------------------------------------------------------*/
/* Data Source:                                                      */
/*-------------------------------------------------------------------*/
/* Census 2014 Small Area Income and Poverty Estimates (SAIPE)       */
/* http://www.census.gov/did/www/saipe/data/statecounty/data/index.html
/* Retrieved on July 19, 2014
/* Years Available: 2001-2012
/* Updates expected
/*-------------------------------------------------------------------*/
* Data Imported using;
* %INCLUDE "&Include_prog.Census\MacroSAIPEdata.sas";

%let dataset = SAIPE;
%let library = &main_library;

LIBNAME &dataset "&dd_SASLib.&dataset";

Data &library..&library._&state.&FYear._&LYear._&dataset Replace;
	Set SAIPE.SAIPE2001_2012
		(Keep = Fips_County Year statefp e: minc:); /* Keep estimates drop percents */;
	Where year between &Fyear and &LYear;
Run;
/*-------------------------------------------------------------------*/
/* Sort SAIPES Data                                                  */
/*-------------------------------------------------------------------*/

Proc Sort Data = &library..&library._&state.&FYear._&LYear._&dataset;
	BY FIPS_County Year;
RUN;

/*-------------------------------------------------------------------*/
/* Import SEER Data                                                  */
/*-------------------------------------------------------------------*/
/* Data includes population estimates by age groups, race, gender
/* By county by year
/*-------------------------------------------------------------------*/
/* Data Source:                                                      */
/* Surveillance, Epidemiology, and End Results Program (SEER) (2013) */
/* US Population Data - 1969-2012                                    */
/*     http://seer.cancer.gov/popdata/download.html (July 24, 2014)  */
/* Years Available: 1990-2012
/* Updates expected
/*-------------------------------------------------------------------*/
/* Note
Using 1990-2012 County-level: Expanded Races 
(White, Black, American Indian/Alaska Native, Asian/Pacific Islander) 
by Origin (Hispanic, Non-Hispanic);
County- and state-level population files with 19 age groups 
(<1, 1-4, ..., 80-84, 85+)
*/
* Data Imported using;
* %INCLUDE "&Include_prog.SEER\AggregateSEER.sas";

%let dataset = SEER;
%let library = &main_library;

LIBNAME &dataset "&dd_SASLib.&dataset";

Data &library..&library._&state.&FYear._&LYear._&dataset Replace;
	Set seer.seer_TotalPopAll;
	Where year between &Fyear and &LYear;
Run;
/*-------------------------------------------------------------------*/
/* Sort SEER Data                                                    */
/*-------------------------------------------------------------------*/

Proc Sort Data = &library..&library._&state.&FYear._&LYear._&dataset;
	BY FIPS_County Year;
RUN;

/*-------------------------------------------------------------------*/
/* Import Unemployement Data                                         */
/*-------------------------------------------------------------------*/
/*-------------------------------------------------------------------*/
/* Generate Unemployment Rates for Counties                          */
/*-------------------------------------------------------------------*/
 /*-------------------------------------------------------------------*/
 /* Data Source:                                                      */
 /* Bureau of Labor Statistics (2014) Local Area Unemployment 
		Statistics Annual Average County Data Tables. 
		Retrieved from 
		http://www.bls.gov/lau/#tables on June 11, 2014.
                                                                      */
 /*-------------------------------------------------------------------*/
* Data Imported using;
* %INCLUDE "&Include_prog.BLS\MacroBLSLAUS.sas";

%let dataset = BLS;
%let library = &main_library;

LIBNAME &dataset "&dd_SASLib.&dataset";
Data &library..&library._&state.&FYear._&LYear._&dataset Replace;
	Set BLS.BLS2000_2013;
	Where year between &Fyear and &LYear;
Run;
/*-------------------------------------------------------------------*/
/* Sort BLS Data                                                     */
/*-------------------------------------------------------------------*/

Proc Sort Data = &library..&library._&state.&FYear._&LYear._&dataset;
	BY FIPS_County Year;
RUN;

/*-------------------------------------------------------------------*/
/* Merge Datasets into one                                           */
/*-------------------------------------------------------------------*/
%let library = &main_library;

DATA &library..AllData&library._&state.&FYear._&LYear REPLACE;
	MERGE &library..&library._&state.&FYear._&LYear._:;
	BY FIPS_County year;
RUN;

DATA &library..AllData&library._&state.&FYear._&LYear REPLACE;
	MERGE 
		&library..AllData&library._&state.&FYear._&LYear
		&library..ruralurbancodes;
	BY FIPS_County;
RUN;

/*-------------------------------------------------------------------*/
/* Drop Observations                                                 */
/*-------------------------------------------------------------------*/
/* Drop state level observations */
DATA &library..DropData&library._&state.&FYear._&LYear REPLACE;
	Set &library..AllData&library._&state.&FYear._&LYear;
RUN;

/*-------------------------------------------------------------------*/
/* Clean up Observations                                             */
/*-------------------------------------------------------------------*/
/* Fill in missing statefps from BEA data */
/* Change redemption amount to 0 for counties with no retail */

DATA &library..DropData&library._&state.&FYear._&LYear REPLACE;
	Set &library..DropData&library._&state.&FYear._&LYear;
	If substr(FIPS_County,3,3) = 000 then delete;
	If Statefp = "" then Statefp = substr(FIPS_County,1,1);
	If retailtotal = 0 then redamt = 0;
RUN;

/*-------------------------------------------------------------------*/
/* Look at numbers with respect to USDA, BEA, per capita             */
/*-------------------------------------------------------------------*/

/* One issue is that the SNAP Benefit data from the USDA and BEA are 
frequently different. Both estimates are an estimation, in the USDA
Time Series Data Documentation the USDA states that the BEA data is 
subject to large sampling errors. However the BEA states in their newest
methodology that they have addressed this issue. Despite the efforts
it still looks like the USDA reports lower numbers for benefits distributed.
In 2008 and 2009 the differneces are most pronounced. USDA Benefit numbers
were 107% and 108% greater than the benefits reported by the BEA. In other 
years the differences are between 100-103%.
Since I am looking at the difference between SNAP redemptions and SNAP benefits
the lower BEA numbers would make the differences greater. A more conservative 
estimate would be to use the greater SNAP Benefit data reported by the USDA.
To address this issue I am going to introduce an average value of the two
benefit numbers where it is possible to calculate.
*/

DATA &library..Check1&library._&state.&FYear._&LYear REPLACE;
	Set &library..Check1&library._&state.&FYear._&LYear;
	If BEA_SNAP = . AND USDA_PRGBEN = . Then BEN_AVG = .;
	Else If BEA_SNAP = . AND USDA_PRGBEN > 0 Then BEN_AVG = USDA_PRGBEN;
	Else If BEA_SNAP > 0 AND USDA_PRGBEN = . Then BEN_AVG = BEA_SNAP;
	Else If BEA_SNAP > 0 AND USDA_PRGBEN > 0 Then BEN_AVG = (BEA_SNAP + USDA_PRGBEN)/2;
	
	diff_ben1 = BEA_SNAP - USDA_PRGBEN;
	diff_ben2 = BEA_SNAP - BEN_AVG;
	diff_ben_red1 = BEA_SNAP - redamt;
	diff_ben_red2 = USDA_PRGBEN - redamt;
	diff_ben_red3 = diff_ben_red1 - diff_ben_red2;
	diff_ben_red4 = diff_ben_red3 / redamt;
	per_USDA_eall = USDA_PRGBEN / eall;
	per_BEA_eall = BEA_SNAP / eall;
	attrib 	BEN_AVG format = comma18.2 label = "USDA SNAP Benefit Distributed (BEA, USDA Avg)"
	diff_ben1 format = comma18.2 label = "Difference between BEA and USDA"
	diff_ben2 format = comma18.2 label = "Difference between BEA and Ben_Avg"
	diff_ben_red1 format = comma18.2 label = "Difference between BEA and USDA Redemptions"
	diff_ben_red2 format = comma18.2 label = "Difference between USDA Benefit Data and USDA Redemptions"
	diff_ben_red3 format = comma18.2 label = "Difference of the differences"
	diff_ben_red4 format = 4.3 label = "Percent Difference of the differences to redemption amount"
	per_USDA_eall format = comma8.2 label = "USDA Ben estimate divided by SAIPES persons in poverty"
	per_BEA_eall format = comma8.2 label = "BEA Ben estimate divided by SAIPES persons in poverty"
	redamt format = comma18.2
	BEA_SNAP format = comma18.2;
RUN;

proc sort data = &library..Check1&library._&state.&FYear._&LYear;
	by decending per_BEA_eall;
	* by fips_county year;
run;
/* in looking at the data the major issue is New York and LA!
Queens, Kings, and Bronx counties have significant differences between
the two data sets. The state of New York only reports the data by New York City
BEA and USDA break NYC into Richmond, Kings, Queens, New York, Bronx Counties.
I would suggest that breaking the City into 5 different counties may cause 
significant differnces.
In comparing the BEA data with the New York State Open Data:
Supplemental Nutrition Assistance Program (SNAP) Caseloads and Expenditures: Beginning 2002
https://data.ny.gov/Human-Services/Supplemental-Nutrition-Assistance-Program-SNAP-Cas/dq6j-8u8z

The BEA data is closer to the NY state data. However the NY data combines
New York City therefore it is impossible to compare the BEA data with the New York 
administrative data.
It might be possible to combine the New York City Data or drop NYC from the 
study.

In comparing the BEA data with the 2009 Pennsylvania Archived Data:
Archives of MA-FOOD-STAMPS-AND-CASH-STATS@LISTSERV.DPW.STATE.PA.US
http://listserv.dpw.state.pa.us/ma-food-stamps-and-cash-stats.html

It looks like the BEA data is closer to the state reported numbers.

Looking at the difference between the differnces and then looking at the 
percentage that the difference is with respect to the actual redemption 
data is telling.
For example Boise County ID in 2005 and 2006. Depending on which data
source is used for benefits distribtution data would swing the numbers by
509%. In 2006 Boise ID reports $75,131.01 in redemptions, BEA reported
$422,000.00 in distribtutions but USDA reported $39,679.58. This difference
would lead to two very different outcomes.
On the other end of the spectrum San Juan County, UT is off by 380% for
2005-2009. In 2009 San Juan reported $2.4 Million in redemptions
BEA reported $4.5 Million dollars in benefits distributed and the USDA
reported $13.3 Million dollars. Looking at the other factors such as total 
population and number of people in poverty shows that the USDA
numbers are more likely to be wrong. Based on the USDA numbers the 
average person in poverty in San Juan county would have recieved
$3,200 in SNAP benefits.

Looking at benefits per persons estimated in poverty is another way
to see how the numbers checkout. The largest per capita is for 
Skagway Municipality in Alaska. An outlier in terms of having
no estimated total population and 31 person in poverty. However the
area had an estimated $210,000 in SNAP dollars. Of the top 25 highest
per persons in poverty Alaskas county equivalents makes up 18, Hawaii
County and Richamond County New York (Staten Island, NYC) make up
the rest of the top 25. All have greater than $2,700 per person
in poverty. The top 25 are the same for both BEA and USDA sources 
of benefit data. The mean for the measure with USDA sources is $990.96. 
The mean using BEA data is $1059.42. The average
per person benefit for food stamp participants would be around
$870 in 2012 (family of 4 on food stamps for 12 months - $290 average
monthly benefit.
Dropping Alaska, Hawaii, and NYC lowers the mean to $983.74 for USDA
data and $1048.54 for BEA data.

With Alaska, Hawaii, and NYC out of the picture the largest outlier
is Hancock County, MS and Harrison County, MS both in 2005. SNAP 
redemption data reports that Hancock had $5.7 Million and Harrison had
$52. Million. BEA reports that Hancock recieved $30.4 Million 
and Harrison recieved $83.3 Million. The USDA reports drastically lower 
numbers $6.4 Million and $18.4 Million. Hancock county had a total population
of 43,304 with an estimated 7,115 people living in poverty in 2005.
Harrison county had a total population of 183,201 with 29,831 person
estimated to live in poverty in 2005. It is very likely that the BEA
estimates for these two Mississippi Counties is significanlty off.
Both Hancock and Harrison County had severe storm damage
from Hurricane Katrina which hit in September of 2005. The hurricane
and the resulting population shifts, combined with
distriubtions of disaster relief including additional SNAP
benefits may explain the differences.
At the other end of the exterme Blaine County, ID reported $199,580.58
in SNAP redemptions. The BEA reported $131,000 in SNAP 
benefits distributed. The SAIPE reported 1,744 persons living in
poverty. This would lead to an average of $75.11 per person living in
poverty. Well below the national average.
*/
Proc Means DATA = &library..Check1&library._&state.&FYear._&LYear;
	VAR per_USDA_eall per_BEA_eall;
Run;

/* Drop Alaska, HI and NYC */
DATA &library..Check1&library._&state.&FYear._&LYear REPLACE;
	Set &library..Check1&library._&state.&FYear._&LYear;
	If Statefp = 02 then delete; * Alaska;
	If Statefp = 15 then delete; * Hawaii;
RUN;

/*-------------------------------------------------------------------*/
/* Drop NYC Variables                                                */
/*-------------------------------------------------------------------*/

DATA &library..Check1&library._&state.&FYear._&LYear REPLACE;
	Set &library..Check1&library._&state.&FYear._&LYear;
	If FIPS_County = 36005 then delete; * Bronx County;
	If FIPS_County = 36047 then delete; * Kings County; 
	If FIPS_County = 36081 then delete; * Queens County;
	If FIPS_County = 36061 then delete; * New York County;
	If FIPS_County = 36085 then delete; * Richmond County;
RUN;

Proc Means DATA = &library..Check1&library._&state.&FYear._&LYear;
	VAR per_USDA_eall per_BEA_eall;
Run;
 
DATA &library..Check1&library._&state.&FYear._&LYear REPLACE;
	Set &library..Check1&library._&state.&FYear._&LYear;
	Drop E0_4: P0_4:; /*Estimate of people under age 5 in poverty Not Calculated for Counties*/
	Drop t_Hspnc9; /*Not Calculated after 1990 in SEER*/
RUN;

/*-------------------------------------------------------------------*/
/* Reorder Variables                                                 */
/*-------------------------------------------------------------------*/

DATA &library..Check1&library._&state.&FYear._&LYear REPLACE;
	Retain
		FIPS_County
		Year
		Yeartxt
		County_Name
		State
		Statefp
		redamt
		diff_ben1
		diff_ben2
		diff_ben_red1
		diff_ben_red2
		diff_ben_red3
		diff_ben_red4
		per_USDA_eall
		per_BEA_eall
		BEA_SNAP
		USDA_PRGBEN
		BEN_AVG
		RedactedFlag
		USDA_FLAG
		t_pop
		Unemployed
		EALL;
	Set &library..Check1&library._&state.&FYear._&LYear;
RUN;
/*-------------------------------------------------------------------*/
/* Look at numbers with respect to SNAP retailers                    */
/*-------------------------------------------------------------------*/

DATA &library..Check2&library._&state.&FYear._&LYear REPLACE;
	Set &library..DropData&library._&state.&FYear._&LYear;
	If BEA_SNAP > 0 then WCR_BEA = RedAmt / BEA_SNAP;
	If USDA_PRGBEN > 0 then	WCR_USDA = RedAmt / USDA_PRGBEN;
	If RetailTotal >= 1 Then do;
		Redperstor = RedAmt / RetailTotal;
		Benperstor = BEA_Snap / RetailTotal;
		diff_perstor = Redperstor - Benperstor;
		* Look at retail total minus Convience Stores;
		if (RetailTotal - meancs) >= 1 then do;
			Redperstor2 = RedAmt / (RetailTotal - meancs);
			Benperstor2 = BEA_Snap / (RetailTotal - meancs);
			diff_perstor2 = Redperstor2 - Benperstor2;
			end;
		* Look at retail total minus Convience Stores and combined stores;
		if (RetailTotal - meancs - meanco) >= 1 then do;
			Redperstor3 = RedAmt / (RetailTotal - meancs - meanco);
			Benperstor3 = BEA_Snap / (RetailTotal - meancs  - meanco);
			diff_perstor3 = Redperstor2 - Benperstor2;
			end;

		end;
	Else do;
		Redperstor = .; * At first I had this = 0 but that skewed the data towards 0;
		Benperstor = .;
		end;
	If MeanSS >= 1 then RedperSS = RedAmt / MeanSS;
	Else RedperSS = 0;
	If MeanSM >= 1 then RedperSM = RedAmt / MeanSM;
	Else RedperSM = 0;
	attrib 	WCR_BEA format = 4.3 label = "Within County Redemptions (BEA)"
			WCR_USDA format = 4.3 label = "Within County Redemptions (USDA)"
			Redperstor format = comma16.2 label = "Redemptions per SNAP Retialer"
			Benperstor format = comma16.2 label = "County Benefits per SNAP Retialer (BEA)"
			diff_perstor format = comma16.2 label = "Difference in Redemptions per store and benefits distributed per store (BEA)"
			Redperstor2 format = comma16.2 label = "Redemptions per SNAP Retialer (Minus Convience Stores)"
			Benperstor2 format = comma16.2 label = "County Benefits per SNAP Retialer (Minus Convience Stores) (BEA)"
			diff_perstor2 format = comma16.2 label = "Difference in Redemptions per store and benefits distributed per store (Minus Convience Stores) (BEA)"
			Redperstor3 format = comma16.2 label = "Redemptions per SNAP Retialer (Minus Convience and Combined Stores)"
			Benperstor3 format = comma16.2 label = "County Benefits per SNAP Retialer (Minus Convience  and Combined Stores) (BEA)"
			diff_perstor3 format = comma16.2 label = "Difference in Redemptions per store and benefits distributed per store (Minus Convience and Combined Stores) (BEA)"
			RedperSS format = comma16.2 label = "Redemptions per SNAP Super Center"
			RedperSM format = comma16.2 label = "Redemptions per SNAP Supermarket"
			redamt format = comma18.2
			BEA_SNAP format = comma18.2;
RUN;


proc sort data = &library..Check2&library._&state.&FYear._&LYear;
	by decending diff_perstor3;
	*by fips_county year;
run;

Proc Means DATA = &library..Check2&library._&state.&FYear._&LYear
	Min Max Mean Median;
	VAR Redperstor Benperstor diff_perstor Redperstor2 Benperstor2  diff_perstor2
	Redperstor3 Benperstor3  diff_perstor3;
Run;

/* 
The mean benefit per snap retialer was $194,103.55. The mean per 
SNAP super center was $2.2 Million and for supermarkets $2.0 Million.
The maximum per snap retailer for a county was $1,062,214 in the 
Central Missippi County of Grenada, which has 4 of the top ten rankings.
Grenada has had 2 super centers and 1 supermarket since 2006. The town of 
Grenada sits in the middle of the county and has a Super Walmart and 
a Kirk Borhters Supercenter (Google Search Sept 29, 2014). The county of Grenada
has a population of around 22,000 with an estimated 5,000 people in living in
poverty. Dawes County, NE ranks 4th and 7th with around $830 per snap 
retailer.
The maximum per super center was $33.5 Million 
The maximum per supermarket was $68.3 Million
Since the data for the redemptions and store counts is aggregated
at the county level it is not possilbe to determine the exact
statistics by store type.
*/

/* Look at the difference between how much was redeemed per 
snap retailer and how much could have been redeemed if all 
of the money was redeemed in county.

In 2011 Convience stores made up 37.96 of stores but only had
4.58% of sales. In 2011 Combined stores made up 23.85% of stores but
only 5.06% of sales. Calculating per store sales without these 2
store types should help paint a clearer picture of differences in counties.
*/
/*-------------------------------------------------------------------*/
/* Reorder Variables                                                 */
/*-------------------------------------------------------------------*/

DATA &library..Check2&library._&state.&FYear._&LYear REPLACE;
	Retain
		FIPS_County
		Year
		Yeartxt
		County_Name
		State
		Statefp
		redamt
		RetailTotal
		MeanCS
		MeanCO
		diff_perstor
		Redperstor
		Benperstor
		diff_perstor2
		Redperstor2
		Benperstor2
		diff_perstor3
		Redperstor3
		Benperstor3	
		MeanSS
		MeanSM
		RedperSS
		RedperSM
		BEA_SNAP
		USDA_PRGBEN
		BEN_AVG
		RedactedFlag
		USDA_FLAG
		t_pop
		Unemployed
		EALL;
	Set &library..Check2&library._&state.&FYear._&LYear;
RUN;

/* Are there any counties where:
			diff_perstor is greater than zero "Difference in Redemptions per store and benefits distributed per store (BEA)"
			diff_perstor2 but is less than zero "Difference in Redemptions per store and benefits distributed per store (Minus Convience Stores) (BEA)"
In theory counties with mostly convience stores should be unattractive.

First attempt diff_perstor < 0 and diff_perstor2 < 0 then delete
When both differences are negative this dropped 17,543 out of 26,310 (67%) of all observations.
First attempt diff_perstor < 0 OR diff_perstor2 < 0 then delete
Using the OR dropped the same number of observations.

There are no counties which attract snap benefits that have a large number 
of convience stores.
*/

DATA &library..Check3&library._&state.&FYear._&LYear REPLACE;
	Set &library..Check2&library._&state.&FYear._&LYear;
	If diff_perstor < 0 or diff_perstor2 < 0 then delete;
RUN;

/* Another option to check would be to take the annual averages of
redemptions by firm from the annual reports.
Multiply the average by the the types in each county.
See if the county redemptions are above or below average.
Based on the annual reports I could also look at average 
redemption amount of firms by state. This might provide some
basis for differences in redemptions by store type and state.
*/

/*-------------------------------------------------------------------*/
/* Keep Variables for Caluculating WCR                               */
/*-------------------------------------------------------------------*/

DATA &library..Clclt&library._&state.&FYear._&LYear REPLACE;
	Set &library..DropData&library._&state.&FYear._&LYear
	(Keep = 
		FIPS_County
		Year
		Yeartxt
		County_Name
		State
		Statefp
		BEA_SNAP
		USDA_PRGBEN
		BEN_Avg
		RedAmt
		RedactedFlag
		USDA_FLAG
		RetailTotal
		Mean:
		WCR_BEA
		WCR_USDA
		Redper:);
RUN;

/*-------------------------------------------------------------------*/
/* Calculate Average Within County Redemptions and Per Store         */
/*-------------------------------------------------------------------*/

%let dataset = &main_library;
%LET InputDataset = &library..Clclt&library._&state.&FYear._&LYear;

/*-------------------------------------------------------------------*/
/* Create Variable list - Variables to get totals for                */
/*-------------------------------------------------------------------*/
/*
The resulting data set (METACLASS) will have one row for each 
variable that was found in the original data set
Instructions found at http://caloxy.com/papers/58-028-30.pdf
Carpenter (nd) Storing and Using a List of Values in a Macro Variable
*/
/* Keep Variable to total */
DATA work.&dataset._totalvars 
	(Keep =
		/* variables to get min max mean for */
			redamt
			bea_snap
			USDA_PRGBEN
			WCR_BEA  /* "Within County Redemptions (BEA)" */
			WCR_USDA /*  "Within County Redemptions (USDA)" */
			Redperstor  /*  "Redemptions per SNAP Retialer" */
			RedperSS  /*  "Redemptions per SNAP Super Center" */
			RedperSM  /*  "Redemptions per SNAP Supermarket"*/ 
	 )
	REPLACE;
	Set &InputDataset;
RUN;

Proc Contents data=work.&dataset._totalvars noprint out=metaclass;
run;

 proc sql noprint;
 select name, label
 into :totalvarslist separated by ' ',
 	  :totalvarslabel separated by ';'
 from metaclass;
 quit;
%let cnttotalvars = &sqlobs;

/*-------------------------------------------------------------------*/
/* Create Variable list - Variables to get mean min max              */
/*-------------------------------------------------------------------*/

DATA work.&dataset._statvars 
	(Keep =
		/* variables to get min max mean for */
			redamt
			bea_snap
			USDA_PRGBEN
			WCR_BEA  /* "Within County Redemptions (BEA)" */
			WCR_USDA /*  "Within County Redemptions (USDA)" */
			Redperstor  /*  "Redemptions per SNAP Retialer" */
			RedperSS  /*  "Redemptions per SNAP Super Center" */
			RedperSM  /*  "Redemptions per SNAP Supermarket"*/ 
	 )
	REPLACE;
	Set &InputDataset;
RUN;

Proc Contents data=work.&dataset._statvars noprint out=metaclass2;
run;

 proc sql noprint;
 select name, label
 into :statvarslist separated by ' ',
 	  :statvarlabel separated by ';'
 from metaclass2;
 quit;
%let cntstatvars = &sqlobs;
/*-------------------------------------------------------------------*/
/* Set Primary Dataset with variables to summarize by county         */
/*-------------------------------------------------------------------*/

DATA work.&dataset._temp2 
		(Keep =
		/* id variables */
		FIPS_County
		Statefp
		Year
		County_Name

		/* variables to get totals for */
		&totalvarslist
		/* variables to get min max mean for */
		&statvarslist
		) 
	REPLACE;
	Set &InputDataset;
RUN;
/*-------------------------------------------------------------------*/
/* Sort by FIPS by Year                                              */
/*-------------------------------------------------------------------*/

Proc Sort Data = work.&dataset._temp2;
	BY FIPS_County Year;
RUN;
/*-------------------------------------------------------------------*/
/* STEPPING THROUGH THE LIST USING THE %SCAN FUNCTION                */
/*-------------------------------------------------------------------*/

/*-------------------------------------------------------------------*/
/* Calculate the Mean First                                          */
/*-------------------------------------------------------------------*/
/* Note: Add variable that helps normalize population and establishments   
I would like to be able to compare variance across counties
when using totals the values are wildly different, using LN might help
*/
%macro MeanCounty(dsn);
DATA work.&dsn._mean REPLACE;
	Set work.&dsn._temp2;
	BY FIPS_County Year;
	IF first.FIPS_County THEN DO;
		 %do i = 1 %to &cntstatvars;
			 mean_%scan(&statvarslist,&i) = 0;
			 meansum_%scan(&statvarslist,&i) = 0;
			 meancnt_%scan(&statvarslist,&i) = 0;
			 lnmean_%scan(&statvarslist,&i) = 0;
			 lnmeansum_%scan(&statvarslist,&i) = 0;
		 %end;
		 cnt = 0;
	end;
	%do i = 1 %to &cntstatvars;
		if %scan(&statvarslist,&i) NE . then do;
			meansum_%scan(&statvarslist,&i) + %scan(&statvarslist,&i);
			lnmeansum_%scan(&statvarslist,&i) + log(%scan(&statvarslist,&i));
			meancnt_%scan(&statvarslist,&i) + 1;
		end;
	%end;
	cnt + 1;
	IF last.FIPS_County THEN do;
		%do i = 1 %to &cntstatvars;
			if meancnt_%scan(&statvarslist,&i) > 0 then do;
			mean_%scan(&statvarslist,&i) =  
				meansum_%scan(&statvarslist,&i) / meancnt_%scan(&statvarslist,&i);
			lnmean_%scan(&statvarslist,&i) =  
				lnmeansum_%scan(&statvarslist,&i) / meancnt_%scan(&statvarslist,&i);
			end;
			else if meancnt_%scan(&statvarslist,&i) > 0 then do;
			mean_%scan(&statvarslist,&i) = .;
			lnmean_%scan(&statvarslist,&i) = .;
			end;
		%end;
		OUTPUT;
		end;
RUN;
%mend MeanCounty;
%MeanCounty(&dataset)
/*-------------------------------------------------------------------*/
/* Drop original variables keep new totals	                         */
/*-------------------------------------------------------------------*/

DATA  work.&dataset._mean
	(Keep =
		FIPS_County
		mean_:
		lnmean_:)
	REPLACE;
	Set  work.&dataset._mean;
Run;

/*-------------------------------------------------------------------*/
/* Merge Mean into dataset                                           */
/*-------------------------------------------------------------------*/

Proc Sort Data = work.&dataset._mean;
	BY FIPS_County;
RUN;

Proc Sort Data = work.&dataset._temp2;
	BY FIPS_County;
RUN;

DATA work.&dataset._temp2 REPLACE;
	MERGE work.&dataset._temp2 work.&dataset._mean;
	BY FIPS_County;
RUN;

/*-------------------------------------------------------------------*/
/* Sort by FIPS by Year                                              */
/*-------------------------------------------------------------------*/

Proc Sort Data = work.&dataset._temp2;
	BY FIPS_County Year;
RUN;

/*-------------------------------------------------------------------*/
/* Calculate totals, min, max, variance                              */
/*-------------------------------------------------------------------*/

%macro SumCounty(dsn);
DATA work.&dsn._temp3 REPLACE;
	Set work.&dsn._temp2;
	BY FIPS_County Year;
	IF first.FIPS_County THEN DO;
		 %do i = 1 %to &cnttotalvars;
		 	total_%scan(&totalvarslist,&i) = 0;
		 %end;
		 %do i = 1 %to &cntstatvars;
		 	min_%scan(&statvarslist,&i) = 0;
			max_%scan(&statvarslist,&i) = 0;
			var_%scan(&statvarslist,&i) = 0;
			varsum_%scan(&statvarslist,&i) = 0;
			diff_%scan(&statvarslist,&i) = 0;
			lndiff_%scan(&statvarslist,&i) = 0;
			lnvarsum_%scan(&statvarslist,&i) = 0;
			cnt_%scan(&statvarslist,&i) = 0;
		 	if %scan(&statvarslist,&i) NE . then do;
				min_%scan(&statvarslist,&i) + %scan(&statvarslist,&i);
				max_%scan(&statvarslist,&i) + %scan(&statvarslist,&i);
				end;
		 %end;
		 cnt = 0;
	end;
	%do i = 1 %to &cnttotalvars;
		 total_%scan(&totalvarslist,&i) + %scan(&totalvarslist,&i);
	%end;
	%do i = 1 %to &cntstatvars;
		if %scan(&statvarslist,&i) NE . then do;
			if min_%scan(&statvarslist,&i) = 0 AND 
				%scan(&statvarslist,&i) NE . then
				min_%scan(&statvarslist,&i) + %scan(&statvarslist,&i); 
			if %scan(&statvarslist,&i) < min_%scan(&statvarslist,&i) then
				min_%scan(&statvarslist,&i) =  %scan(&statvarslist,&i);
			if  %scan(&statvarslist,&i) > max_%scan(&statvarslist,&i) then
				max_%scan(&statvarslist,&i) =  %scan(&statvarslist,&i);
			diff_%scan(&statvarslist,&i) = 
				(%scan(&statvarslist,&i) - mean_%scan(&statvarslist,&i))**2;
			varsum_%scan(&statvarslist,&i) + diff_%scan(&statvarslist,&i);
			/* Calculate log variance */
			lndiff_%scan(&statvarslist,&i) = 
				(log(%scan(&statvarslist,&i)) - lnmean_%scan(&statvarslist,&i))**2;
			lnvarsum_%scan(&statvarslist,&i) + lndiff_%scan(&statvarslist,&i);
			cnt_%scan(&statvarslist,&i) + 1;
		end;
	%end;
	cnt + 1;
	IF last.FIPS_County THEN do;
		%do i = 1 %to &cntstatvars;
			if cnt_%scan(&statvarslist,&i) > 0 then do;
			var_%scan(&statvarslist,&i) =  
				varsum_%scan(&statvarslist,&i) / cnt_%scan(&statvarslist,&i);
			lnvar_%scan(&statvarslist,&i) =  
				lnvarsum_%scan(&statvarslist,&i) / cnt_%scan(&statvarslist,&i);
			end;
			else if cnt_%scan(&statvarslist,&i) = 0 then do;
				min_%scan(&statvarslist,&i) = .;
				max_%scan(&statvarslist,&i) = .;
				var_%scan(&statvarslist,&i) = .;
				varsum_%scan(&statvarslist,&i) = .;
				diff_%scan(&statvarslist,&i) = .;
				lnvarsum_%scan(&statvarslist,&i) = .;
				lndiff_%scan(&statvarslist,&i) = .;
			end;
		%end;
		OUTPUT;
		end;
RUN;
%mend SumCounty;
%SumCounty(&dataset)

/*-------------------------------------------------------------------*/
/* Drop original variables keep new totals	                         */
/*-------------------------------------------------------------------*/

DATA work.&dataset._totals
	(Keep =
		FIPS_County
		Statefp
		County_Name
		total_: 
		min_:
		max_:
		mean_:
		var_:
		cnt:)
	REPLACE;
	Set work.&dataset._temp3;
	/* Calculate absolute dollars gained or lost by county */
	if cnt_redamt = cnt_bea_snap Then Total_SNAPDiff1 = total_redamt - total_bea_snap;
Run;


/*-------------------------------------------------------------------*/
/* Export dataset to CSV for Mapping in QGIS                         */
/*-------------------------------------------------------------------*/
/*
proc export data= work.&dataset._totals
    outfile= "&dd_data.Dissertation\DatatoMap\Map..xls"
	Replace;
run;

/*-------------------------------------------------------------------*/
/* Export dataset to Stata                                           */
/*-------------------------------------------------------------------*/

proc export data= &library..DropData&library._&state.&FYear._&LYear 
    outfile= "&dd_data.Dissertation\Sept29&main_library.&state._&Fyear._&Lyear..dta"
	Replace;
run;
