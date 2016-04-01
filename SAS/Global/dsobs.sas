/*
/ Program Name:     DSOBS.SAS
/
/ Program Version:  2.1
/
/ Program purpose:  This macro stores the number of observations in a data set in
/                   a specified macro variable (modified version of %NUMOBS, shown
/                   on p. 263 of "SAS Guide to Macro Processing" for Version 6)
/
/ SAS Version:      6.12
/
/ Created By:
/ Date:
/
/ Input Parameters: DATA - Name of dataset (default is last dataset referenced).
/                   MV   - Name of variable to store result (default = _NOBS).
/
/ Output Created:   Number of observations in dataset.
/
/ Macros Called:    None.
/
/ Example Call:     %DSOBS(data=data.ae, mv=nae);
/
/================================================================================================
/ Change Log
/
/    MODIFIED BY: Jonathan Fry
/    DATE:        09DEC1998
/    MODID:       JMF001
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 2.1.
/    -------------------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX002
/    DESCRIPTION:
/    -------------------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX003
/    DESCRIPTION:
/    -------------------------------------------------------------------------------
/================================================================================================*/

%macro DSOBS(data=_LAST_,mv=_nobs) ;

/*-----------------------------------------------------------------------------/
/ JMF001                                                                       /
/ Display Macro Name and Version Number in LOG                                 /
/-----------------------------------------------------------------------------*/

     %put ---------------------------------------------------;
     %put NOTE: Macro called: DSOBS.SAS   Version Number: 2.1;
     %put ---------------------------------------------------;


  %global &mv ;
  data _null_ ;
    if 0 then set &data nobs=count ;
    call symput("&mv",left(put(count,8.))) ;
    stop ;
    run ;
%mend DSOBS ;
