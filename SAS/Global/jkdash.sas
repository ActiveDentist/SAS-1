/*
/ PROGRAM NAME: jkdash.sas
/
/ PROGRAM VERSION: 1.0
/
/ PROGRAM PURPOSE: Used by standard macros to process the dash line placement
/   in the ROWS parameter of DTAB.
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
/   _dash_=_dash_   The name of the variable created by this macro.
/
/   delm=%str( +)   The delimiter list for the scan function.
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
/   %jkdash(rowvars=&rows,_name_=_VNAME_,_dash_=_DASH_);
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

%macro jkdash(rowvars=,
               _name_=_VNAME_,
               _dash_=_DASH_,
                 delm=%str( +));
   %local i w w2;
   %let rowvars = %upcase(&rowvars);
   %let i = 1;
   %let w  = %scan(&rowvars,&i,  &delm);
   %let w2 = %scan(&rowvars,&i+1,&delm);

   %if %index("&rowvars",-) | %index("&rowvars",_PATNO_) %then %do;
      select(&_name_);
         when(' '); 
      %do %while("&w"^="");
         %let w2 = %substr(&w2%str( ),1,1);
         %if "&w2" = "-" %then %do;
            when("&w") &_dash_ = 1;
            %end;
         %let i = %eval(&i + 1);
         %let w  = %scan(&rowvars,&i,&delm);
         %let w2 = %scan(&rowvars,&i+1,&delm);
         %end;

      otherwise &_dash_ = 0;
      end;
      %end;
   %else %do;
      select(&_name_);
         when('_PATNO_') &_dash_ = 1;
         otherwise       &_dash_ = 0;
         end;
      %end;
   %mend jkdash;
