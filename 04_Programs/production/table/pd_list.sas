/*=========================================================
Include the data file
=========================================================*/
%let root2=C:\Users\hed2\Downloads\sdtm-adam-pilot-project-master\sdtm-adam-pilot-project-master\updated-pilot-submission-package\900172\m5\datasets\cdiscpilot01\analysis\adam\datasets\mytfl\;
 
 
%include "&root2._data.sas";
 
 
options validvarname=upcase;
/*=========================================================
Programming for the Task
=========================================================*/
 
 
/*=========================================================
Read input datasets
=========================================================*/
 
data addv01;
   set addv;
   where randfl="Y";
run;
 
/*=========================================================
Process the dataset to concatenate sub codes of PD1
=========================================================*/
 
proc sort data=addv01;
   by usubjid dvdecod dvsubcod;
run;
 
data list01;
   set addv01;
   by usubjid dvdecod dvsubcod;
   length subcodes $200 codesubcode $1000;
   retain subcodes;
   if first.dvdecod then subcodes=dvsubcod;
   else do;
      if index(strip(subcodes),strip(dvsubcod))=0 then subcodes=catx(",",subcodes,dvsubcod);
   end;
   if last.dvdecod;
   if subcodes="NA" then subcodes="";
   if subcodes ne "" then subcodes="["||strip(subcodes)||"]";
   codesubcode=catx(" ",dvdecod,subcodes);
run;
 
/*=========================================================
Process the data to concatenate the previously concatenated code/subcodes
=========================================================*/
 
 
data list02;
   set list01;
   by usubjid dvdecod;
   length finalcodes $1000;
    retain finalcodes;
   if first.usubjid then finalcodes=codesubcode;
   else finalcodes=catx(",",finalcodes,codesubcode);
   if last.usubjid;
run;
 
/*=========================================================
Create columns as per listing shell requirement
=========================================================*/
data list03;
   set list02;
   *------------------------------------------------------------------------------;
   *site-col1, subject -col2, treatment=col3, trt duration-col4, deviation codes -col5;
   *------------------------------------------------------------------------------;
   length col4 $20;
   col1="Investigator Site = "||strip(siteid);
   col2=usubjid;
   col3=trt01p;
   if trtedy ne . then col4=strip(put(trtedy,best.));
   else col4="-";
   col5=finalcodes;
run;
 
/*=========================================================
Sort the records as per shell requirement and create a sequence variable
=========================================================*/
 
proc sort data=list03;
   by siteid usubjid;
run;
 
data list04;
   set list03;
   by siteid usubjid;
   listseq=_n_;
run;
 
/*=========================================================
Generate Report
=========================================================*/
 
%rtf_output_style_setup;
 
footnote " ";
title "Protocol Deviations";
title2 "Randomized Analysis Set";
title3 bcolor="#e6f9ec" "Copyright @ www.mycsg.in";
 
ods listing close;
ods rtf file="&outputpath.\&outputname." style=csgpool01;
 
proc report data=list04 nowd missing
   style(report)={just=center}
   style(column)={just=left}
   style(header)={just=left};
 
   column siteid col1 usubjid col2 col3 col4 col5;
 
   define siteid/order order=data noprint;
   define usubjid/order order=data noprint;
   define col1/order order=data noprint;
 
   define col2/"Subject ID" style(column)={cellwidth=1in};
   define col3/"Treatment" "group" style(column)={cellwidth=1in};
   define col4/"Treatment" "Duration" "(days)" style(column)={cellwidth=1in};
   define col5/"Deviation Codes" style(column)={cellwidth=2in};
 
   compute after siteid;
      line @1 " ";
   endcomp;
 
   compute before col1;
      line @1 col1 $150.;
      line @1 " ";
   endcomp;
 
run;
ods rtf close;
ods listing;
 
 
