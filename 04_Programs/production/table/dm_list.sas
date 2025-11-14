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
Read input data
=========================================================*/
 
data adsl01;       /*use adam datasets*/
   set adsl;
   where randfl="Y";
run;
 
/*=========================================================
Create columns as per listing requirement
=========================================================*/
 
data list01;         /*create variables to showcase*/
   set adsl01;
 
   col1="Investigator Site = "||strip(siteid);  
   col2=usubjid;

   col3=trt01p;  

   if age ne . then col4=strip(put(age,best.));
   else col4="-";

   if sex ne "" then col5=sex;
   else col5="-";

   if arace ne "" then col6=arace;
   else arace="-";

   if raceoth ne "" then col7=raceoth;
   else col7="-";
 
   if weightbl ne . then col8=strip(put(weightbl,best.));
   else col8="-";

   if heightbl ne . then col9=strip(put(heightbl,best.));
   else col9="-";
 
run;
 
/*=========================================================
Sort the records as per listing requirement and create a sequence variable
=========================================================*/
 
proc sort data=list01;
   by siteid usubjid;
run;
 
data list02;
   set list01;
   by siteid usubjid;   /*sort by siteid usubjid */
   listseq=_n_;
run;
 
 
/*=========================================================
Generate Report
=========================================================*/
 
%rtf_output_style_setup;
 
footnote " ";
 
title "Demographic Characteristics";
title2 "Randomized Analysis Set";
title3 bcolor="#e6f9ec" "Copyright @ mycsg.in";
 
ods listing close;
ods rtf file="&outputpath.\dm_list.rtf" style=csgpool01;
 
proc report data=list02 nowd missing
   style(report)={just=center}
   style(column)={just=left}
   style(header)={just=left};
 
   column siteid col1 usubjid col2 col3 col4 col5 col6 col7 col8 col9;
 
   define siteid/order order=data noprint;             
   define usubjid/order order=data noprint;

   define col1/order order=data noprint;           /*noprint*/
 
   define col2/"Subject ID" style(column)={cellwidth=0.75in};
   define col3/"Treatment" "group" style(column)={cellwidth=1in};
   define col4/"Age (years)" style(column)={cellwidth=0.75in};
   define col5/"Sex" style(column)={cellwidth=0.5in};
   define col6/"Race" style(column)={cellwidth=1in};
   define col7/"Race" "(Other)" style(column)={cellwidth=1in};
   define col8/"Weight (kg)" style(column)={cellwidth=0.75in};
   define col9/"Height (cm)" style(column)={cellwidth=0.75in};
 
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
 
 
