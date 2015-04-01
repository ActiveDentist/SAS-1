/*
/ Program name: reverse.sas
/
/ Program version: 2.1
/
/ Program purpose: Reverse the value of a SAS macro variable
/
/ SAS version: 6.12 TS020
/
/ Created by:
/ Date:
/
/ Input parameters: ARG - SAS macro variable
/
/ Output created:
/
/ Macros called: None
/
/ Example call:
/
/              %let revname=%reverse(&name);
/
/==========================================================================
/ Change log:
/
/    MODIFIED BY: Jonathan Fry
/    DATE:        10DEC1998
/    MODID:       JMF001
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 2.1.
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
/==========================================================================*/

%MACRO REVERSE(ARG);

   /*
   / JMF001
   / Display Macro Name and Version Number in LOG
   /------------------------------------------------------------*/

   %put -----------------------------------------------------;
   %put NOTE: Macro called: REVERSE.SAS   Version Number: 2.1;
   %put -----------------------------------------------------;


   %local i reverse;
   %do i = %length(&arg) %to 1 %by -1;
      %let reverse = %quote(&reverse)%qsubstr(&arg,&i,1);
      %end;
   &reverse
%mend Reverse;
