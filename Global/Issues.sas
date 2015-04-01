%macro Issues(IType=WARNING,
              Issue=,
              IDataSet=,
              IOthData=,
              ISpecs=,
              subno=subno,
              data=_Issues_) ;

%global __Issues ;
%if &__Issues= %then %let __Issues=1 ;
%else %let __Issues=%eval(&__Issues + 1) ;

%local i w w0 ISpecsPut PutAt ;
%let i = 1;
%let w = %scan(&ISpecs,&i,%str( )) ;
%do %while("&w"~="") ;
  %local w&i ;
  %let w&i = &w ;
  %let i = %eval(&i + 1) ;
  %let w = %scan(&ISpecs,&i,%str( )) ;
%end ;
%let w0 = %eval(&i - 1) ;

%let PutAt = %eval(%length(&IType) + 3) ;
%let ISpecsPut = @&PutAt &subno.%str(= / @&PutAt) ;
%do i = 1 %to &w0 ;
  %let ISpecsPut = &ISpecsPut &&w&i.= ;
  %if &i=&w0 %then
    %let ISpecsPut = &ISpecsPut / ;
  %else %if &i=5 | &i=10 | &i=15 | &i=20 %then
    %let ISpecsPut = &ISpecsPut / @&PutAt ;
%end ;

put "&IType.: &Issue" / &ISpecsPut ;

length IDataSet $40 IOthData $200 IType $20 IssueID 8 Issue $100 ISpecs $1000 ;
IDataSet = "&IDataSet" ;
IOthData = "&IOthData" ;
IType    = "&IType" ;
IssueID  = &__Issues ;
Issue    = "&Issue" ;

ISpecs = ' ' ;
%do i = 1 %to &w0 ;
  ISpecs = left(trim(ISpecs) || ' ' || "&&w&i.=") ;
  if substr(vformat(&&w&i),1,1)='$' then
    ISpecs = trim(ISpecs) || left(trim(putc(&&w&i,vformat(&&w&i)))) ;
  else
    ISpecs = trim(ISpecs) || left(trim(putn(&&w&i,vformat(&&w&i)))) ;
%end ;

output &data ;

%mend Issues ;
