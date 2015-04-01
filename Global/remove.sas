/*
/ Program Name: REMOVE.SAS
/
/ Program Version: 2.1
/
/ Program purpose: Remove all occurrences of a target from a string.
/
/ SAS Version: 6.12
/
/ Created By: Carl P. Arneson
/ Date:       25 Aug 1992
/
/ Input Parameters:
/
/              STRING - Character string to be processed by the macro.
/              TARG   - Target string to be removed from STRING by the macro.
/
/ Output Created:
/
/              A copy of STRING, with occurrences of TARG removed.
/
/ Macros Called: None.
/
/ Example Call:
/
/              %let tmt1 = Ondansetron 1000mg daily;
/              %let tmt2 = %remove(&tmt, daily);
/
/======================================================================================
/ Change Log
/
/    MODIFIED BY: Jonathan Fry
/    DATE:        10DEC1998
/    MODID:óóóóóóóJMF001
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 2.1.
/    ------------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:óóóóóóóXXX002
/    DESCRIPTION:
/    ------------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:óóóóóóóXXX003
/    DESCRIPTION:
/    ------------------------------------------------------------------------
/=====================================================================================*/

%macro REMOVE(string,targ) ;

     /*
     / JMF001
     / Display Macro Name and Version Number in LOG
     /-----------------------------------------------------------*/

     %put ----------------------------------------------------;
     %put NOTE: Macro called: REMOVE.SAS   Version Number: 2.1;
     %put ----------------------------------------------------;


  %local return pos len ;
  %let len=%length(&targ);
  %let return=;
  %let pos=%index(&string,&targ);

  %do %while(&pos) ;
     %if &pos>1 %then
        %let return=&return.%qsubstr(&string,1,%eval(&pos-1));
     %if %eval(&pos + &len)<=%length(&string) %then
        %let string=%qsubstr(&string,%eval(&pos + &len));
     %else %let string=;
     %let pos=%index(&string,&targ);
  %end ;

  %let return=&return.&string;

  &return

%mend REMOVE ;
