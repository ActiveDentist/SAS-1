%macro RELTIME (
                date=,      /* variable containing date of observation */
                time=,      /* variable containing time of observation */
                datetime=,  /* can use this instead of date= and time= */
                ref_d=,     /* variable containing reference date      */
                ref_t=,     /* variable containing reference time      */
                ref_dt=,    /* can use this instead of ref_d and ref_t */

                units=yr mo wk d h m s,   /* units of time overall     */ 
                units_v=,   /* var. containing unit per obs.           */
                round=1,    /* rounding factor for minimum unit        */
                round_v=,   /* var containing rounding factor per obs. */

                year=yr,    /* year abbreviation                       */
                month=mo,   /* month abbreviation                      */
                week=wk,    /* week abbreviation                       */
                day=d,      /* day abbreviation                        */
                hour=h,     /* hour abbreviation                       */
                minute=m,   /* minute abbreviation                     */
                second=s,   /* second abbreviation                     */

                reltime=reltime,    /* var. name for rel. time string  */
                reltimen=reltimen,  /* var. name for rel. time in sec. */
                maxlen=_MAXLEN_     /* macro var for max string length */
               ) ;

%***********************************************************************;
%*                                                                     *;
%* This macro will calculate relative times between two points in      *;
%* both numeric and character format, and will eventually put          *;
%* observations into time windows.                                     *;
%*                                                                     *;
%***********************************************************************;

%***********************************************************************
%* Set a counter for # of times macro has been called (so we dont
%* over-write internal variables):
%**********************************************************************;
%global __r_t__ ;
%if   %length(&__r_t__)=0 %then %let __r_t__ = 1 ;
%else                           %let __r_t__ = %eval(&__r_t__ + 1) ;


%***********************************************************************
%* If DATETIME= is not specified, try to calculate it and put it
%* in a temporary variable:
%**********************************************************************;
%if %length(&datetime)=0 %then %do ;

  %* if no date is specified, complain and leave ;
  %if %length(&date)=0 %then %do ;
    %put ERROR: (RELTIME macro) DATE= or DATETIME= must be specified. ;
    %goto leave ;
  %end ;

  %* if DATE= is specified, but TIME= is not, set a dummy time variable ;
  %else %if %length(&time)=0 %then %do ;

    %let time=__T__&__r_t__ ;
    DROP &time ;

    %* first try to get time from REF_DT= ;
    %if %length(&ref_dt)>0 %then %do ;
      %put NOTE: (RELTIME macro) TIME= not set.  Current time taken from REF_DT=&ref_dt..;
      &time = TIMEPART(&ref_dt) ;
    %end ;
    %* next try to get it from REF_T= ;
    %else %if %length(&ref_t)>0 %then %do ;
      %put NOTE: (RELTIME macro) TIME= not set.  Current time taken from REF_T=&ref_t..;
      &time = &ref_t ;
    %end ;
    %* otherwise, set it to noon ;
    %else %do ;
      %put NOTE: (RELTIME macro) TIME= not set.  Current time set to noon. ;
      &time = HMS(12,00,00) ;
    %end ;

  %end ;

  %let datetime=__DT__&__r_t__ ;
  DROP &datetime ;
  &datetime = (&date * 86400 + &time) ;

%end ;
%else %if %length(&date&time)>0 %then 
  %put WARNING: Both DATETIME= and DATE= and/or TIME= have been specified.  DATETIME= will be used. ;

