%macro OVA(prot=) ;

libname in  "c:\projects\OVA\&prot\data" access=readonly ;
libname raw "c:\projects\OVA\&prot\data\raw" access=readonly ;
libname ids "c:\projects\OVA\&prot\data\intermed" access=readonly ;
libname out "c:\projects\OVA\&prot\data\intermed" ;
%*if &prot~=OVAGY406 %then %do ;
%*  filename trt "c:\projects\OVA\&prot\data\raw\&prot._trt.xls" ;
%*end ;
libname OVAfmt "c:\projects\OVA\&prot\formats" ;

options fmtsearch=(OVAfmt utilfmt) ;

%set_init_directory ;

%local i list ;
%global pad nextt
        head1 head2 head3 head4 head5 head6 head7 head8 head9 head10 
        ;
%let pad='                                                                    ';

%let head1=Protocol: OVA-%substr(&prot,4,2)-%substr(&prot,6) ;

%let nextt = 1 ;
%do i = 1 %to 10 ;
  %if %length(&&head&i)>0 %then %do ;
    title&i "&&head&i" &pad &pad ;
    %let nextt = %eval(&i + 1) ;
  %end ;
%end ;

%leave:

%mend OVA ;
