%macro SeqBounds(
                 alpha=0.05,
				 sides=2,
				 maxSS=1,
				 futility=,
				 futility_gamma=0.3,
				 futility_level=0.01,
				 futility_mean=0.5,
				 t=,
				 alpha_spend=,
				 boundary_truncation=8,
				 append=,
				 out=_DEFAULT_
                ) ;

%global _SeqBounds_ ;
%if %quote(&_SeqBounds_)= %then %let _SeqBounds_ = 1 ;
%else                           %let _SeqBounds_ = %eval(&_SeqBounds_ + 1) ;

%if %quote(&out)=_DEFAULT_ & %quote(&append)= %then 
  %let out = SeqBound ;

%let aSpend = &alpha_spend ;
%if %upcase(&alpha_spend)=OBFL %then
  %let alpha_spend = 2*(1 - cdf('NORMAL',probit(1-(alpha/sides)/2)/sqrt(t))) ;
%else %if %upcase(&alpha_spend)=POCOCK %then
  %let alpha_spend = (alpha/sides)*log(1 + (exp(1)-1)*t) ;

%if %quote(&futility)~= %then %do ;
  %let futility = %upcase(&futility) ;
  %if %index(%str( BETENSKY WIEAND PEPE STOCHCURT ),%str( &futility ))=0 %then %do ;
    %put WARNING: Unknown futility rule.  No futility rule will be used. ;
    %let futility = ;
  %end ;
  %else %if %quote(&futility)=PEPE %then %do ;
    %let futility = BETENSKY ;
	%let futility_level = 0.16 ;
  %end ;
%end ;

%let looks = %words(&t) ;

%if &boundary_truncation>8 %then %do ;
  %put WARNING: Boundary must be truncated at 8 or lower.  Truncation re-set to 8. ;
  %let boundary_truncation = 8 ;
%end ;

