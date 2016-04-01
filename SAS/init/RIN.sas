%macro RIN(prot=,seg=) ;
* Initialization macro to be used at the top of all RIN programs ;

%if &seg~=120 & &seg~=EMEA120 & &seg~=01JAN2009 & &seg~=01JAN2010 %then %do ;
  libname in  "c:\projects\RIN\&prot\data" access=readonly ;
  libname raw "c:\projects\RIN\&prot\data\raw" access=readonly ;
  libname ids "c:\projects\RIN\&prot\data\intermed" access=readonly ;
  libname out "c:\projects\RIN\&prot\data\intermed" ;
%end ;

%else %if &seg=120 %then %do ;
  libname in  "c:\projects\RIN\&prot\120day\data" access=readonly ;
  libname raw "c:\projects\RIN\&prot\120day\data\raw" access=readonly ;
  libname ids "c:\projects\RIN\&prot\120day\data\intermed" access=readonly ;
  libname out "c:\projects\RIN\&prot\120day\data\intermed" ;

  libname inOrig  "c:\projects\RIN\&prot\120day\data\eCRF" access=readonly ;
  libname rawOrig "c:\projects\RIN\&prot\data\raw" access=readonly ;
  libname idsOrig "c:\projects\RIN\&prot\data\intermed" access=readonly ;
  libname outOrig "c:\projects\RIN\&prot\data\intermed" ;
%end ;

%else %if &seg=01JAN2009 %then %do ;
  libname in  "c:\projects\RIN\&prot\Update01JAN2009\data" access=readonly ;
  libname raw "c:\projects\RIN\&prot\Update01JAN2009\data\raw" access=readonly ;
  libname ids "c:\projects\RIN\&prot\Update01JAN2009\data\intermed" access=readonly ;
  libname out "c:\projects\RIN\&prot\Update01JAN2009\data\intermed" ;

  libname inOrig  "c:\projects\RIN\&prot\Update01JAN2009\data\eCRF" access=readonly ;
  libname rawOrig "c:\projects\RIN\&prot\data\raw" access=readonly ;
  libname idsOrig "c:\projects\RIN\&prot\data\intermed" access=readonly ;
  libname outOrig "c:\projects\RIN\&prot\data\intermed" ;
%end ;

%else %if &seg=01JAN2010 %then %do ;
  libname in  "c:\projects\RIN\&prot\Update01JAN2010\data" access=readonly ;
  libname raw "c:\projects\RIN\&prot\Update01JAN2010\data\raw" access=readonly ;
  libname ids "c:\projects\RIN\&prot\Update01JAN2010\data\intermed" access=readonly ;
  libname out "c:\projects\RIN\&prot\Update01JAN2010\data\intermed" ;

  libname inOrig  "c:\projects\RIN\&prot\Update01JAN2010\data\eCRF" access=readonly ;
  libname rawOrig "c:\projects\RIN\&prot\data\raw" access=readonly ;
  libname idsOrig "c:\projects\RIN\&prot\data\intermed" access=readonly ;
  libname outOrig "c:\projects\RIN\&prot\data\intermed" ;
%end ;

%else %if &seg=EMEA120 %then %do ;
  libname in  "c:\projects\RIN\&prot\120day\data" access=readonly ;
  libname raw "c:\projects\RIN\&prot\120day\data\raw" access=readonly ;
  libname ids "c:\projects\RIN\&prot\120day\data\intermed" access=readonly ;
  libname out "c:\projects\RIN\&prot\120day\data\intermed" ;

  libname inOrig  "c:\projects\RIN\&prot\120day\data\eCRF" access=readonly ;
  libname rawOrig "c:\projects\RIN\&prot\data\raw" access=readonly ;
  libname idsOrig "c:\projects\RIN\&prot\data\intermed" access=readonly ;
  libname outOrig "c:\projects\RIN\&prot\data\intermed" ;
%end ;

libname RINfmt "c:\projects\RIN\&prot\formats" ;

options fmtsearch=(RINfmt utilfmt) ;

%set_init_directory;

%local i list ;
%global pad nextt
        head1 head2 head3 head4 head5 head6 head7 head8 head9 head10 
        ;
%let pad='                                                                    ';

%let head1=Protocol: RIN-%substr(&prot,4,2)-%substr(&prot,6) ;
%if %qupcase(&seg)=OL %then
  %let head1 = &head1 [Open-Label Extension] ;
%else %if %qupcase(&seg)=120 %then
  %let head1 = &head1 [Open-Label Extension, 120-day update] ;
%else %if %qupcase(&seg)=EMEA120 %then
  %let head1 = &head1 [EMEA Review Questions] ;
%else %if %qupcase(&seg)=ISS %then
  %let head1 = &head1 [Integrated Summary of Safety] ;
%else %if %qupcase(&seg)=ISE %then
  %let head1 = &head1 [Integrated Summary of Efficacy] ;

