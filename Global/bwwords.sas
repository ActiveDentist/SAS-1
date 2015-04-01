/*
/ Program Name:     BWWORDS.SAS
/
/ Program Version:  2.1
/
/ Program purpose:  Takes a character string and splits it into a series of words, based on a defined
/                   delimiter. Each word is stored in a seperate macro variable, and the total number
/                   of words is returned to the calling program.
/
/                   Macro BWWORDS is a slight modification of the WORDS macro described in the SAS
/                   Guide to Macro Processing.
/
/ SAS Version:      6.12
/
/ Created By:
/ Date:
/
/ Input Parameters: STRING - The name of the variable containing the character string.
/                   ROOT   - A prefix for the series of variables containing the separated words (default = W).
/                   DELM   - A delimiter character, used for separating words (default = a space).
/
/ Output Created:   A series of macros variables containing the separated words, and the total
/                   number of words.
/
/ Macros Called:    None.
/
/ Example Call:
/                   string = "This is a string containing seven words";
/                   %bwwords(string);
/
/=============================================================================================================
/ Change Log
/
/   MODIFIED BY: Jonathan Fry
/   DATE:        09DEC1998
/   MODID:       JMF001
/   DESCRIPTION: Tested for Y2K compliance.
/                Add %PUT statement for Macro Name and Version Number.
/                Change Version Number to 2.1.
/   ----------------------------------------------------------------------------
/   MODIFIED BY:
/   DATE:
/   MODID:       XXX002
/   DESCRIPTION:
/   ----------------------------------------------------------------------------
/   MODIFIED BY:
/   DATE:
/   MODID:       XXX003
/   DESCRIPTION:
/   ----------------------------------------------------------------------------
/=============================================================================================================*/

%MACRO BWWORDS(STRING,ROOT=W,DELM=%STR( ));

/*--------------------------------------------------------------------------/
/ JMF001                                                                    /
/ Display Macro Name and Version Number in LOG                              /
/--------------------------------------------------------------------------*/

   %put ------------------------------------------------------;
   %put NOTE: Macro called: BWWORDS.SAS    Version Number: 2.1;
   %put ------------------------------------------------------;

   %local count word;
   %let count = 1;
   %let word = %scan(&string,&count,&delm);
   %do %while(%quote(&word)~=);
      %global &root&count;
      %let &root&count = &word;
      %let count = %eval(&count + 1);
      %let word = %scan(&string,&count,&delm);
      %end;
   %eval(&count - 1)
   %mend bwwords;
