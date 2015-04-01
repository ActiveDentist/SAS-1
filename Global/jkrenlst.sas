/*
/ PROGRAM NAME: jkrenlst.sas
/
/ PROGRAM VERSION: 1.0
/
/ PROGRAM PURPOSE: Used parse two lists and return a new list where each 
/   word in the original lists are joined by an user specified character.
/
/ SAS VERSION: 6.12
/
/ CREATED BY: John Henry King
/
/ DATE: 1992, actually wrote this in the 80s probably.
/
/ INPUT PARAMETERS:
/   old =       specifies a list of blank delimited words.
/
/   new =       specifies a list of blank delimited workds.
/
/   between =   The string of characters to place between the lists.
/               Equal sign (=) is the default.
/
/ OUTPUT CREATED: Returns a macro string.
/
/ MACROS CALLED: none
/
/ EXAMPLE CALL:
/   
/   %let list = %jkrenlst(old = A B C, new = X Y Z);
/
/   Assigns LIST the value: A = X B = Y C = Z
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

%macro JKrenlst(old=,new=,between=%str(=));

   %local i oldword newword return;
   %let i = 1;
   %let oldword = %scan(&old,&i,%str( ));
   %let newword = %scan(&new,&i,%str( ));

   %do %while("&oldword" ^= "");
      
      %let return = &return &oldword &between &newword;

      %let i = %eval(&i + 1);
      %let oldword = %scan(&old,&i,%str( ));
      %let newword = %scan(&new,&i,%str( ));
 
      %end;

   &return

   %mend JKrenlst;
