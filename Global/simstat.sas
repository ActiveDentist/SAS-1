/*
/ PROGRAM NAME:     SIMSTAT.SAS
/
/ PROGRAM VERSION:  1.2
/
/ PROGRAM PURPOSE:  Summaries of discrete and continious variables. Also
/                   provides a number of statistical test.
/
/ SAS VERSION:      6.12 (UNIX)
/
/ CREATED BY:       John Henry King
/
/ DATE:             FEB1997
/
/ INPUT PARAMETERS: See details below.
/
/ OUTPUT CREATED:   A SAS data set.
/
/ MACROS CALLED:    JKXWORDS - Creates macro variable arrays.
/                   JKCHKDAT - Checks that data set variables exist and are the correct type.
/                   JKCHKLST - Checks the STATS= parameter for valid statistics.
/                   JKPAIRED - Produces a dataset for pairwise analysis.
/                   JKPREFIX - Append characters to the beginning of words in a list.
/                   JKDISC01 - Compute frequencies for discrete variables.
/                   JKCONT01 - Compute summary statistics for continuous variables.
/                   JKPVAL05 - Compute p-values using PROC FREQ.
/                   JKPVAL04 - Compute p-values using GLM.
/
/ EXAMPLE CALL:     %simstat(data = demo,
/                              by = ptcd,
/                             tmt = ntmt,
/                        pairwise = yes,
/                           stats = n mean sum std min max,
/                        discrete = sex,
/                          p_disc = exact,
/                        continue = age,
/                          p_cont = anova);
/
/===================================================================================
/ CHANGE LOG:
/
/    MODIFIED BY: John Henry King
/    DATE:        OCT1997
/    MODID:       JHK001
/    DESCRIPTION: Changed defaults to come to IDSG compliance.
/                 1) default for STATS= changed by adding the MEDIAN to the list.
/                 2) changed defaults for P_CONT and P_DISC to NONE.
/    -----------------------------------------------------------------------------
/    MODIFIED BY: Jonathan Fry
/    DATE:        10DEC1998
/    MODID:       JMF002
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 1.2.
/    -----------------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX003
/    DESCRIPTION:
/    -----------------------------------------------------------------------------
/=================================================================================*/
/*
/ Macro SIMSTA01,
/
/ Parameter=Default    Description
/ -----------------    --------------------------------------------------------
/
/ DATA = _LAST_        The input data set
/
/ OUTSTAT = SIMSTAT    The output data set.  See description of the OUTSTAT data
/                      set below.
/
/ BY =                 By variables for processing the data in groups.
/                      Not to be confused with treatment groups defined by TMT=
/                      below.
/
/ UNIQUEID =            A list of variables that uniquely identifies each record
/                      i.e. patient.  The records must be unique for each treatment
/                      combination that is contained with each of the BY groups
/                      defined by the BY= option, if used.
/
/ TMT =                An INTEGER NUMERIC variable that represents the levels
/                      of treatments.
/
/ TMTEXCL = (1)        This parameter is use to exclude from the analysis of
/                      one or more of the treatment groups.  This options is useful
/                      when you want a analysis with a total column but you do no
/                      want to include those
/
/ CONTROL = _ONE_      A variable used to stratify the analysis, in proc
/                      freq or proc glm.  This variable does NOT cause the
/                      macro to produce summary statistics for each level of
/                      the controlling variable.
/
/--------------------  OPTIONS USED WITH DISCRETE VARIABLES -----------------------------
/
/ DISCRETE =           List the names of descrete variables to be analyzed.
/                      The variables must be CHARACTER, and should have one
/                      character codes. e.g. SEX = M,F or RACE = C,B,O,M,X.
/                      Leave this list blank if there are no discrete
/                      variables.
/
/ YESNO =              This parameter is use to list dicotomus discrete variables for
/                      which only one observation in the output data set is required.
/                      For example a group of YES/NO question might be listed where
/                      only the YES side of the question is to be displayed in a table.
/                      The macro treats YESNO variables as if they were listed in the
/                      DISCRETE= option.  The only special action is that only the YES
/                      observations are kept in the output data set. See the YES=
/                      parameter below.  DO NOT list YESNO variables in the DISCRETE
/                      statement.
/
/ YN_ORDER=            This parameter can be used to have macro SIMSTAT produce an
/                      ordered list of YESNO variables.  The list can then be used
/                      in the ROWS= parameter of macro DTAB.  To have the YESNO
/                      variable ordered by descending frequency, totaled across
/                      treatments use YN_ORDER=DESCENDING.  Use ASCENDING to have
/                      the YESNO variables sorted in ascending order.  The global
/                      macro variable YN_OLIST will be created by SIMSTAT for you
/                      to use as you see fit.
/
/ YES = Y              Use this parameter to specify the value of the YESNO variables
/                      that is to be used for YES.
/
/ DLEVELS =            In many applications some levels of discrete variables are not
/                      all present in the input data set.  For example a table with
/                      age groups as a classification may have one or more groups
/                      that are not represented in the data.
/                      However the user may want the table to include lines in the table
/                      for those values.
/                      This is where dlevels comes into the picture.
/                      In the dlevels parameter list
/                      the values that each of the discrete variables can have seperated
/                      by spaces.  Enclose each discrete variables value list in backslash
/                      characters.  For example \ M F \ 1 2 3 4 5 \.
/                      If you use this parameter then you must supply values for each
/                      discrete variable in the DISCRETE= parameter, and the must be in
/                      the same order as the variables in that list.
/
/ DEXCL =              In some cases discrete variables may have observations in the data
/                      that do not relate to that variable.  For example in a table where
/                      age is grouped by sex the values of age group when the observation is
/                      male do no apply to values of age group for females.  The parameter
/                      DEXCL provides the user a way to tell the macro not to use the
/                      observations with this value as a classification level.  These values
/                      are excluded.
/
/ P_DISC = NONE        P-Value options for discrete variables.
/                      The current options for an unstratified analysis are
/                      CHISQ and EXACT.  For Pearsons chi square and Fishers
/                      exact test respectively.  The EXACT option can burn
/                      up LARGE amounts of CPU so be carefull.
/
/                      For a statified analysis a CMH test is produced.
/                      You can request any one of the following.
/
/                      CMH or CMHGA for General Association.
/                      CMHRMS for Row Mean Scores Differ
/                      CMHCOR for Nonzero Correlation
/
/
/ SCORES=TABLE         The SCORES= parameter is used to control the SCORES= option
/                      in PROC FREQ.  You may request TABLE, RANK, RIDIT or MODRIDIT
/                      scores.  See documentation for PROC FREQ for details.  If no
/                      P_VALUE is requested then the parameter has no effect.
/
/--------------------  OPTIONS USED WITH CONTINUOUS VARIABLES ---------------------------
/
/ CONTINUE =           List of continuous variables.
/                      The variables must be numeric.  Leave this list blank if
/                      there are no continuous variables.
/
/ P_CONT = NONE        P-Value options for continuous variables.  The current
/                      options are VANELT, ANOVA, PAIRED, and ANCOVA.
/
/                      The VANELT and ANOVA tests can be statified, through the
/                      CONTROL= option.
/
/                      The ANCOVA options used in conjuction with the COVARS=
/                      parameter can be used to request an analysis of covariance.
/
/                      The PAIRED test is a t-test for HO: mean=0.  See the
/                      TMTDIFF option when using PAIRED.  DO NOT USE THE PAIRED
/                      option with the PAIRWISE option below.  Note that PAIRED is
/                      a special case and this statistic may also be requested in
/                      the STATS= option.
/
/ TMTDIFF =            Use this option with P_CONT=PAIRED to tell SIMSTAT which level
/                      of the TMT variable contains the differences to be tested by
/                      the PAIRED test.
/
/ COVARS =             Use this option to tell the macro which variables to use as the
/                      covariates in an analysis of covariance.  The number of variables
/                      in this list must match exactly the number of variables in the
/                      CONTINUE= paramter. The following models are avaliable.
/
/                          y = tmt_var covar
/                          y = tmt_var control_var covar => when CONTROL= is used
/                          y = tmt_var|control_var covar => when CONTROL= and INTERACT
/
/
/ SS = SS3             The sum of squares type.
/
/ INTERACT = NO        Include interaction term in the ANOVA model.  This options requires
/                      the CONTROL= option.
/
/
/ STATS = N MEAN STD MEDIAN MIN MAX
/                      Use this parameter to request the calculation of summary
/                      statistics.  This list can include any statistic
/                      computed by PROC UNIVARIATE.  See documentation for that
/                      procedure for details.
/
/                      For continuous variables, the variables that contain the
/                      statistics in the output dataset are named using the option
/                      name. e.g. N=N MEAN=MEAN STD=STD etc.
/
/                      For discrete variables the only statistics computed are
/                      COUNT, N and PCT, and are so named.
/
/ PAIRWISE = NO        Use this option to control the production of pairwise
/                      tests.  If the levels of the TMT= variable are 1,2,3
/                      the macro produces p-values for the three levels of TMT
/                      combined plus 1vs2, 1vs3 and 2vs3.  The macro will name
/                      the variables as follows.
/
/                          PROB P1_2 P1_3 P2_3
/
/                      For all tests except ANOVA the pairwise p-values are
/                      produced by pairwise grouping the data and calling
/                      the procedure for each of these groups.
/                      For ANOVA tests the pairwise p-values are those produced
/                      by the LSMEANS statement using the PDIFF option.
/                      The overall test is an F test for TMT.
/
/ ORDER = INTERNAL     The order parameter can be use to change to ordering of
/                      values of DISCRETE variables to have them ordered by
/                      frequency.  Use DESCENDING or ASCENDING as you see fit.
/                      DTAB will then display the values using the frequency
/                      ordering.
/
/ PRINT = YES          Print the output data set?
/
/ ROW_ORDR =           Use the row ordering parameter to order the values of
/                      _VNAME_ in the output data set.
/                      Using this parameter causes the creation of a new
/                      numeric variable _ROW_.
/                      The output data set is then sorted by the BY variables
/                      and _ROW_.
/                      This parameter is not need if the output from SIMSTAT
/                      is to be displayed with DTABxx.  The row order
/                      in DTABxx is controlled in that macro call.
/ -----------------    --------------------------------------------------------
/
/==============================================================================
/
/ OUTSTAT Data Set
/
/ The OUTSTAT data set is a specially structured sas data set.  It contains
/ the followin variables.
/
/ BY
/   Variables specified in the BY= parameter.  These variables if any have the
/   same attributes as in the original data set.
/
/ TMT
/   The numeric treatment variable specified in the TMT= parameter.
/   This variable has the same name as specified in the TMT= parameter.
/
/ _NAME_
/   Contains the names of the analysis variables from the input data set.
/
/ _LEVEL_
/   Contains the values of the discrete variables from the input data.
/   This character variable is missing for continuous variables.
/
/ _VTYPE_
/   Identifies the analysis variables type. CONT, DISC, PTNO, 01.
/
/ _PTYPE_
/   Identifies the type of p-values computed for each variable. CHISQ,
/   EXACT, CMH, VANELT, ANOVA.
/
/ _CNTL_
/   If a controlling variable is used then this variable contains the
/   name name of that variable.
/
/ PROB
/   The overall p-value identified by _PTYPE_.
/
/ P1_2, P1_3, P2_3, ... Pn_n+1 chose two.
/   The pariwise p-values identified by _PTYPE_.
/
/ PR_CNTL
/   The pr>F when a ANCOVA with CONTROL= is used.
/
/ COUNT
/   The counts for each level of discrete variables.
/
/ PCT
/   The proportions (COUNT/N) for each level of discrete variables.
/
/ N
/   The number of observations.
/
/ MEAN
/   The mean.
/
/ Other requested statistics as per STATS= parameter.
/
/ NOTES:
/
/ If a discrete variable has missing (blank) values the macro produces
/ observations to hold the counts for these missing values.  The macro uses
/ values of _LEVEL_='_' for these counts.
/
/
/ EXAMPLE OUTPUT DATA SET:
/
/ The following macro call,
/
/
/   %simstat(data = demo,
/              by = ptcd,
/             tmt = ntmt,
/        pairwise = yes,
/           stats = n mean sum std min max,
/        discrete = sex,
/          p_disc = exact,
/        continue = age,
/          p_cont = anova)
/
/ produced the output shown below.
/
/ DATA=SIMSTAT
/
/ OBS  PTCD      _NAME_  NTMT  _LEVEL_  _VTYPE_  _PTYPE_   N     MEAN    SUM
/
/   1  S3A258     AGE      1             CONT     ANOVA   120  61.1250  7335
/   2  S3A258     AGE      2             CONT     ANOVA   120  61.0833  7330
/   3  S3A258     AGE      3             CONT     ANOVA   120  61.6417  7397
/   4  S3A258     SEX      1      F      DISC     EXACT   120    .         .
/   5  S3A258     SEX      2      F      DISC     EXACT   119    .         .
/   6  S3A258     SEX      3      F      DISC     EXACT   120    .         .
/   7  S3A258     SEX      1      M      DISC     EXACT   120    .         .
/   8  S3A258     SEX      2      M      DISC     EXACT   119    .         .
/   9  S3A258     SEX      3      M      DISC     EXACT   120    .         .
/  10  S3A258     SEX      1      _      DISC     EXACT     .    .         .
/  11  S3A258     SEX      2      _      DISC     EXACT     .    .         .
/  12  S3A258     SEX      3      _      DISC     EXACT     .    .         .
/
/ OBS    STD    MAX  MIN  COUNT    PCT      PROB     P1_2     P1_3     P2_3
/
/   1  7.30093   76   50     .    .       0.81358  0.96569  0.59389  0.56449
/   2  7.25940   78   50     .    .       0.81358  0.96569  0.59389  0.56449
/   3  7.91849   79   50     .    .       0.81358  0.96569  0.59389  0.56449
/   4   .         .    .    64   0.53333  0.33527  0.24516  1.00000  0.19659
/   5   .         .    .    54   0.45378  0.33527  0.24516  1.00000  0.19659
/   6   .         .    .    65   0.54167  0.33527  0.24516  1.00000  0.19659
/   7   .         .    .    56   0.46667  0.33527  0.24516  1.00000  0.19659
/   8   .         .    .    65   0.54622  0.33527  0.24516  1.00000  0.19659
/   9   .         .    .    55   0.45833  0.33527  0.24516  1.00000  0.19659
/  10   .         .    .     0    .       0.33527  0.24516  1.00000  0.19659
/  11   .         .    .     1    .       0.33527  0.24516  1.00000  0.19659
/  12   .         .    .     0    .       0.33527  0.24516  1.00000  0.19659
/
/
/
/
/----------------------------------------------------------------------------*/