%if &prot=RINPH301 & &seg=120 %then %do ;
  %global _DataCutoff_ _DatabaseDate_ ;
  %let _DataCutoff_ = 01JUL2008 ;
  %if %sysfunc(exist(RAW.MPL)) %then %do ;
    %local _rc_ _id_ ;
    %let _id_ = %sysfunc(open(RAW.MPL)) ;
    %let _DatabaseDate_ = %sysfunc(attrn(&_id_,CRDTE)) ;
    %let _DatabaseDate_ = %sysfunc(putn(&_DatabaseDate_,DATETIME9.)) ;
    %let _rc_ = %sysfunc(close(&_id_)) ;
  %end ;
  %else %let _DatabaseDate_ = ????????? ;
  %*let head2=(Data as of: &_DataCutoff_, DRAFT: &_DatabaseDate_) ;
  %let head2=(Data as of: &_DataCutoff_) ;
%end ;

%if &prot=RINPH301 & &seg=01JAN2009 %then %do ;
  %global _DataCutoff_ _DatabaseDate_ ;
  %let _DataCutoff_ = 01JAN2009 ;
  %if %sysfunc(exist(RAW.MPL)) %then %do ;
    %local _rc_ _id_ ;
    %let _id_ = %sysfunc(open(RAW.MPL)) ;
    %let _DatabaseDate_ = %sysfunc(attrn(&_id_,CRDTE)) ;
    %let _DatabaseDate_ = %sysfunc(putn(&_DatabaseDate_,DATETIME9.)) ;
    %let _rc_ = %sysfunc(close(&_id_)) ;
  %end ;
  %else %let _DatabaseDate_ = ????????? ;
  %let head2=(Data as of: &_DataCutoff_) ;
%end ;

%if &prot=RINPH301 & &seg=01JAN2010 %then %do ;
  %global _DataCutoff_ _DatabaseDate_ ;
  %let _DataCutoff_ = 01JAN2010 ;
  %if %sysfunc(exist(RAW.MPL)) %then %do ;
    %local _rc_ _id_ ;
    %let _id_ = %sysfunc(open(RAW.MPL)) ;
    %let _DatabaseDate_ = %sysfunc(attrn(&_id_,CRDTE)) ;
    %let _DatabaseDate_ = %sysfunc(putn(&_DatabaseDate_,DATETIME9.)) ;
    %let _rc_ = %sysfunc(close(&_id_)) ;
  %end ;
  %else %let _DatabaseDate_ = ????????? ;
  %let head2=(Data as of: &_DataCutoff_) ;
%end ;

%else %if &prot=RINPH301 & &seg=EMEA120 %then %do ;
  %global _DataCutoff_ _DatabaseDate_ ;
  %let _DataCutoff_ = 01JUL2008 ;
  %if %sysfunc(exist(RAW.MPL)) %then %do ;
    %local _rc_ _id_ ;
    %let _id_ = %sysfunc(open(RAW.MPL)) ;
    %let _DatabaseDate_ = %sysfunc(attrn(&_id_,CRDTE)) ;
    %let _DatabaseDate_ = %sysfunc(putn(&_DatabaseDate_,DATETIME9.)) ;
    %let _rc_ = %sysfunc(close(&_id_)) ;
  %end ;
  %else %let _DatabaseDate_ = ????????? ;
  %let head2=(Data as of: &_DataCutoff_) ;
%end ;

%else %if &prot=RINPH301 %then %do ;
  %global _DataCutoff_ _DatabaseDate_ ;
  %let _DataCutoff_ = 01JAN2008 ;

  %local _rc_ _id_ _fr_ _dnum_ _fn_ ;
  %let _fr_ = _DC_ ;
  %let _rc_ = %sysfunc(filename(_fr_,C:\projects\RIN\RINPH301\data\raw\Numoda));
  %let _id_ = %sysfunc(dopen(&_fr_));
  %let _dnum_ = %sysfunc(dnum(&_id_)) ;
  %do i = 1 %to &_dnum_ ;
    %let _fn_ = %sysfunc(dread(&_id_,&i)) ;
    %if %index(%str(&_fn_),%str(LRX-TRIUMPH001-Extract))=1 %then %do ;
      %let _fn_ = %scan(%substr(%str(&_fn_),23),1,%str(.)) ;
      %let _fn_ = %substr(&_fn_,1,5)%substr(&_fn_,%eval(%length(&_fn_)-3)) ;
      %if %sysfunc(inputn(&_fn_,DATE.,9))>%sysfunc(inputn(&_DatabaseDate_,DATE.,9)) %then
        %let _DatabaseDate_ = &_fn_ ;
    %end ;
  %end ;
  %let _rc_ = %sysfunc(dclose(&_id_));
  %let _rc_ = %sysfunc(filename(_fr_)) ;

  %let head2=(Data as of: &_DataCutoff_, Locked: &_DatabaseDate_) ;
%end ;

%else %if &prot=RINPH401 %then %do ;
  %global _DatabaseDate_ ;
  %let _DatabaseDate_ = 13DEC2010 ;
  %let head2=(FINAL Data as of: &_DatabaseDate_) ;
%end ;

%let nextt = 1 ;
%do i = 1 %to 10 ;
  %if %length(&&head&i)>0 %then %do ;
    title&i "&&head&i" &pad &pad ;
    %let nextt = %eval(&i + 1) ;
  %end ;
%end ;

%leave:

%mend RIN ;
