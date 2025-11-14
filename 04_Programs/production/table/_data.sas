LIBNAME MYLIB 'C:\Users\hed2\Downloads\sdtm-adam-pilot-project-master\sdtm-adam-pilot-project-master\updated-pilot-submission-package\900172\m5\datasets\cdiscpilot01\analysis\adam\datasets\mytfl'; /* Assign the library reference */

PROC COPY IN=MYLIB OUT=WORK;
RUN;

%let outputname=TFL; 

%let outputpath=C:\Users\hed2\Downloads\sdtm-adam-pilot-project-master\sdtm-adam-pilot-project-master\updated-pilot-submission-package\900172\m5\datasets\cdiscpilot01\analysis\adam\datasets\mytfl\output;


options orientation=landscape nodate nonumber nobyline;
