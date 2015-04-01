%macro GReset(cat=PANELS) ;

goptions reset=all ;

%if %sysfunc(cexist(&cat,u)) %then %do ;

  proc greplay nofs igout=&cat gout=&cat ;
    delete _all_ ;
    run ;
    quit ;

%end ;

%mend GReset ;