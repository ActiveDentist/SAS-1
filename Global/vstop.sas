/*
/ Program Name:     VSTOP.SAS
/
/ Program Version:  2.1
/
/ Program purpose:  The macro compares the version of SAS on which the current program is
/                   running with the version specified in the macro call. If the two differ,
/                   processing stops.
/
/ SAS Version:      6.12
/
/ Created By:       Randall Austin
/ Date:
/
/ Input Parameters: ARG - The intended SAS version for the program.
/
/ Output Created:   None.
/
/ Macros Called:    None.
/
/ Example Call:     %vstop(6.12);
/
/===============================================================================================
/Change Log
/
/    MODIFIED BY: Jonathan Fry
/    DATE:        10DEC1998
/    MODID:       JMF001
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version number.
/                 Change Version Number to 2.1.
/    ----------------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX002
/    DESCRIPTION:
/    ----------------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX003
/    DESCRIPTION:
/    ----------------------------------------------------------------------------
/================================================================================================*/

%macro vstop(arg);

/*------------------------------------------------------------------------/
/ JMF001                                                                  /
/ Display Macro Name and Version Number in LOG                            /
/------------------------------------------------------------------------*/

   %put ---------------------------------------------------;
   %put NOTE: Macro called: VSTOP.SAS   Version Number: 2.1;
   %put ---------------------------------------------------;

   %local v;
   %let v=%substr(&sysver%str(     ),1,%length(&arg));
   %if "&v"~="&arg" %then %do;
      %put ERROR: You are using the WRONG version of SAS, use &arg..;
      %if &sysenv eq BACK %then %do;
         endsas;
      %end;
   %end;
%mend vstop;
