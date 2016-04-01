%macro LABLABEL(spec=,           /* SUMMARY, LISTING, or GRAPHIC */
                var=,            /* Output variable name */
                label=LABEL,     /* Label variable from IDS.LABINFO */
                unit=STDUNIT) ;  /* Units variable from IDS.LABINFO */
%************************************************************************
%*
%*                        Burroughs Wellcome Co.
%*
%* PURPOSE: Builds different versions of labels for laboratory parms
%*          from the IDS.LABINFO label
%*  AUTHOR: Carl Arneson
%*    DATE: 28 Aug 1996
%*
%***********************************************************************;
%if %length(&spec)=0 | %length(&var)=0 %then %do ;
  %put ERROR: (LABLABEL) Must specify SPEC=, VAR= ;
  %goto leave ;
%end ;
%global _lablbl_ ;
%if "&_lablbl_"="" %then %let _lablbl_=1 ;
%else                    %let _lablbl_=%eval(&_lablbl_ + 1) ;

length &var $40 ;

%if %upcase(&spec)=SUMMARY %then %do ;
  drop __unit&_lablbl_ __labl&_lablbl_ ;
  length __unit&_lablbl_ $25 __labl&_lablbl_ $40 ;


  __unit&_lablbl_ = compress(&unit,'`\~') ;
  __unit&_lablbl_ = tranwrd(__unit&_lablbl_,'*',' ') ;
  /*
  __unit&_lablbl_ = tranwrd(__unit&_lablbl_,'^2','A2'x) ;
  __unit&_lablbl_ = tranwrd(__unit&_lablbl_,'^3','A3'x) ;
  __unit&_lablbl_ = tranwrd(__unit&_lablbl_,'^5','A5'x) ;
  __unit&_lablbl_ = tranwrd(__unit&_lablbl_,'^6','A6'x) ;
  __unit&_lablbl_ = tranwrd(__unit&_lablbl_,'^9','A9'x) ;
  */
  if __unit&_lablbl_ = '(none)' or __unit&_lablbl_=' '
    then __unit&_lablbl_ = ' ' ;
  else __unit&_lablbl_ = '(' || left(trim(__unit&_lablbl_)) || ')' ;

  __labl&_lablbl_ = trim(left(compress(&label,'`\~'))) ;
  __labl&_lablbl_ = tranwrd(__labl&_lablbl_,'*',' ') ;

  &var = trim(__labl&_lablbl_) || ' ' || __unit&_lablbl_ ;
%end ;

%else %if %upcase(&spec)=LISTING %then %do ;
  drop __unit&_lablbl_ __labl&_lablbl_ ;
  length __unit&_lablbl_ $25 __labl&_lablbl_ $40 ;


  __unit&_lablbl_ = &unit ;
  do while (index(__unit&_lablbl_,'`')) ;
    drop __st__ ;
    __st__ = index(__unit&_lablbl_,'`') ;
    substr(__unit&_lablbl_,__st__,1)='FE'x ;
    substr(__unit&_lablbl_,__st__,index(__unit&_lablbl_,'`')-__st__+1)='FE'x ;
    __unit&_lablbl_ = compress(__unit&_lablbl_,'FE'x) ;
  end ;
  __unit&_lablbl_ = tranwrd(__unit&_lablbl_,'~','-*') ;
  __unit&_lablbl_ = tranwrd(__unit&_lablbl_,'\'/*'*/,'*') ;
  /*
  __unit&_lablbl_ = tranwrd(__unit&_lablbl_,'^2','A2'x) ;
  __unit&_lablbl_ = tranwrd(__unit&_lablbl_,'^3','A3'x) ;
  __unit&_lablbl_ = tranwrd(__unit&_lablbl_,'^5','A5'x) ;
  __unit&_lablbl_ = tranwrd(__unit&_lablbl_,'^6','A6'x) ;
  __unit&_lablbl_ = tranwrd(__unit&_lablbl_,'^9','A9'x) ;
  */
  if __unit&_lablbl_ = '(none)' or __unit&_lablbl_=' '
    then __unit&_lablbl_ = ' ' ;
  else __unit&_lablbl_ = '(' || left(trim(__unit&_lablbl_)) || ')' ;

  __labl&_lablbl_ = &label ;
  do while (index(__labl&_lablbl_,'`')) ;
    drop __st__ ;
    __st__ = index(__labl&_lablbl_,'`') ;
    substr(__labl&_lablbl_,__st__,1)='FE'x ;
    substr(__labl&_lablbl_,__st__,index(__labl&_lablbl_,'`')-__st__+1)='FE'x ;
    __labl&_lablbl_ = left(compress(__labl&_lablbl_,'FE'x)) ;
  end ;
  __labl&_lablbl_ = tranwrd(__labl&_lablbl_,'~','-*') ;
  __labl&_lablbl_ = tranwrd(__labl&_lablbl_,'\'/*'*/,'*') ;

  &var = trim(__labl&_lablbl_) || '*' || __unit&_lablbl_ ;
%end ;

%else %if %upcase(&spec)=GRAPHIC %then %do ;
  drop __unit&_lablbl_ __labl&_lablbl_ ;
  length __unit&_lablbl_ $25 __labl&_lablbl_ $40 ;


  __unit&_lablbl_ = compress(&unit,'`\~') ;
  __unit&_lablbl_ = tranwrd(__unit&_lablbl_,'*',' ') ;

  if __unit&_lablbl_ = '(none)' or __unit&_lablbl_=' '
    then __unit&_lablbl_ = ' ' ;
  else __unit&_lablbl_ = '(' || left(trim(__unit&_lablbl_)) || ')' ;

  __labl&_lablbl_ = trim(left(compress(&label,'`\~'))) ;
  __labl&_lablbl_ = tranwrd(__labl&_lablbl_,'*',' ') ;

  &var = trim(__labl&_lablbl_) || ' ' || __unit&_lablbl_ ;
%end ;

%else %do ;
  %put WARNING: (LABLABEL) SPEC=&spec not supported. ;
%end ;

%leave:

%mend LABLABEL ;
