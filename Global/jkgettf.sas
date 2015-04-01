/*
/ PROGRAM NAME: jkgettf.sas
/
/ PROGRAM VERSION: 1.0
/
/ PROGRAM PURPOSE: Used to prepare titles and footnotes, extracted from
/   the TITLES system, for use with the standard macros %DTAB and %AETAB
/
/
/ SAS VERSION: 6.12 (UNIX)
/
/ CREATED BY: John Henry King
/
/ DATE: SEP1997
/
/ INPUT PARAMETERS: None so far.
/
/ OUTPUT CREATED:
/
/ MACROS CALLED:
/
/
/
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

%macro jkgettf(_left=1 2);

   %global hl0 hl1 hl2 hl3 hl4 hl5 hl6 hl7 hl8 hl9 hl10
           hl11 hl12 hl13 hl14 hl15;

   %global hlright hlleft hlcont;

   %global fnote0  fnote1  fnote2  fnote3  fnote4  fnote5
           fnote6  fnote7  fnote8  fnote9  fnote10 fnote11
           fnote12 fnote13 fnote14 fnote15;

   %global findt0  findt1  findt2  findt3  findt4  findt5
           findt6  findt7  findt8  findt9  findt10 findt11
           findt12 findt13 findt14 findt15;

   %global enote0 enote1 enote2 enote3 enote4 enote5
                  enote6 enote7 enote8 enote9 enote10;


   %let hlleft = &_left;
   %let hl0    = 0;
   %let fnote0 = 0;
   %let enote0 = 0;

   data _null_;

      set
         sashelp.vtitle
         end = eof;

      select(type);
         when('T') do;
            hl0 + 1;
            call symput('hl'   ||left(put(number,f2.)) , text);
            end;
         when('F') do;
            if index(text,'ff'x) then do;
               enote0 + 1;
               call symput('enote'||left(put(enote0,f2.)) , trim(text));
               end;
            else do;
               fnote0 + 1;
               call symput('fnote'||left(put(number,f2.)) , trim(text));
               end;
            end;
         otherwise;
         end;

      if eof then do;
         call symput('enote0' , trim(left(put(enote0,f2.))));
         call symput('hl0'    , trim(left(put(hl0   ,f2.))));
         call symput('fnote0' , trim(left(put(fnote0,f2.))));
         end;

      run;

   %local i;

   %put NOTE: --------------------------------------------------------;
   %put NOTE: The following macro variables have been set.;
   %put %str(     ) HLLEFT = &hlleft;

   %do i = 0 %to &hl0;
      %put %str(     ) HL&i = %bquote(&&hl&i);
      %end;
   %do i = 0 %to &fnote0;
      %put %str(     ) FNOTE&i = %bquote(&&fnote&i);
      %end;
   %do i = 0 %to &enote0;
      %put %str(     ) ENOTE&i = %bquote(&&enote&i);
      %end;;
   %put NOTE: --------------------------------------------------------;

   %mend jkgettf;
