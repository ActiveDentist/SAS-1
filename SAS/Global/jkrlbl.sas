/*
/ PROGRAM NAME: jkrlbl.sas
/
/ PROGRAM VERSION: 1.0
/
/ PROGRAM PURPOSE: Used by standard macros to process the row label
/   placement in the ROWS parameter of DTAB.
/
/ SAS VERSION: 6.12 (UNIX)
/
/ CREATED BY: John Henry King
/ DATE: FEB1997
/
/ INPUT PARAMETERS:
/
/   rowvars=        The list of words to process.
/ 
/   _name_=_vname_  The name of _VNAME_ special variable from SIMSTAT.
/ 
/   _rlbl_=_rlbl_   The name of the variable created by this macro.
/
/   delm=%str( -)   The delimiter list for the scan function.
/
/
/ OUTPUT CREATED:
/
/   Add _dash_ to a data set.
/
/ MACROS CALLED: none
/
/ EXAMPLE CALL:
/
/   %jkrlbl(rowvars=&rows,_name_=_VNAME_,_rlbl_=_RLBL_);
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


%macro jkrlbl(rowvars=,
               _name_=_VNAME_,
               _rlbl_=_RLBL_,
                 delm=%str( -));

   %global rlabel1 rlabel2 rlabel3 rlabel4 rlabel5
           rlabel6 rlabel7 rlabel8 rlabel9 rlabel10;

   %local i j w w2;
   %let rowvars = %upcase(&rowvars);
   %let i = 1;
   %let w  = %scan(&rowvars,&i,  &delm);
   %let w2 = %scan(&rowvars,&i+1,&delm);

   length &_rlbl_ $200;

   %if %index("&rowvars",+) %then %do;
      select(&_name_);
 
      %do %while("&w"^="");
         %let w2 = %substr(&w2%str( ),1,1);
         %if "&w2" = "+" %then %do;
            %let j = %eval(&j + 1);
            when("&w") &_rlbl_ = "&&rlabel&j";
            %end;
         %let i = %eval(&i + 1);
         %let w  = %scan(&rowvars,&i,&delm);
         %let w2 = %scan(&rowvars,&i+1,&delm);
         
         %end;

         otherwise &_rlbl_ = ' ';
         end;
      %end;

   %mend jkrlbl;