%***********************************************************************
%* If REL_DT= is not specified, try to calculate it and put it
%* in a temporary variable:
%**********************************************************************;
%if %length(&ref_dt)=0 %then %do ;

  %* if no reference date is specified, complain and leave ;
  %if %length(&ref_d)=0 %then %do ;
    %put ERROR: (RELTIME macro) REL_D= or REL_DT= must be specified. ;
    %goto leave ;
  %end ;

  %* if REF_D= is specified, but REF_T= is not, set a dummy time variable ;
  %else %if %length(&ref_t)=0 %then %do ;

    %let ref_t=__RT__&__r_t__ ;
    DROP &ref_t ;

    %* first try to get time from DATETIME= ;
    %if %quote(&datetime) ~= %quote(__DT__&__r_t__) %then %do ;
      %put NOTE: (RELTIME macro) REF_T= not set.  Reference time taken from DATETIME=&datetime..;
      &ref_t = TIMEPART(&datetime) ;
    %end ;
    %* next try to get it from TIME= ;
    %else %if %quote(&time) ~= %quote(__T__&__r_t__) %then %do ;
      %put NOTE: (RELTIME macro) REF_T= not set.  Reference time taken from TIME=&time..;
      &ref_t = &time ;
    %end ;
    %* otherwise, set it to noon ;
    %else %do ;
      %put NOTE: (RELTIME macro) REF_T= not set.  Reference time set to noon. ;
      &ref_t = HMS(12,00,00) ;
    %end ;

  %end ;

  %let ref_dt=__RDT_&__r_t__ ;
  DROP &ref_dt ;
  &ref_dt = (&ref_d * 86400 + &ref_t) ;

%end ;
%else %if %length(&ref_d&ref_t)>0 %then 
  %put WARNING: Both REF_DT= and REF_D= and/or REF_T= have been specified.  REF_DT= will be used. ;


%***********************************************************************
%* Check the time units specifications and put the overall units
%* into blank spots in the dynamic variable:
%**********************************************************************;
%* create a temporary dynamic unit variable if it isnt specified ;
%if %length(&units_v)=0 %then %do ;
  %let units_v = __UN__&__r_t__ ;
  DROP &units_v ;
  LENGTH &units_v $16 ;
%end ;
%* create a temporary dynamic round variable if it isnt specified ;
%if %length(&round_v)=0 %then %do ;
  %let round_v= __RV__&__r_t__ ;
  DROP &round_v ;
  &round_v = . ;
%end ;  

%let units=%left(%lowcase(&units)) ;

%* reset defaults if they are set to missing ;
%if %length(&units)=0 %then %let units=yr mo wk d h m s ;
%if %length(&round)=0 %then %let round=1 ;
IF &units_v = ' ' THEN &units_v = "&units" ;
ELSE &units_v = LOWCASE(&units_v) ;
IF &round_v <= .Z THEN &round_v = &round ;


%***********************************************************************
%* Calculate relative time and build text string for it:
%**********************************************************************;
%* Set up a bunch of temporary variables ;
%local neg_sign max_len temp_n temp_c yr mo wk d h m s 
       fyr fmo fd fh fm fs tyr tmo td th tm ts tmo ;
%let neg_sign = __NS__&__r_t__ ;
%let max_len  = __MX__&__r_t__ ;
%let temp_n = __TN__&__r_t__ ;
%let temp_c = __TC__&__r_t__ ;
%let yr = __YR__&__r_t__ ;
%let mo = __MO__&__r_t__ ;
%let wk = __WK__&__r_t__ ;
%let d  = __D__&__r_t__ ;
%let h  = __H__&__r_t__ ;
%let m  = __M__&__r_t__ ;
%let s  = __S__&__r_t__ ;
%let fyr = __FYR_&__r_t__ ;
%let fmo = __FMO_&__r_t__ ;
%let fd  = __FD__&__r_t__ ;
%let fh  = __FH__&__r_t__ ;
%let fm  = __FM__&__r_t__ ;
%let fs  = __FS__&__r_t__ ;
%let tyr = __TYR_&__r_t__ ;
%let tmo = __TMO_&__r_t__ ;
%let td  = __TD__&__r_t__ ;
%let th  = __TH__&__r_t__ ;
%let tm  = __TM__&__r_t__ ;
%let ts  = __TS__&__r_t__ ;

