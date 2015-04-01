%macro SeqBoundsSim(
                    data=,
					datatype=,
					active=,
					control=,
					reps=10,
					seeds=-1,
                    simout=_DEFAULT_,
					out=SeqSim,
					report=Y
                   );

%local i j ;
%let SBS_active0  = %words(&active, root=SBS_active, delm=%str( )) ;
%let SBS_control0 = %words(&control,root=SBS_control,delm=%str( )) ;

%let SBS_seed0 = %words(&seeds,root=SBS_seed,delm=%str( )) ;
%if &SBS_seed0<%eval(&SBS_active0 + &SBS_control0) %then %do ;
  %if %quote(&seeds)~=-1 %then
    %put WARNING: %eval(&SBS_active0 + &SBS_control0 - &SBS_seed0) seeds not specified. ;
  %do i = %eval(&SBS_seed0 + 1) %to %eval(&SBS_active0 + &SBS_control0) ;
    %let SBS_seed&i = -1 ;
  %end ;
  %let SBS_seed0 = %eval(&SBS_active0 + &SBS_control0) ;
%end ;

********************************************************************************
* Get a unique list of looks and info at each id:
*******************************************************************************;
proc sort data=&data(keep=SS) out=SBS_bounds nodupkey ;
  by SS ;
  run ;

data _null_ ;
  set SBS_bounds end=eof ;
  i + 1 ;
  call symput('SBS_look' || compress(put(i,8.)),compress(put(SS,8.))) ;
  if eof then call symput('SBS_look0',compress(put(i,8.))) ;
  run ;

proc sort data=&data out=SBS_bounds ;
  by id SS ;
  run ;

%local futility FutGamma FutLevel FutMean ;
data _null_ ;
  set SBP_plot(obs=1) ;
  %chkvar(var=futility FutGamma FutLevel FutMean,
         flag=futility_flag FutGamma_flag FutLevel_flag FutMean_flag) ;
  if futility_flag then call symput('futility','futility') ;
  else                  call symput('futility',"'_NULL_'") ;
  if FutGamma_flag then call symput('FutGamma','FutGamma') ;
  else                  call symput('FutGamma',"0") ;
  if FutLevel_flag then call symput('FutLevel','FutLevel') ;
  else                  call symput('FutLevel',"0") ;
  if FutMean_flag  then call symput('FutMean','FutMean') ;
  else                  call symput('FutMean',"0") ;
  run ;

data _null_ ;
  set SBS_bounds end=eof ;
  by id ;

  length look_str look_str2 upper_str lower_str $200 ;
  retain look_str look_str2 ;
  if first.id then look_str = ' ' ;
  look_str = trim(look_str) || ' ' || compress(put(ss,8.)) ;
  if first.id then look_str2 = compress(put(ss,8.)) ;
  else look_str2 = trim(look_str2) || ', ' || compress(put(ss,8.)) ;

  if last.id then do ;
    _idnum_+1 ;

	select(aSpend) ;
	  when ('OBFL') upper_str = "O'Brien-Fleming" ;
	  when ('POCOCK') upper_str = "Pocock" ;
	  otherwise do ;
	    put 'WARNING: Unknown futility rule (' futility= ').' ;
		upper_str = "Sequential Boundary" ;
	  end ;
	end ;
    upper_str = trim(upper_str) || " [alpha="
	            || compress(put(alpha,best8.))
				|| ' (' || put(sides,1.) || "-sided); n="
				|| trim(left(look_str2)) || "]" ;

    select(&futility) ;
	  when ('BETENSKY') 
        lower_str = "Betensky's Conditional Power [g="
		            || compress(put(&FutGamma,best8.)) 
                    || ", g'="
                    || compress(put(&FutLevel,best8.))
                    || "]" ;
	  when ('STOCHCURT') 
        lower_str = "Stochastic Curtailment [g="
		            || compress(put(&FutGamma,best8.)) 
                    || ", mu="
                    || compress(put(&FutMean,best8.))
                    || "]" ;
	  when ('WIEAND') 
        lower_str = "Wieand Futility Rule" ;
	  when ('_NULL_')
	    lower_str = ' ' ;
	  otherwise do ;
	    put 'WARNING: Unknown futility rule (' &futility ').' ;
		lower_str = "Futility Boundary" ;
	  end ;
	end ;

    call symput('SBS_id'||compress(put(_idnum_,8.)),compress(put(id,8.))) ;
	if lower_str=' ' then
	  call symput('SBS_label'||compress(put(_idnum_,8.)),trim(upper_str)) ;
	else
	  call symput('SBS_label'||compress(put(_idnum_,8.)),
	              trim(upper_str)||'; '||trim(lower_label)) ;
    call symput('SBS_looks'||compress(put(_idnum_,8.)),compress(put(looks,8.))) ;

	do i = (looks+1) to (&SBS_look0) ;
	  look_str = trim(look_str) || ' 0' ;
	end ;
	call symput('SBS_sched'||compress(put(_idnum_,8.)),trim(look_str)) ;

  end ;
  if eof then call symput('SBS_id0',compress(put(_idnum_,8.))) ;

  run ;


