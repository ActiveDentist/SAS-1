/*
/ Program Name:     TRANSLAT.SAS
/
/ Program Version:  2.1
/
/ Program Purpose:  Replaces all occurances of a string with a replacement
/                   string in a macro variable
/
/ SAS Version:      6.12 TS020
/
/ Created By:       Carl Arneson
/ Date:             25/08/92
/
/ Input Parameters: STRING - String value
/                   TARG   - Target string
/                   REPL   - Replacement string
/
/ Output Created:
/
/ Macros Called:    None
/
/ Example Call:     %let char=%translat(&string,hello,bye);
/
/===============================================================================
/ Change Log:
/
/    MODIFIED BY: Jonathan Fry
/    DATE:        10DEC1998
/    MODID:       JMF001
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 2.1.
/    ------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX002
/    DESCRIPTION:
/    ------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX003
/    DESCRIPTION:
/    ------------------------------------------------------------------
/===============================================================================*/

%macro TRANSLAT(string,targ,repl) ;

/*------------------------------------------------------------------/
/ JMF001                                                            /
/ Display Macro Name and Version Number in LOG                      /
/------------------------------------------------------------------*/

  %put ------------------------------------------------------;
  %put NOTE: Macro called: TRANSLAT.SAS   Version Number: 2.1;
  %put ------------------------------------------------------;

  %local return pos len ;
  %let len=%length(&targ);
  %let return=;
  %let pos=%index(&string,&targ);

  %do %while(&pos) ;
     %if &pos>1 %then
        %let return=&return.%qsubstr(&string,1,%eval(&pos-1))&repl;
     %else %let return=&return.&repl;
     %if %eval(&pos + &len)<=%length(&string) %then
        %let string=%qsubstr(&string,%eval(&pos + &len));
     %else %let string=;
     %let pos=%index(&string,&targ);
  %end ;

  %let return=&return.&string;

  &return

%mend TRANSLAT ;
