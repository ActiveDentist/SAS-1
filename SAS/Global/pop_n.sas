%macro pop_N(
             data=,         /* Data set with population specifier & tmt       */
             pop=,          /* Population indicator variable in data set      */
             tmtvar=,       /* Treatment variable in data set                 */
             tmtfmt=,       /* Format for treatment variable                  */
             outfmt=,       /* Output format name (default: &outfmt.n)        */
             outmv=,        /* Output mac. vars (def: level1-leveln, total)   */
             split=%str(*)  /* Split character to use in OUTFMT               */
            ) ;
%*******************************************************************************
%*
%*                            Glaxo Wellcome Inc.
%*
%*   STUDY: L-NMMA (546C88)
%* PURPOSE: Figure out population size for each treatment group and
%*          put this info into a format for treatment and global mvs
%*  AUTHOR: Carl P. Arneson
%*    DATE: 20 Oct 1997
%*
%******************************************************************************;

%* Check for required parameters ;
%if %quote(&data)= | %quote(&pop)= | %quote(&tmtvar)= %then %do ;
  %put ERROR: (POP_N) Must specify DATA=, POP=, TMTVAR=. ;
  %goto leave ;
%end ;
%* Make sure data set exists ;
%else %if %sysfunc(exist(&data))=0 %then %do ;
  %put ERROR: (POP_N) DATA=&data does not exist. ;
  %goto leave ;
%end ;
%* Make sure variables are on data set and pull their numbers ;
%else %do ;
  %local i dsid rc _tmtnum_ _tmttyp_ _tmtlev_ _tmttot_ _popnum_ _fmtsrc_ w;
  %let dsid = %sysfunc(open(&data,i)) ;
  %let _popnum_=%sysfunc(varnum(&dsid,&pop)) ;
  %if ~&_popnum_ %then %do ;
    %put ERROR: (POP_N) POP=&pop not found on DATA=&data.. ;
    %goto leave ;
  %end ;
  %else %if %sysfunc(vartype(&dsid,&_popnum_))=C %then %do ;
    %put ERROR: (POP_N) POP=&pop must be a numeric indicator variable. ;
    %goto leave ;
  %end ;
  %let _tmtnum_=%sysfunc(varnum(&dsid,&tmtvar)) ;
  %if ~&_tmtnum_ %then %do ;
    %put ERROR: (POP_N) TMTVAR=&tmtvar not found on DATA=&data.. ;
    %goto leave ;
  %end ;
  %let _tmttyp_ = %sysfunc(vartype(&dsid,&_tmtnum_)) ;
%end ;

%* If TMTFMT is not specified, use a logical default ;
%if %quote(&tmtfmt)= %then %do ;

  %* First, check if one is already attached to treatment variable ;
  %let tmtfmt = %sysfunc(varfmt(&dsid,&_tmtnum_)) ;

  %* If not, assume it matches the name of the variable ;
  %if %quote(&tmtfmt)= %then %do ;
    %if &_tmttyp_=C %then %let tmtfmt = $&tmtvar.. ;
    %else                 %let tmtfmt = &tmtvar.. ;
  %end ;

%end ;
%else %do ;

  %let tmtfmt = %upcase(%trim(&tmtfmt)) ;
  %if %substr(&tmtfmt,%length(&tmtfmt),1)~=. %then %let tmtfmt= &tmtfmt.. ;

  %* Make sure type of specified format matches variable ;
  %if (&_tmttyp_=C & %substr(&tmtfmt,1,1)~=$) |
      (&_tmttyp_=N &
       %index(ABCDEFGHIJKLMNOPQRSTUVWXYZ_,%substr(&tmtfmt,1,1))=0)
      %then %do ;
    %put ERROR: (POP_N) Type of TMTFMT=&tmtfmt does not match type of TMTVAR=&tmtvar.. ;
    %goto leave ;
  %end ;

%end ;

%* Set an output format name if its not set ;
%if %quote(&outfmt)= %then %do ;

  %if %length(&tmtfmt)<=8 %then
    %let outfmt=%substr(&tmtfmt,1,%eval(%length(&tmtfmt)-1))N. ;
  %else
    %let outfmt=%substr(&tmtfmt,1,7)N. ;

%end ;
%else %do ;

  %let outfmt = %upcase(%trim(&outfmt)) ;
  %if %substr(&outfmt,%length(&outfmt),1)~=. %then %let outfmt= &outfmt.. ;

  %* Make sure type of format matches variable ;
  %if (&_tmttyp_=C & %substr(&outfmt,1,1)~=$) |
      (&_tmttyp_=N &
       %index(ABCDEFGHIJKLMNOPQRSTUVWXYZ_,%substr(&outfmt,1,1))=0)
      %then %do ;
    %put ERROR: (POP_N) Type of OUTFMT=&outfmt does not match type of TMTVAR=&tmtvar.. ;
    %goto leave ;
  %end ;

%end ;

%let dsid=%sysfunc(close(&dsid)) ;

%* Make sure population variable is a (0,1) variable ;
data _p_o_p_n ;
  set &data (keep=&tmtvar &pop) ;
  pop = (&pop>0) ;
  run ;

