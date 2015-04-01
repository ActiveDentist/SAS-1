/*
/ PROGRAM NAME: jkfn.sas
/
/ PROGRAM VERSION: 1.0
/
/ PROGRAM PURPOSE: This macro is used to determine the filename and userid
/   of the executing program.  This information was previously supplied by
/   a modified SAS script.  The default for this macro are to assign this
/   data to SYSPARM in the format that was supplied by the SAS script method.
/   This macro is used in MACPAGE.  If the user needs to use %FN before
/   macpage is called then this macro should be called first, perhaps in INIT.
/
/ SAS VERSION: 6.12 (UNIX)
/
/ CREATED BY: John Henry King
/
/ DATE: 04MAR1997
/
/ INPUT PARAMETERS:
/
/   mvar=   specifies the name of the macro variable assigned.  Use just the 
/           name with no &.  The default is SYSPARM.
/
/   style=  specifies the style of the output.  
/           Valid values are:
/              SYSPARM          ==> userid:\fullpathtofile
/              FULLPATH         ==> fullpath
/              FULLPATH_NO_EXT  ==> fullpath with the extension removed
/              NAME_ONLY        ==> name only
/              NAME_ONLY_NO_ENT ==> name only with the extension removed
/           
/
/    
/ OUTPUT CREATED: Assigns a value to a EXISTING macro variable.  You must be 
/   sure that the variable exists, probably makeing a GLOBAL macro variable 
/   is the easiest.
/ 
/ MACROS CALLED: none
/
/ EXAMPLE CALL:
/  in open code
/  
/  %global pgmpath;
/  %jkfn(mvar=pgmpath,style=fullpath)
/
/   
/==============================================================================
/ CHANGE LOG:
/
/ MODIFIED BY:
/ DATE:
/ MODID: JHK001
/ DESCRIPTION:
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
%macro jkfn(mvar = SYSPARM,
           style = SYSPARM);


   %let style = %upcase(&style);
   %let mvar  = %upcase(&mvar);

   %local _j_k_t_m;
   %global syssesid;

   /*
   / It appears that when a display manages sessing is running
   / the GLOBAL macro variables SYSSESID has the value SAS. When
   / display manager is not running the this variable does not
   / exist.  I will using this to determine if the program is running
   / INTERACTIVE, or non-interactive, i.e dropped on the SAS icon or
   / run from the command line in a terminal session.
   /------------------------------------------------------------------*/

   %if &syssesid^= %then %do;
      %let _j_k_t_m = INTERACTIVE;
      %end;
   %else %do;
      proc sql noprint;
         select xpath
            into :_j_k_t_m
            from dictionary.extfiles
            where fileref='_TMP0002';
         quit;
      %end;


   %if &style = SYSPARM %then %do;
      %let &mvar = %sysget(LOGNAME):&_j_k_t_m;
      %end;
   %else %if &style = FULLPATH %then %do;
      %let &mvar = &_j_k_t_m;
      %end;
   %else %if &style = FULLPATH_NO_EXT %then %do;
      %let &mvar = %substr(&_j_k_t_m,1,%index(&_j_k_t_m,.)-1);
      %end;
   %else %if &style = NAME_ONLY %then %do;
      %let _j_k_t_m = %sysfunc(reverse(&_j_k_t_m));
      %let _j_k_t_m = %substr(&_j_k_t_m,1,%index(&_j_k_t_m,/)-1);
      %let &mvar   = %sysfunc(reverse(&_j_k_t_m));
      %end;
   %else %if &style = NAME_ONLY_NO_EXT %then %do;
      %let _j_k_t_m = %sysfunc(reverse(&_j_k_t_m));
      %let _j_k_t_m = %substr(&_j_k_t_m,1,%index(&_j_k_t_m,/)-1);
      %let _j_k_t_m = %sysfunc(reverse(&_j_k_t_m));
      %let &mvar    = %substr(&_j_k_t_m,1,%index(&_j_k_t_m,.)-1);
      %end;
   
   %put NOTE: &mvar = &&&mvar;

   %mend;
