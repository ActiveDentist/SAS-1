%macro WINDOWS (
               type=,                  /* Type of window                     (REQUIRED) */
               datetime=,              /* Date-time variable for observation (REQUIRED) */
               ref=,                   /* List of reference variables        (REQUIRED) */

               data=_LAST_,            /* Data set for which windows will be calculated */
               out=,                   /* Output data set (if different from DATA=)     */
               windata=IDS.WINDOWS,     /* WINDOWS data set                              */
               multiple=N,             /* Allow observations to fit multiple windows?   */

               window=window,          /* Name of variable to contain window value           */
               diff=diff,              /* Name of variable to contain difference from target */
               sign=sign,              /* Name of variable to contain direction of diff.     */
               pref=pref,              /* Name of variable to contain preferred sort order   */
               units_v=rt_unit,        /* Name of variable to contain %RELTIME(UNITS_V=)     */
               round_v=rt_round,       /* Name of variable to contain %RELTIME(ROUND_V=)     */
               num_win=num_win         /* Number of windows that fit assessment              */
               ) ;

%***********************************************************************;
%*                                                                     *;
%* This macro will calculate time windows for observations based       *;
%* on the "WINDOWS" data set for a study.                              *;
%*                                                                     *;
%***********************************************************************;

%***********************************************************************
%* Process parameters:
%**********************************************************************;
%* Check for required parameters ;
%if %length(&type)=0 or %length(&ref)=0 or %length(&datetime)=0 %then %do ;
  %put ERROR: (WINDOWS) must specify TYPE=, DATETIME= and REF= ;
  %goto leave ;
%end ;

%* Set OUT= if it isnt set ;
%if %length(&out)=0 and %length(&data)<=8 %then
  %let out=&data ;

%* Reset defaut if DATA= isnt set ;
%if %length(&data)=0 %then
  %let data=_LAST_ ;

%local _win_obs _error_ ref0 i ;
 
%* build an array of reference date-time variables ;
%let ref0=1 ;
%do %while (%scan(&ref,&ref0,%str( ))~=) ;
  %local ref&ref0 ;
  %let ref&ref0 = %scan(&ref,&ref0,%str( )) ;
  %let ref0 = %eval(&ref0 + 1) ;
%end ;
%let ref0 = %eval(&ref0 - 1) ;
  


%***********************************************************************
%* Grab input data:
%**********************************************************************;
data _d_a_t_a ;
  set &data ;
  run ;


