/*
/ Program Name:     GETOPTS.SAS
/
/ Program Version:  2.1
/
/ Program purpose:  Read your current system options and put the settings in
/                   macro variables.
/
/ SAS Version:      6.12
/
/ Created By:       Carl P. Arneson
/ Date:             14 Jul 1992
/
/ Input Parameters: OPT    - List of SAS options to be read.
/                   MV     - List of macro variables corresponding to the options specified
/                            in OPT.
/                   DUMP   - Y/N flag for defining whether to output option details to the
/                            log.
/                   CATLIB - Libname used for referencing catalog containing SCL code.
/
/ Output Created:   SAS option details are output to a set of macro variables. These details
/                   are dumped to the log if option DUMP=Y is specified.
/
/ Macros Called:    %bwwords
/
/ Example Call:     %getopts(opt=number missing date,mv=numb miss dat);
/
/=============================================================================================
/ Change Log
/
/   MODIFIED BY: ABR
/   DATE:        10.2.93
/   MODID:       Ver 1.5
/   DESCRIPTION: Remove commented LIBNAME statement.
/   ----------------------------------------------------------------------------
/   MODIFIED BY: Jonathan Fry
/   DATE:        09DEC1998
/   MODID:       JMF001
/   DESCRIPTION: Tested for Y2K compliance.
/                Add %PUT statement for Macro Name and Version Number.
/                Change Version Number to 2.1.
/   ----------------------------------------------------------------------------
/   MODIFIED BY:
/   DATE:
/   MODID:       XXX002
/   DESCRIPTION:
/   ----------------------------------------------------------------------------
/=============================================================================================*/

%macro GETOPTS(opt   =,
               mv    =,
               dump  =Y,
               catlib=utilscl);

/*------------------------------------------------------------------------/
/ JMF001                                                                  /
/ Display Macro Name and Version Number in LOG                            /
/------------------------------------------------------------------------*/

   %put ------------------------------------------------------;
   %put NOTE: Macro called: GETOPTS.SAS    Version Number: 2.1;
   %put ------------------------------------------------------;

   %if &sysver<6.09 %then %do ;
      %put ERROR: You must use version 6.09 or higher with SUMTAB. ;
      %if &sysenv=BACK %then %str(;ENDSAS;) ;
   %end ;

   %local numopt nummv num i ;
   %let dump = %upcase(%substr(&dump,1,1)) ;
   %let opt = %upcase(&opt) ;
   %let mv = %upcase(&mv) ;
   %let numopt = %bwwords(&opt,root=___opt) ;
   %let nummv = %bwwords(&mv,root=___mv) ;
   %if &numopt ~= &nummv %then %do ;
      %let msg1=%str(The number of options specified (&numopt) does not) ;
      %let msg2=%str(equal the number of variables specified (&nummv)) ;
      %put WARNING: &msg1 &msg2 ;
      %let num=%eval((&numopt<&nummv)*&numopt + (&numopt>&nummv)*&nummv) ;
   %end ;
   %else %let num = &numopt ;
   %do i = 1 %to &num ;
      %global &&___mv&i ;
	  %let &&___mv&i = %sysfunc(getoption(&&___opt&i)) ;
   %end ;

   %*if &dump=Y %then %do ;
   %if 1=1 %then %do ;
      %put Options --------------------------------------------------------;
      %do i = 1 %to &num ;
         %local val ;
         %let val = &&___mv&i;
         %put &&___opt&i is set to &&&val. ;
      %end ;
      %put ----------------------------------------------------------------;
   %end ;
%mend GETOPTS;
