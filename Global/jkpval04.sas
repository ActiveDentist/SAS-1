/*
/ PROGRAM NAME: jkpval04.sas
/
/ PROGRAM VERSION: 1.0
/
/ PROGRAM PURPOSE: This utility macro is called by SIMSTAT to perform ANOVA
/   on continious variables.  It retrieves the F statistics associated with
/   the analysis.
/
/ SAS VERSION: 6.12 (UNIX)
/
/ CREATED BY: John Henry King
/
/ DATE: FEB1997
/
/ INPUT PARAMETERS:
/
/   data=               Names the data set to be analyzed.
/
/   by=                 List by variables
/
/   tmt=                Treatment variable name
/
/   control=            The stratification variables produces a two way.  
/ 
/   interact=NO         Will the anova include an interaction term.
/                       e.g. INVCD * TMT
/
/   covars=             List of covariables 
/
/   ss=SS3              The sum of square type as per SAS PROC GLM.
/
/   continue=           Names the analysis variables.
/
/   pairwise=0          Boolean, 0=no pairwise 1=pairwise.
/
/   out=                Names the output data set created by the macro.
/
/   print=NO            Print the output data set?
/
/ OUTPUT CREATED: A SAS data set.
/
/ MACROS CALLED:
/
/
/ EXAMPLE CALL:
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
/*
/
/ Macro JKpval04
/
/ / 
/ If the user requests a pairwise analysis then the macro generates CONTRAST
/ statements, to generate 1 degree of freedom F statistics that are equal to
/ the T test that would be produced by the LSMEANS statement with the PDIFF
/ options.  This is done because the PDIFF p-values are not output into a SAS
/ dataset by the OUT= option on the LSMEANS statement.
/ 
/ Do not use this macro outside the context of macro SIMSTAT.
/
/ Parameter=Default   Description
/ -----------------   ---------------------------------------------------------
/
/
/----------------------------------------------------------------------------*/



