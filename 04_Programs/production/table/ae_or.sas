/*=========================================================
Include the data file
=========================================================*/
 %let root2=C:\Users\hed2\Downloads\sdtm-adam-pilot-project-master\sdtm-adam-pilot-project-master\updated-pilot-submission-package\900172\m5\datasets\cdiscpilot01\analysis\adam\datasets\mytfl\;
 
%include "&root2._data.sas";
 
 
options validvarname=upcase;
/*=========================================================
Programming for the Task
=========================================================*/
 
 
/*----------------------------------------------------------
Read input datasets
----------------------------------------------------------*/
 
data adae01;
    set adae;
    where saffl="Y" and trtemfl="Y";
run;
 
 
data adsl01;
    set adsl;
    where saffl="Y";
run;
 
 
/*=========================================================
Create variable named 'treatment' to hold report level column groupings
=========================================================*/
 
 
data adae02;
    set adae01;
    treatment=trtan;
    output;
run;
 
data adsl02;
   set adsl01;
    treatment=trt01an;
    output;
run;
 
/*=========================================================
````````````````Get treatment totals into a dataset and into macro variables (for column headers)
=========================================================*/
 
 
proc sql;
   create table trttotal_pre as
      select treatment,
      count(distinct usubjid) as trttotal
      from adsl02
      group by treatment;
quit;
 
/*----------------------------------------------------------
Create dummy dataset for treatement totals
----------------------------------------------------------*/
 
data dummy_pre;
   do treatment=0,54;
      output;
   end;
run;
 
/*----------------------------------------------------------
Merge actual counts with dummy counts
----------------------------------------------------------*/
 
data trttotals;
   merge dummy_pre(in=a) trttotal_pre(in=b);
   by treatment;
   if trttotal=. then trttotal=0;
run;
 
 
/*----------------------------------------------------------
Macro variables
----------------------------------------------------------*/
proc sql noprint;
   select count(distinct usubjid) into :n0 from adsl02 where treatment=0;
   select count(distinct usubjid) into :n54 from adsl02 where treatment=54;
quit;
 
 
/*=========================================================
`````````````Obtaining actual counts-for the table
=========================================================*/
 
 
/*----------------------------------------------------------
Subject level count- top row
----------------------------------------------------------*/
 
 
proc sql noprint;
   create table sub_count as
   select "Overall" as label length=200,
   treatment,
   count(distinct usubjid) as count
   from adae02
   group by treatment;
quit;
 
/*----------------------------------------------------------
Preferred term level counts
----------------------------------------------------------*/
 
 
proc sql noprint;
   create table pt_count as
      select aedecod,treatment,
      count(distinct usubjid) as count
      from adae02
      group by aedecod,treatment;
quit;
 
 
/*----------------------------------------------------------
Combine toprow and PT level counts into single dataset
----------------------------------------------------------*/
 
 
data counts01;
   set sub_count pt_count;
run;
 
/*=========================================================
Create zero counts if an event is not present in a treatment
=========================================================*/
/* from 357 to 585  after adding zero records*/
 
/*----------------------------------------------------------
Get all the available PT values
----------------------------------------------------------*/
 
proc sort data=counts01 out=dummy01(keep=aedecod label) nodupkey;
   by aedecod label;
run;
 
/*----------------------------------------------------------
Create a row for each treatment
----------------------------------------------------------*/
 
data dummy02;
   set dummy01;
   do treatment=0,54;
         output;
   end;
run;
 
/*=========================================================
Merge dummy counts with actual counts
=========================================================*/
 
proc sort data=dummy02;
   by aedecod label treatment;
run;
 
 
proc sort data=counts01;
   by aedecod label treatment;
run;
 
data counts02;
   merge dummy02(in=a) counts01(in=b);
   by aedecod label treatment;
   if count=. then count=0;
run;
 
 
/*=========================================================
``````````````Calculate percentages
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
   if a;
run;
 
data counts04;
   set counts03;
   length cp $30;
   if count ne 0 then cp=put(count,3.)||" ("||put(count/trttotal*100,5.1)||"%)";
   else cp=put(count,3.);
run;
 
 
/*=========================================================
Create the label column
=========================================================*/
 
 
data counts05;
   set counts04;
   if missing(aedecod) then label=label;
   else if not missing(aedecod) then label=strip(aedecod);
run;
 
 
/*=========================================================
````````````````Transpose to obtain treatment as columns
=========================================================*/
 
 
proc sort data=counts05;
   by aedecod label ;
run;
 
proc transpose data=counts05 out=trans01 prefix=trt;
   by aedecod label;
   var cp;
   id treatment;
run;
 
 
data trans02;
   set trans01;
   keep aedecod c1 trt: label;
   c1=label;