LENGTH &neg_sign $1 &temp_c $8 &reltime $80 ;
DROP &neg_sign &max_len &temp_c &temp_n &yr &mo &wk &d &h &m &s
     &fyr &fmo &fd &fh &fm &fs &tyr &tmo &td &th &tm &ts ;

%***********************************************************************
%* Figure out the minimum units for rounding purposes:
%**********************************************************************;
&temp_n = 1 ;
DO WHILE (SCAN(&units_v,&temp_n,' ') ~= ' ') ;
  &temp_c = SCAN(&units_v,&temp_n,' ') ;
  &temp_n = &temp_n + 1 ;
END ;

&reltimen = &datetime - &ref_dt ;

DROP &fyr &fmo &fd &fh &fm &fs &tyr &tmo &td &th &tm &ts ;

%* Set the "FROM" and "TO" for each unit (depending on neg or pos rel. time) ;
IF .Z < &reltimen < 0 THEN DO ;
  &neg_sign = '-' ;
  &fyr = YEAR(DATEPART(&datetime)) ;
  &fmo = MONTH(DATEPART(&datetime)) ;
  &fd  = DAY(DATEPART(&datetime)) ;
  &fh  = HOUR(&datetime) ;
  &fm  = MINUTE(&datetime) ;
  &fs  = SECOND(&datetime) ;
  &tyr = YEAR(DATEPART(&ref_dt)) ;
  &tmo = MONTH(DATEPART(&ref_dt)) ;
  &td  = DAY(DATEPART(&ref_dt)) ;
  &th  = HOUR(&ref_dt) ;
  &tm  = MINUTE(&ref_dt) ;
  &ts  = SECOND(&ref_dt) ;
END ;
ELSE DO ;
  &fyr = YEAR(DATEPART(&ref_dt)) ;
  &fmo = MONTH(DATEPART(&ref_dt)) ;
  &fd  = DAY(DATEPART(&ref_dt)) ;
  &fh  = HOUR(&ref_dt) ;
  &fm  = MINUTE(&ref_dt) ;
  &fs  = SECOND(&ref_dt) ;
  &tyr = YEAR(DATEPART(&datetime)) ;
  &tmo = MONTH(DATEPART(&datetime)) ;
  &td  = DAY(DATEPART(&datetime)) ;
  &th  = HOUR(&datetime) ;
  &tm  = MINUTE(&datetime) ;
  &ts  = SECOND(&datetime) ;
END ;

IF INDEXW(&units_v,"yr") THEN DO ;
  &yr = &tyr - &fyr ;

  IF &yr THEN DO ;
    SELECT ;
      WHEN (&fmo = &tmo) SELECT ;
        WHEN (&fd = &td) SELECT ;
          WHEN (&fh = &th) SELECT ;
            WHEN (&fm = &tm) DO;
              IF (&fs > &ts) THEN &yr = &yr - 1 ;
            END ;
            WHEN (&fm > &tm) &yr = &yr - 1 ;
            OTHERWISE ;
          END ;
          WHEN (&fh > &th) &yr = &yr - 1 ;
          OTHERWISE ;
        END ;
        WHEN (&fd > &td) &yr = &yr - 1 ;
        OTHERWISE ;
      END ;
      WHEN (&fmo > &tmo) &yr = &yr - 1 ;
      OTHERWISE ;
    END ;
  END ;

  &fyr = &fyr + &yr ;
            
END ;
ELSE &yr = 0 ;

