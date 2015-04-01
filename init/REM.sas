%macro REM(prot=,Interim=No) ;

%let prot=%upcase(&prot) ;
%let Interim=%upcase(&Interim) ;

%if %substr(&Interim,1,1)=Y %then %do ;
  libname in  "c:\projects\REM\&prot\data\interim" access=readonly ;
  libname raw "c:\projects\REM\&prot\data\interim\raw" access=readonly ;
  libname ids "c:\projects\REM\&prot\data\interim\intermed" access=readonly ;
  libname out "c:\projects\REM\&prot\data\interim\intermed" ;
  filename trt "c:\projects\REM\&prot\data\interim\raw\&prot._trt.xls" ;
%end ;
%else %do ;
  libname in  "c:\projects\REM\&prot\data" access=readonly ;
  libname raw "c:\projects\REM\&prot\data\raw" access=readonly ;
  libname ids "c:\projects\REM\&prot\data\intermed" access=readonly ;
  libname out "c:\projects\REM\&prot\data\intermed" ;
  filename trt "c:\projects\REM\&prot\data\raw\&prot._trt.xls" ;
%end ;

libname REMfmt "c:\projects\REM\&prot\formats" ;
options fmtsearch=(REMfmt utilfmt) ;

%set_init_directory ;

%local i list ;
%global pad nextt
        head1 head2 head3 head4 head5 head6 head7 head8 head9 head10 
        ;
%let pad='                                                                    ';
%if &prot=REVEAL %then
  %let head1=Protocol: REVEAL (Remodulin SC Site Pain Study) ;
%else
  %let head1=Protocol: %substr(&prot,1,3)-%substr(&prot,4,2)-%substr(&prot,6) ;

%if &prot=REMPH401 %then %do ;
  %if %substr(&Interim,1,1)=Y %then
    %let head2=Interim Analysis (Interim Data as of: 27JUL2005) ;
  %else
    %let head2=Final Analysis (FINAL Data as of: 06OCT2005) ;
%end ;

%else %if &prot=REMSP401 %then %do ;
  %let head2=Final Analysis (Data as of: 30MAR2006) ;
%end ;

%else %if &prot=REVEAL %then %do ;
  %let head2=Final Analysis (Data as of: 23FEB2006) ;
%end ;

%let nextt = 1 ;
%do i = 1 %to 10 ;
  %if %length(&&head&i)>0 %then %do ;
    title&i "&&head&i" &pad &pad ;
    %let nextt = %eval(&i + 1) ;
  %end ;
%end ;

%leave:

%mend REM ;
