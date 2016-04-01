/*
/ Program Name:     STATINIT.SAS
/
/ Program Version:  3.1
/
/ Program purpose:  Initialise the environment in preparation for the statistical
/                   macros. In practice, this means allocating a few libraries.
/
/ SAS Version:      6.12
/
/ Created By:       Andrew Ratcliffe, SPS Limited
/ Date:             January 1993
/
/ Input Parameters: UTILDATA = Physical name of library containing data and tables.
/                   UTILFMT  = Physical name of library containing format.
/                   UTILGDEV = Physical name of library containing user-written
/                              graphical devices.
/                   GDEVNUM  = Numeric suffix of libname to which UTILGDEV is to be
/                              allocated, ie. GDEVICEn.
/                   UTILSCL  = Physical name of library containing SCL code.
/                   UTILIML  = Physical name of library containing IML code.
/                   TIDY     = Delete temporary datasets?
/                   PFX      = Prefix of temporary work files. Provided for compatibility
/                              only - %STATINIT does not use any temp files.
/                   VERBOSE  = Verbosity of messages
/
/ Output Created:
/
/ Macros Called:    %FN
/
/ Example Call:     %statinit;
/
/============================================================================================
/Change Log
/
/    MODIFIED BY: ABR      (Original version)
/    DATE:        Jan93
/    MODID:       1
/    DESCRIPTION: Avoid UTILFMT being added to FMTSEARCH more than once.
/    ---------------------------------------------------------------------------------
/    MODIFIED BY: ABR
/    DATE:        10Feb93
/    MODID:       2
/    DESCRIPTION: Add dump=n to %getopts.
/    ---------------------------------------------------------------------------------
/    MODIFIED BY: ABR
/    DATE:        06Apr93
/    MODID:       3
/    DESCRIPTION: Add OS/2.
/    ---------------------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:        14Jun93
/    MODID:       4
/    DESCRIPTION: Add SUN 4.
/    ---------------------------------------------------------------------------------
/    MODIFIED BY: AGW
/    DATE:        20Mar97
/    MODID:       5
/    DESCRIPTION: Only SUN 4, for SPLASH project.
/                 No need for %GETOPTS, %BWSYSIN.
/    ---------------------------------------------------------------------------------
/    MODIFIED BY: AGW
/    DATE:        20Jun97
/    MODID:       6
/    DESCRIPTION: Correction of &utilgdev (GDEVICEn) error.
/    ---------------------------------------------------------------------------------
/    MODIFIED BY: Jonathan Fry
/    DATE:        10DEC1998
/    MODID:       JMF001
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 3.1.
/    ---------------------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX002
/    DESCRIPTION:
/    ---------------------------------------------------------------------------------
/============================================================================================*/

   %macro statinit(utildata = _DEFAULT_
                  ,utilgdev = _DEFAULT_
                  ,gdevnum  = 0
                  ,utilfmt  = _DEFAULT_
                  ,utilscl  = _DEFAULT_
                  ,utiliml  = _DEFAULT_
                  ,tidy=y
                  ,pfx=sti_
                  ,verbose=2
                  );

/*------------------------------------------------------------------------------/
/ JMF001                                                                        /
/ Display Macro Name and Version Number in LOG                                  /
/------------------------------------------------------------------------------*/

   %put ------------------------------------------------------;
   %put NOTE: Macro called: STATINIT.SAS   Version Number: 3.1;
   %put ------------------------------------------------------;

     %let tidy = %upcase(&tidy);

     %if %length(&pfx) gt 4 %then %do;
       %put WARNING: STATINIT: "&pfx" exceeds maximum length for PFX.;
       %let pfx = %substr(&pfx,1,4);
       %put .                  PFX has been truncated to "&pfx".;
       %end;

     %if %index(0123456789,&verbose) eq 0 %then %do;
       %put WARNING: STATINIT: "&verbose" is an invalid value for VERBOSE.;
       %let verbose = 2;
       %put .                  VERBOSE has been set to &verbose.;
       %end;

/*------------------------------------------------------------------------------/
/ For SUN 4                                                                     /
/------------------------------------------------------------------------------*/

     %if "&sysscp" eq "SUN 4" %then %do;

       %if %length(&utilscl) eq 0 %then %do;
         %if &verbose ge 3 %then
           %put NOTE: STATINIT: As requested, SCL library not allocated.;
         %end;
       %else %if %nrbquote(&utilscl) eq _DEFAULT_ %then %do;
         libname utilscl "/usr/local/medstat/sas/scl";
         %end;
       %else %do;
         libname utilscl "&utilscl";
         %end;

       %if %length(&utiliml) eq 0 %then %do;
         %if &verbose ge 3 %then
           %put NOTE: STATINIT: As requested, IML library not allocated.;
         %end;
       %else %if %nrbquote(&utiliml) eq _DEFAULT_ %then %do;
         libname utiliml "/usr/local/medstat/sas/iml";
         %end;
       %else %do;
         libname utiliml "&utiliml";
         %end;

       %if %length(&utilfmt) eq 0 %then %do;
         %if &verbose ge 3 %then
           %put NOTE: STATINIT: As requested, format library not allocated.;
         %end;
       %else %do;
         %if %nrbquote(&utilfmt) eq _DEFAULT_ %then %do;
           libname library "/usr/local/medstat/sas/formats";
           %end;
         %else %do;
           libname library "&utilfmt";
           %end;
       /* options fmtsearch=(&opt_fmts); */
         %end;

       %if %length(&utildata) eq 0 %then %do;
         %if &verbose ge 3 %then
           %put NOTE: STATINIT: As requested, DATA library not allocated.;
         %end;
       %else %if %nrbquote(&utildata) eq _DEFAULT_ %then %do;
         libname utildata "/usr/local/medstat/sas/data";
         %end;
       %else %do;
         libname utildata "&utildata";
         %end;

      %if %length(&utilgdev) eq 0 %then %do;
         %if &verbose ge 3 %then
           %put NOTE: STATINIT: As requested, graph device lib not allocated.;
         %end;
       %else %if %nrbquote(&utilgdev) eq _DEFAULT_ %then %do;
         libname gdevice&gdevnum "/usr/local/medstat/sas/gdevice";
         %end;
       %else %do;
         libname gdevice&gdevnum "&utilgdev";
         %end;

       %local fn shell;
       %let fn=%fn;
       %let shell=%sysget(SHELL);
       %if "&shell"="/bin/csh" %then %do ;
         %sysexec if (-w &fn..gsf) rm &fn..gsf ;
       %end ;
       %else %if "&shell"="/bin/sh" %then %do ;
         %sysexec rm &fn..gsf 2> /dev/null ;
       %end ;
       %else %if "&shell"="/bin/bash" %then %do ;
         %sysexec rm &fn..gsf 2> /dev/null ;
       %end ;

       filename utilgsf "&fn..gsf" new ;

   %end;

/*------------------------------------------------------------------------------/
/ End of SUN 4 processing                                                       /
/------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------/
/ Unsupported OS.                                                               /
/------------------------------------------------------------------------------*/

   %else %do;
      %if &verbose ge 1 %then %do;
         %put ERROR: STATINIT: Unknown operating system (&sysscp);
         %put .                Libraries cannot be allocated;
      %end;
   %end;
%mend statinit;