%********************************************************************************
* Create simulation data set:
*******************************************************************************;

%if %upcase(&datatype)=ORDERED %then %do ;

data _null_ ;
  categories = 0 ;
  %do i = 1 %to &SBS_control0 ;
    n = n(&&SBS_control&i) ;
    prob = sum(&&SBS_control&i) ;
	if 0<=prob<1 then n = n + 1 ;
	if 0<=prob<=1 & n>categories then categories = n ;
  %end ;
  %do i = 1 %to &SBS_active0 ;
    n = n(&&SBS_active&i) ;
    prob = sum(&&SBS_active&i) ;
	if 0<=prob<1 then n = n + 1 ;
	if 0<=prob<=1 & n>categories then categories = n ;
  %end ;
  call symput('SBS_cat',compress(put(categories,8.))) ;
  run ;
    

data &simout ;

  mergevar = 1 ;

  array _SS_ {&SBS_look0} _temporary_ 
                          (%do i = 1 %to &SBS_look0 ; &&SBS_look&i %end ;) ;
  array _X_ {0:1,1:&SBS_cat,1:&SBS_look0} _temporary_ ;
  array nj {&SBS_cat} _temporary_ ;
  array LogWj {&SBS_cat} _temporary_ ;
  array WilWj {&SBS_cat} _temporary_ ;
  array Z {2,&SBS_look0} _temporary_ ;

  array testZ {&SBS_look0} testZ1-testZ&look0 ;

  do sim = 1 to &reps ;
    do control = 1 to &SBS_control0 ;
    do active  = 1 to &SBS_active0 ;
	  
	  do i = 0, 1 ;
	    do j = 1 to &SBS_cat ;
		  do k = 1 to &SBS_look0 ;
		   
		    _X_{i,j,k} = 0 ;

		  end ;
		end ;
	  end ;

	  * load the entire response and treatment vectors ;
      do i = 1 to _SS_{&SBS_look0} ;
	    trt = mod(i,2) ;
		select ;
		  %do i = 1 %to &SBS_control0 ;
			when (trt=0 & control=&i) 
              response = rantbl(&&SBS_seed&i,&&SBS_control&i) ;
		  %end ;
		  %do i = 1 %to &SBS_active0 ;
		    %let j = %eval(&i + &SBS_control0) ;
			when (trt=1 & active=&i)
              response = rantbl(&&SBS_seed&j,&&SBS_active&i) ;
		  %end ;
		  otherwise response = . ;
		end ;
        %do i = 1 %to &SBS_look0 ;
		  if i<=_SS_{&i} & response>.Z then 
            _X_{trt,response,&i} = _X_{trt,response,&i} + 1 ;
		%end ;
	  end ;

      * create subsets for each interim look (this avoids a sort) ;
	  do i = 1 to dim(_SS_) ;

	    N = _SS_{i} ;
	    vj = 0 ;
		WilT = 0 ;
		WilET = 0 ;
		LogT = 0 ;
		LogET = 0 ;

	    do j = 1 to &SBS_cat ;

		  nj{j} = _X_{0,j,i} + _X_{1,j,i} ;
		  njj = nj{j} ;

		  vj_1 = vj ;
		  vj = vj + njj ;
          WilWj{j} = vj_1 + (njj+1)/2 ;

		  LW = 0 ;
		  do k = vj_1+1 to vj ;
		    do l = 1 to k ;
			  LW = LW + 1/(N-l+1) ;
			end ;
		  end ;
		  if njj then LogWj{j} = (LW/njj) - 1 ;
		  else LogWj{j} = 0 ;

		  LogT = LogT + LogWj{j}*_X_{1,j,i} ;
		  WilT = WilT + WilWj{j}*_X_{1,j,i} ;

		  LogET = LogET + LogWj{j}*njj ;
		  WilET = WilET + WilWj{j}*njj ;

		end ;

		LogET = LogET * 0.5 ;
		WilET = WilET * 0.5 ;

		LogST = 0 ;
        WilST = 0 ; 
		do j = 1 to &SBS_cat ;
		  LogST = LogST + ((LogWj{j} - 2*LogET/N)**2)*nj{j} ;
		  WilST = WilST + ((WilWj{j} - 2*WilET/N)**2)*nj{j} ;
		end ;
		LogST = sqrt(LogST*0.25*N/(N-1)) ;
		WilST = sqrt(WilST*0.25*N/(N-1)) ;

		Z{1,i} = (LogT-LogET)/LogST ;
		Z{2,i} = (WilT-WilET)/WilST ;

	  end ;

	  do test = 1 to dim1(Z) ;
	    testZ{i} = Z{test,i} ;
        output ;
	  end ;

	end ;
  end ;

  keep mergevar sim control active test testZ1-testZ&SBS_look0 ;

  run ;

