/*
/ PROGRAM NAME:     AESTAT.SAS
/
/ PROGRAM VERSION:  1.2
/
/ PROGRAM PURPOSE:  AESTAT summarizes AE type data.  It supports a number of
/                   statistical test and other features.
/
/ SAS VERSION:      6.12
/
/ CREATED BY:       John Henry King
/
/ DATE:             1993
/
/ INPUT PARAMETERS: See detailed description below.
/
/ OUTPUT CREATED:   Creates a SAS data set that can be used as input to AETAB.
/
/ MACROS CALLED:    JKPVAL05 - Compute p-value for discrete values.
/                   JKCHKDAT - Check input data for proper variables and types.
/                   JKPAIRED - Produces a dataset for pairwise analysis.
/
/ EXAMPLE CALL:     %aestat(  denom = denom,
/                           adverse = adverse,
/                               tmt = tmt,
/                           uspatno = ptcd subject,
/                           p_value = cmhrms,
/                           control = xptcd,
/                            subgrp = aerel,
/                            level1 = bodytx,
/                            level2 = grptx,
/                          pairwise = yes,
/                             print = 1);
/
/=====================================================================================
/ CHANGE LOG:
/
/    MODIFIED BY: John Henry King
/    DATE:        26FEB1997
/    MODID:       JHK001
/    DESCRIPTION: Fixed type in check list when P_VALUE=CMHCOR and a controlling
/                 variable is used.  CONTROL=
/    ------------------------------------------------------------------------------
/    MODIFIED BY: John Henry King
/    DATE:        27FEB1997
/    MODID:       JHK002
/    DESCRIPTION: Added option to pass PROC FREQ options to JKPVAL05.
/    ------------------------------------------------------------------------------
/    MODIFIED BY: John Henry King
/    DATE:        28FEB1997
/    MODID:       JHK003
/    DESCRIPTION: Enhance error messages to make them more noticable.
/    ------------------------------------------------------------------------------
/    MODIFIED BY: John Henry King
/    DATE:        10NOV1997
/    MODID:       JHK004
/    DESCRIPTION: Added Total option and checking for blank LEVEL1 or LEVEL2
/                 values. Also added OUTSUBJ option to output a subject list
/                 with the summary statistics attached.
/    ------------------------------------------------------------------------------
/    MODIFIED BY: Jonathan Fry
/    DATE:        09DEC1998
/    MODID:       JMF005
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Version Number changed to 1.2.
/    ------------------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX006
/    DESCRIPTION:
/    ------------------------------------------------------------------------------
/======================================================================================*/

