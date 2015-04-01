/*
/ Program name:     IMPORT.SAS
/
/ Program version:  2.1
/
/ Program purpose:  Makes SAS transport files with the XPORT engine.
/
/ SAS version:      6.12 TS020
/
/ Created by:
/ Date:
/
/ Input parameters: IN      - Input filename & path
/                   OUT     - Output location
/                   SELECT  - PROC COPY select option
/                   EXCLUDE - PROC COPY exclude option
/                   ENGINE  - Libname engine option
/                   OUTDD   - Default output libname
/                   INDD    - Default input libname
/
/ Output created:
/
/ Macros called:    None
/
/ Example call:     %import(in =/projects/p999/sas/data/raw/data.xpt,
/                           out=/home/d86/test);
/
/==================================================================================
/ Change log:
/
/    MODIFIED BY: Jonathan Fry
/    DATE:        09DEC1998
/    MODID:       JMF001
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 2.1.
/    ------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX002
/    DESCRIPTION:
/    ------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX003
/    DESCRIPTION:
/    ------------------------------------------------------------------
/=================================================================================*/

%macro import(in = ,
             out = WORK,
          select = ,
         exclude = ,
          engine = saseb,
           outdd = _ZOUTZ_,
            indd = _XINX_);

/*-----------------------------------------------------------------------/
/ JMF001                                                                 /
/ Display Macro Name and Version Number in LOG                           /
/-----------------------------------------------------------------------*/

   %put ------------------------------------------------------;
   %put NOTE: Macro called: IMPORT.SAS     Version Number: 2.1;
   %put ------------------------------------------------------;

   %if %substr(&sysver,1,1)<6 %then %do;
      %put ERROR: Macro IMPORT requires Version 6 or higher;
      %put NOTE: Your are using version &sysver;
      %if &sysenv=BACK %then %do ;
        endsas;
      %end ;
   %else %goto macexit ;
   %end;
   %if "&in"="" %then %do;
      %put ERROR: You must specify an input transport filename;
      endsas;
   %end;
   %if "&out"="" %then %do;
      %put ERROR: You must specify a valid output data library;
      endsas;
   %end;

   %if "&select" ~=""    %then %let select  = SELECT &select %str(;);
   %if "&exclude"~=""    %then %let exclude = EXCLUDE &exclude %str(;);

   filename &indd DISK "&in";
   libname  &indd xport;

   %if "&out"~="WORK" %then %do;
      libname &outdd &engine "&out";
   %end ;
   %else %let outdd=WORK;

   proc copy in=&indd out=&outdd;
      &select
      &exclude
   run;

   filename &indd clear;
   libname  &indd clear;

   %if "&out"~="WORK" %then %do;
      libname &outdd clear;
   %end;
   %macexit:
%mend import;
