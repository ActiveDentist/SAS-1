/*
/ PROGRAM NAME: jkchkdat.sas
/
/ PROGRAM VERSION: 1.0
/
/ PROGRAM PURPOSE: Used internally by standard macros to check input
/    datasets for correct variables and variable type.  This macro can
/    be used by other macros or in user programs.
/
/ SAS VERSION: 6.12
/
/ CREATED BY: John Henry King
/ DATE: 1992
/
/ INPUT PARAMETERS:
/  data   = data set to be checked
/  cvars  = list of variables that must exist and are character
/  nvars  = list of variables that must exist and are numeric
/  vars   = list of variables that must exist of either type
/  return = name of global macro created by the macro, this is how the
/           macro communicates with the user.
/
/ OUTPUT CREATED:
/   a global macro variable named in return=
/
/ MACROS CALLED:
/   none
/
/ EXAMPLE CALL:
/    This example call is from AESTAT.  The parameter values are macro
/    variables that are parameters for AESTAT.  The %if shows
/    how AESTAT is directed to exit when &RC_A is not zero.
/
/  %jkchkdat(data=&adverse,
/            vars=&pageby &control &uniqueid &sex &level1 &level2,
/           nvars=&tmt,
/           cvars=&subgrp,
/          return=rc_a)
/
/   %if &rc_a %then %goto exit;
/
/==============================================================================
/ CHANGE LOG:
/
/ MODIFIED BY: John Henry King
/ DATE: 28FEB1997
/ MODID: JHK001
/ DESCRIPTION: Change the way the macro writes error messages. 
/------------------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID: JHK002
/ DESCRIPTION:
/------------------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID: JHK003
/ DESCRIPTION:
/============================================================================*/

/*
/ JKCHKDAT Macro
/
/ JKCHKDAT provides verification of the existence of a SAS data
/ set. JKCHKDAT also verifies the existance of variables on a
/ data set and can also verify that variables are numeric or
/ character.
/
/ To verify that variables of either type are on the data set
/ include their names in the VARS= parameter.
/
/ To verify that variables exist and are character include their
/ names in the CVARS= parameter.
/
/ To verify that variables exist and are numeric include their
/ name in the NVARS= parameter.
/
/ The macro provides error messages revealing the problems
/ identified by the macro, data set not found, variable not
/ found, or variable is the wrong type.
/
/ The macro also sets the macro variable named in the RETURN
/ parameter to 1 if any error is found.  The default name for
/ this macro variable is RC.  The user can change this through
/ the use of RETURN= if needed.
/
/ The user should provide appropriate logic in calling macro for
/ stopping execution of the calling macro when an error is found.
/-------------------------------------------------------------------*/

%macro JKCHKDAT(data=_last_, /* The dataset           */
               cvars=,       /* Character variables   */
               nvars=,       /* Numeric variables     */
                vars=,       /* Variables of any type */
             return=RC);

   %let data   = %upcase(&data);
   %let return = %upcase(&return);

   %global &return;
   %let &return = 0;


   /*
   / JHK001
   / Remove the ! from ERROR message.
   /---------------------------------------*/
   %local err dash;
   %let err  = ERROR: MACRO JKCHKDAT ERROR:;
   %let dash = _+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_; 

   /*
   / Create unique names for the temporary sas datasets used
   / in this macro
   /---------------------------------------------------------*/

   %local contents vlist;
   %let contents  = _1_&sysindex;
   %let vlist     = _2_&sysindex;

   /*
   / Call proc contents to find out if the data set exists
   / and if so to produce a data set of variable names with
   / their types.
   /-------------------------------------------------------*/
   proc contents noprint
         data = &data
         out  = &contents(keep=memname name type);
      run;

   /*
   / If the data set does not exist then SAS sets the automatic
   / macro variable SYSERR to 3000.  At any rate syserr is not
   / 0 assume that the data set does not exist.
   /------------------------------------------------------------*/

   %if &syserr^=0 %then %do;
      %put &dash;
      %put &err Data set, &data, not found.;
      %put &dash;
      %let &return=1;
      %end;

   %else %do;
      proc sort data=&contents;
         by name;
         run;

      /*
      / Now process the var lists into a data set that has the same
      / structure as that from proc contents.  The variable TYPE2
      / will be compared to TYPE from the proc contents output
      /--------------------------------------------------------------*/

      data &vlist;
         length name $8;
         retain delm ' -';
         array _v[0:2] $200 _temporary_ ("&vars","&nvars","&cvars");
         do i = 0 to 2;
            j = 1;
            name = scan(_v[i],j,delm);
            do while(name^=' ');
               name = upcase(name);
               output;
               j = j + 1;
               name = scan(_v[i],j,delm);
               end;
            end;
         stop;
         drop j;
         rename i=type2;
         run;

      proc sort data=&vlist;
         by name;
         run;

      /*
      / Now merge the proc contents output and the data from the step
      / above to ferret out the problems.
      /---------------------------------------------------------------*/


      /*
      / JHK001
      / The error message text in the section is being change to mask the 
      / message when this code is MPRINTed.
      /-----------------------------------------------------------------------*/
      data _null_;
         merge &contents(in=in1) &vlist(in=in2);
         by name;
         if _n_ = 1 then do;
            length err $28 dash $80;
            retain err dash;
            err = left(reverse('RORRE TADKHCKJ ORCAM :RORRE'));
            dash = repeat('_+',39);
            end;
            
         if ^in1 then do;
            put / dash / err "Variable " name "not found in data &data" '.' / dash / ' ';
            call symput("&return",'1');
            end;
         else if in2 then do;
            if type2^=0 & type^=type2 then do;
               if type2=1 then do;
                  put / dash / err "Variable " name 'must be numeric.' / dash / ' ';
                  end;
               else if type2=2 then do;
                  put / dash / err "Variable " name 'must be character.' / dash / ' ';
                  end;
               call symput("&return",'1');
               end;
            end;
         run;

      proc delete data=&contents &vlist;
         run;

      %end;
   %put NOTE: &return=&&&return;
   %mend JKCHKDAT;
