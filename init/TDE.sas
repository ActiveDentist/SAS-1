%macro TDE(prot=) ;

libname in  "c:\projects\TDE\&prot\data" access=readonly ;
libname raw "c:\projects\TDE\&prot\data\raw" access=readonly ;
libname ids "c:\projects\TDE\&prot\data\intermed" access=readonly ;
libname out "c:\projects\TDE\&prot\data\intermed" ;
libname TDEfmt "c:\projects\TDE\&prot\formats" ;

filename trt "c:\projects\TDE\&prot\data\raw\&prot._trt.xls" ;

options fmtsearch=(TDEfmt utilfmt) ;

%set_init_directory ;

%local i list ;
%global pad nextt
        head1 head2 head3 head4 head5 head6 head7 head8 head9 head10 
        ;
%let pad='                                                                    ';

%let head1=Protocol: TDE-%substr(&prot,4,2)-%substr(&prot,6) ;

%if &prot=TDEPH103 %then %let head2=(FINAL Data as of: 30JUN2005) ;
%else %if &prot=TDEPH104 %then %let head2=(FINAL Data as of: 18NOV2005) ;
%else %if &prot=TDEPH302 %then %let head2=(Soft Lock Data as of: 02JUN2011) ;


%let nextt = 1 ;
%do i = 1 %to 10 ;
  %if %length(&&head&i)>0 %then %do ;
    title&i "&&head&i" &pad &pad ;
    %let nextt = %eval(&i + 1) ;
  %end ;
%end ;

%leave:

%mend TDE ;
