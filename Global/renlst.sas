/*
/ Program name:      RENLST.sas
/
/ Program version:   1.1
/
/ MDP/Protocol id:   N/A
/
/ Program purpose:   Compares two strings of characters and pairs off
/                    space delimited terms.
/                    E.G If &a = 1 2 3? 5 6 and &b = a be cj d  , then
/                    %renlst(old=&a, new=&b) is
/                    1=a 2=be 3?=cj 5=d
/                    The macro iterates until there are no terms in one string.
/
/                    The macro generates a string suitable for the
/                    rename function.
/
/                    Be careful not to use the macro with unquoted
/                    strings containing the comma (parameter delimiter) or
/                    macro triggers.
/                    These will produce errors or warnings.
/
/ SAS Version:       UNIX 6.12
/
/ Created by:        M. Foxwell
/
/ Date:              31 OCT 97
/
/ Input Parameters:
/
/ Output Created:
/
/ Macros called:
/
/ Example call:
/
/===================================================================================
/ Change Log.
/
/    MODIFIED BY: Jonathan Fry
/    DATE:        10DEC1998
/    MODID:       JMF001
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change version Number to 1.1.
/    -------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX002
/    DESCRIPTION:
/    -------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX003
/    DESCRIPTION:
/    -------------------------------------------------------------------
/===================================================================================*/

%macro renlst(old=,new=);

   /*
   / JMF001
   / Display Macro Name and Version Number in LOG
   /---------------------------------------------------------*/

   %put ----------------------------------------------------;
   %put NOTE: Macro called: RENLST.SAS   Version Number: 1.1;
   %put ----------------------------------------------------;


   %local i w1 w2 delm arg;
   %let delm = %str( );
   %let i = 1;
   %let w1 = %scan(&old,&i,&delm);
   %let w2 = %scan(&new,&i,&delm);
   %do %while(%quote(&w1)^= & %quote(&w2)^=);
      %let arg = &arg &w1=&w2;
      %let i = %eval(&i + 1);
      %let w1 = %scan(&old,&i,&delm);
      %let w2 = %scan(&new,&i,&delm);
      %end;
   &arg
   %mend renlst;
