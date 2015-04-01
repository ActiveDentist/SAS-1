/*
/ Program Name:     BWGETTF.SAS
/
/ Program Version:  2.2
/
/ Program purpose:  Use this utility macro to access the currently defined SAS
/                   TITLES and FOOTNOTES, and the current values of the LS PS
/                   and CENTER options.  The values are returned in macro variables
/                   whose names can be changed with the macro options T F LS PS and
/                   CENTER.
/
/                   This macro must be called at a step boundry because it calls
/                   PROC DISPLAY and will produce a step boundry anyway.
/
/                   See macro BWCONT for an example of how this macro can be used.
/
/ SAS Version:      6.12
/
/ Created By:
/ Date:
/
/ Input Parameters: T      - Name of variable for storing title information.
/                   F      - Name of variable for storing footnote information.
/                   LS     - Name of variable for storing linesize information.
/                   PS     - Name of variable for storing pagesize information.
/                   CENTER - Name of variable for storing CENTER/NOCENTER option status.
/                   DUMP   - Option enables the above information to be dumped to the SAS log.
/
/ Output Created:   Title, footnote, linesize, pagesize and CENTER/NOCENTER information output to
/                   SAS log if option DUMP=YES specified.
/
/ Macros Called:    None.
/
/ Example Call:     %bwgettf();
/
/===================================================================================================
/ Change Log
/
/    MODIFIED BY: ABR
/    DATE:        10.2.93
/    MODID:       Ver 1.5
/    DESCRIPTION: Remove commented LIBNAME statement.
/    -------------------------------------------------------------------------------------------
/    MODIFIED BY: Steve Mallett
/    DATE:        28.2.97
/    MODID:       Ver 2
/    DESCRIPTION: Added keyword parameter to allow libname to be specified at macro call time.
/    -------------------------------------------------------------------------------------------
/    MODIFIED BY: John Henry King
/    DATE:        11NOV1997
/    MODID:       Ver 2.1
/    DESCRIPTION: Changed the macro to use SYSFUNC and GETOPTION and SASHELP.VTITLE. The macro no
/                 longer needs the the SCL program to operate.
/    -------------------------------------------------------------------------------------------
/    MODIFIED BY: Jonathan Fry
/    DATE:        09DEC1998
/    MODID:       JMF001
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 2.2.
/    -------------------------------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX002
/    DESCRIPTION:
/    -------------------------------------------------------------------------------------------
/====================================================================================================*/

%macro bwgettf(t = _BWT,
               f = _BWF,
              ls = _BWLS,
              ps = _BWPS,
          center = _BWCT,
            dump = YES,
          catlib = UTILSCL);

      /*
      / JMF001
      / Display Macro Name and Version Number in LOG
      /-----------------------------------------------------------------*/

      %put ------------------------------------------------------;
      %put NOTE: Macro called: BWGETTF.SAS    Version Number: 2.2;
      %put ------------------------------------------------------;


   %if "&sysscp"="SUN 4" %then %do;
      %if &sysver<6.09 %then %do;
         %put ERROR: You must use version 6.09 or higher with SUMTAB.;
         %if &sysenv=BACK %then %str(;ENDSAS;);
         %end;
      %end;

   %local i;
   %let dump=%upcase(&dump);
   %let tl=&t.L;
   %let fl=&f.L;

   %global &t.0;
   %let    &t.0 = 0;

   %global &t.1 &t.2 &t.3 &t.4 &t.5 &t.6 &t.7 &t.8 &t.9 &t.10;
   %global &tl.1 &tl.2 &tl.3 &tl.4 &tl.5 &tl.6 &tl.7 &tl.8 &tl.9 &tl.10;

   %global &f.0;
   %let    &f.0 = 0;
   %global &f.1 &f.2 &f.3 &f.4 &f.5 &f.6 &f.7 &f.8 &f.9 &f.10;
   %global &fl.1 &fl.2 &fl.3 &fl.4 &fl.5 &fl.6 &fl.7 &fl.8 &fl.9 &fl.10;
   %global &ls &ps &center;
   %let &ls     = 0;
   %let &ps     = 0;
   %let &center = 0;

   %do;
      %let &ls     = %sysfunc(getoption(LINESIZE));
      %let &ps     = %sysfunc(getoption(PAGESIZE));
      %let &center = %sysfunc(getoption(CENTER));

      data _null_;
         set
            sashelp.vtitle
            end = eof;

         select(type);
            when('T') do;
               hl0 + 1;
               call symput("&t" || left(put(number,f2.)) , text);
               end;
            when('F') do;
               fnote0 + 1;
               call symput("&f" || left(put(number,f2.)) , text);
               end;
            otherwise;
            end;

         if eof then do;
            call symput("&t.0" , trim(left(put(hl0   ,f2.))));
            call symput("&f.0" , trim(left(put(fnote0,f2.))));
            end;
         run;

      %end;

   %if &dump=YES %then %do;
      %put Macro Variable Dump From Macro BWGETTF;
      %put %str(   ) Linesize(&ls=&&&ls) Pagesize(&ps=&&&ps);
      %put %str(   ) Center(&center=&&&center);
      %put Titles -----------------------------------------------------;
      %put %str(   ) Defined &t.0=&&&t.0;
      %do i = 1 %to &&&t.0;
         %put %str(     ) &tl.&i=&&&tl.&i &t.&i=&&&t.&i;
         %end;
      %put Footnotes --------------------------------------------------;
      %put %str(  ) Defined &f.0=&&&f.0;
      %do i = 1 %to &&&f.0;
         %put %str(     ) &fl.&i=&&&fl.&i &f.&i=&&&f.&i;
         %end;
      %end;
   %mend;
