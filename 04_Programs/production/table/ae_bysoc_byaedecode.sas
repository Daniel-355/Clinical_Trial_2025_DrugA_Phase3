/*create a ae table by decode*/

/*=========================================================
Convert the xpt files into sas files
=========================================================*/
%let path=C:\Users\hed2\Downloads\sas-and-r-main\sas-and-r-main;
%put &path;
%include "&path/TFL/program/general/xpt_2_sas.sas"; /* Adjust the path accordingly */
/* Call the macro */
/*convert xpt into sas7bdat*/
%import_xpt_files(folder=&path\tfl\data\, libname=mytfl, outpath=&path\tfl\mytfl\);

options validvarname=upcase;


/*=========================================================
Programming for the Task saffl="Y";
=========================================================*/
/*----------------------------------------------------------
Read input datasets
----------------------------------------------------------*/
data adsl01;
    set mytfl.adsl;
    where saffl="Y";
run;
 
data adae01;
    set mytfl.adae;
    where saffl="Y" and trtemfl="Y";   /*indicating whether an adverse event (AE) occurred or worsened after a subject started treatment. */
/*with safety dataset*/
run;


/*=========================================================
Create variable named 'treatment' to hold report level column groupings
add totals
=========================================================*/
data adae02;
    set adae01;
    treatment=trtan;
    output;

    treatment=99;
    output;
run;
 
data adsl02;
   set adsl01;
    treatment=trt01an;
    output;

    treatment=99;
    output;
run;


/*=========================================================
Get treatment totals into a dataset and into macro variables (for column headers) from adsl
calculate N
=========================================================*/
proc sql;
   create table trttotals_pre as
      select treatment,        count(distinct usubjid) as trttotal
      from adsl02
      group by treatment;
quit;
/*----------------------------------------------------------
Create dummy dataset for treatement totals
----------------------------------------------------------*/
 data dummy_trttotals;
   do treatment=0,54,81,99;
      output;
   end;
run;
/*----------------------------------------------------------
Merge actual counts with dummy counts
----------------------------------------------------------*/
data trttotals;
   merge dummy_trttotals(in=a) trttotals_pre(in=b);
   by treatment;
   if trttotal=. then trttotal=0;
run;
/*----------------------------------------------------------
create Macro variables for N
----------------------------------------------------------*/
data _null_;
    set trttotals;
    call symputx(cats("n",treatment),trttotal);
run;


/*=========================================================
Obtaining actual counts-for the table
=========================================================*/
/*----------------------------------------------------------
"Subject level" count- top row
----------------------------------------------------------*/
proc sql noprint;
   create table sub_count as
   select "Overall" as label length=200,      treatment,     count(distinct usubjid) as count
   from adae02
   group by treatment;  /*by only treatment */
quit;

/*----------------------------------------------------------
"SOC level" counts
----------------------------------------------------------*/
proc sql noprint;
   create table soc_count as
      select aebodsys, treatment,       count(distinct usubjid) as count
      from adae02
      group by aebodsys, treatment;   /*by treatment and bodysystem*/
quit;
/*----------------------------------------------------------
"Preferred term" level counts
----------------------------------------------------------*/
proc sql noprint;
   create table pt_count as
      select aebodsys, aedecod, treatment,       count(distinct usubjid) as count
      from adae02
      group by aebodsys, aedecod, treatment;  /*by treatment   bodysystem  prefer decode*/
quit;
/*----------------------------------------------------------
Combine toprow, SOC, and PT level counts into single dataset
----------------------------------------------------------*/
data counts01;
   set sub_count soc_count pt_count;
run;


/*=========================================================
=========================================================*/
 /*----------------------------------------------------------
keep possible categories, make missing as zero
Get all the available SOC and PT values, 
----------------------------------------------------------*/
 proc sort data=counts01 out=dummy01(keep=aebodsys aedecod label) nodupkey;
   by aebodsys aedecod label;
run;
/*----------------------------------------------------------
Create a row for each treatment for the above categories
----------------------------------------------------------*/
data dummy02;
   set dummy01;
   do treatment=0,54,81,99;
         output;
   end;
run;
/*=========================================================
Merge dummy counts with actual counts
=========================================================*/
 proc sort data=dummy02;
   by aebodsys aedecod label treatment;
run;
 
proc sort data=counts01;
   by aebodsys aedecod label treatment;
run;
 
data counts02;
   merge dummy02(in=a) counts01(in=b);
   by aebodsys aedecod label treatment;
   if count=. then count=0;
run;

 
/*=========================================================
Calculate percentages
=========================================================*/
 proc sort data=counts02;
   by treatment;
run;
 
proc sort data=trttotals;
   by treatment;
run;
 
data counts03;
   merge counts02(in=a) trttotals(in=b);
   by treatment;
   if a;  /*keep only rows where a is not missing or zero (for numeric, dot) / not blank (for character, blank).”*/
