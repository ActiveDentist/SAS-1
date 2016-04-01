%macro BRANCH(arg) ;
%**********************************************************************;
%*                                                                    *;
%* This macro will determine if a branch of a data program should     *;
%* execute by comparing the argument to the list of appropriate       *;
%* branches in the BRANCHES global macro variable (which normall      *;
%* gets created by the %BRANCHES macro).                              *;
%*                                                                    *;
%**********************************************************************;

%***********************************************************************
%* Fix up the argument for comparing:
%**********************************************************************;
%let arg=%left(%trim(%upcase(&arg))) ;

%***********************************************************************
%* Make sure the BRANCHES global macro variable has been set:
%**********************************************************************;
%global branches ;
%if "&branches"="" %then %do ;
  %put WARNING: BRANCHES global macro variable is null. ;
  %let branches=__NONE__;
%end ;

%***********************************************************************
%* Return 1 if the argument is in the list of branches, and 0 otherwise:
%**********************************************************************;
%if "&branches"="ALL" |
    %index(%str( &branches ),%str( &arg )) %then %do ;
  %put NOTE: Processing &arg branch of %fn MAIN macro. ;
  1
%end ;
%else %str(0) ;

%mend BRANCH ;

