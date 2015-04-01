/*
/ Program name:     FN.SAS
/
/ Program purpose:  Returns name of current SAS program
/                   (or INTERACTIVE if run interactively)
/

/========================================================================*/

%macro fn;

%local fn i ;
%let fn = &UTSYSJOBINFO ;
%let i = %index(&fn,%str(\)) ;
%do %while(&i) ;
  %let fn = %substr(&fn,%eval(&i + 1)) ;
  %let i = %index(&fn,%str(\)) ;
%end ;
%let fn = %scan(&fn,1,%str(.)) ;
&fn

%mend fn ;
