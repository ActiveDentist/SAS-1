%macro DATACONT(lib=,title=1,obs=25) ;
%**********************************************************************;
%*                                                                    *;
%* This macro will print the contents followed by a listing of the    *;
%* first OBS= observations of each member of the specified data       *;
%* library.                                                           *;
%*                                                                    *;
%**********************************************************************;

%***********************************************************************
%* Store all the members of the specified library in a data set:
%**********************************************************************;
proc contents data=%quote(&lib)._all_ noprint out=_t_m_p_ ;
  run ;

%***********************************************************************
%* Make sure each data set only has one observation:
%**********************************************************************;
proc sort data=_t_m_p_ nodupkey ;
  by memname ;
  run ;

%***********************************************************************
%* Put all the data sets in a macro variable array:
%**********************************************************************;
data _null_ ;
  set _t_m_p_ end=eof ;
  i + 1 ;
  call symput('_mem' || left(put(i,5.)), trim(memname)) ;
  if eof then call symput('_mem0',left(put(i,5.))) ;
  run; 


%***********************************************************************
%* Figure out the first available title line, so we dont overwrite
%* any current titles:
%**********************************************************************;
%local nt ;
%bwgettf(dump=NO) ;
%if &_bwt0 > 8 %then %let nt=10 ;
%else                %let nt=%eval(&_bwt0 + 1) ;


%***********************************************************************
%* Loop over the macro variable array, and do a PROC CONTENTS and
%* PROC PRINT on each data set:
%**********************************************************************;
%local i ;
%do i = 1 %to &_mem0 ;

  proc contents data=%quote(&lib).&&_mem&i ;
    title&nt "*** &&_mem&i ***" ;
    run; 

  proc print data=%quote(&lib).&&_mem&i (obs=&obs);
    title&nt "*** &&_mem&i ***" ;
    run ;

%end ;

%mend DATACONT ;
