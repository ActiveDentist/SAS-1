/*
/
/ Program Name:     AGE.SAS
/
/ Program Version:  2.1
/
/ Program purpose:  To return an age value at a specific date, relative to a date of birth (i.e.
/                   numbers of elapsed years, rounding down).
/
/ SAS Version:      6.12
/
/ Created By:       John H. King
/ Date:
/
/ Input Parameters: FROM - A SAS date value, representing the baseline date (date of birth)
/                   TO   - A SAS date value, representing the date at which age is calculated.
/
/ Output Created:   Numbers of whole elapsed years (rounding down).
/
/ Macros Called:    None.
/
/ Example Call:     bthdt = '13AUG65'd;
/                   today = '20FEB97'd;
/                   age = %age(bthdt,today);
/
/================================================================================================
/ Change Log:
/
/   MODIFIED BY: Jonathan Fry
/   DATE:        09DEC1998
/   MODID:       JMF001
/   DESCRIPTION: Tested for Y2K compliance.
/                Add %PUT statement for Macro Name and Version Number.
/                Change Version Number to 2.1.
/   -----------------------------------------------------------------------------
/   MODIFIED BY:
/   DATE:
/   MODID:       XXX002
/   DESCRIPTION:
/   -----------------------------------------------------------------------------
/================================================================================================*/

%macro age(from,to);

/*-------------------------------------------------------------------------/
/ JMF001                                                                   /
/ Display Macro Name and Version Number in LOG                             /
/-------------------------------------------------------------------------*/

   %put ------------------------------------------------------;
   %put NOTE: Macro called: AGE.SAS        Version Number: 2.1;
   %put ------------------------------------------------------;

   (
      ( year(&to)   - year(&from) )
    - ( month(&to) <= month(&from) )
    + ( month(&to)  = month(&from) & day (&to) >= day (&from) )
   )
   %mend;
