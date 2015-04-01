/*
/ PROGRAM NAME: jkxwords.sas
/
/ PROGRAM VERSION: 1.0
/
/ PROGRAM PURPOSE: Parse a list count the words.  The individual words are
/   optionally added stored in a macro variable array.
/
/ SAS VERSION: 6.12
/
/ CREATED BY: John Henry King
/
/ DATE: sometime in the 80s
/
/ INPUT PARAMETERS:
/
/ LIST=             A list to be processed
/
/ ROOT=_W           The root of the macro variable array created to hold the
/                   individual words.  If root is given a NULL value then
/                   the macro only counts the words and does not create the
/                   macro variable array.
/
/ DELM=%str( )      The delimiters for the list.
/
/
/ OUTPUT CREATED: Return the number of words in the list.  And by default
/   created GLOBAL macro variable one for each word.
/
/ MACROS CALLED: none
/
/ EXAMPLE CALL:
/
/   %let wordlist = this is a list of words;
/
/   %let list0 = %words(&wordlist,root=list);
/
/ Assigns LIST0 the value: 6
/ Creates global macro variables as follows.
/
/ list1 = this
/ list2 = is
/ list3 = a
/ list4 = list
/ list5 = of
/ list6 = words
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

%MACRO JKXWORDS(LIST=,ROOT=_w,DELM=%str( ));
   %local i word;
   %let i = 1;
   %let word = %scan(&list,&i,&delm);
   %do %while("&word"^="");
      %if "&root" > "" %then %do;
         %global &root&i;
         %let &root&i = &word;
         %end;
      %let i = %eval(&i + 1);
      %let word = %scan(&list,&i,&delm);
      %end;
   %let i = %eval(&i - 1);
   &i
   %mend jkxwords;
