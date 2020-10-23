/*-------------------------------------------------------------------*/
/*       Merge FEMA CBP Dataset into one county one observation      */
/*          by Nathanael Rosenheim                                   */
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
/* Date Last Updated: 31Jul2014                                      */
/*-------------------------------------------------------------------*/
/* Questions or problem reports concerning this material may be      */
/* addressed to the author on github: https://github.com/npr99       */
/*                                                                   */
/*-------------------------------------------------------------------*/
/* Data Source:                                                      */
/* Various
/*-------------------------------------------------------------------*/
options SYMBOLGEN MPRINT;

/*-------------------------------------------------------------------*/
/* Important Folder Locations                                        */
/*-------------------------------------------------------------------*/

%LET dd_data = C:\Users\Nathanael\Dropbox\MyData\;
%LET dd_data2 = C:\Users\Nathanael\MyData\;
%LET dd_SASLib = C:\Users\Nathanael\MySASLib\;
%LET Include_prog = C:\Users\Nathanael\Dropbox\MyPrograms\;

/*-------------------------------------------------------------------*/
/* Important Macro Variables                                         */
/*-------------------------------------------------------------------*/

%Let FYear = 2001;
%Let LYear = 2012;
%let library = FEMACBP;
%let dataset = L48FEMACBP;

LIBNAME &library "&dd_SASLib.&library";

/*-------------------------------------------------------------------*/
/* Import FEMACBP File                                               */
/*-------------------------------------------------------------------*/
/* 
Select the Variables that you want to include in summation
*/

Proc Contents data=&library..L48FEMACBP_&Fyear._&Lyear noprint out=AllVariables;
run;
DATA work.&dataset._temp REPLACE;
	Set &library..L48FEMACBP_&Fyear._&Lyear;
RUN;

/*-------------------------------------------------------------------*/
/* Add variable that represents estimated IA and IH                  */
/*-------------------------------------------------------------------*/
/* Individual assistance is in terms of percapita for the disater
I need to multiply this by the number of people in the county to get
a comparable idea of how much assistance the county recieved. This 
is an assumption that may not be true
*/

DATA work.&dataset._temp REPLACE;
	Set work.&dataset._temp;
		ecty_ha = dn_percapitaha * t_pop;
		ecty_otheria = dn_percapitaotheria * t_pop;
		ecty_iaih = dn_percapitaiaih * t_pop;
RUN;

DATA work.&dataset._temp REPLACE;
	Set work.&dataset._temp;
	Label
		ecty_ha = "Estimated county Housing Assistance"
		ecty_otheria = "Estimated county Other IA Assistance"
		ecty_iaih = "Estimated county Other IA and IH Assistance";
RUN;

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
		/* variables to get totals for */
		sum_DR			/* Total Number of Major Disasters */
		Sum_DisasterNum
		Sum_EM
		Sum_FM
		/* Count of disasters by type */
		It_: DR_:
		dn_percapita:	/* assistance by disaster num percapita */
		ecty_:			/* Estimated county Individual Assisantce */
		Duration_:      /* Duration of disasters */
		PerCapitaPA_TtlOblg /*County Level Total Available PA Divided By 
								Estimated County Population */
		SumPA_TtlOblg 		/* Sum of The federal share of the Public Assistance 
								Grant eligible project amount, plus grantee 
								(State) and subgrantee (applicant) 
								administrative costs. The federal share is 
								typically 75% of the total cost of the project. */ 
	)
	REPLACE;
	Set work.&dataset._temp;
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
		t_pop				/* total population */
		PALL 				/* Percent of people of all ages in poverty */
		EMP44 EST44 N1_944	/* Retail Trade Data */
		EMP72 EST72 N1_972	/* Accommodation & food services Data */
		EMP23 EST23 N1_923	/* Construction Data */
		Minc				/* Median Income */
	 )
	REPLACE;
	Set work.&dataset._temp;
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
		Year
		County_Name

		/* variables to get totals for */
		&totalvarslist
		/* variables to get min max mean for */
		&statvarslist
		) 
	REPLACE;
	Set work.&dataset._temp;
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
		total_: 
		min_:
		max_:
		mean_:
		var_:
		lnvar_:
		cnt:)
	REPLACE;
	Set work.&dataset._temp3;
Run;

/*-------------------------------------------------------------------*/
/* Add Total Assistance Value                                        */
/*-------------------------------------------------------------------*/

DATA work.&dataset._totals REPLACE;
	Set work.&dataset._totals;
	total_assistance = total_ecty_otherIA + total_ecty_ha + total_SumPA_TtlOblg;
	total_prcptassitance = total_DN_PerCapitaHA + total_DN_PerCapitaOtherIA + total_PerCapitaPA_TtlOblg;
Run;

/*-------------------------------------------------------------------*/
/* Add Labels to Variables                                           */
/*-------------------------------------------------------------------*/
/* Not sure how to do this via a macro;
%macro AddLabels(dsn);
DATA work.&dsn._test Replace;
	Set work.&dsn._totals;
    Attrib
	 %do i = 1 %to &cnttotalvars;
	 	total_%scan(&totalvarslist,&i) label = %superq(%scan(&totalvarslabel,&i,';'))
	 %end;
	 %do i = 1 %to &cntstatvars;
	 	mean_%scan(&statvarslist,&i) label = 'Mean: ' || %scan(&statvarslabel,&i,';')
		min_%scan(&statvarslist,&i) label = 'Min: ' || %scan(&statvarslabel,&i,';')
	 	man_%scan(&statvarslist,&i) label = 'Max: ' || %scan(&statvarslabel,&i,';')
		var_%scan(&statvarslist,&i) label = 'Variance: ' || %scan(&statvarslabel,&i,';')
	 %end;
	;
Run;
%mend AddLabels;
%AddLabels(&dataset)
*/

/*-------------------------------------------------------------------*/
/* Export panel to Library                                           */
/*-------------------------------------------------------------------*/
Data &library..&dataset.countytotals&FYear._&LYear Replace;
	Set work.&dataset._totals;
Run;


/*-------------------------------------------------------------------*/
/* Export Basic info to excel to show on map                         */
/*-------------------------------------------------------------------*/

DATA work.&dataset._totals_&Fyear._&Lyear
	(Keep = 
		FIPS_county
		total_Duration_:
		total_assistance
		total_prcptassitance
		total_SumPA_TtlOblg
		total_PerCapitaPA_TtlOblg
		total_sum_DR
		total_Sum_DisasterNum
		total_Sum_EM
		total_Sum_FM
		total_it_:
		total_dr_:
		lnvar:
	)
	REPLACE;
	Set work.&dataset._totals;
Run;

proc export data=work.&dataset._totals_&Fyear._&Lyear
    outfile= "&dd_data.XiaoPeacockRDC\&dataset._totals_&Fyear._&Lyear..xls"
	Replace;
run;
