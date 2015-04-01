%macro CompileIssues(in=_Issues_,out=Issues) ;

data &out ;
  set %if %sysfunc(exist(&out)) %then %str(&out) ; &in ;
  run ;

proc datasets nodetails nolist nowarn lib=WORK ;
  delete &in ;
  run ;
  quit ;

%mend CompileIssues ;
