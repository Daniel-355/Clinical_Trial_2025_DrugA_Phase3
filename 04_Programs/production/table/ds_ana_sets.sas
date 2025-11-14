/*=========================================================
Include the data file
=========================================================*/
%let root2=C:\Users\hed2\Downloads\sdtm-adam-pilot-project-master\sdtm-adam-pilot-project-master\updated-pilot-submission-package\900172\m5\datasets\cdiscpilot01\analysis\adam\datasets\mytfl\;
 
 
%include "&root2._data.sas";
 
 
options validvarname=upcase;
/*=========================================================
Programming for the Task
=========================================================*/
 
 
*==============================================================================;
*```````````create four analysis datasets, include the data file;
*==============================================================================;
 
 data adsl;
  set adsl;

  length RANDFL FASFL SAFFL PPSFL $1;

  /* 1. Randomized Flag */
  RANDFL=ITTFL;
 
  /* 2. Full Analysis Set (ITT/FAS) */
FASFL=ITTFL;

  /* 3. Safety Population */
/*=SAFFL*/

  /* 4. Per Protocol Population */
  if FASFL="Y" and SAFFL="Y" and DCREASCD ne "Protocol Violation" then PPSFL="Y";
  else PPSFL="N";
run;
 

/*Informed Consent ?      Screening ? Screen Fail/Excluded ?       Randomized ?   Treated -    excluded (withdraw inform consent)? Withdrawn/Completed*/
 
/*proc freq data= adsl;*/
/*table DCDECOD DCREASCD;*/
/*run;*/

*==============================================================================;
*Read and process the input datasets;
*==============================================================================;
 
data adsl01;
    set adsl;
    where randfl="Y";      
run;
 
data adsl02;
    set adsl01;
    treatment=trt01pn;
    output;
 
    treatment=4;
    output;
run;
 
*==============================================================================;
*Get treatment totals and create macro variables;
*==============================================================================;
 
data dummy_trttotals;
    do treatment=0,54,81,4;
        output;
    end;
run;
 
*------------------------------------------------------------------------------;
*get actual treatment totals;
*------------------------------------------------------------------------------;
 
 
proc freq data=adsl02 ;
    tables   treatment /list missing out=trttotals_pre(rename=(count=trttotal) drop=percent);
    where 1=1;
run;
 
*------------------------------------------------------------------------------;
*merge actual and actual treatment totals;
*------------------------------------------------------------------------------;
 
 proc sort data=dummy_trttotals;
   by  treatment;
run;

data trttotals;
   merge dummy_trttotals(in=a)
         trttotals_pre(in=b);
   by treatment;
 
   if a and not b then trttotal=0;
run;
 
*------------------------------------------------------------------------------;
*create macro variables;
*------------------------------------------------------------------------------;
 
data _null_;
    set trttotals;
    call symputx(cats("trt",treatment),trttotal);
run;
*==============================================================================;
*```````````````get counts for table body;
*==============================================================================;
 
proc sql;
   create table counts01 as
      select 1 as order, treatment, count(distinct usubjid) as count
      from adsl02

      where randfl="Y"
      group by treatment
 
 
      union all corr
 
      select 2 as order, treatment, count(distinct usubjid) as count
      from adsl02
      where fasfl="Y"
      group by treatment
 
      union all corr
 
      select 3 as order, treatment, count(distinct usubjid) as count
      from adsl02
      where saffl="Y"
      group by treatment
 
      union all corr
 
      select 4 as order, treatment, count(distinct usubjid) as count
      from adsl02
      where PPSFL="Y"
      group by treatment
      ;
quit;
 
 
*==============================================================================;
*````````````````create dummy data and merge with actual counts;
*==============================================================================;
 
data dummy01;
    length label $200;
 
    order=1; label="Randomized Analysis Set"; output;
    order=2; label="Full Analysis Set"; output;
    order=3; label="Safety Analysis Set"; output;
    order=4; label="Per-protocol Analysis Set"; output;
run;
 
data dummy02;
   set dummy01;
 
   do treatment=0,54,81,4;
    output;
   end;
run;
 
proc sort data=dummy02;
   by order treatment;
   where  ;
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
*`````````````calculate percentages;
*==============================================================================;
 
proc sort data=trttotals ;
   by treatment;
   where  ;
run;
 
proc sort data=counts02 ;
   by treatment;
   where  ;
run;
 
data counts03;
   merge counts02(in=a)
         trttotals(in=b);
   by treatment;
 
   if a;
run;
 
data counts04;
   set counts03;
 
   length cp $30;
 
   if count ne 0 then cp=put(count,3.)||" ("||put(count/trttotal*100,5.1)||")";
   else cp=put(count,3.);
run;
 
*==============================================================================;
*restructure the data to present treatments as columns;
*==============================================================================;
 
proc sort data=counts04;
   by order label;
   where  ;
run;
 
proc transpose data=counts04   out=counts05 prefix=trt  ;
   by order label;
   var cp;
   id treatment;
   where  ;
run;
 
%rtf_output_style_setup;
 
footnote "&outputname.";
title "Summary for Analysis Sets";
title2 "Randomized Analysis Set";
title3 bcolor="#e6f9ec" "Copyright @ mycsg.in";
ods listing close;
ods rtf file="&outputpath.\ds_analysis_sets.rtf" style=csgpool01;
 
 
proc report data = counts05 center headline headskip nowd split='~' missing style(report)=[just=center]
   style(header)=[just=center];
 
   column order label trt0 trt54 trt81 trt4 ;
 
   define order/order noprint;
 
   define label/width=30 " "  style(column)=[cellwidth=1.5in protectspecialchars=off] style(header)=[just=left];
 
   define trt0/"Dose level 1" "(N=&trt0.)"   style(column)=[cellwidth=1.2in just=center] ;
   define trt54/"Dose level 2" "(N=&trt54.)"  style(column)=[cellwidth=1.2in just=center]   ;
   define trt81/"Dose level 3" "(N=&trt81.)"  style(column)=[cellwidth=1.2in just=center]   ;
   define trt4/"Total"        "(N=&trt4.)"  style(column)=[cellwidth=1.2in just=center]   ;
 
run;
 
 
ods rtf close;
ods listing;
