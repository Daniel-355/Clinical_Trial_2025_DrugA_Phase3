/*create a summary table for analysis datasets*/
/*=========================================================
Convert the xpt files into sas files
=========================================================*/
%let path=C:\Users\hed2\Downloads\sas-and-r-main\sas-and-r-main;
%put &path;
%include "&path/TFL/program/general/xpt_2_sas.sas"; /* Adjust the path accordingly */
/* Call the macro */
/*convert xpt into sas7bdat*/
%import_xpt_files(folder=&path\tfl\data\, libname=mytfl, outpath=&path\tfl\mytfl\);

options validvarname=upcase;  /*all variable names are upcase*/


/*----------------------------------------------------------
Read input datasets and add Add the Total
----------------------------------------------------------*/
/* Intend to Treat */
data adsl01;
    set mytfl.adsl;
/*    where ITTFL = "Y";   /*???*/*/;
run;
/*proc contents data=mytfl.adsl varnum;*/
/*run; */
/*proc freq data=mytfl.adsl ;*/
/*table TRT01Pn;*/
/*run;*/

/* Add the Total */
data adsl02;

	set adsl01;
	treatment = TRT01PN;  /*create a new variable treatment*/
	output;
	
	treatment = 99;  /*create a new overall   treatment is 99  , sample size double here*/
	output;
run;
/*proc freq data=adsl02 ;*/
/*table treatment;*/
/*run;*/


/*----------------------------------------------------------
Get the treatment total  /*totoal number*/
----------------------------------------------------------*/
/*create a simple talbe*/
data dummy_trttotals;
	do treatment= 0, 54, 81, 99;
	   output;
	end;
run;
*------------------------------------------------------------------------------;
*get actual treatment totals;
*------------------------------------------------------------------------------;
 proc freq data=adsl02;
	tables treatment /list missing out=trttotals_pre (rename=(count=trttotal) drop=percent);
run;
 *------------------------------------------------------------------------------;
*merge actual/plan and actual treatment totals;
*------------------------------------------------------------------------------;
 data trttotals;   /*totoal number*/
   merge dummy_trttotals(in=a)
         trttotals_pre(in=b);
   by treatment;
   if a and not b then trttotal=0;
run;


*------------------------------------------------------------------------------;
/**create macro variables for the final presentation table; &trt99*/
*------------------------------------------------------------------------------;
data _null_;
    set trttotals;
    call symputx(cats("trt",treatment),trttotal);
run;
%put &trt99.;


*==============================================================================;
/**get counts for table body; calculate by analysis popultion */
*==============================================================================;
 proc sql;
	create table counts01 as 
		select 1 as order, treatment, count(distinct usubjid) as count
		from adsl02
		where ITTFL = "Y"  /*analysis dataset selection*/
		group by treatment
		
		union all corr
		
		select 2 as order, treatment, count(distinct usubjid) as count
		from adsl02
		where SAFFL = "Y"
		group by treatment
		
		union all corr
		
		select 3 as order, treatment, count(distinct usubjid) as count
		from adsl02
		where DISCONFL = "Y"
		group by treatment
		
		union all corr

		select 4 as order, treatment, count(distinct usubjid) as count
		from adsl02
		where DTHFL = "Y"
		group by treatment
		
		;
quit;

*==============================================================================;
/**create dummy data and merge with actual counts; label order*/
*==============================================================================;
 data dummy01;   /*label order*/
    length label $200;
 
    order=1; label="Intent to Treat Set"; output;
    order=2; label="Safety Analysis Set"; output;
    order=3; label="Discontinuation Set"; output;
    order=4; label="Death Set"; output;
run;
 
data dummy02;
   set dummy01;
   
   do treatment=0, 54, 81, 99;  /*create record sequence, read first record in dummy01 then do do loop */
    output;
   end;
run;

proc sort data=counts01;
   by order treatment;
   where  ;
run;
 
data counts02;
   merge dummy02(in=a)
         counts01(in=b);

   by order treatment;
 
   if a and not b then count=0;
