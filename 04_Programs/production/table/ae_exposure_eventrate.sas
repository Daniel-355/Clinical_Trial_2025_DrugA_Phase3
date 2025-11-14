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
Create variable named 'treatment' to    hold report level column groupings<br/>
Also, create a variable named dur to hold treatment duration      to use in subject year calculation 
=========================================================*/
 
 
data adae02;
    set adae01;
    treatment=trtan;
    output;
run;
 
data adsl02;
   set adsl01;
    treatment=trt01an;

    if nmiss(trtsdt,trtedt)=0 then dur=trtedt-trtsdt+1;     /* ```````````create duration time*/
    output;
run;
 
/*=========================================================
Get treatment totals into a dataset and into macro variables (for column headers)
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
   do treatment=0,54,81;
      output;
   end;
run;
 
/*----------------------------------------------------------
```````````````Create a dataset to hold the total subject years of exposure
----------------------------------------------------------*/
 
proc sql;
   create table subjyr as
      select treatment,
      sum(dur)/365.25 as subjyr           /*total person year in three groups */
      from adsl02
      group by treatment;
quit;
 
/*proc contents data=adsl02 varnum;run; */
 
/*----------------------------------------------------------
Merge actual counts, subject years of exposure dataset with dummy counts
----------------------------------------------------------*/
 
data trttotals;
   merge dummy_pre(in=a) trttotal_pre(in=b) subjyr;
   by treatment;
   if trttotal=. then trttotal=0;
run;
 
 
/*----------------------------------------------------------
Macro variables for subject count,  N
----------------------------------------------------------*/
proc sql noprint;
   select count(distinct usubjid) into :n0 from adsl02 where treatment=0;
   select count(distinct usubjid) into :n54 from adsl02 where treatment=54;
   select count(distinct usubjid) into :n81 from adsl02 where treatment=81;
quit;
 
 
/*----------------------------------------------------------
```````````Macro variables for subject years,  total person year
----------------------------------------------------------*/
data _null_;
   set trttotals;
   call symputx(cats("exp_",treatment),round(subjyr,0.01));
run;
/* %put &exp_0;*/

 
/*=========================================================
Obtaining actual counts-for the table
=========================================================*/
 
 
/*----------------------------------------------------------
`````````````Top row counts
----------------------------------------------------------*/
 
 
proc sql noprint;
   create table sub_count as
   select "Overall" as label length=200,
   treatment,
   count(usubjid) as count      /*``````````````no distinct here, recurrance*/
   from adae02
   group by treatment;
quit;
 
 
/*----------------------------------------------------------
SOC level counts
----------------------------------------------------------*/
 
 
proc sql noprint;
   create table soc_count as
      select aebodsys, treatment,
      count(usubjid) as count    /*no distinct here, recurrance*/
      from adae02
      group by aebodsys,treatment;
quit;
 
 
/*----------------------------------------------------------
Preferred term level counts
----------------------------------------------------------*/
 
 
proc sql noprint;
   create table pt_count as
      select aebodsys,aedecod,treatment,
      count(usubjid) as count    /*no distinct here, recurrance*/
      from adae02
      group by aebodsys,aedecod,treatment;
quit;
 
 
/*----------------------------------------------------------
Combine toprow, SOC, and PT level counts into single dataset
----------------------------------------------------------*/
 
 
data counts01;
   set sub_count soc_count pt_count;
run;
 
/*=========================================================
Create zero counts if an event is not present in a treatment
=========================================================*/
 
 
/*----------------------------------------------------------
Get all the available SOC and PT values
----------------------------------------------------------*/
 
proc sort data=counts01 out=dummy01(keep=aebodsys aedecod label) nodupkey;
   by aebodsys aedecod label;
run;
 
/*----------------------------------------------------------
Create a row for each treatment
----------------------------------------------------------*/
 
data dummy02;
   set dummy01;
   do treatment=0,54,81;
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
```````````Calculate percentages
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
   if count ne 0 then cp=put(count,3.)||" ("||put(count/subjyr*100,6.1)||")";    /*```````````````denominator is sum of personyear, Per 100 person-years*/
   else cp=put(count,3.);
run;
 
 
/*=========================================================
Create the label column
=========================================================*/
 
 
data counts05;
   set counts04;
   if missing(aebodsys) and missing(aedecod) then label=label;
   else if not missing(aebodsys) and missing(aedecod) then label=strip(aebodsys);
   else if not missing(aebodsys) and not missing(aedecod) then label='(*ESC*)R"\pnhang\fi220\li220 "'||strip(aedecod);
run;
 
 
/*=========================================================
Transpose to obtain treatment as columns
=========================================================*/
 
 
proc sort data=counts05;
   by aebodsys aedecod label ;
