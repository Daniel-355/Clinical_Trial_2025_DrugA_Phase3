%include 'C:\Users\hed2\Downloads\sas practice\SAS-Clinical-Trials-Toolkit-master2\SAS-Clinical-Trials-Toolkit-master/common.sas';
%common;

**** CREATE EMPTY DM DATASET CALLED EMPTY_DM;

%make_empty_dataset(metadatafile=C:\Users\hed2\Downloads\sas practice\SAS-Clinical-Trials-Toolkit-master2\SAS-Clinical-Trials-Toolkit-master/SDTM_METADATA.xlsx,dataset=EX);


/*numeric missing is .*/
/*chracter missing is empty*/
**** DERIVE THE MAJORITY OF SDTM EX VARIABLES;
data ex;
  set EMPTY_EX
      source.dosing;

    studyid = 'XYZ123';
    domain = 'EX';
    usubjid = left(uniqueid);
    exdose = dailydose;
    exdostot = dailydose;
    exdosu = 'mg';
    exdosfrm = 'TABLET, COATED';
    exstdtc=put(startdt,yymmdd10.);
    exendtc=put(enddt,yymmdd10.);
run;
 
proc sort
  data=ex;
    by usubjid;
run;


**** CREATE SDTM STUDYDAY VARIABLES AND INSERT    EXTRT;
/*subject reference start date/time*/
data ex;
  merge ex(in=inex) target.dm(keep=usubjid rfstdtc arm);
    by usubjid;

    if inex;

    %make_sdtm_dy(refdate=rfstdtc,date=exstdtc); 
    %make_sdtm_dy(refdate=rfstdtc,date=exendtc); 

    **** in this simplistic case all subjects received the treatment they were randomized to;
    extrt = arm;  
run;


**** CREATE SEQ VARIABLE;
proc sort
  data=ex;
    by studyid usubjid extrt exstdtc;
run;


OPTIONS MISSING = ' ';  
data ex;
  retain STUDYID DOMAIN USUBJID EXSEQ EXTRT EXDOSE EXDOSU EXDOSFRM EXDOSTOT
         EXSTDTC EXENDTC EXSTDY EXENDY;
  set ex(drop=exseq);
    by studyid usubjid extrt exstdtc;

    if not (first.exstdtc and last.exstdtc) then
      put "WARN" "ING: key variables do not define an unique record. " usubjid=;

    retain exseq;
    if first.usubjid then
      exseq = 1;
    else
      exseq = exseq + 1;
		
    label exseq = "Sequence Number";
run;


**** SORT EX ACCORDING TO METADATA AND SAVE PERMANENT DATASET;
%make_sort_order(metadatafile=C:\Users\hed2\Downloads\sas practice\SAS-Clinical-Trials-Toolkit-master2\SAS-Clinical-Trials-Toolkit-master/SDTM_METADATA.xlsx,dataset=EX);


proc sort
  data=ex(keep = &EXKEEPSTRING)
  out=target.ex;
    by &EXSORTSTRING;
run;
proc contents data= target.ex varnum;
run;
/*same procedure and plan but different double program*/
