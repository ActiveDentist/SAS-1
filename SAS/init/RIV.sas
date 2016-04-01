%macro RIV(prot=,Interim=No) ;

%let Interim=%upcase(&Interim) ;

%if %substr(&Interim,1,1)=Y %then %do ;
  libname in  "c:\projects\RIV\&prot\interim\data" access=readonly ;
  libname raw "c:\projects\RIV\&prot\interim\data\raw" access=readonly ;
  libname ids "c:\projects\RIV\&prot\interim\data\intermed" access=readonly ;
  libname out "c:\projects\RIV\&prot\interim\data\intermed" ;
  filename trt "c:\projects\RIV\&prot\interim\data\raw\&prot._trt_DUMMY.xls" ;
%end ;
%else %do ;
  libname in  "c:\projects\RIV\&prot\data" access=readonly ;
  libname raw "c:\projects\RIV\&prot\data\raw" access=readonly ;
  libname ids "c:\projects\RIV\&prot\data\intermed" access=readonly ;
  libname out "c:\projects\RIV\&prot\data\intermed" ;
  %if &prot~=RIVPH406 %then %do ;
    filename trt "c:\projects\RIV\&prot\data\raw\&prot._trt.xls" ;
  %end ;
%end ;
libname RIVfmt "c:\projects\RIV\&prot\formats" ;

options fmtsearch=(RIVfmt utilfmt) ;

%set_init_directory ;

%local i list ;
%global pad nextt
        head1 head2 head3 head4 head5 head6 head7 head8 head9 head10 
        ;
%let pad='                                                                    ';

%let head1=Protocol: RIV-%substr(&prot,4,2)-%substr(&prot,6) ;

%if &prot=RIVPH406 %then %let head2=(Manuscript Data as of: 28SEP2005) ;
%else %if &prot=RIVPH407 %then %let head2= /*(Manuscript Data as of: 23DEC2005)*/ ;
%else %if &prot=RIVPH409 %then %let head2=(FINAL Data as of: 20SEP2006) ;
%else %if &prot=RIVPH402 %then %do ;
  %if %substr(&Interim,1,1)=Y %then
    %let head2=Interim Analysis (Interim Data as of: 21NOV2005) ;
  %else
   %let head2=FINAL Analysis (FINAL Data as of: 10JUL2006) ;
%end ;

%let nextt = 1 ;
%do i = 1 %to 10 ;
  %if %length(&&head&i)>0 %then %do ;
    title&i "&&head&i" &pad &pad ;
    %let nextt = %eval(&i + 1) ;
  %end ;
%end ;

%leave:

%mend RIV ;
