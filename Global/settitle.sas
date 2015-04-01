/*
/ Program Name:     SETTITLE.SAS
/
/ Program Version:  2.2
/
/ Program Purpose:  Place the titles for the current program from the titles
/                   data set into global macro variables
/
/ SAS Version:      6.12 TS020
/
/ Created by:       Carl 'Shifty' Arneson
/ Date:
/
/ Input Parameters:
/
/ Output Created:
/
/ Macros Called:
/
/ Example Call:
/
/============================================================================================
/ Change Log:
/
/    MODIFIED BY: SR Austin
/    DATE:        13Dec1994
/    MODID:
/    DESCRIPTION: Added LABEL macro variable
/    ----------------------------------------------------------------------------------
/    MODIFIED BY: SR Austin
/    DATE:        17Jan1995
/    MODID:
/    DESCRIPTION: Added Old-Style section in case macro is inadvertantly called by an
/                 old-style project. Old-style is recognized by lack of LABEL variable
/                 in titles dataset.
/    ----------------------------------------------------------------------------------
/    MODIFIED BY: SR Austin
/    DATE:        27Mar1995
/    MODID:
/    DESCRIPTION: If table number is missing, add a mock number
/    ----------------------------------------------------------------------------------
/    MODIFIED BY: SR Austin
/    DATE:        16May1995
/    MODID:
/    DESCRIPTION: DOCMAN Types must be T, F, or A
/    ----------------------------------------------------------------------------------
/    MODIFIED BY: SR Austin
/    DATE:        25Oct1995
/    MODID:
/    DESCRIPTION: Allow 5-digit protocol identifiers.
/    ----------------------------------------------------------------------------------
/    MODIFIED BY: SR Austin
/    DATE:        04Oct1996
/    MODID:
/    DESCRIPTION: Allow DATA LISTING to be a valid TYPE indicating an Appendix.
/    ----------------------------------------------------------------------------------
/    MODIFIED BY: SR Austin
/    DATE:        13May1996
/    MODID:
/    DESCRIPTION: Fixed bug whereby missing table nums were not being assigned.
/    ----------------------------------------------------------------------------------
/    MODIFIED BY: John 'Dufus' King
/    DATE:        20oct1997
/    MODID:       JHK001
/    DESCRIPTION: Change section that created MACTYPE to allow for the 5 SWIFT table
/                 types and retain APPENDIX one of the old types.
/    ---------------------------------------------------------------------------------
/    MODIFIED BY: Jonathan Fry
/    DATE:        10DEC1998
/    MODID:       JMF002
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 2.2.
/    ---------------------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX003
/    DESCRIPTION:
/    ---------------------------------------------------------------------------------
/============================================================================================*/

%macro SETTITLE(
                fn=%fn,              /* File name of current program (e.g., %fn)  */
                number=tabnum,       /* Numbering field to use (TABNUM or REFNUM) */
                dset=in.title&prot.  /* TITLES data set to use                    */
               ) ;

      /*
      / JMF002
      / Display Macro Name and Version Number in LOG
      /-----------------------------------------------------*/

      %put ------------------------------------------------------;
      %put NOTE: Macro called: SETTITLE.SAS   Version Number: 2.2;
      %put ------------------------------------------------------;

      %put NOTE: Using PROTOTYPE version of the SETTITLE macro.;
      %put Contact Carl Arneson if you experience problems.    ;

%* see if we have a title file name that is too long ;
%if "&dset."="in.title&prot." & %length(&prot) > 3 %then
   %let dset=in.t&prot.;
%*---------------------------------------------------------------------*;
%* check to see if we are using old-style or new-style titles system   *;
%local style; %let style=OLD;
options nodsnferr ;
proc contents data=&dset noprint out=___c_out(keep=name);
data _null_; set ___c_out(where=(name="LABEL"));
  call symput("style","NEW");
run;
options dsnferr;
%* if default dataset is specified, then use the old-style default;
%if &style=OLD & &dset=in.title&prot %then %let dset=in.titles;

%*---------------------------------------------------------------------*
|  Reset the %TITLE macro counter:
*----------------------------------------------------------------------;
%global __tmcnt _t_____n;
%let __tmcnt = 0 ;%let _t_____n=0;

%*---------------------------------------------------------------------*
|  Get only observations for the current program from the
|  titles data set:
*----------------------------------------------------------------------;
data t_e_m_p ;
  set &dset (where=(upcase(program)="%upcase(&fn)")) ;
  run ;

