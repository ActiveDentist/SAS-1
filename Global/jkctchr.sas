/*
/ PROGRAM NAME: jkctchr.sas
/
/ PROGRAM VERSION: 1.0
/
/ PROGRAM PURPOSE: Macro function used to count the occurrences of a 
/  particular character in a macro variable.     
/
/ SAS VERSION: 6.12
/
/ CREATED BY: John Henry King
/
/ DATE: 1996
/
/ INPUT PARAMETERS:
/  string    A string of characters.
/  target    The character to count.
/
/ OUTPUT CREATED: Returns an positive integer value, or zero.
/
/ MACROS CALLED: none
/
/ EXAMPLE CALL: 
/    %let count = %jkctchr(The quick brown fox,o);
/ 
/  Returns 2 to count.
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
/ MODID: JHK001
/ DESCRIPTION:
/------------------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID: JHK003
/ DESCRIPTION:
/============================================================================*/

/*
/ JKCTCHR (FUNCTION)
/ Count the occurrences of a character in a string.
/
/ Returns a value.
/
/ Parameters:
/ STRING         the string of character to search and count
/ TARGET         the character to look for and count
/
/--------------------------------------------------------------------*/
%macro jkctchr(string,target);
 
 
   %local count word newlist delm;
   %local i count;

   %let count = 0;

   %do i = 1 %to %length(&string);
      %if %qsubstr(&string,&i,1) = %quote(&target) 
         %then %let count = %eval(&count + 1);
      %end;

   &count

   %mend jkctchr;
