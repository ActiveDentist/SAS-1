/*
/ Program Name:     WORDS.SAS
/
/ Program Version:  2.1
/
/ Program purpose:  Takes a character string and splits it into a series of words, based on a defined
/                   delimiter. Each word is stored in a seperate macro variable, and the total number
/                   of words is returned to the calling program.
/
/ SAS Version:      6.12
/
/ Created By:
/ Date:
/
/ Input Parameters: STRING - The name of the variable containing the character string.
/                   ROOT   - A prefix for the series of variables containing the separated
/                            words (default = W).
/                   DELM   - A delimiter character, used for separating words (default = a space).
/
/ Output Created:   A series of macros variables containing the separated words, and the total
/                   number of words.
/
/ Macros Called:    None.
/
/ Example Call:     string = "This is a string containing seven words";
/                   %words(string);
/
/=====================================================================================================
/ Change Log:
/
/    MODIFIED BY: Jonathan Fry
/    DATE:        10DEC1998
/    MODID:       JMF001
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 2.1.
/    --------------------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX002
/    DESCRIPTION:
/    --------------------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX003
/    DESCRIPTION:
/    --------------------------------------------------------------------------------
/=====================================================================================================*/

%MACRO WORDS(STRING,ROOT=W,DELM=%STR( ));

   %Local Count Word;
   %Let Count = 1;
   %Let Word = %Scan(&String,&Count,&Delm);
   %Do %While(%Quote(&Word)~=);
      %Global &Root&Count;
      %Let &Root&Count = &Word;
      %Let Count = %Eval(&Count + 1);
      %Let Word = %Scan(&String,&Count,&Delm);
      %End;
   %Eval(&Count - 1)
%Mend Words;