IF INDEXW(&units_v,"mo") THEN DO ;
  &mo = INTCK("MONTH",MDY(&fmo,1,&fyr),MDY(&tmo,1,&tyr)) ;

  IF &mo THEN DO ;
    SELECT ;
      WHEN (&fd = &td) SELECT ;
        WHEN (&fh = &th) SELECT ;
          WHEN (&fm = &tm) DO ;
            IF (&fs > &ts) THEN &mo = &mo - 1 ;
          END ;
          WHEN (&fm > &tm) &mo = &mo - 1 ;
          OTHERWISE ;
        END ;
        WHEN (&fh > &th) &mo = &mo - 1 ;
        OTHERWISE ;
      END ;
      WHEN (&fd > &td) &mo = &mo - 1 ;
      OTHERWISE ;
    END ;
  END ;
          
  &fmo = &fmo + &mo ;
  &fyr = &fyr + INT((&fmo - 1)/12) ;
  &fmo = MOD(&fmo,12) ;
  IF &fmo=0 THEN &fmo=12 ;
  ELSE DO ;
    &temp_n = INTCK('DAY',MDY(&fmo,1,&fyr),MDY(&fmo + 1,1,&fyr)) ;
    IF &fd > &temp_n THEN &fd = &temp_n ;
  END ;
 
END ;
ELSE &mo = 0 ;

%* calculate remaining difference (in sec) with adjusted from time ;
&temp_n = (%dtime(MDY(&tmo,&td,&tyr),HMS(&th,&tm,&ts)))
         -(%dtime(MDY(&fmo,&fd,&fyr),HMS(&fh,&fm,&fs))) ;

%* Pull left over seconds out of difference ;
&s = MOD(&temp_n,60) ;
&temp_n = &temp_n - &s ;

%* Pull left over minutes out of difference ;
&m = MOD(&temp_n,3600) / 60 ;
&temp_n = &temp_n - (MOD(&temp_n,3600)) ;

%* Pull left over hours out of difference ;
&h = MOD(&temp_n,86400) / 3600 ;
&temp_n = &temp_n - (MOD(&temp_n,86400)) ;

%* Pull left over days out of difference ;
&d = mod(&temp_n,604800) / 86400 ;
&temp_n = &temp_n - (MOD(&temp_n,604800)) ;

%* Convert whats left to weeks ;
&wk = &temp_n / 604800 ;

%* If weeks have not been specified, add it to days ;
IF INDEXW(&units_v,"wk")=0 THEN DO ;
  &d = &d + &wk*7 ;
  &wk = 0 ;
END ;

%* If days have not been specified, add it to hours ;
IF INDEXW(&units_v,"d")=0 THEN DO ;
  &h = &h + &d*24 ;
  &d = 0 ;
END ;

%* If hours have not been specified, add it to minutes ;
IF INDEXW(&units_v,"h")=0 THEN DO ;
  &m = &m + &h*60 ;
  &h = 0 ;
END ;

%* If minutes have not been specified, add it to seconds ;
IF INDEXW(&units_v,"m")=0 THEN DO ;
  &s = &s + &m*60 ;
  &m = 0 ;
END ;

%* If seconds have not been specified, put them in the first available spot ;
IF INDEXW(&units_v,"s")=0 THEN DO ;
  SELECT ;
    WHEN (INDEXW(&units_v,"m"))  &m  = &m  + &s/60 ;
    WHEN (INDEXW(&units_v,"h"))  &h  = &h  + &s/3600 ;
    WHEN (INDEXW(&units_v,"d"))  &d  = &d  + &s/86400 ;
    WHEN (INDEXW(&units_v,"wk")) &wk = &wk + &s/604800 ;
    WHEN (INDEXW(&units_v,"mo")) DO ;
      %* figure out # of days in current month to calculate fraction of a month ;
      IF &tmo=12 THEN &temp_n = 31 ;
      ELSE &temp_n = INTCK('DAY',MDY(&tmo,1,&tyr),MDY(&tmo + 1,1,&tyr)) ;
      &mo = &mo + &s/(86400 * &temp_n) ;
    END ;
    WHEN (INDEXW(&units_v,"yr")) DO ;
      %* figure out # of days in current year to calculate fraction of a year ;
      &temp_n = INTCK('DAY',MDY(1,1,&tyr),MDY(1,1,&tyr + 1)) ;
      &yr = &yr + &s/(86400 * &temp_n) ;
    END ;
    OTHERWISE ;
  END ;
  &s = 0 ;
END ;


