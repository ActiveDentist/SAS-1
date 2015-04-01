/*
/ Program Name:     SUFFIX.SAS
/
/ Program Version:  2.1
/
/ Program purpose:  The macro takes a list of words separated by blanks and adds a common
/                   suffix to each word in turn, thus creating a new list.
/
/ SAS Version:      6.12
/
/ Created By:       John H. King
/ Date:
/
/ Input Parameters: STRING - A list of variables to be processed by the macro.
/                   SUFFIX - A string of character(s) to be added to the end of every
/
/ Output Created:   List of variables specified in STRING, with SUUFIX added after every word.
/
/ Macros Called:    None.
/
/ Example Call:
/
/================================================================================================
/Change Log
/
/    MODIFIED BY: Jonathan Fry
/    DATE:        10DEC1998
/    MODID:       JMF001
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 2.1.
/    ----------------------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX002
/    DESCRIPTION:
/    ----------------------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX003
/    DESCRIPTION:
/    ----------------------------------------------------------------------------------
/================================================================================================*/

%macro suffix(string,suffix);

/*----------------------------------------------------------------------------/
/ JMF001                                                                      /
/ Display Macro Name and Version Number in LOG                                /
/----------------------------------------------------------------------------*/

   %put ----------------------------------------------------;
   %put NOTE: Macro called: SUFFIX.SAS   Version Number: 2.1;
   %put ----------------------------------------------------;

   %local count word newlist delm;
   %let delm  = %str( );
   %let count = 1;
   %let word  = %scan(&string,&count,&delm);
   %do %while(%quote(&word)~=);
      %let newlist = &newlist &word.&suffix;
      %let count   = %eval(&count + 1);
      %let word    = %scan(&string,&count,&delm);
      %end;
   &newlist
%mend suffix;
