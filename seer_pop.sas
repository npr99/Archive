*options obs=100 ;
options nocenter ;

/*------------------------------------------------
  by Jean Roth	Wed Apr 25 16:51:52 EDT 2007
  This program reads the  Survey of Epidemiology and End Results (SEER) U.S. Population Data Data File

  Report errors to jroth@nber.org
  This program is distributed under the GNU GPL.
  See end of this file and
  http://www.gnu.org/licenses/ for details.
 ----------------------------------------------- */
/*------------------------------------------------
Modified by Nathanael Rosenheim 
July 24, 2014
 ----------------------------------------------- */

* Data Downloaded from:
All States Combined (Adjusted) County
19 Age Groups	1990	4 Expanded Races by Origin
http://www.nber.org/data/seer_u.s._county_population_data.html;

*  The following line should contain the directory
   where the SAS file is to be stored  ;

/*-------------------------------------------------------------------*/
/* Important Folder Locations                                        */
/*-------------------------------------------------------------------*/
%LET rootdir = C:\Users\Nathanael\Dropbox\MyProjects\RDC2\;

/*------------------------------------------------------------------*/
/* Project Mnemonic                                                 */
/*------------------------------------------------------------------*/
* Select a short (3-4 letter) mnemonic for your project
// The mnemonic will be used to name folders, files, & variables
// What is the Project Mnemonic?;
%LET  prjct = RDC2;

* Where is the source data?;
%LET dd_data = &rootdir.Scratch\Datasets\Source\;

* Where will the sas7bdat files be saved?;
%LET dd_SASLib = &rootdir.Scratch\Datasets\Derived\;

/* Directory to store final NHIS data */
%LET SEER_dir = &dd_SASLib.SEER\;

%let library = SEER;
ods path reset;
 libname SEER clear;
/* Create folder if it doesn't exist */
* options dlcreatedir;
LIBNAME &library "&SEER_dir";


*  The following line should contain
   the complete path and name of the raw data file.
   On a PC, use backslashes in paths as in C:\  ;

/* What is the file name of the IPUMS extract?*/
%LET SEERFile = &dd_data.usrace19agesadj.sas7bdat;

*  The following line should contain the name of the SAS dataset ;

%let dataset = seer_pop ;

DATA SEER.&dataset ;
  set SEERFile;

attrib  year         length=4     label="Year";                                 
attrib  st           length=$2    label="State postal abbreviation";            
attrib  stfips       length=3     label="State FIPS code";                      
attrib  county       length=3     label="County FIPS code";                     
attrib  registry     length=3     label="Registry";                             
attrib  race         length=3     label="Race";                                 
attrib  hispanic     length=3     label="Hispanic Origin";                      
attrib  sex          length=3     label="Sex";                                  
attrib  age          length=3     label="Age";                                  
attrib  pop          length=5     label="Population";                           


INPUT

@1    year           4. 
@5    st            $2. 
@7    stfips         2. 
@9    county         3. 
@12   registry       2. 
@14   race           1. 
@15   hispanic       1. 
@16   sex            1. 
@17   age            2. 
@19   pop            8. 
;
Run;

/*------------------------------------------------
The PROC FORMAT statement will store the formats 
in a sas data set called fseerp
To use the stored formats in a subsequent program, 
use code like the following:

proc format cntlin=SEER.fseerp;
PROC freq;
        tables pesex ;
        format pesex      P135L.;

For more information, consult PROC FORMAT in the SAS Procedures Guide
 ----------------------------------------------- */

PROC FORMAT cntlout=SEER.fseerp;

;
VALUE registry	(default=32)
	01        =  "San Francisco-Oakland SMSA"    
	02        =  "Connecticut"                   
	20        =  "Detroit (Metropolitan)"        
	21        =  "Hawaii"                        
	22        =  "Iowa"                          
	23        =  "New Mexico"                    
	25        =  "Seattle (Puget Sound)"         
	26        =  "Utah"                          
	27        =  "Atlanta (Metropolitan)"        
	29        =  "Alaska Natives"                
	31        =  "San Jose-Monterey"             
	33        =  "Arizona Indians"               
	35        =  "Los Angeles"                   
	37        =  "Rural Georgia"                 
	41        =  "California excluding SF/SJM/LA"
	42        =  "Kentucky"                      
	43        =  "Louisiana"                     
	44        =  "New Jersey"                    
	99        =  "Registry for non-SEER area"    
;
VALUE race    	(default=32)
	1         =  "White"                         
	2         =  "Black"                         
	3         =  "Other (1969+)/American Indian/Alaska Native (1990+)"
	4         =  "Asian or Pacific Islander (1990+)"
;
VALUE hispanic	(default=32)
	0         =  "Non-Hispanic"                  
	1         =  "Hispanic"                      
	9         =  "Not applicable in 1969-2004 W" 
;
VALUE sex     	(default=32)
	1         =  "Male"                          
	2         =  "Female"                        
;
VALUE age     	(default=32)
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
;

/*
proc print data=SEER.seer_pop (obs=6);


FORMAT
	registry   registry. 
	race       race.     
	hispanic   hispanic. 
	sex        sex.      
	age        age.      
; 

proc contents data=SEER.seer_pop;

/*
Copyright 2007 shared by the National Bureau of Economic Research and Jean Roth

National Bureau of Economic Research.
1050 Massachusetts Avenue
Cambridge, MA 02138
jroth@nber.org

This program and all programs referenced in it are free software. You
can redistribute the program or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation;
either version 2 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307
USA.
*/