run;
 

*==============================================================================;
*calculate percentages and format;
*==============================================================================;
/* sort by*/
proc sort data=trttotals ;
   by treatment;
run;
 
proc sort data=counts02 ;
   by treatment;
run;
 
data counts03;
   merge counts02(in=a)
         trttotals(in=b);   /*totoal number*/

   by treatment;
 
   if a;
run;
 
data counts04;
   set counts03;
 
   length cp $30;
 
   if count ne 0 then cp=put(count,3.)||" ("||put(count/trttotal*100,5.1)||")";  /*define the cell format*/
/*   " (" there is space ; */
/*PUT is a SAS function that converts a numeric value into a character string using a format.*/
/*3. means: Minimum field width = 3  No decimals (integer display)   If count=7 ? " 7" (right-aligned, width 3)*/
/*5.1 = total width 5, with 1 decimal place.*/

   else cp=put(count,3.);
run;


*==============================================================================;
*restructure the data to present treatments as columns;
*==============================================================================;
 proc sort data=counts04;
   by order label;
run;
 
/*transpose to wide format*/
proc transpose data=counts04 out=counts05 prefix=trt  ;   /*prefix , new variable prefix */
   by order label;
   var cp;
   id treatment;
run;
 

*==============================================================================;
/*output delivery system format*/
%let outputname=Summary for analysis sets;
footnote "&outputname.";  
/*Use a dot when the variable is immediately followed by letters, numbers, or underscores that could be mistaken as part of its name (&year.2025, &city.France).*/
title "Summary for Analysis Sets";
title2 "Intend to Treat Set";
ods listing close;

ods rtf file="C:\Users\hed2\Downloads\sas-and-r-main\sas-and-r-main\tfl\mytfl/disp1.rtf" style=csgpool01;

proc report data = counts05 center headline headskip nowd split='~' missing style(report)=[just=center]
   style(header)=[just=center];
 
/*   Centers the entire report output horizontally in the results window or output file.*/
/*headline Draws a line under the column headers.*/
/*headskip Adds a blank line after the column headers.*/
/*nowd older SAS versions had a "windowing environment"). interactive */
/*if a column label is "Subject~Count", SAS will display it in two lines:*/
/*missing if a variable is missing, PROC REPORT will still show a row for it.*/
/*just=center means text will be centered across the whole report table.*/
/*just=center means all headers will be centered.*/

   column order label trt0 trt54 trt81 trt99;
 
   define order/order noprint;  /*order noprint*/
 
   define label/width=30 " "  style(column)=[cellwidth=1.5in protectspecialchars=off] style(header)=[just=left];
/* Everything after the / are options controlling formatting and style.*/
/*width=30 Sets the column width in characters (roughly 30 characters wide in LISTING output).*/
/*" " (label override) This is the column label (what shows up in the header row).*/
/*cellwidth=1.5in ? fixes the column width to 1.5 inches in output destinations that use absolute measurement (RTF, PDF, HTML).*/
/*protectspecialchars=off ? allows special characters (like <, >, &) to be rendered as symbols, not escaped.*/
/*just=left means the column header will be left-aligned, even if the rest of the report is centered.*/

   define trt0/"Placebo"    "(N=&trt0.)"   style(column)=[cellwidth=1.2in just=center] ;
   define trt54/"Low Dose"  "(N=&trt54.)"  style(column)=[cellwidth=1.2in just=center] ;
   define trt81/"High Dose" "(N=&trt81.)"  style(column)=[cellwidth=1.2in just=center] ;
   define trt99/"Total"     "(N=&trt99.)"  style(column)=[cellwidth=1.2in just=center] ;
 
run;
 
ods rtf close;
ods listing;  
/*This statement opens the LISTING destination. Any subsequent procedure output will be sent to the SAS Output window (or a specified file).*/
/*Rich Text Format (RTF)*/
/*ods html;:*/
/*This statement reopens the default HTML destination. This is often done if you plan to generate HTML output later in the same SAS session.*/