proc iml ;
  file log ;

  %* define alpha spending function ;
  start alpha_spend(t,alpha,sides) ;
    a = &alpha_spend ;
    return(a) ;
  finish ;

  %* define futility rules ;
  start BETENSKY(SS,looks,alpha,sides,futility_gamma,futility_level,futility_mean) ;
    m = SS[looks] ;
    lower = shape(0,looks,1) ;
	b = probit(1-(alpha/sides)) * sqrt(m) ;
	do i = 1 to looks ;
	  n = SS[i] ;
	  lower[i] = b*sqrt(n)/m - probit(1-futility_gamma)*sqrt(m-n)*sqrt(n)/m
                             - probit(1-futility_level)*(m-n)/m ;
	end ;
	return(lower) ;
  finish ;

  start STOCHCURT(SS,looks,alpha,sides,futility_gamma,futility_level,futility_mean) ;
    lower = shape(0,looks,1) ;
	b = probit(1-(alpha/sides)) * sqrt(looks) ;
	do i = 1 to looks ;
	  lower[i] = b/sqrt(n) - probit(1-futility_gamma)*sqrt(m-n)/sqrt(n)
                           - futility_mean*(m-n)/sqrt(n) ;
	end ;
	return(lower) ;
  finish ;

  start WIEAND(SS,looks,alpha,sides,futility_gamma,futility_level,futility_mean) ;
    lower = shape(0,looks,1) ;
	return(lower) ;
  finish ;

  %* define a function to determine exit probability given bounds ;
  start ExitProb(x,known,tscale) global(Tolerance_Prob,MaxZ,sides) ;
    if sides=1 then new = -MaxZ // x ;
	else            new = -x // x ;
	domain = known || new ;
	call seq(prob,domain) eps=Tolerance_Prob tscale=tscale ;
	alpha = 1 - (prob[2,]-prob[1,])[ncol(prob)] ;
	return(alpha) ;
  finish ;

  %* Secant search routine to find bound that solves for exit probability ;
  start Illinois_Yb(prob,known,tscale,sigma) global(Tolerance,Tolerance_Prob,MaxZ) ;

    %* set search start interval (x1,x2) ;
    xl = 0 ;
	xr = MaxZ*sigma ;

	%* evaluate function at interval boundaries (fx1,fx2) ;
	fxl = ExitProb(xl,known,tscale) - prob ;
	fxr = ExitProb(xr,known,tscale) - prob ;

	last_moved = 2 ;
	if fxr>0 then do ;
	  j = 0 ;
	  xn = xr ;
	  goto found_it ;
	end ;

	%* do a maximum of 50 iterations (shouldnt take nearly this long) ;
	do j = 1 to 99 ;
	  if (xr-xl < Tolerance) then goto found_it ;
	  xn = xl - fxl*(xl-xr)/(fxl-fxr) ;
	  fxn = ExitProb(xn,known,tscale) - prob ;
	  if (abs(fxn)<Tolerance_Prob) then goto found_it ;
	  if (fxn > 0) then do ;
	    xl = xn ;
		fxl = fxn ;
		if last_moved=1 then fxr = fxr / 2 ;
		last_moved = 1 ;
	  end ;
	  else do ;
	    xr = xn ;
		fxr = fxn ;
		if last_moved=0 then fxl = fxl / 2 ;
		last_moved = 0 ;
	  end ;
	end ;
	put 'WARNING: Illinois search routine did not converge.' ;
	j = j - 1 ;
	found_it:
	put 'NOTE: At final step of Illinois search (Iteration ' j 2. '),'
        ' bounds were as follows:' /
        '      Left=' xl 9.7 ' Right=' xr 9.7 /
        '      Prob Diff Left=' fxl ' Prob Diff Right=' fxr /
        '      Final=' xn 9.7 ' Prob Diff=' fxn 
        ;

	return(xn) ;

  finish ;

  start ;

  %* set some defaults for calculations ;
  Tolerance_Prob = 2e-12 ;
  Tolerance = 1e-7 ;
  maxZ = &boundary_truncation ;

  %* process arguments ;
  alpha = &alpha ;
  sides = &sides ;
  maxSS = &maxSS ;
  futility_gamma=&futility_gamma ;
  futility_level=&futility_level ;
  futility_mean=&futility_level ;

  t  = {&t}` ;
  looks = nrow(t) ;

  %* initialize various vectors ;
  SS       = shape(0,looks,1) ;
  t2       = shape(0,looks,1) ;
  tscale   = shape(0,looks-1,1) ;
  ProbExit = shape(0,looks,1) ;
  ProbIncr = shape(0,looks,1) ;
  Sigma    = shape(0,looks,1) ;
  look     = shape(0,looks,1) ;

  %* set information fraction, information, exit probabilities, and process std devs ;
  do i = 1 to looks ;

    look[i] = i ;
    t[i]  = t[i] / t[looks] ;
    t2[i] = t[i] / t[1] ;
	SS[i] = t[i] * maxSS ;
	if i>1 then tscale[i-1] = t2[i] - t2[i-1] ;

    ProbExit[i] = min(1,max(0,sides*alpha_spend(t[i],alpha,sides))) ;
	if i=1 then ProbIncr[i] = ProbExit[i] ;
	else        ProbIncr[i] = min(1,max(0,ProbExit[i] - ProbExit[i-1])) ;

	if i=1 then sigmasq = 1 ;
	else sigmasq = sigmasq + tscale[i-1] ;
    Sigma[i] = sqrt(sigmasq) ;

  end ;

  %* initialize boundary vectors ;
  Zb = shape(0,looks,1) ;
  Za = shape(0,looks,1) ;
  Yb = shape(0,looks,1) ;
  Ya = shape(0,looks,1) ;
  Nb = shape(0,looks,1) ;
  Na = shape(0,looks,1) ;
  Nominal = shape(0,looks,1) ;

  %* set boundaries for first look (simpler case) ;
  if ProbExit[1]=0 then do ;
    Zb[1] = maxZ ;
	ProbExit[1] = sides * (1-cdf('NORMAL',Zb[1])) ;
	ProbIncr[1] = ProbExit[1] ;
	if looks>1 then
	  ProbIncr[2] = max(0,ProbExit[2] - ProbExit[1]) ;
	Yb[1] = Zb[1]*Sigma[1] ;
  end ;
  else if ProbExit[1]=1 then do ;
    Zb[1] = 0 ;
	Yb[1] = 0 ;
  end ;
  else do ;
    Zb[1] = probit(1-(ProbExit[1]/sides)) ;
	if Zb[1]>maxZ then do ;
	  Zb[1] = maxZ ;
	  ProbExit[1] = sides * (1-cdf('NORMAL',Zb[1])) ;
	  ProbIncr[1] = ProbExit[1] ;
	  if looks>1 then
	    ProbIncr[2] = max(0,ProbExit[2] - ProbExit[1]) ;
	end ;
	Yb[1] = Zb[1] * Sigma[1] ;
  end ;
  if sides=2 then do ;
    Za[1] = -1 * Zb[1] ;
	Ya[1] = -1 * Yb[1] ;
  end ;
  else do ;
    Za[1] = -1 * maxZ ;
	Ya[1] = Za[1] * Sigma[1] ;
  end ;

  Na[1] = cdf('NORMAL',Za[1]) ;
  Nb[1] = 1-cdf('NORMAL',Zb[1]) ;
  Nominal[1] = Na[1] + Nb[1] ;

  %* now find each successive bound using a secant search routine on SEQ() ;
  do i = 2 to looks ;

    if ProbExit[i]=0 then do ;
      Zb[i] = maxZ ;
	  Yb[i] = Zb[i]*Sigma[i] ;
	  ProbExit[i] = ExitProb(Yb[i],
                             Ya[1:(i-1)]` // Yb[1:(i-1)]`,
                             tscale[1:(i-1)]) ;
	  ProbIncr[i] = max(0,ProbExit[i] - ProbExit[i-1]) ;
	  if looks>i then
	    ProbIncr[i+1] = max(0,ProbExit[i+1] - ProbExit[i]) ;
    end ;

    else if ProbExit[i]=1 then do ;
      Zb[i] = 0 ;
	  Yb[i] = 0 ;
    end ;

	else do ;

      Yb_new = Illinois_Yb(ProbExit[i],
                           Ya[1:(i-1)]` // Yb[1:(i-1)]`,
					       tscale[1:(i-1)],
					       Sigma[i]) ;
	  Yb[i] = Yb_new ;
	  Zb[i] = Yb_new / Sigma[i] ;

	  if Zb[i]=maxZ then do ;
	    ProbExit[i] = ExitProb(Yb[i],
                               Ya[1:(i-1)]` // Yb[1:(i-1)]`,
                               tscale[1:(i-1)]) ;
	    ProbIncr[i] = max(0,ProbExit[i] - ProbExit[i-1]) ;
	    if looks>i then
	      ProbIncr[i+1] = max(0,ProbExit[i+1] - ProbExit[i]) ;
	  end ;

	end ;

    if sides=2 then do ;
      Za[i] = -1 * Zb[i] ;
	  Ya[i] = -1 * Yb[i] ;
    end ;
    else do ;
      Za[i] = -1 * maxZ ;
	  Ya[i] = Za[i] * Sigma[i] ;
    end ;

  end ;

  %if %quote(&futility)~= %then %do ;
    Za = &futility(SS,looks,alpha,sides,futility_gamma,futility_level,futility_mean) ;
	Ya = Za#Sigma ;
  %end ;

  do i = 1 to looks ;
    if Za[i]<0 then
      Na[i] = -1*cdf('NORMAL',Za[i]) ;
    else
	  Na[i] = 1-cdf('NORMAL',Za[i]) ;
    Nb[i] = 1-cdf('NORMAL',Zb[i]) ;
    Nominal[i] = sides * Nb[i] ;
  end ;

  id    = shape(&_SeqBounds_,looks,1) ;
  alpha = shape(alpha,looks,1) ;
  sides = shape(sides,looks,1) ;
  aSpend= shape("&aSpend",looks,1) ;
  %if %quote(&futility)~= %then %do ;
    Futility = shape("&futility",looks,1) ;
	FutLevel = shape(futility_level,looks,1) ;
	FutGamma = shape(futility_gamma,looks,1) ;
	FutMean  = shape(futility_mean,looks,1) ;
  %end ;
  maxSS    = shape(maxSS,looks,1) ;
  NominalP = Nominal ;
  LowerP   = Na ;
  UpperP   = Nb ;
  LowerZ   = Za ;
  UpperZ   = Zb ;
  LowerY   = Ya ;
  UpperY   = Yb ;
  looks    = shape(looks,looks,1) ;
  outvar = {"id" "alpha" "sides" "looks" "aSpend"
            %if %quote(&futility)~= %then %do ;
			  "Futility" 
			  %if %index(%str( BETENSKY ),%str( &futility )) %then
                 %str("FutLevel") ;
			  %if %index(%str( BETENSKY STOCHCURT ),%str( &futility )) %then
                %str("FutGamma") ;
              %if %index(%str( STOCHCURT ),%str( &futility )) %then
                %str("FutMean") ;
			%end ;
            "maxSS" "look" "t" "t2" "SS" "Sigma" "ProbExit" "ProbIncr"
            "NominalP" "LowerP" "UpperP" "LowerZ" "UpperZ" "LowerY" "UpperY"} ;

  create &out var outvar ;
  append ;

  finish ;

  run ;
  quit ;

%if %quote(&append)~= %then %do ;
  data &append ;
    set &append &out ;
	run ;

  %if %quote(&out)=_DEFAULT_ %then %do ;
    proc datasets library=work nolist ;
	  delete _DEFAULT_ ;
	  run ;
	  quit ;
  %end ;

%end ;

%mend SeqBounds ;