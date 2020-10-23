/* Source:
http://support.sas.com/kb/26/139.html
Sample 26139: Create variable labels from data set values
*/

/* Example 1: Use the values from one data set to create labels for another */
/*            data set                                                      */

/* Create a macro to generate labels from values in one data set and apply */
/* the new labels to variables in another data set.                        */

%macro label(datain= );
  %local dsid getvalue getvarname close i ;

  /* Open dataset whose values in the first observation will become new labels */
  %let dsid=%sysfunc(open(&datain));

  /* ATTRN and NVARS will return the number of variables in &datain */
  %do i=1 %to %sysfunc(attrn(&dsid,nvars));

    /* Retrieve each variable name in &datain */
    %let getvarname=%sysfunc(varname(&dsid,&i));

    /* FETCHOBS reads the specified observation from &datain */
    %let rc=%sysfunc(fetchobs(&dsid,1));

    /* Retrieve the value of each variable */
    %let getvalue=%qsysfunc(getvarc(&dsid,&i));
	
    /* Build the syntax for the LABEL statement that will be generated */
    &getvarname = "&getvalue"
  %end;

  /* Close the dataset */
  %let close=%sysfunc(close(&dsid));

%mend label;

/* Create a sample data set whose values will later be used as labels for */
/* a second data set.                                                     */

data one;
  infile datalines dsd ;
  input (var1-var3)(:$13.);
datalines;
label's one,label's two,label's three
;

/* Call the macro %LABEL while creating WORK.TWO.  %LABEL will generate a */
/* LABEL statement based upon the variables and values from the specified */
/* data set, in this case, WORK.ONE.  Note the variable names must be the */
/* same in both data sets.                                                */

data two;
  input (var1-var3) ($1.,+1);
  label %label(datain = one);
datalines;
a b c
d e f
;

proc print data=two label;
run;




/* Example 2: Applying the macro %LABEL when reading from one file           */
/*                                                                           */
/*            Read a flat file whose first record is meant to be variable    */
/*            names but are invalid SAS variable names.  Create labels from  */
/*            the first record instead.                                      */

/* Create sample test file to be read. Modify your FILE statement as needed. */

data _null_;
  file "c:\temp\sample1727.txt";
  put "2005,2006,2007,Total Revenue";
  put "1,2,3,25000";
  put "4,5,6,50000";
run;

/* Read only the first record from SAMPLE1727.TXT using OBS=1 on the INFILE  */
/* statement.                                                                */

data one_2;
  infile "c:\temp\sample1727.txt" dsd obs=1;
  input (var1-var3) (:$4.) var4 :$13.;
run;

/* Read the rest of SAMPLE1727.TXT starting from the second observation.  Use  */
/* the macro %LABEL created above to use the values from WORK.ONE_2 as the new */
/* variable labels.                                                            */

data two_2;
  infile "c:\temp\sample1727.txt" dsd firstobs=2;
  input (var1-var4)(:8.);
  label %label(datain = one_2);
run;

proc print data=two_2 label;
run;
