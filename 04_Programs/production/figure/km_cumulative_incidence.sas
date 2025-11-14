/*create km curve*/
/*=========================================================
Convert the xpt files into sas files
=========================================================*/
%let path=C:\Users\hed2\Downloads\sas-and-r-main\sas-and-r-main;
%put &path;
%include "&path/TFL/program/general/xpt_2_sas.sas"; /* Adjust the path accordingly */
/* Call the macro */
/*convert xpt into sas7bdat*/
%import_xpt_files(folder=&path\tfl\data\, libname=mytfl, outpath=&path\tfl\mytfl\);

options validvarname=upcase;



/*=========================================================
Programming for the Task
=========================================================*/
 
/*=========================================================
Read input data use only adtte dataset 
=========================================================*/
 
data adtte01;
   set mytfl.adtte;  /*time-to-event*/
run;
 
proc sort data=adtte01;
   by paramcd trtan;
run;
 
 

/*=========================================================
Get Kaplan-Meier Estimate of Cumulative Incidence, lifetest
=========================================================*/
 
/*----------------------------------------------------------
alphaqt option is used to specify the level of significance</br>
notice the usage of method= and conftype= options </br>
notice the usage of plots= options </br>
notice the request for failure plot along with atrisk numbers </br>
number of rows output into the dataset of ProductLimitEstimates is restricted by using timelist= option</br>
----------------------------------------------------------*/
proc lifetest data=adtte01
   alphaqt=0.05
   method=km  /*Specifies Kaplan–Meier estimator as the method for survival function estimation.*/
   plots=survival(failure atrisk=0 to 200 by 25 )   /*Requests a survival plot, but in failure form (1–S(t)), i.e., cumulative incidence.*/
   timelist=(0 to 200 by 25)  /*Requests estimates of survival probabilities (and confidence intervals) at specific time*/
   conftype=linear ;  /*Type of confidence interval for survival probabilities.*/
 
   time aval*cnsr(1);  /*aval = analysis value (time to event).*/
   strata trtan;  /*groups, Requests separate survival curves by treatment group (trtan).*/
   ods output FailurePlot  = sur_fail ProductLimitEstimates=estimates;
/*   FailurePlot = sur_fail ? dataset with values used to create the failure (1–S(t)) plot.*/
/*ProductLimitEstimates = estimates ? dataset with Kaplan–Meier survival estimates, standard errors, CI, number at risk, etc.*/
run;
 


/*=========================================================
Select the Number of subjects at risk, data organization
=========================================================*/
 
data est(rename=(timelist=time stratum=stratumnum));  
   set estimates(keep=stratum timelist left );
run;
 
/*=========================================================
Output blockplot timepoints and atrisk numebrs
=========================================================*/
 
proc sort data=sur_fail;
   by stratumnum time;
run;
 
/* Update the data preparation to include correct labels */
data new_survival (drop=j);
   merge est   sur_fail ;

   length param_t $100 trt $20;

   by stratumnum time;

      do j = 0 to 200 by 25;
          if time = j  then do;
/*		  new variables*/
            blkrsk = put(left,3.);
            blkx   = time;
         end;
      end;

    trtan = stratumnum;
    param_t="parameter name";
    paramn=1;

    /* Assign correct treatment labels */
    if trtan = 1 then trt = 'Placebo';
    else if trtan = 2 then trt = 'Low Dose';
    else if trtan = 3 then trt = 'High Dose';
run;

/*proc contents data=sur_fail varnum;run;*/


***************************************;
/* Update the template */
proc template;
   define statgraph kmplot;     /*create a statistical graphics template.*/
   dynamic x_var y_var1 y_var2;  /*dynamic variables = placeholders that can be filled in later when you render the graph.*/

/*/*/*/*   title*/*/*/*/;
    begingraph;
         entrytitle "Category = Time to Event" /
         textattrs=(size=9pt) pad=(bottom=20px);
