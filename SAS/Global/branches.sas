%macro BRANCHES(dsl) ;
%**********************************************************************;
%*                                                                    *;
%* This macro will build a list of brances of the data program to     *;
%* execute based on the data set list specified and the dependency    *;
%* scheme specified in the BRNCHDEF macro variable.  It will create   *;
%* a global variable called BRANCHES.                                 *;
%*                                                                    *;
%**********************************************************************;

%***********************************************************************
%* Globalize the BRANCHES variable, so it can be used later.  Also,
%* make sure a BRNCHDEF global variable has been defined:
%**********************************************************************;
%global BRANCHES brnchdef ;

%***********************************************************************
%* Fix up the data set list, so teh compares work:
%**********************************************************************;
%let dsl=%left(%trim(%upcase(&dsl))) ;


%***********************************************************************
%* If the BRNCHDEF global variable has not been defined, assume
%* no branches will need to get executed:
%**********************************************************************;
%if "&brnchdef"="" %then %let branches=__NONE__ ;

%***********************************************************************
%* If ALL data sets are specified, set BRANCHES to ALL:
%**********************************************************************;
%else %if "&dsl" = "ALL" %then %let branches=ALL;

%***********************************************************************
%* Otherwise, build branch list based on specified data sets and
%* dependency structure:
%**********************************************************************;
%else %do ;
  
  %*********************************************************************
  %* Parse BRNCHDEF global macro variable into the following local
  %* macro variable arrays:
  %*        B1-Bn, B0       (the branch names)
  %*        B1_1-B1_k, B1_0 (data sets that contribute to branch 1)
  %*              to
  %*        Bn_1-Bn_k, Bn_0 (data sets that contribute to branch n)
  %********************************************************************;
  %local i j b0 st b0_0 ;
  %let i = 1;   %* word counter ;
  %let b0 = 0;   %* branch counter ;
  %let b0_0=0 ; %* counter for dsets in a branch ;
  %let st = %scan(&brnchdef,&i,%str( )) ;
  %do %while (%quote(&st)~=);
    %if %index(&st,%str(:))=%length(&st) %then %do ;
      %let b0 = %eval(&b0 + 1) ;
      %local b&b0 b&b0._0 ;
      %let b&b0 = %substr(&st,1,%length(&st)-1) ;
      %let b&b0._0 = 0 ;
    %end ;
    %else %do ;
      %let b&b0._0 = %eval(&&b&b0._0 + 1) ;
      %local tmp ;
      %let tmp = &&b&b0._0 ;
      %local b&b0._&tmp ;
      %let b&b0._&tmp = &st ;
    %end ;
    %let i = %eval(&i + 1) ;
    %let st = %scan(&brnchdef,&i,%str( )) ;
  %end ;

  
  %*********************************************************************
  %* For each of the branches, compare each contributing data set
  %* to the specified data set list, and append branches for which
  %* data sets match to the BRANCHES macro variable:
  %********************************************************************;
  %let branches=;
  %do i = 1 %to &b0 ;
    %do j = 1 %to &&b&i._0 ;
      %if   %index(%str( &dsl ),%str( &&b&i._&j ))
                           and
            %index(%str( &branches ),%str( &&b&i ))=0
      %then %let branches=%left(%trim(&branches &&b&i)) ;
    %end ;
  %end ;

  
  %*********************************************************************
  %* Specify that no branches should be executed if no matches
  %* are found:
  %********************************************************************;
  %if "&branches"="" %then %let branches=__NONE__ ;

%end ;

%mend BRANCHES ;
