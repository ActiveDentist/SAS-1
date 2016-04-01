/*
/ Program name: labels.sas
/
/ Program version: 2.1
/
/ Program purpose: Apply labels to variables with recognised names.
/
/ SAS version: 6.12 TS020
/
/ Created by: Andrew Ratcliffe, SPS Limited
/ Date: ?
/
/ Input parameters: data     - input library & file
/                   out      - output library & file
/                   override - replace existing labels?
/                   length   - length of labels(short, long, shortest, longest)
/                   fmtlib   - format library which holds $labels macro
/                   tidy     - delete temporary datasets?
/                   pfx      - prefix of temporary work files
/                   verbose  - verbosity of messages
/
/ Output created:
/
/ Macros called: None
/
/ Example call:
/
/                   %labels(data=g123.ld01);
/
/=============================================================================
/ Change log:
/
/    MODIFIED BY: ABR
/    DATE:        23SEP1992
/    MODID:       Ver 1.1
/    DESCRIPTION: Original Version
/    --------------------------------------------------------------------
/    MODIFIED BY: ABR
/    DATE:        28SEP1992
/    MODID:       Ver 1.2
/    DESCRIPTION: Put labels in external table to improve speed.
/                 Provide larger table.
/                 Add TABLE option.
/    --------------------------------------------------------------------
/    MODIFIED BY: ABR
/    DATE:        12OCT1992
/    MODID:       Ver 1.3
/    DESCRIPTION: Change TABLE option to FMTLIB to improve speed.
/    --------------------------------------------------------------------
/    MODIFIED BY: ABR
/    DATE:        02DEC1992
/    MODID:       Ver 1.4
/    DESCRIPTION: Remove default for FMTLIB.
/    --------------------------------------------------------------------
/    MODIFIED BY: ABR
/    DATE:        09FEB1993
/    MODID:       Ver 1.5
/    DESCRIPTION: Add LENGTH parameter.
/    --------------------------------------------------------------------
/    MODIFIED BY: Jonathan Fry
/    DATE:        09DEC1998
/    MODID:       JMF001
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 2.1.
/    --------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX002
/    DESCRIPTION:
/    --------------------------------------------------------------------
/=============================================================================*/

 %macro labels(data     = ,
               out      = ,
               override = n,
               length   = longest,
               fmtlib   = ,
               pfx      = lbl_,
               tidy     = y,
               verbose  = 2);

     /*
     / JMF001
     / Display Macro Name and Version Number in LOG
     /--------------------------------------------------------*/

     %put ----------------------------------------------------;
     %put NOTE: Macro called: LABELS.SAS   Version Number: 2.1;
     %put ----------------------------------------------------;


 %let tidy = %upcase(&tidy);
 %let length = %upcase(&length);
 %let fmtlib = %upcase(&fmtlib);
 %let override = %upcase(&override);

 %if &override ne Y and &override ne N %then %do;
   %put WARNING: LABELS: "&override" is an invalid value for OVERRIDE.;
   %let override = N;
   %put WARNING: LABELS: OVERRIDE has been set to "&override".;
   %end;
 %if &length ne SHORT    and &length ne LONG    and
     &length ne SHORTEST and &length ne LONGEST %then %do;
   %put WARNING: LABELS: "&length" is an invalid value for LENGTH.;
   %let length = LONGEST;
   %put WARNING: LABELS: LENGTH has been set to "&length".;
   %end;
 %if %length(&pfx) gt 4 %then %do;
   %put WARNING: LABELS: "&pfx" exceeds maximum length for PFX.;
   %let pfx = %substr(&pfx,1,4);
   %put WARNING: LABELS: PFX has been truncated to "&pfx".;
   %end;
 %if %index(0123456789,&verbose) eq 0 %then %do;
   %put WARNING: LABELS: "&verbose" is an invalid value for VERBOSE.;
   %let verbose = 2;
   %put WARNING: LABELS: VERBOSE has been set to "&verbose".;
   %end;
 %if %length(&out) eq 0 %then %do;
   %let out = &data;
   %if &verbose ge 3 %then %do;
     %put NOTE: LABELS: No output file specified.;
     %put               Input file will be used for output.;
     %end;
   %end;

   %if %length(&fmtlib) gt 0 %then %do;
     LIBNAME library "&fmtlib";
     %end;
   libname library "/usr/local/medstat/sas/formats";

   proc contents data=&data out=&pfx.0010 noprint;

   %let lvnum = 0;

   data _null_;
     set &pfx.0010;
     retain tot 0;
     length msg $80;
     length labelt $40;
     msg = '';  /* Avoid messages about msg being uninitialised */
     %if &override eq N %then %do;
       if label ne '' then do;
         %if &verbose ge 3 %then %do;
           msg = 'NOTE: LABELS: Label already exists for '
                 || compress(name)
                 || '. No over-ride requested.'
                 ;
           put msg;
           %end;
         delete;
         end;
       %end;
                            /* Let's go get a label */
     if "%substr(&length,1,1)" eq 'S' then do;
       labelt = put(name,$labels.);
       if labelt = '' and
          "%substr(&length,%eval(%length(&length)-2),3)" eq 'EST' then do;
         %if &verbose ge 3 %then %do;
           msg = 'NOTE: LABELS: No known short label for '
                 || compress(name)
                 || '.'
                 ;
           put msg;
           %end;
         labelt = put(name,$labell.);
         end;
       end;
     else do; /* Must be an L */
       %if &verbose ge 9 %then %do;
         put 'DEBUG: LABELS: Looking for a long(est) label. ' name=;
         %end;
       labelt = put(name,$labell.);
       if labelt = '' and
          "%substr(&length,%eval(%length(&length)-2),3)" eq 'EST' then do;
         %if &verbose ge 3 %then %do;
           msg = 'NOTE: LABELS: No known long label for '
                 || compress(name)
                 || '.'
                 ;
           put msg;
           %end;
         labelt = put(name,$labels.);
         end;
       end;

     if labelt = '' then do;
       %if &verbose ge 3 %then %do;
         msg = 'NOTE: LABELS: No known label for '
               || compress(name)
               || '. None supplied.'
               ;
         put msg;
         %end;
       delete;
       end;
     tot = tot + 1;
     call symput('lvn'||compress(put(tot,best.)),name);  /* Name  */
     call symput('lv'||compress(put(tot,best.)),labelt); /* Label */
     call symput('lvnum',put(tot,best.));

 %if &data ne &out %then %do;
   data &out;
     set &data;
   %end;

 %let dotpos = %index(&out,.);
 %if &dotpos eq 0 %then %do;
   %let olib =;
   %let ofile = &out;
   %end;
 %else %do;
   %let olib = %substr(&out,1,&dotpos-1);
   %let ofile = %substr(&out,&dotpos+1,%length(&out)-&dotpos);
   %end;

   proc datasets nolist
     %if %length(&olib) gt 0 %then %do;
       lib=&olib
       %end;
     ;
     modify &ofile;
     %do i = 1 %to &lvnum;
       label &&lvn&i = "&&lv&i";
       %end;
     quit;

 %if &tidy eq Y %then %do;
    proc datasets lib=work nolist;
      delete &pfx.0010;
      quit;
    %end;
  %else %do;
    %if &verbose ge 3 %then %do;
      %put NOTE: LABELS: As requested, temporary datasets not deleted.;
      %end;
    %end;

   run;

   %mend labels;
