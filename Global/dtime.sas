/*
/ Program name:     DTIME.SAS
/
/ Program version:  2.1
/
/ Program purpose:  Converts a SAS date & time value to a SAS Datetime value
/
/ SAS version:      6.12 TS020
/
/ Created by:
/ Date:
/
/ Input parameters: DATE - SAS date value
/                   TIME - SAS time value
/
/ Output created:
/
/ Macros called:    None.
/
/ Example call:     dt1=%dtime(d1,t1);
/
/===========================================================================
/ Change log:
/
/    MODIFIED BY: Jonathan Fry
/    DATE:        09DEC1998
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
/===========================================================================*/

%macro dtime(date,time);

/*---------------------------------------------------------------------------/
/ JMF001                                                                     /
/ Display Macro Name and Version Number in LOG                               /
/---------------------------------------------------------------------------*/

   %put ------------------------------------------------------;
   %put NOTE: Macro called: DTIME.SAS      Version Number: 2.1;
   %put ------------------------------------------------------;

   (&date * 86400 + &time)
%mend dtime;
