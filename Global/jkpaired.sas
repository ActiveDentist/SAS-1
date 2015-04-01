/*
/ PROGRAM NAME: jkpaired.sas
/
/ PROGRAM VERSION: 1.0
/
/ PROGRAM PURPOSE:
/
/ Use macro JKPAIRED to prepare data for a paired analysis.
/ A paired analysis is one where the treatments are tested 2 at a time.
/ For example for 3 treatments.
/
/   1 vs 2
/   1 vs 3
/   2 vs 3
/
/ This macro was written for the standard macros but can be used in any 
/ program where a paired data set is needed.
/
/ SAS VERSION: 6.12
/
/ CREATED BY: John Henry King
/
/ DATE: 1993
/
/ INPUT PARAMETERS:
/
/ data      = _LAST_
/             Names the input dataset.            
/
/ out       = _PAIRED_
/             Names the output data set.
/
/ by        = <list of variables>
/             BY variables. 
/
/ overall   = YES
/             Specifies that the OUT= data set will have the overall (unpaired)
/             data included also.  For some types of anlalysis, odds rations,
/             from proc freq for example are only approaite for 2x2 tables.  
/             In that case OVERALL=NO should be specified.
/
/ pair      = <numeric treatment variable>
/             Names the variable to pair the data by.  
/
/ _1        = _1
/             Specifies the name of the variable to contain the first paired
/             group variable.
/
/ _2        = _2
/             Specifies the name of the variable to contain the first paired
/             group variable.
/
/ root      = _
/             Provides root name for macro variable arrays used internally
/             by the macro.  This parameter would rarely need to be changed.
/
/ print     = NO 
/             Print the out= data set.
/
/ chkdata   = YES
/             Call macro CHKDATA to verify input to the macro?
/
/ 
/ idname    = Variable name for ID variable.
/
/ id        = Character expression used to assign ID variable.
/
/ sortby    = &_1 &_2
/             By variable list to sort the out= data on.
/
/ sort      = YES
/             Control sorting of out= data set.  By default the data is
/             sorted by &_1 and &_2.
/            
/
/
/ OUTPUT CREATED: The paired dataset.  All variable from original plus
/  the special variables created by the macro.
/
/ MACROS CALLED:
/  May call JKCHKDAT if CHKDATA=YES is specified.
/
/ EXAMPLE CALL:
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

%macro JKPAIRED(data = _LAST_,
               where = ,
                 out = _PAIRED_,
                  by = ,
                pair = ,
                root = _,
                  _1 = _1,
                  _2 = _2,
             overall = YES,
               print = NO,
             chkdata = YES,
              idname = ,
                  id = ,
              sortby = ,
                sort = YES);

   %local temp1;
   %let temp1 = _1_&sysindex;

   %local i j k;

   %let chkdata = %upcase(&chkdata);
   %let print   = %upcase(&print);

   %let data    = %upcase(&data);
   %let out     = %upcase(&out);
   %let by      = %upcase(&by);
   %let pair    = %upcase(&pair);
   %let sortby  = %upcase(&sortby);
   %let sort    = %upcase(&sort);
   %let overall = %upcase(&overall);
 
   %if %length(&pair)=0 %then %do;
      %put ER!ROR: Macro parameter PAIR must not be null.;
      %goto EXIT;
      %end;


   %if "&chkdata" = "YES" %then %do;
      %jkchkdat(data=&data,vars=&by &pair,return=xrc)

      %if &xrc %then %do;
         %put ER!ROR: Macro JKPAIRED ending due to ER!RORs;
         %goto EXIT;
         %end;

      %end;

   %if %length(&sortby)=0 %then %do;
      %let sortby = &_1 &_2;
      %end;

   %if "&sort"="YES"
      %then %let sort = 1;
      %else %let sort = 0;

   %if "&overall"="YES"
      %then %let overall = 1;
      %else %let overall = 0;

   %if "&print"="YES"
      %then %let print = 1;
      %else %let print = 0;


   /*
   / Sort the input data
   /------------------------------------------------*/
   proc sort 
         data=&data
         (
      %if %length(%nrquote(&where))> 0 %then %do;
         where = (&where)
         %end;
         )
         out=&out;
      by &by &pair;
      run;



   /*
   / Find the unique WAYs of the data.
   /-----------------------------------------------*/

   proc summary data=&data nway;
      by &by;
      class &pair;
      output out=&temp1(drop=_type_ _freq_);
      run;

   /*
   / Transpose the summary output data to have one observation
   / per BY group with the levels of PAIR stored in an array '_CLn'
   /---------------------------------------------------------------*/

   proc transpose data=&temp1 out=&temp1(drop=_name_) prefix=_CL;
      by &by;
      var &pair;
      run;

   /*
   / Now using the values of each observations PAIR variable
   / and the PAIR values array create the pairwise data set.
   /----------------------------------------------------------*/

   data &out;

   /*
   / If there are no BY variables then we need to SET &temp1
   / on _n_=1.  If there are by variables then we need to do
   / a match merge.
   /----------------------------------------------------------*/

   %if %length(&by)=0 %then %do;
      set &out;
      if _n_ = 1 then set &temp1;
      %end;

   %else %do;
      merge &out(in=in1) &temp1(in=in2);
      by &by;
      %end;

      drop _cl: _i_; 

      array _cl[*] _cl:;

      &_1 = 0;
      &_2 = 0;

      %if %length(&idname) > 0 %then %do;
         length &idname $8;
         %end;
 

      /*
      / This link to OUT will output the unpaired data into the data set also.
      / If the desired statistic from proc freq is not approiate for for RxC
      / tables then OVERALL= can be used to restrict that activity.
      /-----------------------------------------------------------------------*/

      %if &overall %then %do;
         link out;
         %end;

      do _i_ = 1 to dim(_cl); 

         if _cl[_i_] = . then continue;

         select;
            when(_cl[_i_] > &pair) do;
               &_1 = &pair;
               &_2 = _cl[_i_];
               link out; 
               end;
            when(_cl[_i_] < &pair) do; 
               &_1 = _cl[_i_];
               &_2 = &pair;
               link out;
               end;
            otherwise;
            end;

         end;
      return;

    OUT:
      %if %length(&idname)>0 %then %do;
         &idname = &id;
         %end;
      output;
      return;
      run;

   proc delete data=&temp1;
      run;

   %if &sort %then %do;
      %if %length(&sortby)>0 %then %do;
         proc sort data=&out;
            by &by &sortby;
            run;
         %end;
      %end;

   %if &print %then %do;
      title5 "DATA=&out OUT from macro JKPAIRED";
      proc print data=&out;
         run;
      title5;
      %end;
 
 %EXIT: 

   %mend JKPAIRED;
