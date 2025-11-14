*---------------------------------------------------------------*;
* ADEF.sas creates the ADaM BDS-structured data set
* for efficacy data (ADEF), saved to the ADaM libref.
*---------------------------------------------------------------*;

%let path1=C:\Users\hed2\Downloads\sas practice\SAS-Clinical-Trials-Toolkit-master2\SAS-Clinical-Trials-Toolkit-master;
%let path2=C:\Users\hed2\Downloads\sas practice\SAS-Clinical-Trials-Toolkit-master2\SAS-Clinical-Trials-Toolkit-master;

%include "&path2/setup.sas";

**** CREATE EMPTY ADEF DATASET CALLED EMPTY_ADEF;
%let metadatafile=&path1/adam_metadata.xlsx;
%include "&path1/make_empty_dataset.sas";
%make_empty_dataset(metadatafile=&metadatafile,dataset=ADEF)
%put &adefKEEPSTRING;
/*STUDYID USUBJID AGE AGEGR1N RANDDT AGEGR1 SEX SITEID TRTPN TRTP PARAMCD PARAM COUNTRY AVISIT AVISITN ABLFL XPSEQ VISITNUM ADT ADY AVAL AVALC BASE CHG CRIT1FL CRIT1 ITTFL*/


** calculate changes from baseline for all post-baseline visits;
%include "&path2/cfb.sas";
%cfb(indata=sdtm.xp, outdata=adef, dayvar=xpdy, avalvar=   xpstresn);  /*is what is the primary outcome/measurement*/

proc sort
  data = adam.adsl
  (keep = usubjid siteid country age agegr1 agegr1n sex race randdt trt01p trt01pn ittfl)
  out = adsl;
    by usubjid;
    
%include "&path2/dtc2dt.sas";      
data adef;
  merge adef (in = inadef) adsl (in = inadsl);  /*in both datasets*/
    by usubjid ;
    
        if not(inadsl and inadef) then
          put 'PROB' 'LEM: Missing subject?-- '   usubjid= inadef= inadsl= ;
        
        rename trt01p    = trtp   /*generally in adsl trt01p but other trtp, if only one period  */
               trt01pn   = trtpn

               xptest    = param    /*test*/
               xptestcd  = paramcd

               visit     = avisit
               xporres   = avalc    /*values*/
        ;               

        if inadsl and inadef;
        avisitn = input(put(visitnum, avisitn.), best.);
        
        %dtc2dt(xpdtc, refdt=randdt);   /*date in adam convert into numeric*/
        
        retain crit1 "Pain improvement from baseline of at least 2 points";

        RESPFL = put((.z <= chg <= -2), _0n1y.);         /*flag is effective: improve from baseline at 2 points*/

        if RESPFL='Y' then
          crit1fl = 'Y';
        else
          crit1fl = 'N';          
run;

** assign variable order and labels;
data adef;
  retain &ADEFKEEPSTRING;
  set EMPTY_ADEF adef;   /*put empty table first*/
  keep &ADEFKEEPSTRING;
run;

**** SORT ADEF ACCORDING TO METADATA AND SAVE PERMANENT DATASET;
%include "&path1/make_sort_order.sas"; 
%make_sort_order(metadatafile=&metadatafile,dataset=ADEF)

proc sort
  data=adef 
  out=adam.adef;
    by &ADEFSORTSTRING;
run;        

/*proc contents data=adam.adef varnum; run; */
