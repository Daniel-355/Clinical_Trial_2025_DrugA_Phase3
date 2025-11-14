%include 'C:\Users\hed2\Downloads\sas practice\SAS-Clinical-Trials-Toolkit-master2\SAS-Clinical-Trials-Toolkit-master/common.sas';
%common;
%include 'C:\Users\hed2\Downloads\sas practice\SAS-Clinical-Trials-Toolkit-master2\SAS-Clinical-Trials-Toolkit-master/make_sdtm_dy2.sas';
%include 'C:\Users\hed2\Downloads\sas practice\SAS-Clinical-Trials-Toolkit-master2\SAS-Clinical-Trials-Toolkit-master/make_sort_order.sas';
%include 'C:\Users\hed2\Downloads\sas practice\SAS-Clinical-Trials-Toolkit-master2\SAS-Clinical-Trials-Toolkit-master/make_empty_dataset.sas';
%make_empty_dataset(metadatafile=C:\Users\hed2\Downloads\sas practice\SAS-Clinical-Trials-Toolkit-master2\SAS-Clinical-Trials-Toolkit-master/SDTM_METADATA.xlsx,dataset=AE);
%put &AEKEEPSTRING;
/*STUDYID DOMAIN USUBJID AESEQ AETERM AEDECOD AEBODSYS AESEV AESER AEACN AEREL AESTDTC AEENDTC AESTDY AEENDY*/


**** DERIVE THE MAJORITY OF SDTM AE VARIABLES;
options missing = '~';  /*Specifies the character to print for missing numeric values.*/
data ae;
  set EMPTY_AE  /*empty dataset*/
  source.adverse;  /*original variables*/
    studyid = 'XYZ123';
    domain = 'AE';
    usubjid = left(uniqueid);
run;

/*proc contents data= source.adverse varnum; run;  */
/*proc contents data= EMPTY_AE varnum; run; /*three variables missing*/*/;
 
proc sort
  data=ae;
    by usubjid;
run;


/*merge ae and reference start in dm*/
data ae;
  merge ae(in=inae) target.dm(keep=usubjid rfstdtc);
    by usubjid;

    if inae;

    %make_sdtm_dy(refdate=rfstdtc,date=aestdtc);   /*aestdtc- rfstdtc= AESTDY*/
    %make_sdtm_dy(refdate=rfstdtc,date=aeendtc); /*aeendtc- rfstdtc= AEenDY*/
run;
/*(in=in ) To identify which input data set contributed an observation during a SET, MERGE, or UPDATE.*/
/*proc contents data= ae varnum; run;  */


**** CREATE SEQ VARIABLE;
proc sort
  data=ae;
    by studyid usubjid aedecod aestdtc aeendtc;
run;

data ae;
  retain STUDYID DOMAIN USUBJID AESEQ AETERM AEDECOD AEBODSYS AESEV AESER AEACN AEREL AESTDTC
         AEENDTC AESTDY AEENDY;
  set ae(drop=aeseq);
    by studyid usubjid aedecod aestdtc aeendtc;

    if not (first.aeendtc and last.aeendtc) then
      put "WARN" "ING: key variables do not define an unique record. " usubjid=;   /*the above sort varibles are not unique*/

    retain aeseq;
    if first.usubjid then
      aeseq = 1;
    else
      aeseq = aeseq + 1;
		
    label aeseq = "Sequence Number";
run;


**** SORT AE ACCORDING TO METADATA AND SAVE PERMANENT DATASET;
%make_sort_order(metadatafile=C:\Users\hed2\Downloads\sas practice\SAS-Clinical-Trials-Toolkit-master2\SAS-Clinical-Trials-Toolkit-master/SDTM_METADATA.xlsx,dataset=AE);
%put &AESORTSTRING;
/*STUDYID  USUBJID  AEDECOD  AESTDTC*/

proc sort
  data=ae(keep = &AEKEEPSTRING)
  out=target.ae;
    by &AESORTSTRING;
run;

proc contents data= target.ae varnum;
run;
