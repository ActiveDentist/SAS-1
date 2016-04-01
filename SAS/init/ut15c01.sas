%macro UT15C01(prot=) ;

libname in  "c:\projects\ut15c01\&prot\data" access=readonly ;
libname raw "c:\projects\ut15c01\&prot\data\raw" access=readonly ;
libname ids "c:\projects\ut15c01\&prot\data\intermed" access=readonly ;
libname out "c:\projects\ut15c01\&prot\data\intermed" ;
libname ut15c01f "c:\projects\ut15c01\&prot\formats" ;

options fmtsearch=(ut15c01f utilfmt) ;

%set_init_directory ;

%local i list ;
%global pad nextt
        head1 head2 head3 head4 head5 head6 head7 head8 head9 head10 
        ;
%let pad='                                                                    ';

%let head1=Protocol: UT15C01:&prot ;

%if &prot=101 %then %let head2=(FINAL Data as of: 02MAR2004) ;

%let nextt = 1 ;
%do i = 1 %to 10 ;
  %if %length(&&head&i)>0 %then %do ;
    title&i "&&head&i" &pad &pad ;
    %let nextt = %eval(&i + 1) ;
  %end ;
%end ;

%leave:

%mend UT15C01 ;