%***********************************************************************
%* Process WINDOWS data set:
%**********************************************************************;
data _null_ ;
  set &windata (where=(type="%upcase(&type)")) end=eof ;

  array b_num {10} _temporary_ ;
  array e_num {10} _temporary_ ;
  array b_unit {10} $2 _temporary_ ;
  array e_unit {10} $2 _temporary_ ;
  array b_op {10} $2 _temporary_ ;
  array e_op {10} $2 _temporary_ ;
  array refv {10} $8 _temporary_ ;
  array ref_time {10} _temporary_ ;
  length pref ref_type $1 t_unit $2 temp $15 cond stm1 stm2 stm3 stm4 $200 ;

  n+1 ;


  %* put each reference variable into an array ;
  nref = 1 ;
  do while(scan(ref,nref,'&| ')~=' ') ;
    refv{nref} = symget('REF'||trim(scan(ref,nref,'&|'))) ;
    if refv{nref} = ' ' then do ;
      put "ERROR: (WINDOWS) More REFs exist in &windata than specified with REF=";
      call symput('_ERROR_','1') ;
      stop ;
    end ;
    nref+1 ;
  end ;
  nref = nref - 1 ;

  %* check for &s or |s in ref and store ;
  if index(ref,'|') & index(ref,'&') then do ;
    put "ERROR: (WINDOWS) Cannot use both & and | in REF." ;
    put REF= ;
    call symput('_ERROR_','1') ;
    stop ;
  end ;
  else if index(ref,'|') then ref_type = '|' ;
  else if index(ref,'&') then ref_type = '&' ;

  %* pull values apart from units ;
  t_num  = input(substr(target,1,verify(target,'-.0123456789') - 1),?? 8.) ;
  if t_num=. then put 'WARNING: (WINDOWS) T_NUM is missing...' + 1 _all_ ;
  t_unit = substr(target,verify(target,'-.0123456789')) ;

  do i = 1 to nref ;

    %* pull apart the BEGIN variable, and split numeric portion from unit ;
    temp = scan(begin,i,',') ;
    if temp = ' ' then do ;
      put "ERROR: (WINDOWS) fewer BEGINs specified than REFs in &windata.." ;
      put BEGIN= REF= ;
      call symput('_ERROR_','1') ;
      stop ;
    end ;
    b_num{i}  = input(substr(temp,1,verify(temp,'-.0123456789') - 1),?? 8.) ;
    if b_num{i}=. then put 'WARNING: (WINDOWS) B_NUM is missing...' + 1 _all_ ;
    b_unit{i} = substr(temp,verify(temp,'-.0123456789')) ;

    %* pull apart the END variable, and split numeric portion from unit ;
    temp = scan(end,i,',') ;
    if temp = ' ' then do ;
      put "ERROR: (WINDOWS) fewer ENDs specified than REFs in &windata.." ;
      put END= REF= ;
      call symput('_ERROR_','1') ;
      stop ;
    end ;
    e_num{i}  = input(substr(temp,1,verify(temp,'-.0123456789') - 1),?? 8.) ;
    if e_num{i}=. then put 'WARNING: (WINDOWS) E_NUM is missing...' +1 _all_ ;
    e_unit{i} = substr(temp,verify(temp,'-.0123456789')) ;

    %* pull apart the BEGIN_OP variable ;
    temp = scan(begin_op,i,',') ;
    if temp=' ' then do ;
      put "ERROR: (WINDOWS) fewer BEGIN_OPs specified than REFs in &windata.." ;
      put BEGIN_OP= REF= ;
      call symput('_ERROR_','1') ;
      stop ;
    end ;
    select(upcase(temp)) ;
      when ('GT','LT','>','<')   b_op{i} = '<'  ; 
      when ('GE','LE','>=','<=') b_op{i} = '<=' ;
      otherwise do ;
        put "ERROR: (WINDOWS) BEGIN_OP specification not valid in &windata.." ;
        put BEGIN_OP ;
        call symput('_ERROR_','1') ;
        stop ;
      end ;
    end ;
    
    %* pull apart the END_OP variable ;
    temp = scan(end_op,i,',') ;
    if temp=' ' then do ;
      put "ERROR: (WINDOWS) fewer END_OPs specified than REFs in &windata.." ;
      put END_OP= REF= ;
      call symput('_ERROR_','1') ;
      stop ;
    end ;
    select(upcase(temp)) ;
      when ('GT','LT','>','<')   e_op{i} = '<'  ; 
      when ('GE','LE','>=','<=') e_op{i} = '<=' ;
      otherwise do ;
        put "ERROR: (WINDOWS) END_OP specification not valid in &windata.." ;
        put END_OP ;
        call symput('_ERROR_','1') ;
        stop ;
      end ;
    end ;
    
    %* make sure the units are consistent for BEGINs and ENDs ;
    if (b_unit{i}=' ' & e_unit{i}~=' ') | (b_unit{i}~=' ' & e_unit{i}=' ') then do ;
      put "ERROR: (WINDOWS) BEGIN and END units do not all match up." ;
      put BEGIN= END= ;
      call symput('_ERROR_','1') ;
      stop ;
    end ;
    else if (b_unit{i}=' ') then ref_time{i}=0 ;
    else                         ref_time{i}=1 ;

  end ;

  %* make sure TARGET and BEGIN/END units are consistent ;
  if (b_unit{1}=' ' & t_unit~=' ') | (b_unit{1}~=' ' & t_unit=' ') then do ;
    put "ERROR: (WINDOWS) TARGET units do not match BEGIN and END units." ;
    put TARGET= BEGIN= END= ;
    call symput('_ERROR_','1') ;
    stop ;
  end ;

  %* convert target time to seconds if time units are given ;
  select (upcase(t_unit)) ;
    when ('WK') t_num = t_num * 60 * 60 * 24 * 7 ;
    when ('D')  t_num = t_num * 60 * 60 * 24 ;
    when ('H')  t_num = t_num * 60 * 60 ;
    when ('M')  t_num = t_num * 60 ;
    when ('S',' ')  ;
    otherwise do ;
      put "ERROR: (WINDOWS) Units specifed are not valid for TARGET." ;
      put TARGET= ;
      call symput('_ERROR_','1') ;
      stop ;
    end ;
  end ;

  pref = ' ' ;

  do i = 1 to nref ;

    %* convert BEGIN time to seconds if time units are given ;
    select (upcase(b_unit{i})) ;
      when ('WK') b_num{i} = b_num{i} * 60 * 60 * 24 * 7 ;
      when ('D')  b_num{i} = b_num{i} * 60 * 60 * 24 ;
      when ('H')  b_num{i} = b_num{i} * 60 * 60 ;
      when ('M')  b_num{i} = b_num{i} * 60 ;
      when ('S',' ')  ;
      otherwise do ;
        put "ERROR: (WINDOWS) Units specifed are not valid for BEGIN." ;
        put BEGIN= ;
        call symput('_ERROR_','1') ;
        stop ;
      end ;
    end ;

    %* convert END time to seconds if time units are given ;
    select (upcase(e_unit{i})) ;
      when ('WK') e_num{i} = e_num{i} * 60 * 60 * 24 * 7 ;
      when ('D')  e_num{i} = e_num{i} * 60 * 60 * 24 ;
      when ('H')  e_num{i} = e_num{i} * 60 * 60 ;
      when ('M')  e_num{i} = e_num{i} * 60 ;
      when ('S',' ')  ;
      otherwise do ;
        put "ERROR: (WINDOWS) Units specifed are not valid for END." ;
        put END= ;
        call symput('_ERROR_','1') ;
        stop ;
      end ;
    end ;

    %* build a condition for the WHEN statements to calculate windows ;
    if ref_time{i} then
      cond = left(trim(cond) || compress(pref,' ') || 
             '(' ||

                compress(put(b_num{i},best12.),' ') ||

                trim(b_op{i}) ||

                "(&datetime - " || trim(refv{i}) || ')' ||

                trim(e_op{i}) ||

                compress(put(e_num{i},best12.),' ') ||

             ')') ;
    else
      cond = left(trim(cond) || compress(pref,' ') || 
             '(' ||

                compress(put(b_num{i},best12.),' ') ||

                trim(b_op{i}) ||

                "(" || trim(refv{i}) || ')' ||

                trim(e_op{i}) ||

                compress(put(e_num{i},best12.),' ') ||

             ')') ;

    pref = ref_type ;
  end ;

  %* create some other statements to calculate windows and associated variables ;
  %if %upcase(%substr(&multiple,1,1))=Y %then %do ;
    stm1 = "_window(&num_win) = " || compress(put(window,best15.),' ') ;
    if t_unit=' ' then
      stm2 = "_diff(&num_win) = " || trim(refv{1}) || '-(' || compress(put(t_num,best15.),' ') || ')' ;
    else
      stm2 = "_diff(&num_win) = (&datetime - " || trim(refv{1}) || ')-(' || compress(put(t_num,best15.),' ') || ')' ;
  %end ;
  %else %do ;
    stm1 = "&window = " || compress(put(window,best15.),' ') ;
    if t_unit=' ' then
      stm2 = "&diff = " || trim(refv{1}) || '-(' || compress(put(t_num,best15.),' ') || ')' ;
    else
      stm2 = "&diff = (&datetime - " || trim(refv{1}) || ')-(' || compress(put(t_num,best15.),' ') || ')' ;
  %end ;
  stm3 = "&units_v = '" || trim(lowcase(rt_unit)) || "'" ;
  stm4 = "&round_v = " || compress(put(rt_round,best15.),' ') ;

  %* put everything into macro variable arrays to be pulled in at a later data step ;
  call symput('cond_' || left(put(n,8.)), trim(cond)) ;
  call symput('stm1_'|| left(put(n,8.)), trim(stm1)) ;
  call symput('stm2_'|| left(put(n,8.)), trim(stm2)) ;
  call symput('stm3_'|| left(put(n,8.)), trim(stm3)) ;
  call symput('stm4_'|| left(put(n,8.)), trim(stm4)) ;
  if eof then call symput('_win_obs',compress(put(n,8.))) ;

  run ;