run;
 
proc transpose data=counts05 out=trans01 prefix=trt;
   by aebodsys aedecod label;
   var cp;
   id treatment;
run;
 
 
data trans02;
   set trans01;
   keep aebodsys aedecod c1 trt: label;
   c1=label;
run;
 
 
/*=========================================================
Create variables to sort the SOCs by descending frequency in high dose and also sort PTs by descending frequency in high dose within each SOC
``````````````````````descending order steps
=========================================================*/
 
/*----------------------------------------------------------
Extract counts from high dose column (trt81) for sorting 
----------------------------------------------------------*/
data trans03;
   set trans02;
   cnt81=input(scan(trt81,2,'()'),best.);
run;
 
 
/*----------------------------------------------------------
Separate top row, soc rows and pt rows into separate datasets
----------------------------------------------------------*/
 
data section0 section1 section2;
   set trans03;
   if label="Overall" and aebodsys="" and aedecod="" then output section0;
   if aebodsys ne "" and aedecod="" then output section1;
   if aedecod ne "" then output section2;
run;
 
 
/*----------------------------------------------------------
Create an order variable for top row
----------------------------------------------------------*/
data section0;
   set section0;
   section0ord+1;
run;
 
/*----------------------------------------------------------
Create order variable for SOC rows by sorting based on required variables
----------------------------------------------------------*/
proc sort data=section1;
   by descending cnt81 aebodsys;
run;
 
data section1;
   set section1;
   by descending cnt81 aebodsys;
   section1ord+1;
   section0ord=999;
run;
 
 
/*----------------------------------------------------------
Create order variable for PT rows by sorting based on required variables within each SOC
----------------------------------------------------------*/
 
proc sort data=section2;
   by aebodsys descending cnt81 aedecod;
run;
 
data section2;
   set section2;
   by aebodsys descending cnt81 aedecod;
   section2ord+1;
   section0ord=999;
run;
 
 
/*----------------------------------------------------------
Bring the SOC sort order variable into PT rows dataset
----------------------------------------------------------*/
 
proc sql;
   create table section2_2 as
      select a.*,b.section1ord
      from section2 as a
      left join
      section1 as b
      on a.aebodsys=b.aebodsys;
quit;
 
 
/*----------------------------------------------------------
Combine all datasets after creating sort order variables
----------------------------------------------------------*/
data final;
   set section0 section1 section2_2;
run;
 
 
/*----------------------------------------------------------
Sort the final dataset using section sort order variables
----------------------------------------------------------*/
 
proc sort data=final;
   by  section0ord section1ord section2ord;
run;
 
 
/*=========================================================
Report generation
=========================================================*/
 
%rtf_output_style_setup;
 
footnote "&outputname.";
title "   Exposure Adjusted Event Rate by SOC and PT";
title2 "Safety Analysis Set";
title3 bcolor="#e6f9ec" "Copyright @ mycsg.in";
 
ods listing close;
ods rtf file="&outputpath.\ae_soc_pt_eventrate_descending.rtf" style=csgpool01;
 
proc report data=final nowd headline headskip missing style(report)=[just=center]
   style(header)=[just=center];
   columns section0ord section1ord section2ord c1  trt0 trt54 trt81;
   define section0ord/ order noprint;
   define section1ord/order noprint;
   define section2ord/order noprint;
 
   define c1 / "System Organ Class" '(*ESC*)R"\fi-420\li420 "Preferred Term' style(column)=[cellwidth=3.7in protectspecialchars=off]
            style(header)=[just=left] ;
   define trt0/"Placebo" "(N=%cmpres(&n0))" "[Subj-yr=%cmpres(&exp_0)]" "  n   (r)" style(column)=[cellwidth=1.7in just=center] ;
   define trt54/"Low Dose" "(N=%cmpres(&n54))" "[Subj-yr=%cmpres(&exp_54)]" "  n   (r)" style(column)=[cellwidth=1.7in just=center]   ;
   define trt81/"High Dose" "(N=%cmpres(&n81))" "[Subj-yr=%cmpres(&exp_81)]" "  n   (r)"  style(column)=[cellwidth=1.7in just=center]   ;
 
   compute after section1ord;
        line @1 "";
   endcomp;
 
run;
 
ods rtf close;

/*event rate*/
/*Example: 30 headaches occurred over 250 person-years ? 12 events per 100 person-years.*/
/*incidence rate*/
/*Example: 20 of 100 patients had =1 headache ? 20% incidence.*/
/*Incidence rate ? How many patients are affected?*/
/*Event rate ? How often do events occur (per patient-time)?*/
