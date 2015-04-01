%macro SET_JOBINFO ;
%*******************************************************************************
%* Create a global macro variable UTSYSJOBINFO to store either the program
%* file name for batch execution or "INTERACTIVE" for interactive execution
%******************************************************************************;

%global UTSYSJOBINFO ;

%put SYSPROCESSNAME=&SYSPROCESSNAME ;
%if %scan(&SYSPROCESSNAME,1,%str( ))=Program %then
  %let UTSYSJOBINFO = %scan(&SYSPROCESSNAME,2,%str( %")) ;
%else
  %let UTSYSJOBINFO = INTERACTIVE ;

%put NOTE: UTSYSJOBINFO=&UTSYSJOBINFO ;
%mend SET_JOBINFO ;
