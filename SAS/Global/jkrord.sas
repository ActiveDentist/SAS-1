/*
/ PROGRAM NAME: jkrord.sas
/
/ PROGRAM VERSION: 1.0
/
/ PROGRAM PURPOSE: Used by standard macros to assign a sort order variable
/   to a list of words.  Specifically to order SIMSTAT output data according 
/   to the order given in ROWS= in DTAB.
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
/   _row_=_row_     The name of the variable created by this macro.
/
/   delm=%str( -+)  The delimiter list for the scan function.
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
/  %jkrord(rowvars=&rows,_name_=_VNAME_,_row_=_ROW_);
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

/*
/ This macro is used to assign a sort order variable to
/ a list of words.
/----------------------------------------------------------------------*/

%macro jkrord(rowvars=,
               _name_=_VNAME_,
                _row_=_ROW_,
                 delm=%str( -+));
   %local i w;
   %let rowvars = %upcase(&rowvars);
   %let i = 1;
   %let w = %scan(&rowvars,&i,&delm);

   select(&_name_);

   %do %while("&w"^="");

      when("&w") &_row_ = &i;
      %let i = %eval(&i + 1);
      %let w = %scan(&rowvars,&i,&delm);
      %end;

      otherwise &_row_ = .;
      end;
   %mend jkrord;