%macro simstat(data = _LAST_,
            outstat = SIMSTAT,
           uniqueid = ,
            uspatno = ,
                tmt = ,
            tmtexcl = (1),
                 by = ,
            control = ,
             scores = TABLE,
                 ss = SS3,
           interact = NO,
             covars = ,
              stats = ,
           discrete = ,
             p_disc = NONE,
            dlevels = ,
              dexcl = ,
           continue = ,
             p_cont = NONE,
            tmtdiff = ,
              yesno = ,
                yes = Y,
           yn_order = DEFAULT,
           orderval = COUNT,
              print = YES,
           pairwise = NO,
           row_ordr = ,
              order = INTERNAL,
            sasopts = NOSYMBOLGEN NOMLOGIC);

   options &sasopts;

   /*
   / JMF002
   / Display Macro Name and Version Number in LOG
   /-------------------------------------------------------------*/

   %put -----------------------------------------------------;
   %put NOTE: Macro called: SIMSTAT.SAS   Version Number: 1.2;
   %put -----------------------------------------------------;


   %global vsimstat;
   %let vsimstat=1.1;

   /*
   / Uppercase macro parameters and setup default values
   / for parms that must not be missing
   /-------------------------------------------------------------*/

   %let discrete = %upcase(&discrete);
   %let yesno    = %upcase(&yesno);

   %let discrete = &discrete &yesno;
   %let scores   = %upcase(&scores);

   %let dlevels  = %upcase(&dlevels);
   %let continue = %upcase(&continue);

   %let print    = %upcase(&print);
   %let data     = %upcase(&data);
   %let order    = %upcase(&order);
   %let yn_order = %upcase(&yn_order);

   %local erdash;
   %let erdash = ERROR: _+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_;

   %if &data=_LAST_ | %length(&data)=0 %then %let data=&syslast;
   %if &data=_NULL_ %then %do;
      %put &erdash;
      %put ERROR: There is no DATA= data set;
      %put &erdash;
      %goto EXIT;
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

   %if %length(&tmt)=0 %then %do;
      %put &erdash;
      %put ERROR: TMT Must not be blank;
      %put &erdash;
      %goto EXIT;
      %end;

   %if %index(&uniqueid,&control) %then %do;
      %put &erdash;
      %put ERROR: Your CONTROLling variable is also in UNIQUEID,;
      %put ERROR: this could cause problems for SIMSTAT.;
      %put ERROR: Rename the CONTROLling variable and try again.;
      %put &erdash;
      %goto exit;
      %end;

   %if &row_ordr^= %then %do;
      %if &yn_order^=DEFAULT %then %do;
         %put &erdash;
         %put ERROR: YN_ORDER and ROW_ORDR are incompatable options;
         %put &erdash;
         %goto exit;
         %end;
      %end;

   %let pairwise = %upcase(&pairwise);
   %if "&pairwise"="YES"
      %then %let pairwise=1;
      %else %let pairwise=0;

   %if "&discrete" > "" %then %do;
      %local xdn0;
      %let   xdn0 = %jkxwords(list=&discrete,root=);
      %if &xdn0 > 26 %then %do;
         %put &erdash;
         %put ERROR: You may not use more than 26 YESNO and DISCRETE variables;
         %put ERROR: Use two or more calls to SIMSTAT with 26 or less variables;
         %put &erdash;
         %goto EXIT;
         %end;

      %if %length(&dlevels)>0 & %index("&dlevels",\) = 0 %then %do;
         %put &erdash;
         %put ERROR: You need to delimit DLEVELS= with a backslash \;
         %put &erdash;
         %goto EXIT;
         %end;

      /*
      / Check p-value request for discrete variables
      /------------------------------------------------*/

      %let p_disc   = %upcase(&p_disc);

      %if "&p_disc"="" %then %let p_disc=NONE;

      %if ^%index(CHISQ CMH CMHCOR CMHRMS CMHGA EXACT NONE,&p_disc) %then %do;
         %put &erdash;
         %put ERROR: The type of p-values requested for discrete variables is invalid.;
         %put &erdash;
         %goto EXIT;
         %end;

      %if "&control" > "" & %index(CHISQ EXACT,&p_disc) %then %do;
         %put &erdash;
         %put ERROR: You cannot request Fishers EXACT or Chi Square test with a controlling variable.;
         %put &erdash;
         %goto EXIT;
         %end;

      %end;

   %if "&continue" > "" %then %do;

      /*
      / Check p-value requests for continue variables
      /------------------------------------------------*/

      %let p_cont   = %upcase(&p_cont);
      %let interact = %upcase(&interact);
      %let covars   = %upcase(&covars);

      %if "&p_cont" = "" %then %let p_cont=NONE;

      %if ^%index(ANOVA ANCOVA CMHRMS VANELT NONE PAIRED,&p_cont) %then %do;
         %put &erdash;
         %put ERROR: The type of p-values requested for continue variables is invalid.;
         %put &erdash;
         %goto EXIT;
         %end;

      %if "&interact" = "YES" & "&control"="" %then %do;
         %put &erdash;
         %put ERROR: You have specified INTERACT=YES but CONTROL= is blank.;
         %put &erdash;
         %goto EXIT;
         %end;

      %if "&covars" = "" & "&p_cont"="ANCOVA" %then %do;
         %put &erdash;
         %put ERROR: You MUST have COVARS= when you specify P_CONT=ANCOVA.;
         %put &erdash;
         %goto EXIT;
         %end;

      %if &pairwise & "&p_cont"="PAIRED" %then %do;
         %put &erdash;
         %put ERROR: The Paired test for continuous variables is not valid with PAIRWISE=YES.;
         %put &erdash;
         %goto EXIT;
         %end;

      %if "&covars" > "" %then %do;
         %local _xcv0 _xvv0;
         %let _xcv0 = %jkxwords(list=&covars,root=);
         %let _xvv0 = %jkxwords(list=&continue,root=);
         %if &_xcv0 ^= &_xvv0 %then %do;
            %put &erdash;
            %put ERROR: You must have an EQUAL number of COVARiateS and CONTINUE variables.;
            %put &erdash;
            %goto EXIT;
            %end;
         %end;

      %if "&covars" > "" & "&p_cont"^="ANCOVA" %then %do;
         %put &erdash;
         %put ERROR: You MUST have P_CONT=ANCOVA when you specify Covariates.;
         %put &erdash;
         %goto EXIT;
         %end;
      %end;

   /*
   / Call CHKDATA macro.  This is used to verify the existance of the input data
   / and variables.
   /---------------------------------------------------------------------------*/

   %jkchkdat(data=&data,
             vars=&by &uniqueid &control,
            nvars=&continue &tmt &covars,
            cvars=&discrete)

   %if &RC %then %goto EXIT;

   /*
   / Create macro variables to hold the names of temporary data sets.  Use
   / SYSINDEX to return a unique number to name the data sets.
   /-------------------------------------------------------------------------*/

   %local subset temp1 temp2 _disc_ _cont_ _disc2_ _cont2_ _pdisc_ _pcont_ _patno_;

   %let subset  = _0_&sysindex;
   %let temp1   = _1_&sysindex;
   %let temp2   = _2_&sysindex;
   %let _patno_ = _3_&sysindex;
   %let _disc_  = _5_&sysindex;
   %let _disc2_ = _6_&sysindex;
   %let _pdisc_ = _7_&sysindex;
   %let _cont_  = _8_&sysindex;
   %let _cont2_ = _9_&sysindex;
   %let _pcont_ = _A_&sysindex;
   %let dups    = _B_&sysindex;
   %let _lsm_   = _C_&sysindex;
   %let _pairt_ = _D_&sysindex;

   %local id;

   /*
   / Set up default STATS, if stats is blank then assign it.
   / If STATS is provided by the user then add N MEAN and SUM to the
   / list just in case the user left it off.  If the user did include
   / N MEAN and SUM these will then be in the list twice, however
   / PROC UNIVARIATE doesn't mind if you ask for a statistic more than
   / once.
   / If the user requested statistics then we need to check their
   / validity against what can be done by proc univariate.
   /--------------------------------------------------------------------*/

   %if "&stats" = "" %then %let stats = N MEAN STD MEDIAN MIN MAX;
   %else %do;
      %jkchklst(list=&stats,against=UNISTATS,return=RC2)
      %if &rc2 %then %goto EXIT;
      %end;

   %let stats    = %upcase(&stats);

   %let tmt      = %upcase(&tmt);

   %if %index(&p_cont,CMH) | %index(&p_cont,VAN) %then %let p_cont=CMHRMS;

   %if "&control"="" %then %let control=_ONE_;
   %let control  = %upcase(&control);

   %local kontrol;
   %if "&control"="_ONE_" %then %do;
      %let kontrol = ;
      %end;
   %else %do;
      %let kontrol = &control;
      %end;

   %let data    = %upcase(&data);
   %let outstat = %upcase(&outstat);

   %let _by0=%jkxwords(list=&by,root=_by);

   /*
   / Create a temporary dataset subsetting the variables
   / to only include those variables nessary for the
   / analysis to be performed.
   /------------------------------------------------------*/

   proc sort
      data = &data
         (
         keep=&by &uniqueid &tmt &kontrol &discrete &continue &covars
         )
      out  = &temp1;

      by &by &uniqueid &tmt;
      format _all_;
      run;

   %put NOTE: PROC SORT SYSINFO=&sysinfo, SYSRC=&SYSRC, SYSERR=&SYSERR;

   /*
   / Create variable _ONE_ and check that the data is unique for each patient
   / number.  If not stop the macro.
   /-------------------------------------------------------------------------*/

   %local dupflag;
   %let dupflag = 0;

   data &temp1 &dups;
      set &temp1;
      by &by &uniqueid &tmt;

   %if &_by0 > 0 %then %do;
      if first.&&_by&_by0 then _BYID_ + 1;
      %end;
   %else %do;
      retain _byid_ 1;
      %end;

      if ^(first.&tmt & last.&tmt) then do;
         output &dups;
         call symput('DUPFLAG','1');
         end;

      output &temp1;

      retain _one_ 1;
      format _all_;
      run;

   %if &dupflag %then %do;
      title5 'Duplicates found in input data, correct and resubmit';
      proc print data=&dups;
         run;
      title5;
      %put &erdash;
      %put ERROR: MACRO simstat, Duplicates found in input data.;
      %put &erdash;
      %goto EXIT;
      %end;

   data &subset;
      set &temp1(where=(&tmtexcl));
      run;

   proc sort data=&subset;
      by &by &kontrol &uniqueid &tmt;
      run;

   /*
   / Compute the frequency counts for the NUMBER of patients
   / variable.  This is a count of the observations in each
   / level of treatment.
   /-----------------------------------------------------------*/

   proc summary data=&temp1 nway;
      by &by;
      class &tmt;
      output out=&_patno_(drop=_type_ rename=(_freq_=n));
      run;

   data &_patno_;
      set &_patno_;
      length _vname_ $8 _vtype_ $8;
      retain _vname_ '_PATNO_' _vtype_ 'PTNO';
      run;

   %if %length(&discrete) > 0 %then %do;

      %jkdisc01(data=&temp1,
                 out=&_disc_,
                  by=&by,
                 var=_one_,
             uniqueid=&uniqueid,
                 tmt=&tmt,
               print=NO,
            discrete=&discrete,
             dlevels=&dlevels,
               dexcl=&dexcl)

      proc sort data=&_disc_;
         by &by _vname_ _vtype_;
         run;

      %if %index(CMHRMS CMHGA CMHCOR CHISQ EXACT CMH,&p_disc) %then %do;

         %if "&control"="_ONE_" %then %do;

            %jkdisc01(data=&subset,
                       out=&_disc2_,
                        by=&by,
                       var=_one_,
                   uniqueid=&uniqueid,
                       tmt=&tmt,
                     print=NO,
                  discrete=&discrete,
                   dlevels=&dlevels,
                     dexcl=&dexcl)

            proc sort data=&_disc2_;
               by &by _vname_ _vtype_;
               run;

            data &_disc2_;
               set &_disc2_;
               if _level_ = '_' then delete;
               retain _one_ 1;
               run;
            %let id = ;
            %end;

         %else %do;
            %jkdisc01(data=&subset,
                       out=&_disc2_,
                        by=&by &control,
                       var=_one_,
                   uniqueid=&uniqueid,
                       tmt=&tmt,
                     print=NO,
                  discrete=&discrete,
                   dlevels=&dlevels,
                     dexcl=&dexcl)

            data &_disc2_;
               set &_disc2_;
               if _level_ = '_' then delete;
               retain _one_ 1;
               run;
            %let id = ;
            %end;

         %if &pairwise %then %do;
            %jkpaired(chkdata = NO,
                         data = &_disc2_,
                        where = _level_^='_',
                          out = &_disc2_,
                           by = &by _vname_ _vtype_,
                         pair = &tmt,
                       sortby = ,
                       idname = _id_,
                           id = %str(compress(put(_1,3.)||'_'||put(_2,3.),' ')) )

            %let id = _id_;
            %end;

         %jkpval05(data=&_disc2_,
                    out=&_pdisc_,
                     by=&by _vname_ _vtype_,
                     id=&id,
               uniqueid=&uniqueid,
                control=&control,
                 scores=&scores,
                    tmt=&tmt,
               response=_level_,
                 weight=count,
                p_value=&p_disc,
                vartype=discrete,
               pairwise=&pairwise)

         proc delete data=&_disc2_;
            run;

         data &_disc_;
            merge &_disc_ &_pdisc_;
            by &by _vname_ _vtype_;
            run;

         %end /* endif for p_values were requested */;

      /*
      title5 "DATA=&_disc_ _DISC_ the discrete variables";
      proc print data=&_disc_;
         run;
      title5;
      */

      %end /* endif discrete variables exist */;

   %else %do;
      %let _disc_ =;
      %end;

   /*
   / P value processing for the continuous variables, if no pvalues
   / are requested then this section of the macro is skipped
   /------------------------------------------------------------------*/

   %if %length(&continue) > 0 %then %do;

      %jkcont01(data=&temp1,
                 out=&_cont_,
                  by=&by,
                 tmt=&tmt,
            uniqueid=&uniqueid,
                 var=&continue,
               stats=&stats,
               print=NO)

      %if "&p_cont" = "CMHRMS" %then %do;

         %if &pairwise %then %do;
            %jkpaired(chkdata = NO,
                         data = &subset,
                        where = ,
                          out = &_cont2_,
                           by = &by,
                         pair = &tmt,
                       sortby = ,
                       idname = _id_,
                           id = %str(compress(put(_1,3.)||'_'||put(_2,3.),' ')) )

            %let id = _id_;
            %end;
         %else %do;
            %let id = ;
            %let _cont2_ = &subset;
            %end;

         %jkpval05(data=&_cont2_,
                    out=&_pcont_,
                     by=&by,
                     id=&id,
               uniqueid=&uniqueid,
                control=&control,
                    tmt=&tmt,
               response=,
                p_value=&p_cont,
                vartype=CONTINUE,
               pairwise=&pairwise);

         data &_cont_;
            merge &_cont_ &_pcont_;
            by &by _vname_;
            length _vtype_ $8;
            retain _vtype_ 'CONT';
            run;

         proc delete data=&_pcont_;
            run;
         %end;

      %else %if "&p_cont" = "ANOVA" %then %do;

         %jkpval04(data=&subset,
                   out=&_pcont_,
                    by=&by,
               control=&control,
              interact=&interact,
                    ss=&ss,
                   tmt=&tmt,
              continue=&continue,
              pairwise=&pairwise,
                 print=NO)

         data &_cont_;
            merge &_cont_ &_pcont_;
            by &by _vname_ &tmt;
            length _vtype_ $8;
            retain _vtype_ 'CONT';
            run;

         proc delete data=&_pcont_;
            run;

         %end;

      %else %if "&p_cont" = "ANCOVA"  & "&covars" > "" %then %do;

         %jkpval04(data=&subset,
                   out=&_pcont_,
                    by=&by,
                covars=&covars,
               control=&control,
              interact=&interact,
                    ss=&ss,
                   tmt=&tmt,
              continue=&continue,
              pairwise=&pairwise,
                 print=NO)

         data &_cont_;
            merge &_cont_ &_pcont_;
            by &by _vname_ &tmt;
            length _vtype_ $8;
            retain _vtype_ 'CONT';
            run;

         proc delete data=&_pcont_;
            run;
         %end;

      %else %if "&p_cont" = "PAIRED" %then %do;
         %jkpval05(data=&subset,
                    out=&_pcont_,
                     by=&by,
                     id=&id,
               uniqueid=&uniqueid,
                control=,
                    tmt=&tmt,
                tmtdiff=&tmtdiff,
               response=,
                p_value=&p_cont,
                vartype=CONTINUE,
               pairwise=&pairwise)

         data &_cont_;
            merge &_cont_ &_pcont_;
            by &by _vname_;
            length _vtype_ $8;
            retain _vtype_ 'CONT';
            run;

         proc delete data=&_pcont_;
            run;

         %end;

      %else %do;

         data &_cont_;
            set &_cont_;
            length _vtype_ $8;
            retain _vtype_ 'CONT';
            run;

         %end;

      /*
      title5 "DATA=&_cont_ _CONT_  The continuous variables";
      proc print data=&_cont_;
         run;
      title5;
      */

      %end /* if continue variables exist 0 */;

   %else %do;
      %let _cont_ = ;
      %end;

   data &outstat;
      retain &by _vname_ &tmt _order_ _level_ _vtype_
            _ptype_ _covar_ _cntl_;

      length _order_ 8 _cntl_ $8 _level_ $8;

   %if %length(&kontrol) > 0 %then %do;
      retain _cntl_ "&kontrol";
      %end;

      set &_disc_ &_cont_ &_patno_;
      by &by _vname_;

   %if %length(&yesno)>0 %then %do;
      if indexw("&yesno",trim(_vname_)) then do;
         if _level_ ^= "&yes" then delete;
         _vtype_ = 'YESNO';
         end;
      %end;

   %local _row_;
   %if "&row_ordr"^="" %then %do;
      %jkrord(rowvars=&row_ordr)
      %end;

      label
         _row_   = 'Order variable for _VNAME_ variables'
         _vname_ = 'Analysis variables original name'
         _order_ = 'Order variable for _LEVEL_'
         _level_ = 'Values of original discrete variables'
         _vtype_ = 'Analysis variable type'
         _ptype_ = 'Statistical test used for PROB'
         _covar_ = 'The covariate'
         _cntl_  = 'The controlling variable'
         _scores_= 'Value used in PROC FREQ scores option'
         n       = 'n'
         nmiss   = 'n Missing'
         max     = 'Max.'
         min     = 'Min.'
         mean    = 'Mean'
         median  = 'Median'
         q1      = '25th percentile'
         q3      = '75th percentile'
         mode    = 'Mode'
         std     = 'SD'
         stdmean = 'Std Error'
         sum     = 'Sum'
         count   = 'Frequency'
         pct     = 'Proportions'
         prob    = 'P-values'
         lsm     = 'Mean (adj)'
         lsmse   = 'se'
         sse     = 'Error SS'
         dfe     = 'Error df'
         mse     = 'MSE'
         rootmse = 'Root MSE'
         pr_cntl = 'P-value for controlling variable'
         ;
      run;

   %if "&row_ordr"^="" %then %do;
      %let _row_ = _row_;
      proc sort data=&outstat;
         by &by &_row_;
         run;
      %end;

   /*
   / Process the data for the ORDER= option
   /-------------------------------------------------------*/

   %local rs_order;
   %if %index(&order,DESCEND) | %index(&order,ASCEND) %then %do;

      %let rs_order = _&sysindex._A;

      /*
      / Compute the row totals for use in _ORDER_ variable
      /-----------------------------------------------------*/

      proc summary data=&outstat nway missing;
         class &by &_row_ _vname_ _level_;
         var &orderval;
         output
            out=&rs_order(drop=_type_ _freq_)
            sum=_order_;
         run;

      data &outstat;
         merge
            &outstat
               (
                drop=_order_
               )
            &rs_order
               (
                keep = &by &_row_ _vname_ _level_ _order_
               )
            ;

         by &by &_row_ _vname_ _level_;

         %if %index(&order,DESCEND) %then %do;
            _t__ = _order_ * -1;
            drop _order_;
            rename _t__ = _order_;
            %end;
         run;

      proc sort data=&outstat;
         by &by &_row_ _vname_ _order_ _level_;
         run;

      %end;

   /*
   / Process the data for the YN_ORDER= option
   /--------------------------------------------------------*/

   %local yn_data;
   %if %index(&YN_order,DESCEND) | %index(&YN_order,ASCEND) %then %do;

      %let yn_data = _&sysindex._A;

      /*
      / Compute the row totals for use in _ORDER_ variable
      /-----------------------------------------------------*/

      proc summary
            nway missing
            data=&outstat(where=(_vtype_='YESNO'));

         class &by _vname_ _vtype_;
         var &orderval;
         output
            out=&yn_data(drop=_type_ _freq_)
            sum=_order_;
         run;

      %local YN_SORT;
      %if %index(&yn_order,DESCEND) %then %let yn_sort = DESCENDING;

      proc sort data=&yn_data;
         by &by &yn_sort _order_;
         run;

      %local _YNO_0 YNI;

      %let _yno_0 = 0;

      %global YN_OLIST;
      %let    yn_olist = ;

      data _null_;
         set &yn_data end=eof;

         length ci $8;
         ci = left(put(_n_,8.));

         call symput('_YNO_'||ci , trim(_vname_));

         if eof then do;
            call symput('_YNO_0' , trim(ci));
            end;

         run;

      %do YNI = 1 %to &_yno_0;
         %let yn_olist = &yn_olist &&_yno_&yni;
         %end;

      %put NOTE: You have specified YN_ORDER=&yn_order, SIMSTAT has created YN_OLIST as follows:;
      %put NOTE: YN_OLIST=&yn_olist;

      %end;

   proc delete
      data=&subset &temp1 &temp2 &dups &_patno_ &_cont_ &_cont2_
           &_disc_ &_disc2_ &_pcont_ &_pdisc_ &rs_order yn_data;
      run;

   %if "&print"="YES" %then %do;
      title5 "DATA=&outstat";
      proc contents data=&outstat;
         run;
      proc print data=&outstat;
         by &by;
         run;
      %end;

 %EXIT:
   %put NOTE: MACRO simstat Ending execution.;
   %mend simstat;
