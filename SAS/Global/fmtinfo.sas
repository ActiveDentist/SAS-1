/*
/ Program Name:     FMTINFO.SAS
/
/ Program Version:  2.1
/
/ Program purpose:  Return Information About the Formats in the Specified
/                   Version 6 Format Library
/
/ SAS Version:      6.12
/
/ Created By:       Carl P. Arneson
/ Date:             06 Jan 1993
/
/ Input Parameters: LIB     - library name used for format catalog
/                   FMTOUT  - name of dataset for storing format catalog details
/                   SELECT  - list of catalog entries to be selected (optional)
/                   EXCLUDE - list of catalog entries to be excluded (optional)
/                             (either SELECT or EXCLUDE can be specified, but not both)
/                   REPORT  - (Y/N) option for producing a report
/
/ Output Created:   Format details are output to the dataset specified in the parameter
/                   FMTOUT. A report is produced if hte value of the parameter REPORT is
/                   set to Y.
/
/ Macros Called:    INFIX.SAS
/
/ Example Call:
/
/===========================================================================================
/ Change Log
/
/    MODIFIED BY: Jonathan Fry
/    DATE:        09DEC1998
/    MODID:       JMF001
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 2.1.
/    ---------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX002
/    DESCRIPTION:
/    ---------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX003
/    DESCRIPTION:
/    ---------------------------------------------------------------------
/==========================================================================================*/

%macro FMTINFO(lib=,
               out=FMTOUT,
               select=,
               exclude=,
               report=Yes);

/*-------------------------------------------------------------------------/
/ JMF001                                                                   /
/ Display Macro Name and Version Number in LOG                             /
/-------------------------------------------------------------------------*/

   %put -----------------------------------------------------;
   %put NOTE: Macro called: FMTINFO.SAS   Version Number: 2.1;
   %put -----------------------------------------------------;

%local where;

%if %length(&report)  %then %let report=%substr(%upcase(&report),1,1);
%if %length(&select)  %then %let select=%left(%trim(%upcase(&select)));
%if %length(&exclude) %then %let exclude=%left(%trim(%upcase(&exclude)));

%if %length(&select) %then
  %let where=%infix(list=&select,operator=%str(,),quote=Yes);

%else %if %length(&exclude) %then
  %let where=%infix(list=&exclude,operator=%str(,),quote=Yes);

%if %length(&select) %then
  %let where=(where=(fmtname in(&where)));

%else %if %length(&exclude) %then
  %let where=(where=(fmtname ~in(&where)));

proc format lib=&lib cntlout=&out ;
  run ;

data &out ;
  set &out &where ;
  length idname $20 ;
  if type in('C','J') then idname = '$' !! fmtname ;
  else idname = fmtname ;
  run ;

%if &report=Y %then %do ;
  proc report nowd data=&out headline headskip missing ;
    column idname length start end sexcl eexcl hlo
           range label ;
    define idname / order width=12 center 'Format Name';
    define length / order width=6 center 'Length' ;
    define start / noprint spacing=0 ;
    define end / noprint spacing=0 ;
    define sexcl / noprint spacing=0 ;
    define eexcl / noprint spacing=0 ;
    define hlo / noprint spacing=0 ;
    define range / computed center 'Range' ;
    define label / display left 'Label' ;
    break after length / skip ;
    compute range / char length=30 ;
      if hlo='O' then do ;
        start='OTHER' ;
        end='OTHER' ;
      end ;
      if index(hlo,'L') then do ;
        start='LOW' ;
        sexcl='Y' ;
      end ;
      if index(hlo,'H') then do ;
        end='HIGH' ;
        eexcl='Y' ;
      end ;
      if start=end then
         range = '<' !! left(trim(start)) !! '>' ;
      else do ;
        if sexcl='Y' then range = '<' !! left(start) ;
        else range = '(' !! start ;
        range = trim(range) !! ',' !! left(end) ;
        if eexcl='Y' then range = trim(range) !! '>' ;
        else range = trim(range) !! ')' ;
      end ;
    endcomp ;
    run ;
%end ;

%mend FMTINFO ;