/*
/ Macro AESTAT
/
/ Use macro AESTAT to count adverse events.
/
/ Parameter=default   Description
/ -----------------   ----------------------------------------------------------
/
/ ADVERSE=            Names the data set of adverse events.  This data set
/                     should have one observation for each adverse event, and
/                     should not include observations for patients who did not
/                     have adverse events.
/
/ DENOM=              Names the data set of denominator patients.  This data set
/                     should have one observation for each patient who is in the
/                     populations defined by the PAGEBY variables.  The macro
/                     will verify that DENOM has only one patient in each
/                     population by treatment combination.
/
/ OUTSTAT=AESTAT      Names the summary data set created by the macro.  See
/                     description of OUTSTAT data set below.
/
/ OUTSUBJ=            Names a data set of subject numbers merged with the summary
/                     stats to be used to produce the listing of subjects with
/                     each ae.  If this parameter is blank, the default, then no
/                     subject list is produced.  Note this option is only available
/                     when LEVEL2 group is used.
/
/ UNIQUEID=           Names the variable(s) used to uniquely identify each patient
/                     in the DENOM and ADVERSE data sets.  Please note that older
/                     versions on AESTAT did not support more that one variable in
/                     this parameter.  You may now specify as may variables as are
/                     needed to uniquely identify the patients.
/
/ PAGEBY=             Names variables used to group the analysis.  The variables
/                     must be in BOTH the DENOM and ADVERSE data sets.
/                     Typically PAGEBY could represent "STUDY PERIOD", PROTOCOL
/                     or some similar grouping of the analysis.
/
/ TMT=                Names the variable that defines the treatment groups.
/                     This variable must be integer numeric. For example
/                     1, 2, 3, 4, 5.
/
/ TOTAL=NO            Use this options to cause AESTAT to include a total across all
/                     treatment groups.
/
/ TOTALTMT=99         This parameter used in conjunction with TOTAL to give a treatment
/                     value to the total group.
/
/ SUBGRP=             The SUBGRP parameter can be used with AESTAT to produce
/                     a summary of an AE subset and also provide the totals
/                     for
/                        Number of patients with any AE
/                     and
/                        Number of patients with any subgroup
/
/                     For example you want to produce an AE table of drug related
/                     AE.  You also want the display to include the total number of
/                     patients with any AE.  To accomplish this create character
/                     variable with a value of '1' for the AEs in the subgroup and
/                     a missing value for the others.  The tell AESTAT the name of
/                     this variable with the SUBGRP= parameter and AESTAT will
/                     produce a dataset that also contains
/
/                        Number of patients with any AE.
/
/ TMTEXCL = (1)       This parameter is use to exclude from the analysis of
/                     one or more of the treatment groups.
/
/ SEX=                Names the variable that contains the patients sex code.
/                     If the user wants a sex specific denominator for adverse
/                     events that can only occur in one sex then this parameter
/                     should be specified and the DEMOM and ADVERSE data sets
/                     should be structured as follows.
/
/                     In the DEMOM data set this variable should be associated
/                     with EVERY patient and repeated in all PAGEBY groups.
/
/                     In the ADVERSE data set this variable should be blank for
/                     all but ADVERSE events that can only occur in males or females.
/
/                     For example DISS codes that begin with T are Genitalia (Female)
/                     therefore the proper denominator for these events would include
/                     only female patients.
/
/ LEVEL1=             This parameter names the first level of adverse event
/                     classification, typically some type of body system
/                     grouping.  SYMPCLASS or DISS code first letter.
/
/ ORDER1=_ORDER1_     Names the variable in the output data that orders the values
/                     of the LEVEL1= variable.
/
/ LEVEL2=             This paremeter names the second level of adverse event
/                     classification, typically DISS code, or SYMPGP.  This
/                     parameter may be left blank if the summary is to only have
/                     one level of classification.
/
/ ORDER2=_ORDER2_     Names the variable in the output data that orders the values of
/                     then LEVEL2= variable.
/
/ CUTOFF=0            This parameter is used to specify an occurance percentage cutoff.
/                     The user would use this parameter to subset the summary to
/                     events that have a mimimum percent occurance.  For example a
/                     summary of events in 5% or greater of the patients would be
/                     specified by CUTOFF=.05.
/                     The cutoff is compared to the smallest percent of the various
/                     treatments included in the CUTWHERE= parameter.
/
/ CUTWHERE=1          This parameter is used to specify a where clause to direct
/                     the CUTOFF to a specific subset of TREATMENTS.  For example
/                     to restrict the analysis to 5% of treatment 1 patients use,
/                     CUTOFF=.05, CUTWHERE=%str(TMT=1).  CUTWHERE can be used with
/                     both CUTOFF= and CUTSTMT=.
/
/ CUTSTMT=            The cut statement parameter provideds similar functionality
/                     to that provided by the CUTOFF= parameter.  While CUTOFF
/                     allows the user to subset to events that are larger than
/                     the cutoff the CUTSTMT allows the use to specify a
/                     subsetting SAS statement.  This way the user is allowed to
/                     do the subsetting based on what ever criteria he wishes.
/                     The CUTSTMT= should be a valid sas IF statement including
/                     the simicolon.  ex.
/                         CUTSTMT=%STR(if 0.01 <= CUTOFF <= 0.05;),
/                     Note that variable CUTOFF is the variable created by
/                     AESTAT that will contain the cutoff value.  Do not use
/                     CUTOFF= when using CUTSTMT=.
/
/ CUTMNX = MIN        The parameter is used to control how AETAT creates the
/                     the CUTOFF value.  By default the MIN percent across
/                     treatment is used in the comparision.  You may want to
/                     use MAX for some types of cuts.
/ ORDER1BY=1
/ ORDER2BY=1          The orderby parameter is used to specify the subset of
/                     treatments used to order the adverse events by frequency.
/                     The default is to sum the frequency of events for all
/                     treatments and order the events by decending frequency of
/                     that sum.  The user may request that only some of the
/                     treatments be used to order the events by using a VALID
/                     where expression in the orderby parameter.  The user will
/                     need to surround the expression with the %STR macro
/                     function.  For example to order the events by the sum of
/                     treatments 2, 3, and 4 use.
/
/                        ORDER2BY = %STR(tmt in(2,3,4))
/
/                     The macro will create a variable in the output dataset named
/                     _ORDER2_.  This variable is then used in a by statement in
/                     proc sort.  The values of _order_ have their sign reversed
/                     so that the sort will be descending without having to use
/                     the descending option in the by statement.
/
/ STLEVEL=2           Use this parameter to control which of the LEVEL groupings
/                     p-values will be computed for.  For example the default is
/                     to compute pvalues for all levels of the LEVEL1 and LEVEL2
/                     variables.  If a user only wanted the p-values for the
/                     LEVEL2 groupings, the body system grouping, then STLEVEL=1
/                     would need to be specified.
/
/ P_VALUE=NONE        This parameter is used to specify the type of p-values to
/                     compute and include in the output data set.  The user may
/                     request CHISQ, EXACT, CMHRMS, CMHGA, CMHCOR, or LGOR.
/                     When LGOR is specifed then the upper and lower confidence
/                     limits are also output.
/
/ SCORES=TABLE        The SCORES= parameter is used to control the SCORES= option
/                     in PROC FREQ.  You may request TABLE, RANK, RIDIT or MODRIDIT
/                     scores.  See documentation for PROC FREQ for details.  If no
/                     P_VALUE is requested then the parameter has no effect.
/
/ PAIRWISE=NO         Use this parameter to request pairwise p-values.
/                     PAIRWISE=YES must be specified when requesting P_VALUE=LGOR
/                     this will insure 2x2 table for the odds ratios.
/
/ CONTROL=            A variable used to produce a stratified analysis (p values)
/                     This is typically study center or perhaps protocol in
/                     an ISS AE table.  This parameter does NOT cause the macro
/                     to produce the AE counts by each level of the controlling
/                     variable.
/
/ PRINT=YES           Use this parameter to request a proc contents and proc
/                     print of the OUTSTAT data set produced by the macro.
/
/ -----------------   ----------------------------------------------------------
/
/===============================================================================
/
/ The OUTSTAT data set.
/
/ The OUTSTAT data set contains one observation for each of the various levels
/ of classifications defined by PAGEBY, TMT, LEVEL1, and LEVEL2.  If you made a
/ table of this data each observation would make up one cell of that table.
/ Where a table cell would include counts, denominator, and percent.
/
/ OUTSTAT is sorted as follows:
/   When LEVEL1 and LEVEL2 are both specifed.
/      BY   PAGEBY _ORDER1_ LEVEL1 _ORDER2_ LEVEL2 TMT
/
/   When LEVEL2 is not specified.
/      BY   PAGEBY _ORDER1_ LEVEL1 TMT
/
/
/
/ The OUTSTAT data set contains the following variables.
/
/ pageby variables:
/   The variables named in the PAGEBY= parameter.
/
/ level1 variable
/   The variable named in the LEVEL1= parameter.
/
/ level2 variable
/   The variable named in the LEVEL2= parameter.  This variable will not appear
/   in the outstat data set if this parameter was not specified.
/
/ sex variable
/   The variable named in the SEX= parameter.  Does not appear if this parameter
/   is not specified.
/
/ tmt variable
/   The variable named in the TMT= parameter.
/
/ _AETYPE_
/   This variable is used to describe the type of summary that has been
/   applied to a particular observation in OUTSTAT.
/     _AETYPE_ = 0 for patients with ANY event
/     _AETYPE_ = 1 for patients with any LEVEL1 event
/     _AETYPE_ = 2 for LEVEL2 events.
/
/ _ORDER1_ _ORDER2_
/   This is the sort order variable.
/
/ N_PATS
/   The number of patients with a particular event.
/
/ N_EVTS
/   The number of occurances of a particular event.
/
/ DENOM
/   The denominator for an event.
/
/ PCT
/   proportion of patients experiencing an event, N_PATS / DENOM
/
/ _PTYPE_
/   The type of p-value if requested in the P_VALUE= parameter. CHISQ or EXACT
/
/ PROB
/   The p-value identified by _PTYPE_.
/
/ P1_2, P1_3, P1_4 ...
/    If PAIRWISE=YES then variables of this form are produced to hold the
/    pairwise p-values.
/
/-----------------------------------------------------------------------------*/

