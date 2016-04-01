/*
/ Program Name: MAKERUN.SAS
/
/ Program Version: 2.1
/
/ Program purpose: Used to run a multi-protocol program enclosed within a macro, for a given
/                  protocol or list of protocols.
/
/ SAS Version: 6.12
/
/ Created By:
/ Date:
/
/ Input Parameters:
/
/      GROUP -
/      VAR   - Name of operating system environment variable containing list of protocols.
/      PARAM - Parameter to pass to the macro MAIN, used for specifying protocol number.
/      EXTRA - Additional parameters to be passed to macro MAIN.
/
/ Output Created: None.
/
/ Macros Called: BWWORDS
/
/ Example Call:  %makerun(var=proto,param=prot);
/
/==============================================================================================
/ Change Log
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
/==============================================================================================*/

%macro MAKERUN(group=,
               var=,
               param=,
               extra=) ;

   /*
   / JMF001
   / Display Macro Name and Version Number in LOG
   /---------------------------------------------------------------*/

   %put -----------------------------------------------------;
   %put NOTE: Macro called: MAKERUN.SAS   Version Number: 2.1;
   %put -----------------------------------------------------;


  %local protlist ;
  %let group = %upcase(&group) ;
  %let var = %upcase(&var) ;
  %let protlist = %sysget(&var) ;
  %if &protlist= %then %do ;
    %local msg1 msg2 ;
      %let msg1 = %str(NOTE: No protocols were read from the environmental);
      %let msg2 = %str(variable &var);
    %put &msg1 &msg2 ;
  %end ;
  %else %do ;
    %put NOTE: Processing protocol(s): &protlist ;
    %local __num ;
    %let __num = %bwwords(&protlist,root=__pr) ;
    %local i ;
    %if %quote(&param)~= %then %let param = &param= ;
    %if %bquote(&extra)~= %then %let extra = ,&extra ;
    %do i = 1 %to &__num ;
      %main(&param &&__pr&i &extra) ;
    %end ;
    %endsas ;
  %end ;
%mend MAKERUN ;