%macro jkpval04(data=,
                 out=,
                  by=,
             control=,
                 tmt=,
            interact=NO,
                  ss=SS3,
            continue=,
              covars=,
            pairwise=0,
               print=YES);

   %local anova glm lsm pdf EMS CTL stats tmtlist i j k l _x ptype;
   %let anova   = _1&sysindex;
   %let glm     = _2&sysindex;
   %let lsm     = _3&sysindex;
   %let tmtlist = _4&sysindex;
   %let pdf     = _5&sysindex;
   %let stats   = _6&sysindex;
   %let ems     = _7&sysindex;
   %let ctl     = _8&sysindex;

 
   %let print    = %upcase(&print);
   %let interact = %upcase(&interact);
   %if "&interact"="YES" 
      %then %let interact=|;
      %else %let interact=;

   %let control = %upcase(&control);
   %if "&control"="_ONE_" %then %let control=;

   %if "&covars"="" %then %do;
      %let _x = ;
      %let ptype = ANOVA;
      data &anova;
         set &data(keep=&by &uspatno &tmt &control &continue);
 
         array _1[*] &continue;
         length _vname_ _covar_ $8;
         do _i_ = 1 to dim(_1);
            call vname(_1[_i_],_vname_);
            _y = _1[_i_];

            if _y>.Z then output;

            end;
         drop &continue;
         run;
      %end;
   %else %do;
      %let _x = _x;
      %let ptype = ANCOVA;
      data &anova;
         set &data(keep=&by &uspatno &tmt &control &continue &covars);

         array _1[*] &continue;
         array _2[*] &covars;
         length _vname_ _covar_ $8;
         do _i_ = 1 to dim(_1);
            call vname(_1[_i_],_vname_);
            call vname(_2[_i_],_covar_);
            _y = _1[_i_];
            _x = _2[_i_];
 
            if n(_y,_x)=2 then output;
            end;
         drop &continue &covars;
         run;
      %end;
 
   proc sort data=&anova;
      by &by _vname_ _covar_;
      run;

   data &anova;
      set &anova;
      by &by _vname_ _covar_;

      if first._covar_ then _byid_ + 1;

      run;

   /*
   / We need to know two things for this to work.  One is the total
   / number of treatments in each BY group.  And two the value of TMT=
   / for each of these group.
   /
   / This information is needed to construct the CONTRAST statements and
   / to get them labled properly in the output dataset created by SIMSTAT.
   /
   /------------------------------------------------------------------------*/


   /*
   / This proc summary will return the TMT= values for each BY group.
   /------------------------------------------------------------------------*/
  
   proc summary data=&anova nway missing;
      class _byid_ &by &tmt;
      output out=&tmtlist(drop=_type_ _freq_);
      run;


   /*
   / This data null step is used to creat macro variable array to hold to
   / total number of TMTs per BY group and the values of the TMTs in each.
   /
   /
   / The macro variables are named as follows.
   /
   / _0 The number of unique BY groups.
   /
   / _1_1 ... _1_n
   / _2_1 ... _2_n
   / ...
   / _k_1 ... _k_n
   /
   / Where n is the number of TMTs in each BY group.
   / Where k is the number of BY groups.
   /---------------------------------------------------------------------------*/

   %local _0;
   %let _0 = 0;

   /*
   / Make the array variables LOCAL, I hope this is enough.
   /---------------------------------------------------------------------------*/
   
   %do k = 1 %to 20;
      %do i = 0 %to 20;
         %local _&k._&i; 
         %end;
      %end;

   /*
   / Using the output from PROC SUMMARY above create the macro variable arrays
   /---------------------------------------------------------------------------*/

   data _null_;
      set &tmtlist end=eof;
      by _byid_ &by;

      if first._byid_ then do;
         _1_ = 0;
         end;

      _1_ + 1;

      length _name_ $8;
      _name_ = '_'||trim(left(put(_byid_,8.)))||'_'||left(put(_1_,8.));
      
      call symput(_name_,trim(left(put(&tmt,8.))));

      if last._byid_ then do;
         _name_ = '_'||trim(left(put(_byid_,8.)))||'_0';

         call symput(_name_,trim(left(put(_1_,8.))));
         end;

      if eof then do;
         call symput('_0',trim(left(put(_byid_,8.))));
         end;
      run;

   /*
   / Look at the values of the variables just created.
   /-----------------------------------------------------------*/

   /*
   %do k = 1 %to &_0;
      %do i = 0 %to &&_&k._0;
         %put NOTE: _&k._&i = &&_&k._&i;
         %end;
      %end;
   */


   /*
   / Now call GLM once for each BY group, using the macro variable
   / arrays to generate the CONTRAST statements.
   /----------------------------------------------------------------*/

   %do k = 1 %to &_0;
      proc glm 
            noprint 
            order   = internal
            data    = &anova
               (
                where=(_byid_=&k)
               ) 
            outstat = &GLM
            ;

         by &by _vname_ _covar_;

         class &control &tmt;
         model _y = &control &interact &tmt  &_x / &ss;

      /*
      / If the pairwise analysis was requested then this bit of code
      / will generate the contrast statements needed to produce the same
      / p-values as the PDIFF option on the LSMEANS statement.
      /
      / The array variables that were created above are used to determine
      / the number of coefients and the label for the contrast.
      /--------------------------------------------------------------------*/

      %if &pairwise %then %do;
         %do i = 1 %to &&_&k._0 -1;
            %do j = &i+1 %to &&_&k._0;
 
               contrast "%str(P)&&_&k._&i%str(_)&&_&k._&j" &tmt
 
               %do l = 1 %to &i-1;
                  0
                  %end;
               1
               %do l = &i+1 %to &j-1;
                  0
                  %end;
               -1;
               %end;
            %end;
         %end;
 
         lsmeans &tmt / out=&LSM;
         run;
         quit;

      %if "&print"="YES" %then %do;
         title5 "DATA=GLM(&glm) the outstat data set";
         proc print data=&glm;
            run;
         title5;
         %end;

 
      /*
      / Use transpose to arrange the CONTROLing variable p-value
      /---------------------------------------------------------------*/
      %if "&control" ^= "" %then %do;
         proc transpose
               data = &GLM
                  (
                   where  = (_source_ = "&control")
                  )
               out  = &CTL
                  (
                   rename = (_x_x1 = PR_CNTL)
                  )

               prefix = _x_x
               ;

            by &by _vname_ _covar_;
            var prob;
            run;

         %if "&print"="YES" %then %do;
            title5 "DATA=CTL(&ctl) the pvalue for the controlling variable";
            proc print data=&ctl;
               run;
            title5;
            %end;
         %end;


      /*
      / Use transpose to arrange the ERROR Sum of square and DF
      /---------------------------------------------------------------*/

      proc transpose 
            data = &GLM
               (
                where  = (_type_ = 'ERROR')
               )
            out  = &EMS 
            ;
         by &by _vname_ _covar_;
         id _source_;
         var df ss;  
         run;

      %if "&print"="YES" %then %do;
         title5 "DATA=EMS(&EMS) the transposed outstat dataset";
         proc print data=&ems;
            run;
         title5;
         %end;      

      proc transpose data=&ems out=&ems(drop=_name_);
         by &by _vname_ _covar_;
         id _name_;
         var error;
         run;

      %if "&print"="YES" %then %do;
         title5 "DATA=EMS(&EMS) the transposed outstat dataset";
         proc print data=&ems;
            run;
         title5;
         %end;




      /*
      / Use transpose to arrange the p-values for the SIMSTAT output 
      / dataset.
      /---------------------------------------------------------------*/

      proc transpose 
            data = &GLM
               (
                where  = (_type_ = 'CONTRAST' | _source_="&tmt")
               )
            out  = &PDF 
               (
                drop   = _name_
                rename = (&tmt = PROB)
               );

         by &by _vname_ _covar_;
         id _source_;
         var prob;
         run;


      %if "&print"="YES" %then %do;
         title5 "DATA=PDF(&pdf) the transpose outstat dataset";
         proc print data=&pdf;
            run;
         title5;
         %end;

      /*
      / Now merge the LSMEANS with the p-values
      /----------------------------------------------------------------*/

      data &stats&k;
         merge 
            &PDF
            &EMS
               (
                rename=(df=dfe ss=sse)
               )

         %if "&control" ^= "" %then %do;
            &CTL
               (
                keep = &by _vname_ _covar_ pr_cntl
               )
            %end;

            &LSM
               (
                drop   = _name_
                rename = (lsmean=LSM stderr=LSMSE)
               );

         by &by _vname_ _covar_;

         mse     = sse / dfe;
         rootmse = sqrt(mse);

         length _ptype_ $8;
         retain _ptype_ "&ptype"; 
         run;

      %if "&print"="YES" %then %do;
         title5 "DATA=STATS&k(&stats&k) the processed stats and lsm data";
         proc print data=&stats&k;
            run;
         title5;
         %end;

      %end;


   /*
   / Delete the temporary datasets
   /---------------------------------------------------------------*/

   proc delete data=&glm &lsm &ems &pdf &anova &tmtlist;
      run;

   /*
   / Put the individual datasets together
   /---------------------------------------------------------------*/

   data &out; 
      set
      %do k = 1 %to &_0;
         &stats.&k
         %end;
      ;
      by &by _vname_ _covar_;
      run;

   proc sort data=&out;
      by &by _vname_ &tmt;
      run;


   /*
   / Delete those temporary datasets
   /---------------------------------------------------------------*/

   proc delete data=
      %do k = 1 %to &_0;
         &stats.&k
         %end;
      ;
      run;


   %if "&print"="YES" %then %do;
      title5 "DATA=&out ANOVA Pvalues";
      proc contents data=&out;
         run;
      proc print data=&out;
         run;
      title5;
      %end; 

   %mend jkpval04;