/* "Category = Time to Event" is the text shown.*/
/*textattrs=(size=9pt) ? makes the font smaller.*/
/*pad=(bottom=20px) ? adds spacing below the title.*/

/*/*/*/*linetype and colors*/*/*/*/;
         discreteattrmap name='colors' / ignorecase=true;
/*		 Creates a mapping of attributes (colors, symbols, line styles) to categorical values of your group variable (trt in your case).*/
/*/ ignorecase=true ? makes it case-insensitive (so "Placebo" and "placebo" map the same).*/
			value 'Placebo'  / lineattrs=(color=blue pattern=solid) markerattrs=(color=blue symbol=trianglefilled);
            value 'Low Dose' / lineattrs=(color=red  pattern=solid) markerattrs=(color=red symbol=circlefilled);
            value 'High Dose'/ lineattrs=(color=green pattern=solid) markerattrs=(color=green symbol=squarefilled);
         enddiscreteattrmap;
/* Placebo ? Blue solid line, blue triangle marker*/
/*Low Dose ? Red solid line, red circle marker*/
/*High Dose ? Green solid line, green square marker*/
         discreteattrvar attrvar=gmarker var=trt attrmap='colors';   /*trt is group variable*/
/* Links your dataset variable (trt) with the custom attribute map (colors).*/
/*Creates a new variable gmarker in the graph, which carries the assigned line and marker styles.*/
/*when you plot survival curves by trt, each treatment group automatically picks up the right color, line style, and marker.*/

/*/*/*/*x and y axis*/*/*/*/;
	layout overlay /
/*	This begins the graphing area where your survival or incidence curves will be drawn.*/
/*All axis settings (xaxisopts, yaxisopts) apply inside this overlay.*/
            xaxisopts=(Label="Time at Risk (days)"
               display=(tickvalues line label ticks)
               type=linear
               linearopts=(tickvaluesequence=(start=0 end=200 increment=25)
                    viewmin=0 viewmax=200))
/*This customizes the X-axis, which is time in your KM plot.*/
/*Label="Time at Risk (days)" ? X-axis will display the label “Time at Risk (days)”.*/
/*display=(tickvalues line label ticks) ? Ensures tick marks, tick values, axis line, and label are shown.*/
/*type=linear ? X-axis uses a linear scale.*/
/*linearopts=( ... )*/
/*tickvaluesequence=(start=0 end=200 increment=25) ? Draws ticks at 0, 25, 50, …, 200.*/
/*viewmin=0 viewmax=200 ? Limits X-axis range between 0 and 200.*/
            yaxisopts=(Label="Cumulative Incidence of Subjects with Event"
               type=linear   linearopts=(viewmin=0 viewmax=1    tickvaluesequence=(start=0 end=1 increment=0.2)));
 
/*/*/*/*			   plot*/*/*/*/;
            /* Flip the plot     by using 1-survival */
            StepPlot X=x_var Y=eval(1-y_var1) / primary=true    Group=gmarker    /*			   is a failure plot*/
               LegendLabel="Cumulative Incidence of Subjects with Event" NAME="STEP";
/* StepPlot ? Draws a step function curve (common for survival or failure plots).*/
/*y_var1 is usually the survival probability (S(t)).*/
/*1 - y_var1 converts it to cumulative incidence (failure probability F(t)).*/
/*primary=true ? Marks this plot as the primary element in the overlay (important for legends).*/
/*Group=gmarker ? Groups curves by treatment (gmarker comes from your earlier discreteattrvar, so each treatment arm gets its own color/marker style).*/
/*NAME="STEP"*/
/*Internal name for this step plot element — useful if you want to refer to it later (e.g., when building a custom legend).*/

			scatterPlot X=x_var Y=eval(1-y_var2) / Group=gmarker    markerattrs=(symbol=plus)
                 LegendLabel="Censored" NAME="SCATTER";
/* markerattrs= ? Specifies attributes for markers (shapes, colors, sizes, etc.).*/
/*symbol=plus ? Draws a “+” sign at each marker location.*/