%end ;

********************************************************************************
* Format sequential bounds data for convenience in simulation:
*******************************************************************************;
proc sort data=&data out=SBS_bounds ;
  by id look ;
  run ;

data SBS_bounds ;
  set SBS_bounds ;
  by id ;
  mergevar = 1 ;
  retain _ID_ 0 ;
  if first.id then _ID_ + 1 ;
  length suffix $9 ;
  suffix = 'ID' || compress(put(_ID_,3.)) || 'L' || compress(put(look,3.)) ;
  run ;

proc transpose data=SBS_bounds out=SBS_upper(drop=_name_) prefix=upper ;
  by mergevar ;
  var upperZ ;
  id suffix ;
  run ;

proc transpose data=SBS_bounds out=SBS_bounds(drop=_name_) prefix=lower ;
  by mergevar ;
  var lowerZ ;
  id suffix ;
  run ;

data &out ;
  merge SBS_bounds SBS_upper &simout ;
  by mergevar ;

  array lower {&SBS_id0,&SBS_look0} 
              %do i = 1 %to &SBS_id0 ;
                lowerID&i.L1-lowerID&i.L&SBS_look0
              %end ;
              ; 
  array upper {&SBS_id0,&SBS_look0} 
              %do i = 1 %to &SBS_id0 ;
                upperID&i.L1-upperID&i.L&SBS_look0
              %end ;
              ;

  array Z {&SBS_look0} testZ1-testZ&SBS_look0 ;

  array _SS_ {0:&SBS_id0, &SBS_look0} _temporary_ 
             (
              %do i = 1 %to &SBS_look0 ; &&SBS_look&i %end ;
			  %do i = 1 %to &SBS_id0 ;
			    &&SBS_sched&i
			  %end ;
             ) ;

  array looks {&SBS_id0} _temporary_
              (%do i = 1 %to &SBS_id0 ; &&SBS_looks&i %end ;) ;
  
  do id = 1 to dim1(lower) ;
    
      WinF = Z{TestType,4} > probit(0.975) ;
	  Stop = 0 ;
	  SS = 0 ;
	  do i = 1 to dim2(lower) ;
	    W{i} = 0 ;
		if i<dim2(lower) then F{i} = 0 ;
        if ~Stop & Z{TestType,i}>=upper{BoundType,i} then do ;
          W{i} = 1 ;
		  Stop = 1 ;
		  SS = SS_{i} ;
		end ;
		if ~Stop & Z{TestType,i}<lower{BoundType,i} & i<dim2(lower) then do ;
          F{i} = 1 ;
		  Stop = 1 ;
		  SS = SS_{i} ;
		end ;
	  end ;
	  if SS=0 then SS = SS_{4} ;
	  Win = Max(of W{*}) ;
	  output ;

  end ;
  keep scenario BoundType TestType WinF Win1-Win4 Win Fut1-Fut3 SS ;
  run ;