run;
 
data counts04;
   set counts03;
   length cp $30;
   if count ne 0 then cp=put(count,3.)||" ("||put(count/trttotal*100,5.1)||")";
   else cp=put(count,3.);
run;
 
 
/*=========================================================
Create the label column
=========================================================*/
 data counts05;
   set counts04;
   if missing(aebodsys) and missing(aedecod) then label=label;
   else if not missing(aebodsys) and missing(aedecod) then label=aebodsys;
   else if not missing(aebodsys) and not missing(aedecod) then label= "      "||strip(aedecod);
run;

 
/*=========================================================
Transpose to obtain treatment as columns
=========================================================*/

proc sort data=counts05;
   by aebodsys aedecod label ;
run;
 
proc transpose data=counts05 out=counts06 prefix=trt;  
   by aebodsys aedecod label;
   var cp;
   id treatment;
run;


/*=========================================================
Report generation
proc report 
=========================================================*/
/*=========================================================
Report generation with page numbers
=========================================================*/
footnote j=l "Page \{thispage} of \{lastpage}" j=c "AE_BYSOC_BYDECOD"; /*j=l left, \{thispage} of \{lastpage}*/
title1 j=c f=Times h=16pt "Summary of Treatment-Emergent Adverse Events by Primary System Organ Class and Preferred Term";
/*position, font, size*/
title2 j=c f=Times h=16pt "Safety Analysis Set";
*Output rtf file*;
ods listing close;
options orientation=landscape nodate nonumber nobyline;
/*“Make the output page wide (landscape), and remove the date, page number, and BY-group lines for a cleaner report.”*/
ods rtf file= "C:\Users\hed2\Downloads\sas-and-r-main\sas-and-r-main\tfl\mytfl/AE_BYSOC_BYAEDECOD.rtf" style=ars_sj1 startpage=Yes;
ods escapechar='\';
/*“Whenever you see a backslash in text, treat what follows as a formatting command, not as plain text.”*/
/*So style=ars_sj1 means: "Render the output using the ars_sj1 style template."*/
/*ars_sj1 is a custom ODS style — it’s not one of SAS’s built-in styles like journal, listing, htmlblue, etc.*/
/*startpage=Yes This controls whether SAS forces a new page at certain boundaries in ODS destinations (like RTF or PDF).*/
proc report data=counts06 center nowd headline headskip spacing=0 NOFS split='|' missing 
/*You can choose any character as the split character (split='~', split='|', etc.).*/
/*Only affects column headers, not the data.*/
/*Often used in clinical trial tables for multi-line labels, e.g., "Number|of Subjects" ?*/

    style(report)={width=100% frame=void rules=none} style(header)={just=c borderbottomstyle=solid borderbottomwidth=0.5pt} 
    style(column)={just=c verticalalign=bottom};
/* style(report) Applies style attributes to the entire report table.*/
/*width=100% Sets the table to span the full width of the output page (100% of the available space).*/
/*void ? no border is drawn around the table.*/
/*Other options: box (single line around table), hsides, vsides, all (all borders), etc.*/
/*none ? no lines inside the table (no grid lines). Other options: cols (vertical lines), rows (horizontal lines), all (both horizontal and vertical).*/

/*“For this column, center the text horizontally, and align it to the bottom of each cell vertically.”*/

/*“Center the header text horizontally and draw a thin solid line under the header.”*/
   columns aebodsys aedecod label  trt0 trt54 trt81 trt99;
   define aebodsys/ order noprint;
   define aedecod/order noprint;
   
   define label /"System Organ Class" "      Preferred Term"
   	style=[just=L cellwidth=2 in asis=on];
/* 	Sets the cell width to 2 inches.*/
/*asis=on Stands for “as is.” Tells SAS not to break lines or re-wrap text automatically — instead, display the text exactly as it appears in the data.*/
   define trt0/"Placebo" "(N=%cmpres(&n0))" "  n   (%)" style=[just=c cellwidth=1 in asis=on];
   define trt54/"Low Dose" "(N=%cmpres(&n54))" "  n   (%)" style=[just=c cellwidth=1 in asis=on];
   define trt81/"High Dose" "(N=%cmpres(&n81))" "  n   (%)" style=[just=c cellwidth=1 in asis=on];
   define trt99/"Total" "(N=%cmpres(&n99))" "  n   (%)" style=[just=c cellwidth=1 in asis=on];  
 
   compute after aebodsys;
/*   With the COMPUTE AFTER AEBODSYS block, you’d get an extra blank line between groups:*/
        line @1 "";
/*		So this simply inserts a blank line after each aebodsys group in the report.*/
   endcomp;
/* endcomp;Marks the end of the COMPUTE block.*/
/*   “After finishing each aebodsys section in the report, insert one blank line for spacing.”*/
run;
 
ods rtf close;
ods listing;

 