run;
 
 
/*=========================================================
Get odds ratio and 95% confidence interval
=========================================================*/
 
 
/*----------------------------------------------------------
`````````````Subset the required treatment groups  ,  keep two groups
----------------------------------------------------------*/
data events01;
   set counts05;
   where treatment in (0,54);
   if treatment=0 then treatment=2;
   else treatment=1;
run;
 
/*----------------------------------------------------------
``````````````Get the number subjects with non-event
----------------------------------------------------------*/
/*----------------------------------------------------------
This count can be obtained by substracting the number of subjects with event from denominator
----------------------------------------------------------*/
 
data events02;
   set events01;
   event=1;
   output;
   count=trttotal-count;
   event=2;
   output;
run;
 
 
/*----------------------------------------------------------
````````````````Check if there is any aedecod with 0 counts in both treatments
----------------------------------------------------------*/
/*----------------------------------------------------------
0 counts can be present in both treatments when there are more than 2 treatment groups</br>
as other treatment groups may have events with no events in treatments under consideration for p-value
----------------------------------------------------------*/
/* from 925---724 records after deleting both zero*/
proc sql;
   create table nonzerodecods as
      select distinct aedecod,label
      from events01
      group by aedecod,label
      having sum(count) gt 0;
quit;
 
proc sql;
   create table events03 as
      select a.*
      from events02 as a
      inner join
      nonzerodecods as b
      on a.aedecod=b.aedecod and a.label=b.label;
quit;
 
/*----------------------------------------------------------
``````````````Run proc freq with required options (relrisk on tables statment)
----------------------------------------------------------*/
 
proc sort data=events03;
   by aedecod label treatment event;
run;
 
ods output relativerisks=odds01;
 
proc freq data=events03;
    by aedecod label;
    tables treatment*event/relrisk;     /*relrisk = or*/
    weight count;
run;
 
 
/*----------------------------------------------------------
Process p-value dataset to create variable to hold p-value
----------------------------------------------------------*/
/* ````````````reformat odds ratio*/
data odds02;
    set odds01;
    where statistic="Odds Ratio";   /*select/specify odds ratio stats; rr= relative risk*/
    length odds est ll ul $30;
 
    if value ne . then est=put(round(value,0.1),6.1);
    else est="NE";
    if lowercl ne . then ll=put(round(lowercl,0.1),6.1);
    else ll="NE";
    if uppercl ne . then ul=put(round(uppercl,0.1),6.1);
    else ul="NE";
   odds=strip(est)||" ("||strip(ll)||","||strip(ul)||")";    /*combine into a cell*/
run;
 
/*----------------------------------------------------------
````````````Merge the odds ratio dataset to the dataset containing treatments as columns
----------------------------------------------------------*/
 
proc sort data=trans02;
   by aedecod label;
run;
 
data trans03;
   merge trans02(in=a) odds02(in=b keep=aedecod label odds);
   by aedecod label;
   if a;
   if aedecod="" and label="Overall" then ord=1;
   else ord=2;
   if missing(odds) then odds="-";
run;
 
/*=========================================================
``````````````````Report generation
=========================================================*/
 
%rtf_output_style_setup;
 
footnote "&outputname.";
 
title "TEAE by PT - Odds Ratio";
title2 "Safety Analysis Set";
title3 bcolor="#e6f9ec" "Copyright @  mycsg.in";
 
ods listing close;
ods rtf file="&outputpath.\ae_or.rtf" style=csgpool01;
 
proc report data=trans03 nowd headline headskip missing style(report)=[just=center]
   style(header)=[just=center];
   columns ord aedecod c1  trt0 trt54 odds;
   define aedecod/ order noprint;
   define ord/ order noprint;
 
   define c1 /order 'Preferred Term' style(column)=[cellwidth=3.7in protectspecialchars=off]
            style(header)=[just=left] ;
   define trt0/"Placebo" "(N=%cmpres(&n0))" "  n   (%)" style(column)=[cellwidth=1.2in just=center] ;
   define trt54/"Active" "(N=%cmpres(&n54))" "  n   (%)" style(column)=[cellwidth=1.2in just=center]   ;
   define odds/"OR (95% CI)" style(column)=[cellwidth=1.2in just=center];
 
   compute after ord;
        line @1 "";
   endcomp;
 
run;
 
ods rtf close;

/*Rule of thumb in clinical safety/efficacy tables:*/
/**/
/*Common events (=10%) ? report Relative Risk (PROC GENMOD).*/
/**/
/*Rare events (<10%) ? Odds Ratio is fine (PROC LOGISTIC).*/
/**/
/*When to Use*/
/**/
/* Want quick OR & RR for a 2×2 table? ? PROC FREQ*/
/**/
/* Need OR with covariates (multivariable)? ? PROC LOGISTIC*/
/**/
/* Need RR (not OR), or rate ratios, or more complex distributions? ? PROC GENMOD*/
