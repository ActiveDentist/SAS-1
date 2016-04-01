%macro InitializeIssues(lib=WORK,data=Issues) ;
%global __Issues ;
%let __Issues = ;

%if %sysfunc(exist(&lib..&data)) %then %do ;
  proc datasets nodetails nolist nowarn lib=&lib ;
    delete &data ;
    run ;
    quit ;
%end ;

%mend InitializeIssues ;
