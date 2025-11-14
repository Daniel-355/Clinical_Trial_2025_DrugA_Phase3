**** defines common librefs and SAS options.;

libname sdtm    "C:\Users\hed2\Downloads\sas practice\SAS-Clinical-Trials-Toolkit-master2\SAS-Clinical-Trials-Toolkit-master\target";
libname adam    "C:\Users\hed2\Downloads\sas practice\SAS-Clinical-Trials-Toolkit-master2\SAS-Clinical-Trials-Toolkit-master\target";

proc format;
        value _0n1y 0 = 'N'   /*no need to ifelse */
                    1 = 'Y'
        ;                    
        value avisitn 1 = '3'
                      2 = '6'
        ;                      
        value popfl 0 - high = 'Y'  /*0 to high is yes*/
                    other = 'N'
        ;                    
        value $trt01pn  'Active' = '1'   /*captial sensitive*/
                        'Placebo'             = '0'
        ;
        value agegr1n 0 - 54 = "1"
                      55-high= "2"
        ;                      
        value agegr1_ 1 = "<55 YEARS"
                      2 = ">=55 YEARS"
        ;                      
        value $aereln  'not'        = '0'
                       'possibly'   = '1'
                       'probably'   = '2'
        ;
        value $aesevn  'mild'               = '1'
                       'moderate'           = '2'
                       'severe'             = '3'
        ;                                              
        value relgr1n 0 = 'NOT RELATED'
                      1 = 'RELATED'
        ;                       
        value evntdesc 0 = 'PAIN RELIEF'
                       1 = 'PAIN WORSENING PRIOR TO RELIEF'
                       2 = 'PAIN ADVERSE EVENT PRIOR TO RELIEF'
                       3 = 'COMPLETED STUDY PRIOR TO RELIEF'
        ;                    
run;