%* Count observations in each level of treatment variables ;
proc summary data=_p_o_p_n nway ;
  class &tmtvar pop ;
  output out=_p_o_p_n(keep=&tmtvar pop _freq_) ;
  run ;

data _p_o_p_n;
   set _p_o_p_n;
   length start $200;
   %if &_tmttyp_ = C %then %do;
      start = &tmtvar;
      %end;
   %else %if &_tmttyp_ = N %then %do;
      start = put(&tmtvar,16.);
      %end;
   run;

%* Only keep track of count for population of interest, but do it
%* this way to make sure _ALL_ levels of TMTVAR are accounted for,
%* even if they dont occur in this particular population ;
proc transpose data=_p_o_p_n
               out=_p_o_p_n(keep=start _1 rename=(_1=N)) ;
  by start ;
  var _freq_ ;
  id pop ;
  run ;


%* Count the number of levels of treatment ;
%let dsid=%sysfunc(open(_p_o_p_n,i)) ;
%let _tmtlev_ = %sysfunc(attrn(&dsid,NOBS)) ;
%let _tmtnum_ = %sysfunc(varnum(&dsid,N)) ;

%* Create a local array of variables for output MV names assigning
%* any specified variables to the first levels, and filling in missing
%* levels with a default of "LEVEL#", and fill their values with the
%* counts ;
%let _tmttot_ = 0 ;
%do i = 1 %to &_tmtlev_ ;
  %local __mv&i ;
  %let __mv&i = %scan(&outmv,&i,%str( )) ;
  %if %quote(&&__mv&i)= %then %let __mv&i = LEVEL&i ;
  %global &&__mv&i ;
  %let rc = %sysfunc(fetchobs(&dsid,&i)) ;
  %let rc = %sysfunc(getvarn(&dsid,&_tmtnum_)) ;
  %if &rc=. %then %let &&__mv&i = 0 ;
  %else %do ;
    %let &&__mv&i = &rc ;
    %let _tmttot_ = %eval(&_tmttot_ + &rc) ;
  %end ;
%end ;

%* Do the same thing for total across all levels ;
%local __mvt ;
%let __mvt = %scan(&outmv,&i,%str( )) ;
%if %quote(&__mvt)= %then %let __mvt = TOTAL ;
%global &__mvt ;
%let &__mvt = &_tmttot_ ;

%let rc = %sysfunc(close(&dsid)) ;

%* Now figure out where the treatment format is ;
%let _fmtsrc_ = %sysfunc(getoption(fmtsearch)) ;
%put ------ _fmtsrc_ = *&_fmtsrc_*;

%if %quote(&_fmtsrc_)~= %then
  %let _fmtsrc_ = %substr(&_fmtsrc_,2,%eval(%length(&_fmtsrc_)-2)) ;

%let _fmtsrc_ = WORK &_fmtsrc_ LIBRARY ;


%let i = 1 ;
%let rc = 0 ;
%let w = %scan(&_fmtsrc_,&i,%str( ));

%do %while(%bquote(&w)^= & &rc=0) ;
  %* See if it has a format matching the specified TMTFMT ;
  %if %sysfunc(cexist(&w..FORMATS))>0 %then %do;
    proc format lib=&w..FORMATS cntlout=p_o_p_n_ ;
      select %substr(&tmtfmt,1,%eval(%length(&tmtfmt)-1));
      run ;

    %let dsid = %sysfunc(open(p_o_p_n_,i)) ;
    %let rc = %sysfunc(attrn(&dsid,NOBS)) ;
    %let dsid = %sysfunc(close(&dsid)) ;
    %end;

  %let i = %eval(&i + 1);
  %let w = %scan(&_fmtsrc_,&i,%str( ));

  %if &i > 3 %then %goto leave;
%end ;

%if &rc=0 %then %do ;
  %put WARNING: (POP_N) Cannot find TMTFMT=&tmtfmt.... will not make format. ;
  %goto leave ;
%end ;

%* Build a new format based on existing format, just tacking on Ns ;

data _p_o_p_n ;
  length label start end $200 ;
  merge  p_o_p_n_(keep=start label)
        _p_o_p_n (keep=start n) ;
  by start ;
  length fmtname $8 extra $15 type $1 ;

  %if &_tmttyp_=C %then %do ;
    fmtname = "%substr(&outfmt,2,%eval(%length(&outfmt)-2))" ;
    type = "C" ;
  %end ;
  %else %do ;
    fmtname = "%substr(&outfmt,1,%eval(%length(&outfmt)-1))" ;
    type = "N" ;
  %end ;

  end = start ;

  if n>.Z then extra = "&split.(N=" || compress(put(n,8.)) || ')' ;
  else extra = "&split.(N=0)" ;

  if label=' ' then label='???' || extra ;
  else label = trim(label) || extra ;

  output ;
  substr(fmtname,length(fmtname),1) = 'C' ;
  label = translate(label," ","&split") ;
  output ;

  run ;

proc sort data=_p_o_p_n ;
  by fmtname ;
  run ;

proc format cntlin=_p_o_p_n;
  run;


%leave:

%mend pop_N ;