%* Make sure no problems arose in the WINDOWS data ;
%if %length(&_error_)>0 %then
  %goto err ;
%if %length(&_win_obs)=0 %then %do ;
  %put WARNING: (WINDOWS) No observations for TYPE=%upcase(&type) found in &windata ;
  %goto err ;
%end ;


%***********************************************************************
%* In a data step with the specified data, produce a set of WHENs
%* corresponding to each window, and calculate the windows and other
%* associated variables:
%**********************************************************************;
%if %upcase(%substr(&multiple,1,1))=Y %then %do ;
data _d_a_t_a ;
  set _d_a_t_a end=eof ;
  drop _maxwin_ ;
  length &units_v $18 ;
  retain _maxwin_ 0 ;
  &num_win = 0 ;
  array _window {9} &window.1-&window.9 ;
  array _diff   {9} &diff.1-&diff.9     ;
  array _sign   {9} &sign.1-&sign.9     ;
  array _pref   {9} &pref.1-&pref.9     ;
  %do i = 1 %to &_win_obs ;
    if (&&cond_&i) then do ;
      &num_win + 1 ;
      if &num_win > _maxwin_ then _maxwin_ = &num_win ;
      &&stm1_&i ;
      &&stm2_&i ;
      _sign{&num_win} = -1*(_diff{&num_win} < 0) + (_diff{&num_win} > 0) ;
      _diff{&num_win} = abs(_diff{&num_win}) ;
      &&stm3_&i ;
      &&stm4_&i ;
    end ;
  %end ;
  if eof then call symput('_maxwin_',trim(left(put(_maxwin_,2.)))) ;
  run ;

data &out ;
  set _d_a_t_a(drop=%do i=%eval(&_maxwin_ + 1) %to 9 ; 
                      &window.&i &diff.&i &sign.&i &pref.&i
                    %end ;) ;
  run ;
%end ;
%else %do ;
  data &out ;
    set _d_a_t_a ;
    length &units_v $18 ;
    &pref = . ;
    select ;
      %do i = 1 %to &_win_obs ;
        when (&&cond_&i) do ;
          &&stm1_&i ;
          &&stm2_&i ;
          &sign = -1*(&diff < 0) + (&diff > 0) ;
          &diff = abs(&diff) ;
          &&stm3_&i ;
          &&stm4_&i ;
        end ;
      %end ;
      otherwise ;
    end ;
    run; 
%end ;
%goto leave ;
%err:
data &out ;
  set _d_a_t_a ;
  run ;

%leave:

%mend WINDOWS ;
