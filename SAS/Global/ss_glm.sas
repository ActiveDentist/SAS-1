%macro SS_GLM(
              /* Required POWERLIB specs */
              essencex=,
              sigma=,
              beta=,
              c=,

              /* Optional POWERLIB specs */
              u=,
              theta0=,

                    /* note: these arent supported yet */
              alpha=,        /* Make sure to */
              sigscal=,      /* handle multiple */
              rhoscal=,      /* values for these */
              betascal=,     /* vectors         */
              round=,
              toleranc=,
              opt_on=,       /* Think about */
              opt_off=,      /* these later */
              dsname=,

              /* Additional optional specs */
              cross=Y,                         /* Cross multiple values?   */
              min=1,                           /* Min. for SS search range */
              max=2000,                        /* Max. for SS search range */
              power={.80 .85 .90},             /* Vector of desired powers */
              out=ss_glm                       /* Output Dataset           */
             );

%* Put arguments which allow multiple values into arrays ;
%let ess0=%bwwords(&essencex,root=ess,delm=%str(|)) ;
%let sig0=%bwwords(&sigma,   root=sig,delm=%str(|)) ;
%let bet0=%bwwords(&beta,    root=bet,delm=%str(|)) ;
%let c0  =%bwwords(&c,       root=c,  delm=%str(|)) ;
%let u0  =%bwwords(&u,       root=u,  delm=%str(|)) ;
%let the0=%bwwords(&theta0,  root=the,delm=%str(|)) ;

%* Make sure required arguments have been specified ;
%if &ess0=0 | &sig0=0 | &bet0=0 | &c0=0 %then %do ;
  %put ERROR: (SS_GLM) Must specify ESSENCEX=, SIGMA=, BETA=, and C=. ;
  %goto leave ;
%end ;

%* If multiple values arent being crossed, make sure the numbers match ;
%if %upcase(%substr(&cross,1,1))~=Y %then %do ;
  %if &ess0~=&sig0 or &ess0~=&bet0 or &ess0~=&c0
      or (&u0>0 & &ess0~=&u0) or (&the0>0 & &ess0~=&the0) %then %do ;
    %put ERROR: (SS_GLM) Number of matrices specified must match for CROSS=N.;
    %goto leave;
  %end ;
%end ;

libname utiliml '~/sas/iml' ;

%* Start IML ;
proc iml ;

  %* Load the POWERLIB modules ;
  reset storage=utiliml.power ;
  load module=_all_ ;


  %* define a module to resolve macro variables dynamically ;
  start resolve(macvar) ;
    call execute('val=&',macvar,';') ;
    return(val);
  finish ;

  %* set up the output dataset ;
  %let vars=%eval(14 + %eval(&u0>0) + %eval(&the0>0) ) ;
  dummy={ %do i = 1 %to &vars ; 1 %end ; } ;
  outvar = {essencex sigma beta contrast
            %if &u0>0 %then %do ;
              u
            %end ;
            %if &the0>0 %then %do ;
              theta
            %end ;
            des_pow num_iter n case alpha
            sigscal rhoscal betascal total_n power} ;

  create &out from dummy[colname=outvar] ;



  %* loop over all essence matrices ;
  do i = 1 to &ess0 ;
    essencex = resolve(concat('ess',char(i,int(log10(i))+1)));

%* If we are crossing over multiple values, start a bunch of do ;
%* loops and resolve the correct matrices ;
%if %upcase(%substr(&cross,1,1))=Y %then %do ;
    do j = 1 to &sig0 ;
      sigma = resolve(concat('sig',char(j,int(log10(j))+1))) ;
      do k = 1 to &bet0 ;
        beta = resolve(concat('bet',char(k,int(log10(k))+1))) ;
        do l = 1 to &c0 ;
          c = resolve(concat('c',char(l,int(log10(l))+1))) ;
          %if &u0>0 %then %do ;
            do m = 1 to &u0 ;
              u = resolve(concat('u',char(m,int(log10(m))+1))) ;
          %end ;
          %if &the0>0 %then %do ;
            do o = 1 to &the0 ;
              theta0 = resolve(concat('the',char(o,int(log10(o))+1))) ;
          %end ;
%end ;

%* Otherwise, just resolve correct matrices ;
%else %do ;
    sigma = resolve(concat('sig',char(i,int(log10(i))+1)));
    beta  = resolve(concat('bet',char(i,int(log10(i))+1)));
    c     = resolve(concat('c',char(i,int(log10(i))+1)));
    %if &u0>0 %then %do ;
      u   = resolve(concat('u',char(i,int(log10(i))+1)));
    %end ;
    %if &the0>0 %then %do ;
      theta0 = resolve(concat('the',char(i,int(log10(i))+1)));
    %end ;
%end ;

  %* grab the vector of powers ;
  des_pow = &power ;

  %* loop over all powers ;
  do p = 1 to ncol(des_pow) ;

    %* set search bounds ;
    lb = &min ; ub = &max ;

    %* turn off printout and warnings from "POWER" module ;
    opt_on={noprint} ;
    opt_off={warn} ;

    %* initialize sample size and #of search iterations ;
    n = 0 ;
    iter = 0 ;

    %* calculate power at the lower and upper bounds ;
    repn = lb ;
    run power ;
    iter = iter + 1 ;
    lp = _holdpow ;

    repn = ub ;
    run power ;
    iter = iter + 1 ;
    up = _holdpow ;

    %* perform discrete bisection to search for sample size that ;
    %* acheives desired power ;
    if (lp[1,ncol(lp)] <= des_pow[1,p] <= up[1,ncol(up)]) then do ;
      do while (ub-lb>1) ;
        repn = int((ub+lb)/2) ;
        run power ;
        iter = iter + 1 ;
        if      (des_pow[1,p] < _holdpow[1,ncol(_holdpow)]) then do ;
          ub = repn ;
          up = _holdpow ;
        end ;
        else if (des_pow[1,p] > _holdpow[1,ncol(_holdpow)]) then do ;
          lb = repn ;
          lp = _holdpow ;
        end ;
        else do ;
          n = repn ;
          goto getout ;
        end ;
      end ;
      n = ub ;
      _holdpow = up ;
    end ;
getout:

    %* compile the results into a single row vector ;
    outmat =  %if %upcase(%substr(&cross,1,1))=Y %then %do ;
                i || j || k || l
                %if &u0>0 %then %do ;
                  || m
                %end ;
                %if &the0>0 %then %do ;
                  || o
                %end ;
              %end ;
              %else %do ;
                i || i || i || i
                %if &u0>0 %then %do ;
                  || i
                %end ;
                %if &the0>0 %then %do ;
                  || i
                %end ;
              %end ;
              || des_pow[1,p] || iter || n || _holdpow[1,] ;
  append from outmat ;

  %* end loop over power ;
  end ;

%* If we are crossing over multiple values, close all the loops ;
%if %upcase(%substr(&cross,1,1))=Y %then %do ;
  end ; end ; end ;
  %if &u0>0 %then %str(end ;) ;
  %if &the0>0 %then %str(end ;) ;
%end ;

  %* close outermost loop ;
  end ;

  quit ;

%leave:

%mend SS_GLM ;
