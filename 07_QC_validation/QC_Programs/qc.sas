/******************************************************************/
/*   End-to-End Clinical Site QC Report Demo (Mock Data)          */
/******************************************************************/
 


/*--- 0. Define Library (adjust path as needed) ---*/
libname trial  "C:\Users\hed2\Downloads\sdtm-adam-pilot-project-master\sdtm-adam-pilot-project-master\updated-pilot-submission-package\900172\m5\datasets\cdiscpilot01\analysis\adam\datasets\mytfl\qc";   /* Using WORK for demo; replace with permanent path */

/*--- 1. Create Mock Datasets ---*/

/* Patient Data */
data trial.patient_data;
    call streaminit(123);
    do site_id = 101 to 105;
        do patient_id = 1 to 20;
            visit_date = today() - ceil(rand("uniform")*90); /* last 90 days */
            month = month(visit_date);
            enrolled = ifc(rand("uniform") < 0.8, "Y", "N"); /* ~80% enrolled */
            output;
        end;
    end;
run;

/* Query Data */
data trial.query_data;
    call streaminit(456);
    do site_id = 101 to 105;
        do query_id = 1 to 15;
            query_date = today() - ceil(rand("uniform")*90);
            month = month(query_date);
            days_to_resolve = ceil(rand("normal",5,2)); /* avg 5 days */
            if days_to_resolve < 1 then days_to_resolve = 1;
            output;
        end;
    end;
run;

/* Visit / Deviation Data */
data trial.visit_data;
    call streaminit(789);
    do site_id = 101 to 105;
        do visit_id = 1 to 25;
            visit_date = today() - ceil(rand("uniform")*90);
            month = month(visit_date);
            deviation = ifc(rand("uniform") < 0.08, "Y", "N"); /* ~8% deviations */
            output;
        end;
    end;
run;

/*--- 2. Enrollment Metrics ---*/
proc sql;
    create table site_enrollment as
    select site_id, month,
           count(distinct patient_id) as total_screened,
           sum(case when enrolled='Y' then 1 else 0 end) as total_enrolled,
           calculated total_enrolled / calculated total_screened format=percent8.1 as enroll_rate
    from trial.patient_data
    group by site_id, month;
quit;

/*--- 3. Query Metrics ---*/
proc sql;
    create table query_metrics as
    select site_id, month,
           count(*) as total_queries,
           mean(days_to_resolve) format=8.1 as avg_resolution_days,
           sum(case when days_to_resolve > 7 then 1 else 0 end) as queries_over_7days
    from trial.query_data
    group by site_id, month;
quit;

/*--- 4. Visit Metrics ---*/
proc sql;
    create table visit_metrics as
    select site_id, month,
           count(*) as total_visits,
           sum(case when deviation='Y' then 1 else 0 end) as total_deviations,
           calculated total_deviations / calculated total_visits format=percent8.1 as deviation_rate
    from trial.visit_data
    group by site_id, month;
quit;

/*--- 5. Merge into QC Report ---*/
proc sql;
    create table qc_report as
    select a.site_id, a.month,
           a.total_screened, a.total_enrolled, a.enroll_rate,
           b.total_queries, b.avg_resolution_days, b.queries_over_7days,
           c.total_visits, c.total_deviations, c.deviation_rate
    from site_enrollment as a
    left join query_metrics as b on a.site_id=b.site_id and a.month=b.month
    left join visit_metrics as c on a.site_id=c.site_id and a.month=c.month;
quit;

/*--- 6. Add Performance Flags ---*/
data qc_report_flagged;
    set qc_report;
    /* Enrollment Flags */
    if enroll_rate >=0.7 then enroll_flag='Green';
    else if enroll_rate >=0.5 then enroll_flag='Yellow';
    else enroll_flag='Red';
    /* Query Resolution Flags */
    if avg_resolution_days <=5 then query_flag='Green';
    else if avg_resolution_days <=7 then query_flag='Yellow';
    else query_flag='Red';
    /* Deviation Flags */
    if deviation_rate <=0.05 then deviation_flag='Green';
    else if deviation_rate <=0.10 then deviation_flag='Yellow';
    else deviation_flag='Red';
run;

footnote "&outputname.";
title "QC by sites by month";
title3 bcolor="#e6f9ec" "Copyright @ mycsg.in";
ods listing close;
ods rtf file="C:\Users\hed2\Downloads\sdtm-adam-pilot-project-master\sdtm-adam-pilot-project-master\updated-pilot-submission-package\900172\m5\datasets\cdiscpilot01\analysis\adam\datasets\mytfl\qc\qc_report.rtf" style=csgpool01;

/*--- 7. Print QC Report ---*/
proc print data=qc_report_flagged noobs label;
    title "Clinical Site QC Report with Flags";
    label site_id="Site ID" month="Month"
          total_screened="Screened Patients"
          total_enrolled="Enrolled Patients"
          enroll_rate="Enrollment Rate"
          enroll_flag="Enrollment Flag"
          total_queries="Total Queries"
          avg_resolution_days="Avg Query Resolution (days)"
          query_flag="Query Flag"
          total_visits="Total Visits"
          total_deviations="Protocol Deviations"
          deviation_rate="Deviation Rate"
          deviation_flag="Deviation Flag";
run;

/*--- 8. Plots ---*/

/* Enrollment Trend */
proc sgplot data=qc_report_flagged;
    series x=month y=enroll_rate / group=site_id markers lineattrs=(thickness=2);
    yaxis label="Enrollment Rate" values=(0 to 1 by 0.1);
    xaxis label="Month";
    title "Monthly Enrollment Rate Trend by Site";
run;

/* Query Resolution Trend */
proc sgplot data=qc_report_flagged;
    series x=month y=avg_resolution_days / group=site_id markers lineattrs=(thickness=2);
    yaxis label="Avg Query Resolution (days)";
    xaxis label="Month";
    title "Monthly Avg Query Resolution Trend by Site";
run;

/* Deviation Trend */
proc sgplot data=qc_report_flagged;
    series x=month y=deviation_rate / group=site_id markers lineattrs=(thickness=2);
    yaxis label="Deviation Rate" values=(0 to 0.5 by 0.05);
    xaxis label="Month";
    title "Monthly Protocol Deviation Rate Trend by Site";
run;

ods rtf close;
ods listing;


/*--- 9. Export to Excel ---*/
proc export data=qc_report_flagged
    outfile="C:\Users\hed2\Downloads\sdtm-adam-pilot-project-master\sdtm-adam-pilot-project-master\updated-pilot-submission-package\900172\m5\datasets\cdiscpilot01\analysis\adam\datasets\mytfl\qc\QC_Report.xlsx"
    dbms=xlsx replace;
run;

