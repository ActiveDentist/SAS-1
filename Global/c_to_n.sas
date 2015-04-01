/*
/ Program Name:     C_TO_N.sas (Macro)
/
/ Program Version:  1.1
/
/ MDP/Protocol id:  N/A
/
/ Program Purpose:  Convert character variables to numeric, drop the character
/                   variables, and rename the new numeric variables using the old
/                   names.  All in one data step.
/
/ SAS Version:      Unix 6.12
/
/ Created By:       M. Foxwell.
/ Date:             05NOV97
/
/ Input Parameters:
/
/ Output Created:
/
/ Macros Called:    None
/
/ Example Call:     Suppose you have a data set with 10 character variables
/                   that you need to convert to numeric for analysis.
/
/                      data nums;
/                      set chars;
/
/                         %c_to_n(varlist = A B C D E F G H I J)
/
/                      run;
/
/====================================================================================
/ Change Log:
/
/    MODIFIED BY: M Foxwell
/    DATE:        05NOV97
/    MODID:
/    DESCRIPTION: Changed informat in input function from 8. to best12..
/                 This leaves numeric variables unchanged if inadvertently
/                 put through the macro.
/    -------------------------------------------------------------------
/    MODIFIED BY: Jonathan Fry
/    DATE:        09DEC1998
/    MODID:       JMF001
/    DESCRIPTION: Tested for Y2k compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change the Version Number to 1.1.
/    -------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX002
/    DESCRIPTION:
/    -------------------------------------------------------------------
/=====================================================================================*/

%macro c_to_n(varlist=);

/*------------------------------------------------------------------------/
/ JMF001                                                                  /
/ Display Macro Name and Version Number in LOG                            /
/------------------------------------------------------------------------*/

   %put ------------------------------------------------------;
   %put NOTE: Macro called: C_TO_N.SAS     Version Number: 1.1;
   %put ------------------------------------------------------;

/*------------------------------------------------------------------------/
/ This macro uses the same list scanning logic as %WORDS                  /
/------------------------------------------------------------------------*/

   %local i word delm;
   %let delm = %str( );
   %let i    = 1;
   %let word = %scan(&varlist,&i,&delm);

   %do %while("&word"^="");

      _&i = input(&word,best12.);
      drop &word;
      rename _&i = &word;

      %let i = %eval(&i + 1);
      %let word = %scan(&varlist,&i,&delm);

      %end;

   %mend c_to_n;