%***********************************************************************
%* Build the text string from any specified units with non-zero values,
%* and round off as specified if it is the smallest unit:
%**********************************************************************;
IF (INDEXW(&units_v,"yr") & &yr) THEN DO ;
  IF &temp_c = 'yr' THEN 
    &reltime = LEFT(TRIM(&reltime)||' '||COMPRESS(PUT(ROUND(&yr,&round_v),best12.),' ')||"&year") ;
  ELSE 
    &reltime = LEFT(TRIM(&reltime)||' '||COMPRESS(PUT(&yr,best12.),' ')||"&year") ;
END ;

IF (INDEXW(&units_v,"mo") & &mo) THEN DO ;
  IF &temp_c = 'mo' THEN 
    &reltime = LEFT(TRIM(&reltime)||' '||COMPRESS(PUT(ROUND(&mo,&round_v),best12.),' ')||"&month") ;
  ELSE 
    &reltime = LEFT(TRIM(&reltime)||' '||COMPRESS(PUT(&mo,best12.),' ')||"&month") ;
END ;

IF (INDEXW(&units_v,"wk") & &wk) THEN DO ;
  IF &temp_c = 'wk' THEN 
    &reltime = LEFT(TRIM(&reltime)||' '||COMPRESS(PUT(ROUND(&wk,&round_v),best12.),' ')||"&week") ;
  ELSE 
    &reltime = LEFT(TRIM(&reltime)||' '||COMPRESS(PUT(&wk,best12.),' ')||"&week") ;
END ;

IF (INDEXW(&units_v,"d") & &d) THEN DO ;
  IF &temp_c = 'd' THEN 
    &reltime = LEFT(TRIM(&reltime)||' '||COMPRESS(PUT(ROUND(&d,&round_v),best12.),' ')||"&day") ;
  ELSE 
    &reltime = LEFT(TRIM(&reltime)||' '||COMPRESS(PUT(&d,best12.),' ')||"&day") ;
END ;

IF (INDEXW(&units_v,"h") & &h) THEN DO ;
  IF &temp_c = 'h' THEN 
    &reltime = LEFT(TRIM(&reltime)||' '||COMPRESS(PUT(ROUND(&h,&round_v),best12.),' ')||"&hour") ;
  ELSE                                                                                       
    &reltime = LEFT(TRIM(&reltime)||' '||COMPRESS(PUT(&h,best12.),' ')||"&hour") ;
END ;

IF (INDEXW(&units_v,"m") & &m) THEN DO ;
  IF &temp_c = 'm' THEN 
    &reltime = LEFT(TRIM(&reltime)||' '||COMPRESS(PUT(ROUND(&m,&round_v),best12.),' ')||"&minute") ;
  ELSE 
    &reltime = LEFT(TRIM(&reltime)||' '||COMPRESS(PUT(&m,best12.),' ')||"&minute") ;
END ;

IF (INDEXW(&units_v,"s") & &s) THEN DO ;
  IF &temp_c = 's' THEN 
    &reltime = LEFT(TRIM(&reltime)||' '||COMPRESS(PUT(ROUND(&s,&round_v),best12.),' ')||"&second") ;
  ELSE 
    &reltime = LEFT(TRIM(&reltime)||' '||COMPRESS(PUT(&s,best12.),' ')||"&second") ;
END ;

%* If RELTIMEN is 0, set RELTIME to 0 of the smallest specified unit ;
IF &reltime = ' ' & &reltimen = 0 THEN &reltime = '0' || &temp_c ;

%* Tack on the negative sign if appropriate ;
&reltime = LEFT(TRIM(&neg_sign)||&reltime) ;

RETAIN &max_len 0 ;
IF LENGTH(&reltime)>&max_len THEN DO ;
  &max_len = LENGTH(&reltime) ;
  CALL SYMPUT("&maxlen",trim(left(put(&max_len,8.)))) ;
END ;


%leave:

%mend RELTIME ;
