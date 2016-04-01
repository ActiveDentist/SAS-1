%macro phlrtest(data=,
                var=,
                resp=,
                label=,
                out=) ;

%***********************************************************************
%*
%*                        Burroughs Wellcome Co.
%*
%* PURPOSE: Calculate Type I and Type III Likelihood Ratio Tests
%*          for Specified Effects in Proportional Hazards Regression
%*  AUTHOR: Carl Arneson
%*    DATE: 18 Nov 1996
%*
%**********************************************************************;

%***********************************************************************
%* Parse up the variable list:
%**********************************************************************;
%local i model df phvs groups timev censv;
%let groups = 0 ;
%let phv0=%words(&var,root=phv) ;
%do i = 1 %to &phv0 ;
  %if %index(&&phv&i,%str(+)) %then %let groups = 1 ;
  %let phv&i = %translat(&&phv&i,%str(+),%str( )) ;
  %let phvs = &phvs &&phv&i ;
%end ;
%let timev=%scan(&resp,1,%str(*)) ;
%let censv=%scan(&resp,2,%str(*)) ;
%if %index(&censv,%str(%()) %then
  %let censv = %substr(&censv,1,%index(&censv,%str(%())-1) ;

%***********************************************************************
%* Parse up the label list:
%**********************************************************************;
%if %length(&label)=0 %then %let label=&var ;
%let phl0=%words(&label,root=phl) ;
%if &phl0~=&phv0 %then %do ;
  %put ERROR: Must supply a label in LABEL= for each variable in VAR= ;
  %goto leave ;
%end ;


%***********************************************************************
%* Fit the full model:
%**********************************************************************;
filename phlrtest "/tmp/phlrtest.&sysjobid" ;

proc printto print=phlrtest new ;
  run ;

data _d_a_t_a ;
  set &data (where=(nmiss(
                         %infix(list=&timev &censv &phvs,operator=%str(,))
                         )=0)) ;
  run ;

proc phreg data=_d_a_t_a outest=&out(
                                  keep=_lnlike_
                                  %if &groups=0 %then %do ;
                                    &phvs
                                  %end ;
                                  rename=(_lnlike_=full)
                                 ) ;
  model &resp = &phvs ;
  run ;

proc printto ;
  run ;

data _t_m_p ;
  infile phlrtest length=len ;
  input @1 line $varying200. len ;
  if index(left(line),'-2 LOG L')=1 then do ;
    drop line ;
    i1 = input(scan(line,4,' '),12.) / -2 ;
    dfi1 = 0 ;
    output ;
  end ;
  run ;

x "rm /tmp/phlrtest.&sysjobid" ;

%if &groups=0 %then %do ;
  proc transpose data=&out out=_p_a_r_m(keep=_name_ col1
                                        rename=(col1=estimate)) ;
    var &phvs ;
    run ;
  data _p_a_r_m ;
    set _p_a_r_m ;
    effect + 1 ;
    * drop _name_ ;
    run ;
%end ;

data &out ;
  merge &out(keep=full) _t_m_p ;
  run ;

%***********************************************************************
%* Fit all the models for the type III tests:
%**********************************************************************;
%if &phv0>1 %then %do i = 1 %to &phv0 ;

  %let model = %remove(&phvs,&&phv&i) ;
  %let df = %words(&model,root=____) ;

  proc phreg data=_d_a_t_a noprint outest=_t_m_p(
                                              keep=_lnlike_
                                              rename=(_lnlike_=III&i)
                                             ) ;
    model &resp = &model ;
    run ;

  data &out ;
    merge &out _t_m_p ;
    dfIII&i = &df ;
    run ;

%end ;

%***********************************************************************
%* Fit all the models for the type I tests:
%**********************************************************************;
%let model=%remove(&phvs,&&phv&phv0) ;

%do i = %eval(&phv0 - 1) %to 2 %by -1 ;

  %let model = %remove(&model,&&phv&i) ;
  %let df = %words(&model,root=____) ;

  proc phreg data=_d_a_t_a noprint outest=_t_m_p(
                                              keep=_lnlike_
                                              rename=(_lnlike_=I&i)
                                             ) ;
    model &resp = &model ;
    run ;

  data &out ;
    merge &out _t_m_p ;
    dfI&i = &df ;
    run ;

%end ;
 
data &out ;
  set &out ;
  keep effect label df1 chisq1 pval1 df3 chisq3 pval3 ;

  dffull = %words(&phvs,root=____) ;
  %if &phv0>1 %then %do ;
    array _df1 {*} dfi1-dfi%eval(&phv0 - 1) dfiii&phv0 dffull ;
    array _ll1 {*} i1-i%eval(&phv0 - 1) iii&phv0 full ;
    array _df3 {*} dfiii1-dfiii&phv0 ;
    array _ll3 {*} iii1-iii&phv0 ;
  %end ;
  %else %do ;
    array _df1 {*} dfi1 dffull ;
    array _ll1 {*} i1 full ;
    array _df3 {*} dfi1 ;
    array _ll3 {*} i1 ;
  %end ;

  length label $20 ;
  do effect = 1 to &phv0 ;
    label = upcase(symget('PHL' || trim(left(put(effect,3.))))) ;
    
    * type I analyses ;
    df1 = _df1{effect+1} - _df1{effect} ;
    chisq1 = 2 * abs(_ll1{effect+1} - _ll1{effect}) ;
    pval1 = 1 - probchi(chisq1,df1) ;

    * type III analyses ;
    df3 = dffull - _df3{effect} ;
    chisq3 = 2 * abs(full - _ll3{effect}) ;
    pval3 = 1 - probchi(chisq3,df3) ;

    output ;
  end ;
  
  run ; 

%if &groups=0 %then %do ;
  data &out ;
    merge &out _p_a_r_m ;
    by effect ;
    run ;
%end ;

%leave: 

%mend phlrtest ;
