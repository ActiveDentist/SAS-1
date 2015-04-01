/*
/ PROGRAM NAME: jkcont01.sas
/
/ PROGRAM VERSION: 1.0
/
/ PROGRAM PURPOSE: This utility macro is called by SIMSTAT to produce 
/   descriptive statistisc for continious variables.  Do not use this 
/   macro outside the context of macro SIMSTAT.
/
/ SAS VERSION: 6.12 (UNIX)
/
/ CREATED BY: John Henry King
/ DATE: FEB1997
/
/ INPUT PARAMETERS:
/
/   data=               Names the data set to be analyzed.
/
/   out=                The output dataset.
/
/   by=                 List by variables
/
/   uniqueid=           Unique patient identifier
/
/   tmt=                Treatment variable name
/
/   var=                List of varaibles to be processed
/
/   stats=              List of statistics to be computed
/
/   print=NO            Print the OUT= dataset.
/
/ OUTPUT CREATED: sas data set
/
/ MACROS CALLED:  none
/
/ EXAMPLE CALL:
/
/   %jkcont01(data=&temp1,
/              out=&_cont_,
/               by=&by,
/              tmt=&tmt,
/         uniqueid=&uniqueid,
/              var=&continue,
/            stats=&stats,
/            print=NO)
/
/==============================================================================
/ CHANGE LOG:
/
/ MODIFIED BY:			    
/ DATE:
/ MODID: JHK001
/ DESCRIPTION:
/------------------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID: JHK002
/ DESCRIPTION:
/------------------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID: JHK003
/ DESCRIPTION:
/============================================================================*/

%macro jkcont01(data=,
                 out=,
                  by=,
                 tmt=,
            uniqueid=,
                 var=,
               stats=,
               print=NO);

      %local i temp1; 

      %let temp1 = _1_&sysindex;
 
      %let print = %upcase(&print);

      /*
      / Sort the data for proc transpose. Keep only the variables that are
      / needed for this analysis.
      /----------------------------------------------------------------------*/
      proc sort 
            data=&data(keep=&by &tmt &uniqueid &var)
            out=&temp1;
         by &by &tmt &uniqueid;
         run;

      /*
      / Transpose the ANALYSIS variables so they can be run through 
      / PROC UNIVARIATE by _NAME_.
      /-----------------------------------------------------------------------*/

      proc transpose
            data   = &temp1(keep=&by &tmt &uniqueid &continue)
            out    = &temp1(rename=(_name_=_vname_))
            prefix = xxxxxxx;
         by &by &tmt &uniqueid;
         var &var;
         run;

      proc sort data=&temp1;
         by &by _vname_ &tmt;
         run;


      /*
      / Call UNIVARIATE and request only the statistics requested by the user.
      / The statistics will be named using the statistic name.
      /---------------------------------------------------------------------*/

      %let stat0 = %jkxwords(list=&stats,root=stat);

      proc univariate data=&temp1 noprint;
         by &by _vname_ &tmt;
         var xxxxxxx1;
         output out= &out
         %do i = 1 %to &stat0;
            &&stat&i=&&stat&i
            %end;
            ;
         run;

      proc delete data=&temp1; 
         run;

   %if "&print"="YES" %then %do;
      title4 "DATA=&out, Created by MACRO JKCONT01";
      proc print data=&out;
         run;
      title4;
      %end;
 
   %mend jkcont01;
