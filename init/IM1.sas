%macro IM1(prot=) ;

libname in  "c:\projects\IM1\&prot\data" access=readonly ;
libname raw "c:\projects\IM1\&prot\data\raw" access=readonly ;
libname ids "c:\projects\IM1\&prot\data\intermed" access=readonly ;
libname out "c:\projects\IM1\&prot\data\intermed" ;
libname IM1fmt "c:\projects\IM1\&prot\formats" ;

filename trt "c:\projects\IM1\&prot\data\raw\p231_&prot._trt.xls" ;

options fmtsearch=(IM1fmt utilfmt) ;

%set_init_directory ;

%local i list ;
%global pad nextt
        head1 head2 head3 head4 head5 head6 head7 head8 head9 head10 
        ;
%let pad='                                                                    ';

%let head1=Protocol: IM1-%substr(&prot,4,2)-%substr(&prot,6) ;

%if &prot=IM1HC103 %then %let head2=(FINAL Data as of: 10AUG2005) ;

%let nextt = 1 ;
%do i = 1 %to 10 ;
  %if %length(&&head&i)>0 %then %do ;
    title&i "&&head&i" &pad &pad ;
    %let nextt = %eval(&i + 1) ;
  %end ;
%end ;

%leave:

%mend IM1 ;