proc summary data=final nway ;
  class BoundType TestType scenario ;
  var Win: Fut: SS ;
  output out=final(drop=_type_) mean= ;
  run ;

data final ;
  set final ;
  Win2 = Win1 + Win2 ;
  Win3 = Win2 + Win3 ;
  Win4 = Win3 + Win4 ;
  Fut2 = Fut1 + Fut2 ;
  Fut3 = Fut2 + Fut3 ;
  run ;

proc format ;
  value bound 1="g=0.1, g'=0.01"
              2="g=0.3, g'=0.01"
			  3="g=0.1, g'=0.05"
			  4="g=0.3, g'=0.05"
			  ;
  value test 1='Log-rank'
             2='Wilcoxon'
			 ;
  value scenario 1='No Effect'
                 2='Max  8% Earlier'
				 3='Max 15% Earlier'
				 4='Max  8% Later'
				 5='Max 15% Later'
				 ;
  run ;

%macpage(capture=ON) ;

proc report nowd data=final headline headskip missing split='*' ;
  column BoundType TestType scenario WinF
         ('Pr(Win) at Look' '++' Win1 Win2 Win3 Win4)
		 ('Pr(Futility) at Look' '++' Fut1 Fut2 Fut3) ss ;
  define BoundType / order order=internal f=bound. center 
                     'Futility' 'Boundary' ;
  define TestType / order order=internal f=test. center 'Type of' 'Test' ;
  define scenario / order order=internal f=scenario. left
                    'Treatment Effect' 'Assumption' ;
  define WinF / display f=7.5 center 'Fixed' 'Power' ;
  define Win1 / display f=7.5 center '1' ;
  define Win2 / display f=7.5 center '2' ;
  define Win3 / display f=7.5 center '3' ;
  define Win4 / display f=7.5 center 'Final' ;
  define Fut1 / display f=7.5 center '1' ;
  define Fut2 / display f=7.5 center '2' ;
  define Fut3 / display f=7.5 center '3' ;
  define ss / display f=3. center width=5 'E(SS)' ;
  break after TestType / skip ;
  title ' ' ;
  title2 'Simulation Stopping Probabilities for CLI Trial' ;
  title3 '(O''Brien-Fleming Upper Boundary and Betensky''s Conditional Power Lower Boundary)' ;
  footnote 'FF'x ;
  run ;

%macpage ;

%mend SeqBoundsSim ;
libname tmp '.' ;
%SeqBoundsSim(
              data=tmp.bounds,
			  datatype=ORDERED,
			  control=%str(0.02,0.03,0.29,0.28,0.28,0.10),
			  active= %str(0.02,0.03,0.29,0.28,0.28,0.10)
                      %str(0.01,0.02,0.26,0.26,0.27,0.18)
					  %str(0.01,0.02,0.21,0.24,0.27,0.25)
					  %str(0.01,0.02,0.27,0.27,0.25,0.18)
					  %str(0.01,0.02,0.24,0.24,0.24,0.25),
			  reps=1000,
			  seeds=798622 943286 89236 20436 2066272 447246,
              simout=sim,
              out=out,
              report=Y
             ) ;