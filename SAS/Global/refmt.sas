/*
/ Program name:     REFMT.SAS
/
/ Program version:  1.1
/
/ MDP/Protocol ID:  N/A
/
/ Program Purpose:  Renames variables' corresponding valid value list formats
/                   to fit in DTAB's variable formatting scheme for the ROWS
/                   statement.
/
/                   Assumes: the valid value list format library has been
/                   assigned to a LIBREF of LIBRARY. Also that the macro PREFIX
/                   is on your SASAUTOS macro library.
/
/ SAS version:      Unix 6.12
/
/ Created by:       Scott Burroughs
/ Date:             08JAN91
/
/ Input parameters:
/
/ Output Created:
/
/ Macros called:    PREFIX.SAS
/
/ Example call:
/
/===============================================================================
/ Change Log:
/
/    MODIFIED BY: Jonathan Fry
/    DATE:        10DEC1998
/    MODID:       JMF001
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 1.1.
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
/===============================================================================*/

%MACRO refmt(varlist);

   /*
   / JMF001
   / Display Macro Name and Version number in LOG
   /-------------------------------------------------------*/

   %put ---------------------------------------------------;
   %put NOTE: Macro called: REFMT.SAS   Version Number: 1.1;
   %put ---------------------------------------------------;


   %let fmtvrlst=%prefix(&varlist,$v);

   proc format
      library = library
      cntlout = fmtlist
      ;
      select &fmtvrlst;
   run;

   data fmtlist2;
      set fmtlist;
      fmtname=substr(fmtname,2);
   run;

   proc format
      cntlin = fmtlist2
      ;
   run;

%MEND;
