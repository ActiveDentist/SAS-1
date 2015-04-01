%macro SETGSF(file=,disp=,fileref=UTILGSF) ;
%*******************************************************************************
%*
%*                         Glaxo Wellcome Inc.
%*
%* PURPOSE: Set the current GSF file for graphics output and
%*          erase any that already exist
%*  AUTHOR: Carl Arneson
%*    DATE: 10 Feb 1997
%*MODIFIED: 31 Mar 1999 - 1. removed all open code
%*                        2. Added TYPE, NUM and TOC to file
%*
%******************************************************************************;

%*******************************************************************************
%* If we are using an appropriate PostScript device, insert the DONELIST
%* information at the top of it (as comment lines):
%******************************************************************************;
%local __gdev__ __ext__ ;
%let __gdev__ = %upcase(%sysfunc(getoption(device))) ;
%if %substr(%str( &__gdev__ ),1,2)=PS %then           %let __ext__ = ps  ;
%else %if %index(%str( PDF PDFC ),%str( &__gdev__ )) %then %let __ext__ = pdf ;
%else                                                 %let __ext__ = gsf ;

%*******************************************************************************
%* Set filename if it is blank and we are operating in background
%******************************************************************************;
%global _gsfinc_ ;
%if &_gsfinc_=
    %then %let _gsfinc_ = 001 ;
    %else %let _gsfinc_ = %eval(&_gsfinc_+1) ;
%if &UTSYSJOBINFO ~= INTERACTIVE %then %do ;
  %if %bquote(&file)= %then %do ;
    %let file = %fn ;
    %if %bquote(&file)=
        %then %let file = gsffile_&_gsfinc_..&__ext__ ;
        %else %let file = &file._%substr(0123456789abcdefghijklmnopqrstuvwxyz,&_gsfinc_,1).&__ext__ ;
  %end ;
  %else %if %qscan(%str(&file),2,%str(.))= %then
    %let file=&file..&__ext__ ;
%end ;
%else %do ;
  %let file = INTERACTIVE ;
%end ;

%*******************************************************************************
%* If OUTPUT was set and we are operating in DOCMAN mode, make sure
%* FILE uses OUTPUT directory.  If OUTPUT is set and we are not in DOCMAN
%* mode, use OUTPUT only if FILE doesnt already have a directory specified.
%******************************************************************************;
/*
%if %bquote(&__outd__)^= %then %do ;
  %if %quote(&__pub__) = YES %then %do ;
    %local root ;
    %let file = %sysfunc(reverse(&file)) ;
    %let file = %scan(&file,1,%str(\)) ;
    %let root = %sysfunc(reverse(&file)) ;
    %let file = %sysfunc(trim(&__outd__))\%sysfunc(reverse(&file)) ;
  %end ;
  %else %if %index(&file,%str(\))=0 %then %do ;
    %let file = %sysfunc(trim(&__outd__))\&file ;
  %end ;
%end ;
*/

%*******************************************************************************
%* Keep track of the number of times this FILE was used within this 
%* SAS session
%******************************************************************************;
%let disp = %upcase(&disp) ;
%global _sgsf0 ;
%local f ;
%if &_sgsf0 = %then %do ;
  %let _sgsf0  = %eval(&_sgsf0 + 1) ;
  %global _sgsf1 _sgsfn1 ;
  %let _sgsf1  = &file ;
  %let _sgsfn1 = 1 ;
  %let f       = 1 ;
%end ;
%else %do ;
  %do f=1 %to &_sgsf0 ;
    %if "&file"="&&_sgsf&f" %then %do ;
      %let _sgsfn&f = %eval(&&_sgsfn&f + 1) ;
      %goto exit ;
    %end ;
  %end ;
  %let _sgsf0 = &f ;
  %global _sgsfn&f _sgsf&f ;
  %let _sgsf&f = &file ;
  %let _sgsfn&f = 1 ;
%end ;
%exit:

%*******************************************************************************
%* If DISP was not set explicitly, set it according to whether other calls
%* within the SAS session used the same FILE.  For interactive sessions,
%* blank it out all together.
%******************************************************************************;
%if %bquote(&file)=INTERACTIVE
  %then %let disp = ;
%else %if "&disp"="" %then %do ;
  %if &&_sgsfn&f = 1
    %then %let disp = ; 
    %else %let disp = MOD ;
%end ;

%*******************************************************************************
%* Re-set specified fileref:
%******************************************************************************;
%local rc fid ;
%if %bquote(&file)=INTERACTIVE %then %do ;
  %let rc = %sysfunc(filename(fileref,,DUMMY)) ;
  %if &rc %then
    %put %sysfunc(sysmsg()) ;
%end ;
%else %do ;
  %if %bquote(&disp)=MOD %then %do ;
    %let rc = %sysfunc(filename(fileref,&file,DISK,MOD)) ;
	%if &rc %then
	  %put %sysfunc(sysmsg()) ;
  %end ;
  %else %do ;
    %let rc = %sysfunc(filename(fileref,&file)) ;
	%if &rc %then
	  %put %sysfunc(sysmsg()) ;
    %if %sysfunc(fexist(&fileref)) %then 
      %let rc = %sysfunc(fdelete(&fileref)) ;
	%if &rc %then
	  %put %sysfunc(sysmsg()) ;
  %end ;
%end ;

%mend SETGSF ;
