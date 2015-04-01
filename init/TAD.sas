%macro TAD(prot=) ;

libname in  "c:\projects\TAD\&prot\data" access=readonly ;
libname raw "c:\projects\TAD\&prot\data\raw" access=readonly ;
libname ids "c:\projects\TAD\&prot\data\intermed" access=readonly ;
libname out "c:\projects\TAD\&prot\data\intermed" ;
libname TADfmt "c:\projects\TAD\&prot\formats" ;

%if &prot=LVGX %then %do ;
  libname inDB  "c:\projects\TAD\LVGY\data" access=readonly ;
  libname idsDB "c:\projects\TAD\LVGY\data\intermed" access=readonly ;
%end ;

options fmtsearch=(TADfmt utilfmt) ;

%set_init_directory ;

%local i list ;
%global pad nextt
        head1 head2 head3 head4 head5 head6 head7 head8 head9 head10 
        ;
%let pad='                                                                    ';

%let head1=Protocol: Tadalafil Study &prot ;

%if &prot=LVGX %then %let head2=(Lilly Data Transfer March 2009) ;
%else %if &prot=LVGY %then %let head2=(Lilly Data Transfer March 2009) ;

%let nextt = 1 ;
%do i = 1 %to 10 ;
  %if %length(&&head&i)>0 %then %do ;
    title&i "&&head&i" &pad &pad ;
    %let nextt = %eval(&i + 1) ;
  %end ;
%end ;

%leave:

%mend TAD ;