%*---------------------------------------------------------------------*
|  Count the number of title entries for the current program:
*----------------------------------------------------------------------;
%local _nobs ;
data _null_ ;
  if 0 then set t_e_m_p nobs=count ;
  call symput('_nobs',left(put(count,8.))) ;
  stop ;
  run ;


%if &style=NEW %then %do;
%*---------------------------------------------------------------------*
|  Initialize and globalize the macro variables:
|
|    TNSTR1-TNSTRn, __TYPE1-__TYPEn, __NUM1-__NUMn, TTL1_1-TTL8_n
|
|    where n is the number of observations in the titles data set
|    for the current program.
*----------------------------------------------------------------------;
%local i j ;
%do i = 1 %to &_nobs ;
  %global tnstr&i __type&i __num&i __LBL_&i. ;
  %do j = 1 %to 8 ;
    %global ttl&j._&i ;
  %end ;
  %do j = 1 %to 10 ;
    %global fnt&j._&i ;
  %end ;
%end ;

%*---------------------------------------------------------------------*
|  Read the titles data set and use CALL SYMPUT to put the titles and
|  table numbers into the appropriate macro variables:
*----------------------------------------------------------------------;
%let _t_____n = &_nobs;
%if &_nobs>0 %then %do ;
  data _null_ ; length mactype $1 &number. $8;
    set t_e_m_p ;
    array _t {8} title1-title8 ;
    array _f {10} fn1-fn10 ;

    dumcnt+1;

    if indexc(upcase(&number.),"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ")=0
      then &number=compress('M' !! put(dumcnt,3.0));

    if type<=" " then type='Mock';


/*
    %* Define TYPES for MACPAGE (Only T, F, and A are allowed) ;
     if upcase(type) in("T","TABLE","DATA SUMMARY","E","EXHIBIT") then mactype="T";
     else if
     upcase(type) in("A","APPENDIX","X","XA","X-APPENDIX","XAPPENDIX","DATA LISTING")
      then mactype="A";
     else if upcase(type) in("F","FIGURE","G","GRAPH") then mactype="F";
     else mactype=' ';
 */

      /*
      / JHK001
      / Define TYPES for MACPAGE using new SWIFT classes.
      /-----------------------------------------------------*/

      uptype = upcase(type);
      select(uptype);
         when('T','TABLE','DATA SUMMARY','E','EXIBIT')          mactype = 'T';
         when('A','APPENDIX','X','XA','X-APPENDIX','XAPPENDIX') mactype = 'A';
         when('SUPPORTING TABLE','SUPPORTING TAB')              mactype = 'S';
         when('LISTING')                                        mactype = 'L';
         when('DATA LISTING')                                   mactype = 'D';
         when('CRF TABULATION','TABULATION')                    mactype = 'C';
         when('F','FIGURE','G','GRAPH')                         mactype = 'F';
         otherwise                                              mactype = 'U';
         end;

    call symput(compress('tnstr'||left(_n_)),trim(type)||' '||trim(&number)) ;
    call symput(compress('__type'||left(_n_)),substr(mactype,1,1)) ;
    call symput(compress('__num'||left(_n_)),trim(&number)) ;
    call symput(compress('__LBL_'||left(_n_)),upcase(label)) ;
    do i = 1 to dim(_t) ;
      call symput(compress('ttl'||left(i)||'_'||left(_n_)),trim(_t{i})) ;
    end ;
    do i = 1 to dim(_f) ;
      call symput(compress('fnt'||left(i)||'_'||left(_n_)),trim(_f{i})) ;
    end ;
    run ;
%end ;

%end;
%else %if &style=OLD %then %do;

%do i = 1 %to &_nobs ;
  %global tabnum&i type&i num&i ;
  %do j = 1 %to 9 ;
    %global ttl&j._&i ;
  %end ;
%end ;

%if &_nobs>0 %then %do ;
  data _null_ ;
    set t_e_m_p ;
    array _t {9} title1-title9 ;
    call symput(compress('tabnum'!!left(_n_)),trim(type)!!' '!!trim(tabnum)) ;
    call symput(compress('type'!!left(_n_)),substr(type,1,1)) ;
    call symput(compress('num'!!left(_n_)),trim(tabnum)) ;
    do i = 1 to dim(_t) ;
      call symput(compress('ttl'!!left(i)!!'_'!!left(_n_)),trim(_t{i})) ;
    end ;
    run ;
%end ;

%end; %*** End old-style code ***;

%mend SETTITLE ;
