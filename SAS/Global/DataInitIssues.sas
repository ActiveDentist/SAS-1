%macro DataInitIssues(data=_Issues_,subno=subno) ;

(drop=IDataSet IOthData IType IssueID Issue ISpecs)
&data (keep=&subno IDataSet IOthData IType IssueID Issue ISpecs)

%mend DataInitIssues ;
