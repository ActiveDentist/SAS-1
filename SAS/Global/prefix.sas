/*
/ Program Name: PREFIX.SAS
/
/ Program Version: 2.1
/
/ Program purpose: Concatenates a common prefix to a list of variables.
/
/ SAS Version: 6.12
/
/ Created By: John H. King
/ Date:
/
/ Input Parameters:
/
/            STRING - List of variables.
/            PREFIX - Character(s) to be added to variables listed in STRING.
/
/ Output Created:
/
/            A list of variables corresponding to those listed in STRING, with the character(s)
/            specified in PREFIX added to each word.
/
/ Macros Called: None.
/
/ Example Call:
/
/            %let varlist = age sex height;
/            %let newlist = %prefix(&varlist, new);
/
/================================================================================================
/ Change Log
/
/    MODIFIED BY: Jonathan Fry
/    DATE:        10DEC1998
/    MODID:       JMF001
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 2.1.
/    ----------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX002
/    DESCRIPTION:
/    ----------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX003
/    DESCRIPTION:
/    ----------------------------------------------------------------------
/================================================================================================*/

%MACRO PREFIX(STRING,PREFIX);

      /*
      / JMF001
      / Display Macro Name and Version Number in LOG
      /-----------------------------------------------------------------*/

      %put ----------------------------------------------------;
      %put NOTE: Macro called: PREFIX.SAS   Version Number: 2.1;
      %put ----------------------------------------------------;


   %LOCAL COUNT WORD NEWLIST DELM;
   %LET DELM  = %STR( );
   %LET COUNT = 1;
   %LET WORD  = %SCAN(&STRING,&COUNT,&DELM);
   %DO %WHILE(%QUOTE(&WORD)~=);
      %LET NEWLIST = &NEWLIST &PREFIX.&WORD;
      %LET COUNT   = %EVAL(&COUNT + 1);
      %LET WORD    = %SCAN(&STRING,&COUNT,&DELM);
      %END;
   &NEWLIST
   %MEND prefix;