%macro AESTAT(adverse = ,
                denom = ,
              outstat = AESTAT,
              outsubj = ,
             uniqueid = ,
              uspatno = ,
                  sex = ,
               pageby = ,

                  tmt = ,
                total = N,
             totaltmt = 99,

              tmtexcl = (1),

               subgrp = ,

               level1 = ,
               order1 = _order1_,
             order1by = 1,

               level2 = ,
               order2 = _order2_,
             order2by = 1,

               cutoff = 0,
             cutwhere = 1,
              cutstmt = ,
               cutmnx = MIN,

              p_value = NONE,
              control = ,
               scores = TABLE,
               recall = 0,
             pairwise = NO,
              stlevel = 2,
                print = YES,
              sasopts = NOSYMBOLGEN NOMLOGIC,
                debug = 0,
             freqopts = NOPRINT  /* JHK002 */);

   options &sasopts;
   %global vaestat;
   %let    vaestat = 1.0;

   /*
   / JMF005
   / Display Macro Name and Version Number in LOG.
   /------------------------------------------------------------------------*/

   %put ------------------------------------------------------;
   %put NOTE: Macro called: AESTAT.SAS     Version Number: 1.2;
   %put ------------------------------------------------------;


   /*
   / JHK003
   / New macro variable added to make error message more noticable.
   / All ! mark removed from old error messages.
   /--------------------------------------------------------------------------*/

   %local erdash;
   %let erdash = ERROR: _+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_;


   %if "&denom"="" %then %do;
      %put &erdash;
      %put ERROR: There is no DEMOMinator data set.;
      %put &erdash;
      %goto exit;
      %end;

   %if "&adverse"="" %then %do;
      %put &erdash;
      %put ERROR: There is no ADVERSE data set.;
      %put &erdash;
      %goto exit;
      %end;

   %if "&uspatno"^="" & "&uniqueid"="" %then %do;
      %let uniqueid=&uspatno;
      %let uspatno=;
      %end;

   %if "&uniqueid"="" %then %do;
      %put &erdash;
      %put ERROR: The macro parameter UNIQUEID must not be blank.;
      %put &erdash;
      %goto exit;
      %end;

   %if "&tmt"="" %then %do;
      %put &erdash;
      %put ERROR: The macro parameter TMT must not be blank.;
      %put &erdash;
      %goto exit;
      %end;

   %if "&level1"="" %then %do;
      %put &erdash;
      %put ERROR: The macro parameter LEVEL1 must not be blank.;
      %put &erdash;
      %goto exit;
      %end;

   %if %bquote(&level2)= & %bquote(&outsubj)^= %then %do;
      %put &erdash;
      %put ERROR: You cannot request a subject list without a LEVEL2 variable.;
      %put &erdash;
      %goto exit;
      %end;


   %if "&scores"="" %then %do;
      %put &erdash;
      %put ERROR: The macro parameter SCORES must not be blank.;
      %put &erdash;
      %goto exit;
      %end;

   %if %index(&uniqueid,&control) %then %do;
      %put &erdash;
      %put ERROR: Your CONTROLling variable is also in UNIQUEID,;
      %put ERROR: this could cause problems for AESTAT.;
      %put ERROR: Rename the CONTROLling variable and try again.;
      %put &erdash;
      %goto exit;
      %end;

   /*
   / check that the user is not trying to use the older CUTOFF and
   / CUTWHERE parameters with the newer CUTSTMT and CUTMX parameters
   /------------------------------------------------------------------*/
   %if ^%index(MIN MAX,&cutmnx) %then %do;
      %put &erdash;
      %put ERROR: CUTMN must have the value MIN or MAX;
      %put &erdash;
      %goto exit;
      %end;

   %if "&cutstmt"^="" & "&cutoff"^="0"  %then %do;
      %put &erdash;
      %put ERROR: You are try to use the CUTSTMT with CUTOFF.;
      %put ERROR: These are incompatable options use either a CUTSTMT, the preferred method,;
      %put ERROR: or the older CUTOFF parameter.;
      %put &erdash;
      %goto exit;
      %end;


   %if "&p_value"="" %then %let p_value=NONE;
   %let p_value = %upcase(&p_value);

   %if ^%index(CHISQ EXACT CMH CMHCOR CMHRMS CMHGA NONE LGOR,&p_value) %then %do;
      %put &erdash;
      %put ERROR: p-value requested "&p_value" is not valid.;
      %put &erdash;
      %goto exit;
      %end;

   %if "&control" > "" & %index(CHISQ EXACT,&p_value) %then %do;
      %put &erdash;
      %put ERROR: You cannot request Fishers EXACT or Chi Square test with a controlling variable.;
      %put &erdash;
      %goto EXIT;
      %end;


   %let pairwise = %upcase(&pairwise);

   %if "&pairwise"="YES"
      %then %let pairwise = 1;
      %else %let pairwise = 0;


   %if ^&pairwise & "&p_value"="LGOR" %then %do;
      %put &erdash;
      %put ERROR: You MUST specify PAIRWISE=YES when requesting Odds Ratios (P_VALUE=LGOR).;
      %put &erdash;
      %goto EXIT;
      %end;


   %jkchkdat(data=&denom,
             vars=&pageby &control &uniqueid &sex,
            nvars=&tmt,
           return=rc_d)

   %if &rc_d %then %goto exit;


   %jkchkdat(data=&adverse,
             vars=&pageby &control &uniqueid &sex &level1 &level2,
            nvars=&tmt,
            cvars=&subgrp,
           return=rc_a)

   %if &rc_a %then %goto exit;


   %if "&outstat" = "" %then %let outstat = AESTAT;
   %let outstat = %upcase(&outstat);


   %if "&print"="" %then %let print = NO;
   %let print = %upcase(&print);
   %if "&print" = "YES" | "&print"="1"
      %then %let print = 1;
      %else %let print = 0;

   %let order1 = %upcase(&order1);
   %let order2 = %upcase(&order2);

   %if "&order1"="NONE" %then %let order1=;

   %if "&order2"="NONE" %then %let order2=;
   %if "&level2"=""     %then %let order2=;

   %if "&order1by"="" %then %let order1by = 1;
   %if "&order2by"="" %then %let order2by = 1;

   %if "&cutwhere"="" %then %let cutwhere = 1;


   %local subgrp_f;

   %if %length(&subgrp) > 0
      %then %let subgrp_f = 1;
      %else %let subgrp_f = 0;

   %let recall = %upcase(&recall);

   %if ^%index(0 1,&recall) %then %do;
      %put &erdash;
      %put ERROR: The macro parameter RECALL must be either 0 or 1.;
      %put &erdash;
      %goto exit;
      %end;

   %let control = %upcase(&control);

   %local tcontrol;
   %if &recall & "&control" > ""
      %then %let tcontrol = &control;
      %else %let tcontrol = ;

   %let total = %upcase(&total);
   %if %bquote(&total)=YES | %bquote(&total)=Y | %bquote(&total)=1
      %then %let total = 1;
      %else %let total = 0;


   %local setlist aetype;

   %local adv all pop pop2 advm1 adv0 adv1 adv2 zero ztmt
          freq pval order cutd dups xadvr tdenom subj;

   %let all    = _1_&sysindex;
   %let pop    = _2_&sysindex;
   %let pop2   = _3_&sysindex;
   %let adv0   = _4_&sysindex;
   %let adv1   = _5_&sysindex;
   %let adv2   = _6_&sysindex;
   %let zero   = _7_&sysindex;
   %let ztmt   = _8_&sysindex;
   %let freq   = _9_&sysindex;
   %let pval   = _A_&sysindex;
   %let order  = _B_&sysindex;
   %let cutd   = _C_&sysindex;
   %let dups   = _D_&sysindex;
   %let advm1  = _E_&sysindex;
   %let xadvr  = _F_&sysindex;
   %let tdenom = _G_&sysindex;
   %let adv    = _H_&sysindex;
   %let subj   = _I_&sysindex;

   /*
   / Verify that the DEMOMinator data has unique observations for each patient.
   /--------------------------------------------------------------------------*/

   %local dupflag;
   %let dupflag = 0;

   proc sort data=&denom out=&tdenom;
      by &pageby &tcontrol &uniqueid &tmt;
      run;

   data &dups;
      set &tdenom;
      by &pageby &tcontrol &uniqueid &tmt;
      if ^(first.&tmt & last.&tmt) then do;
         output &dups;
         call symput('DUPFLAG','1');
         end;
      format _all_;
      run;

   %if &dupflag %then %do;
      title5 'Duplicates found in input data, correct and resubmit';
      proc print data=&dups;
         run;
      title5;
      %put &erdash;
      %put ERROR: Duplicates found in input data correct and resubmit.;
      %put ERROR: Please check the listing for a list of duplicate data.;
      %put &erdash;
      %goto EXIT;
      %end;


   %if &total %then %do;
      data &tdenom;
         set &tdenom;
         output;
         &tmt = &totaltmt;
         output &tdenom;
         run;
      %end;


   /*
   / check ADVERSE for missing values of LEVEL1 or LEVEL2 and create
   / total variable is TOTAL=YES.
   /--------------------------------------------------------------------*/

   data &adv &dups;
      set &adverse;

      if &level1=' ' %if %bquote(&level2)^= %then | &level2=' '; then do;
         output &dups;
         call symput('DUPFLAG','1');
         end;


      output &adv;

      %if &total %then %do;
         &tmt = &totaltmt;
         output &adv;
         %end;

      run;

   %let adverse = &adv;

   %if &dupflag %then %do;
      title5 'Missing value for LEVEL1 | LEVEL2 variables found in input data, correct and resubmit';
      proc print data=&dups;
         run;
      title5;
      %put &erdash;
      %put ERROR: Missing values for LEVEL1 | LEVEL2 variables found in input data correct and resubmit.;
      %put ERROR: Please check the listing for a list of missing data.;
      %put &erdash;
      %goto EXIT;
      %end;



   /*
   / If we are doing a subgroup analysis then this step
   / will creat a new data set with only the subgroup in
   / it.  Otherwise the adverse data will be used.
   /------------------------------------------------------*/

   %if &subgrp_f %then %do;

      data &xadvr;
         set &adverse;
         if &subgrp > ' ';
         run;

      %end;
   %else %let xadvr = &adverse;



   /*
   / Use the denominator data to compute counts for the various levels of &TMT.
   / POP will be the number of patients for each treatment and if used sex.
   /--------------------------------------------------------------------------*/

   proc summary data=&tdenom nway missing;
      class &pageby &tcontrol &tmt &sex;
      output out=&pop(drop=_type_ rename=(_freq_=denom));
      run;


   /*
   / Depending on if the user specified a value for SEX the macro needs to
   / create a POP2 data set that has patient counts that do not include sex.
   /--------------------------------------------------------------------------*/

   %if "&sex" = "" %then %do;
      data &pop2;
         set &pop;
         run;
      %end;
   %else %do;
      /*
      / POP will include the totals for each tmt and for each tmt and sex
      /-----------------------------------------------------------------------*/
      proc summary data=&tdenom nway missing;
         class &pageby &tcontrol &tmt;
         output out=&pop2(drop=_type_ rename=(_freq_=denom));
         run;

      data &pop;
         set &pop2 &pop;
         by &pageby &tcontrol &tmt;
         run;
      %end;


   %if &subgrp_f %then %do;
      /*
      / Now find the total number of patients with ANY adverse event.
      / _AETYPE_ = -1.  This is for all subgrp values.
      /--------------------------------------------------------------------------*/
      proc summary
            nway missing
            data=&adverse;

         class &uniqueid &tcontrol &pageby &tmt;
         output out = &advm1(drop=_type_);
         run;
      proc summary data=&advm1 nway missing;
         class &pageby &tcontrol &tmt;
         var _freq_;
         output out = &advm1(drop=_type_ _freq_)
                  n = n_pats
                sum = n_evts;
         run;
      %let setlist = &advm1(in=inm1);
      %let aetype  = inm1*-1;

      %end;


   /*
   / Now find the total number of patients with ANY adverse event.
   / _AETYPE_ = 0
   /--------------------------------------------------------------------------*/
   proc summary data=&xadvr nway missing;
      class &uniqueid &tcontrol &pageby &tmt;
      output out = &adv0(drop=_type_);
      run;
   proc summary data=&adv0 nway missing;
      class &tcontrol &pageby &tmt;
      var _freq_;
      output out = &adv0(drop=_type_ _freq_)
               n = n_pats
             sum = n_evts;
      run;

   %let setlist = &setlist &adv0(in=in0);
   %let aetype  = &aetype + in0*0;

   /*
   / If LEVEL1 is not blank find the total number of patients for each level
   / of the variable specified in LEVEL1.  This would typically be body system.
   /--------------------------------------------------------------------------*/
   %if "&level1" ^= "" %then %do;
      proc summary data=&xadvr nway missing;
         class &uniqueid &tcontrol &pageby &tmt &sex &level1;
         output out = &adv1(drop=_type_);
         run;
      proc summary data=&adv1 nway missing;
         class &pageby &tcontrol &tmt &sex &level1;
         var _freq_;
         output out = &adv1(drop=_type_ _freq_)
                  n = n_pats
                sum = n_evts;
         run;
      %let setlist = &setlist &adv1(in=in1);
      %let aetype  = &aetype + in1*1;
      %end;
   %else %do;
      %let adv1 = ;
      %end;

   /*
   / If LEVEL2 is not blank find the total number of patients for each level
   / of this variable.
   /--------------------------------------------------------------------------*/
   %if "&level2" ^= "" %then %do;
      proc summary data=&xadvr nway missing;
         class &uniqueid &tcontrol &pageby &tmt &sex &level1 &level2;
         output out = &adv2(drop=_type_);
         run;

      %if %bquote(&outsubj)^= %then %do;
         proc sort data=&adv2 out=&subj;
            by &pageby &level1 &level2 &tmt;
            run;
         %end;
      %else %let subj =;

      proc summary data=&adv2 nway missing;
         class &pageby &tcontrol &tmt &sex &level1 &level2;
         var _freq_;
         output out = &adv2(drop=_type_ _freq_)
                  n = n_pats
                sum = n_evts;
         run;
      %let setlist = &setlist &adv2(in=in2);
      %let aetype  = &aetype + in2*2;
      %end;
   %else %do;
      %let adv2 = ;
      %let subj = ;
      %end;


   /*
   / Put the data created above together and sort.
   /--------------------------------------------------------------------------*/
   data &all;
      set &setlist;
      _aetype_ = &aetype;
      run;

   proc sort data=&all;
      by &pageby &level1 &level2 &sex _aetype_ &tcontrol &tmt;
      run;

   /*
   / Some adverse events may not have occured in all treatments.  In the next
   / few steps create a FRAME of zeros using data from above and update
   / the FRAME with that data.
   /--------------------------------------------------------------------------*/

   /*
   / Using ALL, the adverse event counts, create a data set with one
   / observation for each event.
   /--------------------------------------------------------------------------*/
   proc summary data=&all nway missing;
      class &pageby &level1 &level2 &tcontrol &sex _aetype_;
      output out=&zero(drop=_type_ _freq_);
      run;

   /*
   / Now using the POP data create ZTMT a data set with one observation for
   / each treatment.
   /--------------------------------------------------------------------------*/
   proc summary data=&pop nway missing;
      class &tmt;
      output out=&ztmt(drop=_type_ _freq_);
      run;

   /*
   / Create the FRAME of zeros.
   /--------------------------------------------------------------------------*/
   data &zero;
      set &zero end=eof;
      do point = 1 to nobs;
         set &ztmt point=point nobs=nobs;
         output;
         end;
      retain n_pats 0;
      run;

   proc sort data=&zero;
      by &pageby &level1 &level2 &sex _aetype_ &tcontrol &tmt;
      run;


   /*
   / Use UPDATE to add the non-zero values calculated above to the FRAME of
   / zeros.
   /--------------------------------------------------------------------------*/

   data &all;
      update &zero &all;
      by &pageby &level1 &level2 &sex _aetype_ &tcontrol &tmt;
      run;



   /*
   / Create an the ORDER 1 variable
   /--------------------------------------------------------------------------*/
   %if "&order1" ^= "" %then %do;
      proc summary nway missing data=&all(where=((&order1by) & (_aetype_<=1)));
         class &pageby &level1;
         var n_pats;
         output out=&order(drop=_type_ _freq_)
                sum=_xorder_;
         run;


      %if &debug %then %do;
         title5 "DATA=ORDER1(&order)";
         proc print data=&order;
            run;
         title5;
         %end;



      /*
      / Merge the order variable with the counts.  A new variable is created by
      / changing the sign of the original variable created above.  By changing the
      / sign the AEs will sort in descending order without using the DESCENDING
      / by statement option.  This will make it easier as the descending option
      / will not be needed.
      /--------------------------------------------------------------------------*/

      data &all;
         merge &all &order;
         by &pageby &level1;
         &order1 = _xorder_ * -1;
         drop _xorder_;
         run;

      %end;


   /*
   / Create an the ORDER 2 variable
   /--------------------------------------------------------------------------*/
   %if "&order2" ^= "" %then %do;
      proc summary nway missing data=&all(where=(&order2by));
         class &pageby &level1 &level2;
         var n_pats;
         output out=&order(drop=_type_ _freq_)
                sum=_xorder_;
         run;

      /*
      / Merge the order variable with the counts.  A new variable is created by
      / changing the sign of the original variable created above.  By changing the
      / sign the AEs will sort in descending order without using the DESCENDING
      / by statement option.  This will make it easier as the descending option
      / will not be needed.
      /--------------------------------------------------------------------------*/

      data &all;
         merge &all &order;
         by &pageby &level1 &level2;
         &order2  = _xorder_ * -1;
         drop _xorder_;
         run;

      %end;



   /*
   / Now sort the counts and merge on the denominator
   /--------------------------------------------------------------------------*/
   proc sort data=&all;
      by &pageby &tcontrol &tmt &sex;
      run;

   data &all;

      retain &pageby &order1 &level1 &order2 &level2 _aetype_ &tmt &sex;

      merge &all(in=in1) &pop(in=in2);
      by &pageby &tcontrol &tmt &sex;
      if in1;

      pct = round(n_pats / denom,1e-6);

      label
         denom    = 'Denominator'
         pct      = 'Proportion of patients reporting an AE'
         n_pats   = 'Number of patients reporting an AE'
         n_evts   = 'Number of AEs reported'
         _aetype_ = 'Type of classification'
           cutoff = 'Value used in CUTSTMT comparison.'

      %if "&order1" > "" %then %do;
         &order1  = 'Level 1 sort order variable'
         %end;
      %if "&order2" > "" %then %do;
         &order2  = 'Level 2 sort order variable'
         %end;

         ;
      run;

   proc sort data=&all;
      by &pageby &level1 &level2 _aetype_;
      run;


   /*
   / If the user specified a non-zero cutoff then subset the adverse events
   / by removing events with a percentage occurance less that the cutoff.
   /--------------------------------------------------------------------------*/

   %if "&cutoff" ^= "0" %then %do;
      proc summary nway missing data=&all(where=(%unquote(&cutwhere)));
         class &pageby &level1 &level2 _aetype_;
         var pct;
         output out=&cutd(drop=_freq_ _type_)
            &cutmnx=cutoff;
         run;
      %if &debug %then %do;
         title5 "DATA=CUTD(&cutd)";
         Proc print data=&cutd;
            run;
         title5;
         %end;
      data &all;
         merge &all(in=in1) &cutd(in=in2);
         by &pageby &level1 &level2 _aetype_;
         if cutoff < &cutoff then delete;
         run;
      %end;
   %else %if "&cutstmt" ^= "" %then %do;
      proc summary nway missing data=&all(where=(%unquote(&cutwhere)));
         class &pageby &level1 &level2 _aetype_;
         var pct;
         output out=&cutd(drop=_freq_ _type_)
            &cutmnx=cutoff;
         run;
      %if &debug %then %do;
         title5 "DATA=CUTD(&cutd)";
         Proc print data=&cutd;
            run;
         title5;
         %end;
      data &all;
         merge &all(in=in1) &cutd(in=in2);
         by &pageby &level1 &level2 _aetype_;
         %unquote(&cutstmt);
         run;
      %end;
   %else %let cutdata = ;

   /*
   / If the user asked for p-values then create a dataset for use by jkpval05.
   /--------------------------------------------------------------------------------*/

   /*
   / JHK001, Change reference
   / change CMHOR to CMHCOR
   /-----------------------------*/
   %if "&control"="" & %index(CHISQ EXACT CMH CMHGA CMHRMS CMHCOR LGOR,&p_value) %then %do;

      %local id;

      data &freq(keep=&pageby &level1 &level2 _aetype_ &tmt response weight _one_);

         set
            &all
               (
                keep  = &pageby &tmt &level1 &level2 n_pats denom _aetype_
                where = &tmtexcl
               )
            ;

         if _aetype_ <= &stlevel;

         retain _one_ 1;
         response = 1;
         weight   = n_pats;
         output;

         response = 2;
         weight   = denom - n_pats;
         output;

         run;

      %put NOTE: PAIRWISE=&pairwise;

      %local overall;

      %if "&p_value"="LGOR"
         %then %let overall = NO;
         %else %let overall = YES;


      %if &pairwise %then %do;
         %jkpaired(chkdata = NO,
                     print = NO,
                      data = &freq,
                     where = ,
                   overall = &overall,
                       out = &freq,
                        by = &pageby &level1 &level2 _aetype_,
                      pair = &tmt,
                    sortby = ,
                      sort = NO,
                    idname = _id_,
                        id = %str(compress(put(_1,3.)||'_'||put(_2,3.),' ')) )
         %let id = _id_;
         %end;
      %else %let id = ;

      %jkpval05(data = &freq,
                 out = &pval,
                  by = &pageby &level1 &level2 _aetype_,
                  id = &id,
             control = _one_,
                 tmt = &tmt,
              weight = weight,
            response = response,
             vartype = discrete,
             p_value = &p_value,
            pairwise = &pairwise,
               print = NO,
            freqopts = &freqopts)  /* JHK002 */

      data &all;
         merge &all(in=in1) &pval(in=in2);
         by &pageby &level1 &level2 _aetype_;
         if in1;


         label
            _ptype_ = 'Statistical test used for PROB'
             _cntl_ = 'The controlling variable name if used'
           _scores_ = 'Type of scores used in PROC FREQ'
               prob = 'p-values'
            ;


      %if "&p_value"="LGOR" %then %do;

         if pct > 0 then do;
            _p     = pct;
            _n     = denom;
            _q     = 1 - _p;

            retain zalpha 1.96;

            _a     = (2*_n*_p + zalpha**2 +1);
            _b     = zalpha*(zalpha**2 + 2 -(1/_n) +4*_p*(_n*_q -1))**0.5;
            _c     = 2*(_n+zalpha**2);

            ucb    = (_a+_b)/_c;
            drop _p _n zalpha _a _b _c _q;
            end;

         label ucb = '95% UCB';

         %end;



         run;

      %end;
   /*
   / JHK001, change reference
   / changed CMHOR to CMHCOR
   /------------------------------*/
   %else %if "&control" > "" & %index(LGOR CMH CMHRMS CMHGA CMHCOR,&p_value) %then %do;

      %local id;
      %local xaestat;
      %let xaestat = _X_&sysindex;

      %put NOTE: Tcontrol=&tcontrol, Control=&control;

      %AESTAT(  adverse = &adverse,
                  denom = &denom,
                outstat = &xaestat,
               uniqueid = &uniqueid,
                    sex = &sex,
                 pageby = &pageby,
                    tmt = &tmt,
                tmtexcl = &tmtexcl,

                 subgrp = &subgrp,

                 level1 = &level1,

                 level2 = &level2,

                p_value = NONE,
                control = &control,
                 recall = 1,
               pairwise = NO,
                stlevel = &stlevel,
                  print = NO,
                sasopts = &sasopts,
                  debug = 0)


      %put NOTE: Tcontrol=&tcontrol, Control=&control;

      data &freq(keep=&pageby &level1 &level2 _aetype_ &control &tmt response weight);

         set
            &xaestat
               (
                keep  = &pageby &tmt &control &level1 &level2 n_pats denom _aetype_
                where = &tmtexcl
               )
            ;

         if _aetype_ <= &stlevel;

         retain _one_ 1;

         response = 1;
         weight = n_pats;
         output;

         response = 2;
         weight = denom - n_pats;
         output;

         run;

      %put NOTE: PAIRWISE=&pairwise;

      %if &pairwise %then %do;

         %local overall;

         %if "&p_value"="LGOR"
            %then %let overall = NO;
            %else %let overall = YES;

         %jkpaired(chkdata = NO,
                     print = NO,
                      data = &freq,
                     where = ,
                       out = &freq,
                        by = &pageby &level1 &level2 _aetype_,
                      pair = &tmt,
                   overall = &overall,
                    sortby = ,
                      sort = NO,
                    idname = _id_,
                        id = %str(compress(put(_1,3.)||'_'||put(_2,3.),' ')) )

         %let id = _id_;
         %end;
      %else %let id = ;

      %if 0 %then %do;
         title5 "DATA=FREQ(&freq) just before call to jkpval05";
         proc print data=&freq;
            run;
         %end;

      %jkpval05(data = &freq,
                 out = &pval,
                  by = &pageby &level1 &level2 _aetype_,
                  id = &id,
             control = &control,
                 tmt = &tmt,
              weight = weight,
            response = response,
             vartype = discrete,
             p_value = &p_value,
            pairwise = &pairwise,
               print = no,
            freqopts = &freqopts)  /* JHK002 */


      data &all;
         merge
            &all
               (
                in = in1
               )
            &pval
               (
                in = in2
               )
            ;
         by &pageby &level1 &level2 _aetype_;

         if in1;

         length _cntl_ $8;
         retain _cntl_ "&control";

         label
            _ptype_ = 'Statistical test used for PROB'
             _cntl_ = 'The controlling variable name if used'
           _scores_ = 'Type of scores used in PROC FREQ'
               prob = 'p-values'
            ;

      %if "&p_value"="LGOR" %then %do;

         if pct > 0 then do;
            _p     = pct;
            _n     = denom;
            _q     = 1 - _p;

            retain zalpha 1.96;

            _a     = (2*_n*_p + zalpha**2 +1);
            _b     = zalpha*(zalpha**2 + 2 -(1/_n) +4*_p*(_n*_q -1))**0.5;
            _c     = 2*(_n+zalpha**2);

            ucb    = (_a+_b)/_c;
            drop _p _n zalpha _a _b _c _q;
            end;

         label ucb = '95% UCB';

         %end;

         run;
      %end;

   %else %do;
      %let pval = ;
      %let freq = ;
      %end;


   %if %bquote(&outsubj)^= %then %do;
      data &subj;
         merge
            &all
               (
                in=in1
               )
            &subj
               (
                in     = in2
                rename = (_freq_ = subj_frq)
               )
            ;

         by &pageby &level1 &level2 &tmt;
         if in1;

         label subj_frq = 'Subject events';
         run;

      proc sort data=&subj out=&outsubj;
         by &pageby &order1 &level1 &order2 &level2 _aetype_ &tcontrol &tmt;
         run;

      %if &print %then %do;
         title5 "DATA=OUTSUBJ(&outsubj) The subject list";
         proc contents data=&outsubj;
            run;
         proc print data=&outsubj;
            run;
         title5;
         %end;
      %end;


   /*
   / Sort the data by the ORDER variable within the PAGEBY variables.
   /--------------------------------------------------------------------------*/

   proc sort data=&all out=&outstat;
      by &pageby &order1 &level1 &order2 &level2 _aetype_ &tcontrol &tmt;
      run;



   /*
   / Delete the temporary data sets created by the macro
   /--------------------------------------------------------------------------*/
   proc delete
      data=&all &pop &pop2 &adv0 &adv1 &adv2 &zero
            &ztmt &freq &pval &order &subj &adv &tdenom &dups;
      run;


   proc datasets library=work;
      run;
      quit;

   %if &print %then %do;
      title5 "DATA=&outstat";
      proc contents data=&outstat;
         run;
      proc print data=&outstat;
         run;
      title5;
      %end;

 %EXIT:
   %put NOTE: ------------------------------------------------;
   %put NOTE: MACRO AESTAT Ending execution, Recall=&recall.;
   %put NOTE: ------------------------------------------------;
   %mend AESTAT;