/*/*/*/*            /*   legend   */*/*/*/*/;
            Mergedlegend "STEP"   "SCATTER" /   /* Move legend up */
               location=inside halign=left valign=top    across=1     valueattrs=(family="Arial" size=8pt)
               autoalign=(TopLeft Top TopRight);
/* Mergedlegend ? Combines multiple plot elements into one shared legend.*/
/*across=1 Tells SAS to stack legend items vertically (one per line).*/
/*valueattrs=(family="Arial" size=8pt)*/
/*Controls the font style of the legend text.*/
/*autoalign=(TopLeft Top TopRight)*/
/*A smart feature: SAS tries these alignments in order, depending on space.*/
/*If TopLeft overlaps your data, it might move to Top, or TopRight.*/
/*Keeps the legend visible without obscuring important curves.*/

/*/*/*/*			   /*risk tables*/*/*/*/*/;
         innermargin / align=bottom;  
            axistable x=blkx value=blkrsk / class=gmarker   colorgroup=gmarker
               display=(label) 

               labelattrs=(family="Arial" size=8pt)
               valueattrs=(family="Arial" size=8pt);
/*innermargin ? Creates a special region inside the graph area, often used for annotations or risk tables.*/
/*align=bottom ? Puts this region at the bottom of the graph, directly under the X-axis.*/
/*axistable ... ; This statement generates the actual at-risk table:*/

/*x=blkx*/
/*The X-axis variable (time points, usually 0, 25, 50, …).*/
/*blkx is typically created earlier to align with your survival time grid.*/
/*value=blkrsk*/
/*The values shown in the table ? number of subjects still at risk at each time point.*/
/*class=gmarker*/
/*Splits the values by treatment group (gmarker = your treatment variable with colors/markers from earlier).*/
/*colorgroup=gmarker*/
/*Matches the table text color to the treatment color (blue for Placebo, red for Low Dose, etc.).*/
/*display=(label)*/
/*Requests that the row labels (like “Placebo”, “Low Dose”) be displayed.*/
/*labelattrs=(family="Arial" size=8pt)*/
/*Font style for the row labels (treatment names).*/
/*valueattrs=(family="Arial" size=8pt)*/
/*Font style for the numeric values in the risk table.*/

         endinnermargin;
         endlayout;
   endgraph;

   end;
run;

/*data new_survival2 ;*/
/*set new_survival ;*/
/*keep time survival censored; */
/*run;*/

/*=========================================================
Set options for graph and save to RTF
=========================================================*/

ods listing close;
ods graphics on / border=off height=13cm width=14.72cm imagename="KM_CUMULATIVE_INCIDENCE" imagefmt=png;

footnote "Time to event";
title "Cumulative Incidence Plot";
title2 "Safety Analysis Set";
 
ods rtf file="C:\Users\hed2\Downloads\sas-and-r-main\sas-and-r-main\tfl\mytfl/KM_CUMULATIVE_INCIDENCE.rtf" style=csgpool01;
/*csgpool01 is likely a custom style defined in your SAS environment (maybe for sponsor or study reporting).*/
proc sgrender data=new_survival    template=kmplot;
    dynamic x_var="time" y_var1="survival" y_var2="censored";
run;
/*PROC SGRENDER, which is part of the ODS Graphics system in SAS. It’s used when you already have a graph template defined (with PROC TEMPLATE) and want to render data into that template.*/
/*data=new_survival Likely has variables such as time, survival, censored, atrisk, etc.*/
/*dynamic Passes values into the template dynamically (like parameters).*/

ods rtf close;
ods listing;

/*proc contents data=new_survival2 varnum; run; */

/*Example workflow*/
/**/
/*PROC LIFETEST produces survival estimates and censoring info ? stored in new_survival.*/
/**/
/*PROC TEMPLATE defines a statgraph kmplot template (with instructions on how to draw survival curves, censor symbols, etc.).*/
/**/
/*PROC SGRENDER combines the dataset + template to produce the final graph.*/
