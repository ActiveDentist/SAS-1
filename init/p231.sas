%macro P231(prot=) ;

libname in  "c:\projects\p231\&prot\data" access=readonly ;
%if %index(%str( 0101 0102 ),%str( &prot )) %then %do ;
  libname NoFmt "c:\projects\p231\&prot\data\noformats" access=readonly ;
%end ;
libname raw "c:\projects\p231\&prot\data\raw" access=readonly ;
libname ids "c:\projects\p231\&prot\data\intermed" access=readonly ;
libname out "c:\projects\p231\&prot\data\intermed" ;
libname p231fmt "c:\projects\p231\&prot\formats" ;

filename trt "c:\projects\p231\&prot\data\raw\p231_&prot._trt.xls" ;

options fmtsearch=(p231fmt utilfmt) ;

%set_init_directory ;

%local i list ;
%global pad nextt
        head1 head2 head3 head4 head5 head6 head7 head8 head9 head10 
        ;
%let pad='                                                                    ';

%if %length(&prot)=4 %then
  %let head1=Protocol: P231-%substr(&prot,1,2):%substr(&prot,3,2) ;
%else
  %let head1=Protocol: P231 - &prot ;

%if &prot=0101 %then %let head2=(FINAL Data as of: 10FEB2003) ;
%else %if &prot=0102 %then %let head2=(FINAL Data as of: 15DEC2004) ;
%else %if &prot=0201 %then %let head2=(FINAL Data as of: 15APR2005) ;

%let nextt = 1 ;
%do i = 1 %to 10 ;
  %if %length(&&head&i)>0 %then %do ;
    title&i "&&head&i" &pad &pad ;
    %let nextt = %eval(&i + 1) ;
  %end ;
%end ;

%leave:

%mend P231 ;