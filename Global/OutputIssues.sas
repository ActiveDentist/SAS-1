%macro OutputIssues(data=Issues,file=) ;

%if %bquote(&file)= %then %let file = %quote(%fn).xls ;
proc export data=&data outfile="&file" dbms=XLS replace ;
  sheet='Issues' ;
  run ;

%mend ;
