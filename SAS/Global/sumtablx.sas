%macro SUMTABLX(data=_LAST_,     /* Input data set                      */
              var=,            /* Analysis variable list (required)   */
              across=,         /* Across variable name                */
              by=,             /* Column style BY-variable list       */
              pageby=,         /* PAGEBY-variable list                */
              varstyle=Column, /* Style for listing the variable name */
              varuline=%str( ),/* Underline char. for varstyle=Row    */
              indent=2,        /* Indent spacing when varstyle=Row    */
              out=SUMOUT,      /* Output data set name                */
              append=,         /* Data set to add to current summary  */
              print=Y,         /* Print out a report?                 */
              total=N,         /* Include total for across variable?  */
              nozero=N,        /* Suppress N=0?                       */
              fillzero=Y,      /* Fill in levels of cat vars with 0's?*/
              cbzero=Y,        /* List levels with zeros for CB vars? */
              pctzero=N,       /* Include "(0%)" string with 0's?     */
              printn=Y,        /* Print N's for categorical variables?*/
              hideacn=N,       /* Hide across level counts?(=> blind) */
              hideacp=N,       /* Hide across level pcts?  (=> blind) */
              pgblock=N,       /* Fit variable blocks on a page?      */
              skipby=Y,        /* Skip a line between By-groups?      */
              missing=Y,       /* Include missing levels of cat vars ?*/
              missord=Last,    /* Put missing levs of cat vars last?  */
              misslbl=Missing, /* Def label for miss vals of cat vars */
              varlbl=Variable,               /* Variable column label */
              statlbl=Statistic*or*Category, /* Statistic column label*/
              totlbl=Total,                  /* Total column label    */
              vallbl=Value,    /* Label for "Value" when no acr. var. */
              catnlbl=n,       /* Label for Categorical N             */
              uline=%str(+),   /* Underline character for span titles */
              split=%str(*),   /* Split character for PROC REPORT     */
              dec=2,           /* Def dec places used in statistics   */
              pctdec=0,        /* # dec places used for percents      */
              spacing=,        /* Force column spacing in PROC REPORT */
              width=,          /* Width to use for value columns      */
              maxdig=,         /* Maximum # digits to use before dec. */
              outof=0,         /* # digits in denom for ##/## (##%)   */
              resolve=N,       /* Resolve macro expressions in labels?*/
              statfmt=_DEFAULT_, /* Format used for summary statistics*/
              stats=N {INT} MEAN {+1} STD {+1} MEDIAN {+1} MIN MAX) ;
                                                 /* PROC UNIVARIATE   */
                                                 /* key words list    */
%***********************************************************************
*
*                        Burroughs Wellcome Co.
*
*     PURPOSE: Provide summary statistics for numeric and categorical
*              data and print out the results in a report
* MACROS USED: %CMPRES %LEFT %TRIM %LOWCASE (from SASAUTOS MACLIB)
*              %GETOPTS %BWGETTF %TRANSLAT %INFIX (from UTILITY MACLIB)
*      AUTHOR: Carl P. Arneson
*        DATE: 12 Aug 1992
*
***********************************************************************;
%if "&sysscp"="SUN 4" %then %do ;
  %if &sysver<6.09 %then %do ;
    %put ERROR: You must use version 6.09 or higher with SUMTAB. ;
    %if &sysenv=BACK %then %str(;ENDSAS;) ;
  %end ;
%end ;

%*---------------------------------------------------------------------*
! Find out about previous SUMTAB calls:
*----------------------------------------------------------------------;
%global __sumtab ;
%if &__sumtab= %then %let __sumtab=1 ;
%else %let __sumtab=%eval(&__sumtab + 1) ;

%*---------------------------------------------------------------------*
! Make sure input data set is not empty:
*----------------------------------------------------------------------;
%local _nobs_ ;

proc contents data=&data noprint out=__core1(keep=nobs) ;
  run ;

data _null_ ;
  set __core1(obs=1) ;
  call symput('_nobs_',left(nobs)) ;
  run ;

%if ~(&_nobs_) %then %do ;
  %put WARNING: Input data set has 0 observations ;
  %goto leave ;
%end ;

%*---------------------------------------------------------------------*
! Parse up variable list into variables and variable type
! specifications:
*----------------------------------------------------------------------;
%local piece cnt1 cnt2 vopt0 i j k cb ncb ;

%let ncb=0 ;
%let cnt1 = %index(&var,%str(<)) ;
%do %while(&cnt1) ;
  %let cnt2 = %eval(%index(&var,%str(>)) + 1) ;
  %let ncb = %eval(&ncb + 1) ;
  %let cb = &cb %substr(&var,&cnt1,%index(%substr(&var,&cnt1),%str(>)));
  %if &cnt1=1 and %length(&var)=%eval(&cnt2-1) %then %let var = #&ncb ;
  %else %if &cnt1=1 %then %let var = #&ncb %substr(&var,&cnt2) ;
  %else %if %length(&var)>%eval(&cnt2-1) %then
    %let var = %substr(&var,1,%eval(&cnt1-1)) #&ncb %substr(&var,&cnt2) ;
  %else %let var = %substr(&var,1,%eval(&cnt1-1)) #&ncb ;
  %let cnt1 = %index(&var,%str(<)) ;
%end ;

%local go check ;
%let go = 1 ;
%let check = 0 ;
%let cnt1 = 1 ;
%let cnt2 = 0 ;

%do %while (&go) ;
  %let piece = %scan(&cb,&cnt1,%str(<>)) ;
  %if %length(&piece)>0 %then %do ;
    %let check = 0 ;
    %let cnt2 = %eval(&cnt2 + 1) ;
    %local cb&cnt2 ;
    %let cb&cnt2 = &piece ;
  %end ;
  %else %if &check=1 %then %let go = 0 ;
  %else %let check = 1 ;
  %let cnt1 = %eval(&cnt1 + 1) ;
%end ;

%local cbvars ;
%do i = 1 %to &ncb ;
  %let cbvars = &cbvars %upcase(&&cb&i) ;
  %let cnt1 = 1 ;
  %let piece = %scan(&&cb&i,&cnt1,%str( )) ;
  %do %while (&piece~=) ;
    %local cb&i._%eval(&cnt1-1) ;
    %let cb&i._%eval(&cnt1-1) = %upcase(&piece) ;
    %let cnt1 = %eval(&cnt1 + 1) ;
    %let piece = %scan(&&cb&i,&cnt1,%str( )) ;
  %end ;
  %local ncb&i ;
  %let ncb&i = %eval(&cnt1 - 2) ;
%end ;

%let cnt1=0 ;
%let cnt2=1 ;
%let piece = %qscan(&var,&cnt2,%str( )) ;
%do %while(&piece~=) ;
  %let cnt2 = %eval(&cnt2 + 1) ;
  %if %substr(&piece,1,1)={ %then
    %let vopt&cnt1 = %upcase(%substr(&piece,2,1)) ;
  %else %if %substr(&piece,1,1)=# %then %do ;
    %let cnt1 = %eval(&cnt1 + 1) ;
    %let i = %substr(&piece,2) ;
    %let var&cnt1 = &&cb&i._0 ;
    %let vopt&cnt1 = B ;
  %end ;
  %else %do ;
    %local var&cnt1 vopt&cnt1 ;
    %let cnt1 = %eval(&cnt1 + 1) ;
    %let var&cnt1 = %upcase(&piece) ;
    %let vopt&cnt1 = ;
  %end ;
  %let piece = %qscan(&var,&cnt2,%str( )) ;
%end ;
%local nvar ;
%let nvar = &cnt1 ;
%local varlst ;
%let varlst = ;
%do i = 1 %to &nvar ;
  %if &&vopt&i ~= B %then %let varlst = &varlst &&var&i ;
%end ;

%*---------------------------------------------------------------------*
! Parse up Summary Statistic list:
*----------------------------------------------------------------------;
%let cnt1 = 0 ;
%let cnt2 = 1 ;
%let piece = %qscan(&stats,&cnt2,%str( )) ;
%do %while(&piece~=) ;
  %if %substr(&piece,1,1)~={ %then %do ;
    %let cnt1 = %eval(&cnt1 + 1) ;
    %local stat&cnt1 stat2&cnt1 statadj&cnt1;
    %let statadj&cnt1 = 0 ;
    %let stat&cnt1 = %upcase(&piece) ;
    %if %length(&&stat&cnt1)>=7 %then
      %let stat2&cnt1 = %substr(&&stat&cnt1,1,6) ;
    %else %let stat2&cnt1 = &&stat&cnt1 ;
  %end ;
  %else %do ;
    %local statadj&cnt1 ;
    %let statadj&cnt1 = %upcase(%substr(&piece,2,%eval(%length(&piece)-2))) ;
  %end ;
  %let cnt2 = %eval(&cnt2 + 1) ;
  %let piece = %qscan(&stats,&cnt2,%str( )) ;
%end ;
%local nstat ;
%let nstat = &cnt1 ;

%if &nstat>9 %then
  %put WARNING: More than 9 summary statistics specified with STATS=. ;

%*---------------------------------------------------------------------*
! Parse up BY and PAGEBY variable lists:
*----------------------------------------------------------------------;
%local lstby nby ;
%let lstby= ;
%let cnt1=1 ;
%let piece=%scan(&by,&cnt1,%str( )) ;
%do %while(%quote(&piece)~=) ;
  %local by&cnt1 ;
  %let by&cnt1=%upcase(&piece) ;
  %let lstby=&piece ;
  %let cnt1=%eval(&cnt1+1) ;
  %let piece=%scan(&by,&cnt1,%str( )) ;
%end ;
%let nby=%eval(&cnt1-1) ;

%local lstpby npby ;
%let lstpby= ;
%let cnt1=1 ;
%let piece=%scan(&pageby,&cnt1,%str( )) ;
%do %while(%quote(&piece)~=) ;
  %local pby&cnt1 lpby&cnt1 ;
  %let pby&cnt1=%upcase(&piece) ;
  %let lstpby=&piece ;
  %let cnt1=%eval(&cnt1+1) ;
  %let piece=%scan(&pageby,&cnt1,%str( )) ;
%end ;
%let npby=%eval(&cnt1-1) ;

%*---------------------------------------------------------------------*
! Figure out how to set width and maxdig for value columns:
*----------------------------------------------------------------------;
%if &width= & &maxdig= %then %do ;
  %let maxdig = 4 ;
  %let width = %eval(11 + (&pctdec>0) + &pctdec) ;
  %if &outof>0 %then %let width=%eval(&width + &outof + 1) ;
%end ;
%else %if &width= %then %do ;
  %let width = %eval(&maxdig + 7 + (&pctdec>0) + &pctdec) ;
  %if &outof>0 %then %let width=%eval(&width + &outof + 1) ;
%end ;
%else %if &maxdig= %then %do ;
  %if &outof>0 %then %let maxdig = &outof ;
  %else %do ;
    %local maxdadj ;
    %let maxdig = 4 ;
    %let maxdadj = %eval(&width - (11 + (&pctdec>0) + &pctdec)) ;
    %if &maxdadj>1 %then %do ;
      %let maxdadj = %eval(&maxdadj/2) ;
      %let maxdig = %eval(&maxdig + &maxdadj) ;
    %end ;
  %end ;
%end ;

%*---------------------------------------------------------------------*
! Figure out what format to use for percentages:
*----------------------------------------------------------------------;
%if %quote(&hideacn)~= %then
  %let printn = %upcase(%substr(&printn,1,1)) ;

%if %quote(&hideacp)~= %then
  %let printn = %upcase(%substr(&printn,1,1)) ;

%if "&hideacn"="Y" & "&hideacp"="Y" %then %do ;
  %put WARNING: Cannot hide both Ns and Percents. ;
  %let hideacp=N ;
%end ;
%else %if ("&hideacn"="Y" | "&hideacp"="Y") & &outof>0 %then %do ;
  %put WARNING: Cannot use OUTOF>0 with HIDEACN=Y or HIDEACP=Y. ;
  %goto leave ;
%end ;

%local pctfmt pctstrl maxpsl ;
%let maxpsl = %eval(&width - (&maxdig + 1)) ;
%let pctstrl = %eval(6 + (&pctdec>0) + &pctdec) ;
%if &pctstrl>&maxpsl %then %do ;
  %let pctstrl = &maxpsl ;
  %put NOTE: Some percentage strings may be truncated in the report. ;
%end ;
%let pctfmt = %eval(3 + (&pctdec>0) + &pctdec) ;
%let pctfmt = %str(&pctfmt).&pctdec ;
%if &hideacp=Y %then %do ;
  %local hidepct ;
  %do i = 1 %to &pctdec ;
    %let hidepct=%trim(&hidepct)* ;
  %end ;
  %if &pctdec>0 %then %let hidepct=%str(.)&hidepct ;
  %let hidepct=(***&hidepct.%) ;
%end ;

%*---------------------------------------------------------------------*
! Format TOTLBL:
*----------------------------------------------------------------------;
%local totpad ntpc ;
%let totpad='            ';
%let cnt1 = 1 ;
%let piece=%left(%trim(%scan(&totlbl,&cnt1,%str(&split))));
%do %while(&piece~=) ;
  %local tpc&cnt1 ;
  %let cnt2=%length(&piece) ;
  %if &cnt2<%eval(&width - 1) %then %do ;
    %let cnt2=%eval(%eval((&width-&cnt2)/2)+1) ;
    %let piece=%qsubstr(&totpad,1,&cnt2)%str(&piece.%') ;
    %let tpc&cnt1=%unquote(&piece);
  %end ;
  %else %do ;
    %let piece=%str(%')&piece.%str(%') ;
    %let tpc&cnt1=%unquote(&piece) ;
  %end ;
  %let cnt1=%eval(&cnt1 + 1) ;
  %let piece=%left(%trim(%scan(&totlbl,&cnt1,%str(&split))));
%end ;
%let ntpc=%eval(&cnt1 - 1);
%let totlbl= ;
%do i = 1 %to &ntpc ;
  %let totlbl=&totlbl &&tpc&i ;
%end ;

%*---------------------------------------------------------------------*
! Start keeping track of maximum # of header levels and widths:
*----------------------------------------------------------------------;
%local maxvarl maxstatl ;
%let maxvarl=0 ;
%let maxstatl=0;
%if %quote(&split)~=%str(*) and %index(&statlbl,%str(*)) %then
  %let statlbl=%translat(&statlbl,%str(*),%str(&split)) ;
%local heads ;
%let heads = &ntpc ;
%let cnt1 = 1 ;
%let piece = %scan(&varlbl,&cnt1,%str(&split)) ;
%do %while(%quote(&piece)~=) ;
  %if %length(&piece)>&maxvarl %then %let maxvarl=%length(&piece) ;
  %let cnt1 = %eval(&cnt1 + 1) ;
  %let piece = %scan(&varlbl,&cnt1,%str(&split)) ;
%end ;
%let cnt1 = %eval(&cnt1 - 1) ;
%if &cnt1>&heads %then %let heads = &cnt1 ;
%let cnt1 = 1 ;
%let piece = %scan(&statlbl,&cnt1,%str(&split)) ;
%do %while(%quote(&piece)~=) ;
  %if %length(&piece)>&maxstatl %then %let maxstatl=%length(&piece) ;
  %let cnt1 = %eval(&cnt1 + 1) ;
  %let piece = %scan(&statlbl,&cnt1,%str(&split)) ;
%end ;
%let cnt1 = %eval(&cnt1 - 1) ;
%if &cnt1>&heads %then %let heads = &cnt1 ;

%*---------------------------------------------------------------------*
! Process MISSING= statement:
*----------------------------------------------------------------------;
%if %quote(&missing)= %then %let missing=N ;
%if ~%index(YN,%upcase(%substr(&missing,1,1))) %then
  %let missing=%infix(list=%cmpres(&missing),operator=%str(,));
%else %let missing=%upcase(%substr(&missing,1,1));
%if %quote(&missing)=N %then %let missing=(where=(__val__>.Z));
%else %if %quote(&missing)=Y %then %let missing=;
%else %let missing=(where=(__val__>.Z or __var__ in(&missing)));

%*---------------------------------------------------------------------*
! Initialize the remaining parameters:
*----------------------------------------------------------------------;
%let data = %upcase(&data) ;

%let across = %upcase(&across) ;

%let statfmt = %upcase(&statfmt) ;

%if %quote(&varstyle)~= %then
  %let varstyle = %upcase(%substr(&varstyle,1,1)) ;

%if %quote(&print)~= %then
  %let print = %upcase(%substr(&print,1,1)) ;

%if %quote(&total)~= %then
  %let total = %upcase(%substr(&total,1,1)) ;

%if %quote(&pgblock)~= %then
  %let pgblock = %upcase(%substr(&pgblock,1,1)) ;

%if %quote(&missord)~= %then
  %let missord = %upcase(%substr(&missord,1,1)) ;

%if %quote(&fillzero)~= %then
  %let fillzero = %upcase(%substr(&fillzero,1,1)) ;

%if %quote(&cbzero)~= %then
  %let cbzero = %upcase(%substr(&cbzero,1,1)) ;

%if %quote(&pctzero)~= %then
  %let pctzero = %upcase(%substr(&pctzero,1,1)) ;

%if %quote(&nozero)~= %then
  %let nozero = %upcase(%substr(&nozero,1,1)) ;

%if %quote(&printn)~= %then
  %let printn = %upcase(%substr(&printn,1,1)) ;

%if %quote(&skipby)~= %then
  %let skipby = %upcase(%substr(&skipby,1,1)) ;

%if %quote(&resolve)~= %then
  %let resolve = %upcase(%substr(&resolve,1,1)) ;

%*---------------------------------------------------------------------*
! Initialize the input data set:
*----------------------------------------------------------------------;
data __core1 ;
  set &data ;
  __sort__ = 1 ;
  keep &varlst &across &pageby &by &cbvars __sort__;
  run ;

%if %quote(&across.&pageby.&by)~= %then %do ;
  proc sort data=__core1 ;
    by &across &pageby &by ;
    run ;
%end ;

%*---------------------------------------------------------------------*
! Get formats, labels, etc., from the input data set:
*----------------------------------------------------------------------;
proc contents data=__core1(keep=&by &varlst &across &cbvars)
              noprint out=__core2 ;
  run ;
data _null_ ;
  length label $200 ;
  set __core2(keep=format label formatd formatl length type name) ;
  length format2 $20 ;
  retain maxlen &maxvarl heads &heads
         %do i = 1 %to &nby ; maxby&i 0 %end ; ;
  if formatl then format2 = trim(format)
                            !!compress(formatl)!!'.' ;
  else if format~=' ' then format2 = trim(format)!!'.' ;
  if formatd then format2 = trim(format2)!!left(formatd) ;
  select(trim(name)) ;
    when ("&across") do ;
      if type=1 then call symput('cbtac','N') ;
      else call symput('cbtac','C') ;
      call symput('cblac',left(length)) ;
      call symput('fac',trim(format2)) ;
      %if %quote(&resolve)=Y %then %do ;
        label=resolve(label) ;
      %end ;
      call symput('lac',trim(label)) ;
      i = 1 ;
      piece = scan(label,i,"&split") ;
      do while(piece~=' ') ;
        i = i + 1 ;
        piece = scan(label,i,"&split") ;
      end ;
      call symput('spanlev',left(i)) ;
    end ;
    %do i = 1 %to &nvar ;
      when ("&&var&i") do ;
        %if %quote(&resolve)=Y %then %do ;
          label = resolve(label) ;
        %end ;
        if length(label)>maxlen then maxlen=length(label) ;
        call symput("fvar&i",trim(format2)) ;
        call symput("lvar&i",trim(label)) ;
        call symput("tvar&i",trim(left(type))) ;
        call symput('maxvarl',trim(left(maxlen))) ;
      end ;
    %end ;
    %do i = 1 %to &nby ;
      when ("&&by&i") do ;
        call symput("fby&i",trim(format2)) ;
        i = 1 ;
        %if %quote(&resolve)=Y %then %do ;
          label = resolve(label) ;
        %end ;
        piece = scan(label,i,"&split") ;
        do while (piece~=' ') ;
          if length(piece)>maxby&i then maxby&i = length(piece) ;
          i + 1 ;
          piece = scan(label,i,"&split") ;
        end ;
        call symput("maxby&i",left(put(maxby&i,2.))) ;
        i = i - 1 ;
        if i>heads and %index(&&by&i,NOPRINT)~=1 then do ;
          heads = i ;
          call symput('heads',left(heads)) ;
        end ;
      end ;
    %end ;
    otherwise ;
  end ;
  run ;

%if %quote(&across)~= %then %do ;
  %if &fac= %then
    %put ERROR: No format specified for the across variable (&across) ;
  %if %nrbquote(&lac)= %then
    %let lac=%substr(&across,1,1)%substr(%lowcase(&across),2) ;
%end ;

  %*-------------------------------------------------------------------*
  ! Get levels of the across variable:
  *--------------------------------------------------------------------;
%if %quote(&across&by)~= %then %do ;
  data _null_ ;
    do until (eof) ;
      set __core1(keep=&across &by) end=eof ;
      retain i 0 ;
      %if %quote(&across)~= %then %do ;
        by &across ;
        retain heads &heads ;
        if first.&across then do ;
          i + 1 ;
          length piece $&width whole $80 ;
          call symput('faclev'!!left(i),trim(left(put(&across,&fac)))) ;
          j = 1 ;
          whole = ' ' ;
          piece = left(scan(put(&across,&fac),j,"&split")) ;
          do until(piece=' ') ;
            j = j + 1 ;
            if length(piece)<(&width - 1) then do ;
              pad = int((&width-length(piece))/2) ;
              piece = repeat(' ',pad) !! trim(piece) ;
            end ;
            whole = trim(whole) !! " '" !! trim(piece) !! "'" ;
            piece = left(scan(put(&across,&fac),j,"&split")) ;
          end ;
          if whole=' ' then whole="' '" ;
          call symput('achead'!!left(i),trim(whole)) ;
          j = j + &spanlev - 1 ;
          if j>heads then do ;
            heads = j ;
            call symput('heads',left(heads)) ;
          end ;
        end ;
      %end ;
      %do i = 1 %to &nby ;
        retain maxby&i &&maxby&i ;
        x&i = length(put(&&by&i,&&fby&i)) ;
        if x&i>maxby&i then maxby&i = x&i ;
      %end ;
    end ;
    if i then call symput('naclev',left(i)) ;
    %do i = 1 %to &nby ;
      call symput("maxby&i",left(put(maxby&i,2.))) ;
    %end ;
    run ;
%end ;

%*---------------------------------------------------------------------*
! Set the variable type for variables for which it was not
! specified, issue a warning for invalid variable types:
*----------------------------------------------------------------------;
%do i = 1 %to &nvar ;
  %if ~%index( C N B ,&&vopt&i) & %quote(&&vopt&i)~= %then %do ;
   %put WARNING: Invalid variable type (&&vopt&i) specified for &&var&i;
   %put WARNING: The default variable type is being used instead. ;
    %let vopt&i = ;
  %end ;
  %if &&vopt&i = %then %let vopt&i = %substr(NC,&&tvar&i,1) ;
  %else %if &&tvar&i=2 & &&vopt&i=N %then %do ;
   %put WARNING: Invalid variable type (&&vopt&i) specified for &&var&i;
   %put WARNING: The variable type "C" is being used instead. ;
    %let vopt&i=C ;
  %end ;
  %else %if &&tvar&i=1 & &&vopt&i=B %then %do ;
    %put ERROR: Invalid variable type (Numeric) for variable &&var&i ;
    %put ERROR: Errors may result. ;
  %end ;
%end ;

%*---------------------------------------------------------------------*
! Make lists of just the Numeric and Categorical variables:
*----------------------------------------------------------------------;
%local ncat nnum catlst numlst ;
%let ncat = 0 ;
%let nnum = 0 ;
%let catlst = ;
%let numlst = ;
%do i = 1 %to &nvar ;
  %if &&vopt&i=C %then %do ;
    %let ncat = %eval(&ncat + 1) ;
    %local cat&ncat fcat&ncat tcat&ncat ;
    %let cat&ncat = &&var&i ;
    %let fcat&ncat = &&fvar&i ;
    %let tcat&ncat = &&tvar&i ;
    %let catlst = &catlst &&var&i ;
  %end ;
  %else %if &&vopt&i=N %then %do ;
    %let nnum = %eval(&nnum + 1) ;
    %local num&nnum ;
    %let num&nnum = &&var&i ;
    %let numlst = &numlst &&var&i ;
  %end ;
%end ;

%*---------------------------------------------------------------------*
! Read the levels of each of the categorical variables:
*----------------------------------------------------------------------;
%let maxcatl=10 ;
%do i = 1 %to &ncat ;
  %local nc&i.lev ;
  %let nc&i.lev = 0 ;
  proc sort data=__core1(keep=&&cat&i) out=__core2 ;
    by &&cat&i ;
    run ;
  data _null_ ;
    retain maxl &maxcatl ;
    %if &&tcat&i=1 %then %let cnt1=.;
    %else %let cnt1=' ';
    if left(put(&cnt1,&&fcat&i)) in(' ','.') then do ;
      call symput("misslb&i","&misslbl") ;
      if length("&misslbl")>maxl then maxl=length("&misslbl") ;
    end ;
    else do ;
      call symput("misslb&i",trim(put(&cnt1,&&fcat&i))) ;
      x = length(trim(put(&cnt1,&&fcat&i))) ;
      if x>maxl then maxl = x ;
    end ;
    call symput('maxcatl',left(maxl)) ;
    do until (eof) ;
      set __core2(
                   where=(%if &&tcat&i=1 %then %do ;
                            &&cat&i>.Z
                          %end ;
                          %else %do ;
                            &&cat&i~=' '
                          %end ;
                         )
                  ) end=eof ;
      by &&cat&i ;
      if first.&&cat&i then do ;
        i + 1 ;
        call symput("c&i.lev"!!left(i),
                   trim(put(&&cat&i,&&fcat&i)));
        x = length(trim(put(&&cat&i,&&fcat&i))) ;
        if x > maxl then maxl = x ;
      end ;
    end ;
    call symput("nc&i.lev",left(i)) ;
    call symput('maxcatl',left(maxl)) ;
    run ;
%end ;
%if &maxcatl>&maxstatl %then %let maxstatl=&maxcatl ;

%*---------------------------------------------------------------------*
! Process check-box variables:
*----------------------------------------------------------------------;
%if &ncb>0 %then %do ;
  %local cblby maxcbl ;
  %let cnt1 = 1 ;
  %let cnt2 = %scan(__sort__ &across &pageby &by,&cnt1,%str( )) ;
  %do %while (&cnt2~=) ;
    %let cblby = &cnt2 ;
    %let cnt1 = %eval(&cnt1 + 1) ;
    %let cnt2 = %scan(__sort__ &across &pageby &by,&cnt1,%str( )) ;
  %end ;

  %local cbindat __sort__;
  %if %quote(&across)~= & &total=Y %then %do ;
    %let cbindat = __corex ;
    data __corex ;
      set __core1(keep=__sort__ &across &pageby &by &cbvars) ;
      output ;
      %if &cbtac=C %then %do ;
        &across = repeat('FE'x,&cblac - 1) ;
      %end ;
      %else %do ;
        &across = 99999999 ;
      %end ;
      output ;
      run ;

    proc sort data=__corex ;
      by &across &pageby &by ;
      run ;
  %end ;
  %else %do ;
    %let cbindat = __core1 ;
  %end ;
  %if %quote(&across&pageby&by)= %then %let __sort__=__sort__;

  %* Fill in all levels of across variable for all by groups ;
  %if %quote(&across)~= & %quote(&pageby&by)~= %then %do ;

    proc freq data=&cbindat ;
      tables &across
             %if %quote(&pageby)~= %then %str(* &pageby) ;
             %if %quote(&by)~=     %then %str(* &by) ;
             / noprint sparse out=__corex2(drop=count percent) ;
      run ;

    data &cbindat ;
      merge __corex2 &cbindat ;
      by &across &pageby &by ;
      run ;

  %end ;

  data __corex ;
    set &cbindat(keep=&__sort__ &across &pageby &by &cbvars) end=eof ;
    %if %quote(&across&pageby&by)~= %then %do ;
      by &across &pageby &by ;
    %end ;
    %else %do ;
      by __sort__ ;
    %end ;
    %do i = 1 %to &ncb ;
      array __cb_&i {0:&&ncb&i} &&cb&i ;
      array __n__&i {0:&&ncb&i} _temporary_ ;
      array __p__&i {1:&&ncb&i} $&pctstrl _temporary_ ;
      array __t__&i {1:&&ncb&i} $&width __t&i._1-__t&i._&&ncb&i ;
      %if %quote(&cblby)~= %then %do ;
        if first.&cblby then __n__&i.{0} = 0 ;
      %end ;
      if __cb_&i.{0}~=' ' then __n__&i.{0} + 1 ;
      drop j ;
      do j = 1 to &&ncb&i ;
        %if %quote(&cblby)~= %then %do ;
          if first.&cblby then do ;
            __n__&i.{j} = 0 ;
            __p__&i.{j} = ' ' ;
            __t__&i.{j} = ' ' ;
          end ;
        %end ;
        if __cb_&i.{0}~=' ' and __cb_&i.{j}~=' ' then __n__&i.{j} + 1 ;
          %if %quote(&cblby)~= %then %do ;
        if last.&cblby then do ;
          %end ;
          %else %do ;
        if eof then do ;
          %end ;
          if __n__&i.{0} then do ;
            if 0 < __n__&i.{j}/__n__&i.{0}*100 < (10**-&pctdec) then
              __p__&i.{j} = '(<' || compress(put(10**-&pctdec,&pctfmt)) || '%)' ;
            else if 100-(10**-&pctdec) < __n__&i.{j}/__n__&i.{0}*100 < 100 then
              __p__&i.{j} = '(>' || compress(put(100-(10**-&pctdec),&pctfmt)) || '%)' ;
            %if %quote(&pctzero)=N %then %do ;
              else if __n__&i.{j} = 0 then
                __p__&i.{j} = ' ' ;
            %end ;
            else
              __p__&i.{j} = '(' !!
                            compress(put((__n__&i.{j}/__n__&i.{0})*100,&pctfmt))
                            !! '%)' ;
          end ;
          else
          %if %quote(&pctzero)=Y %then %do;
            __p__&i.{j} = '(' !! compress(put(0,&pctfmt)) !! '%)' ;
          %end ;
          %else %do ;
            __p__&i.{j} = ' ' ;
          %end ;
          %if %quote(&across)~= & %index(%str(&hideacn&hideacp),Y) %then %do ;
            %if &cbtac=C %then %do ;
              if &across ~= repeat('FE'x,&cblac - 1) then
            %end ;
            %else %do ;
              if &across ~= 99999999 then
            %end ;
            %if &hideacn=Y %then %do ;
            __t__&i.{j} = repeat(' ',&maxdig - 2)!!'* '!!right(__p__&i.{j}) ;
            %end ;
            %else %do ;
            __t__&i.{j} = put(__n__&i.{j},&maxdig..)
                          !!repeat(' ',max(0,&pctstrl - length("&hidepct")))
                          !!"&hidepct" ;
            %end ;
            else
          %end ;
          __t__&i.{j} = put(__n__&i.{j},&maxdig..)!!' '!!right(__p__&i.{j}) ;
          %if &outof>0 %then %do ;
            __t__&i.{j} = put(__n__&i.{j},&maxdig..) || '/' ||
                          left(put(__n__&i.{0},&outof..)) ;
            __t__&i.{j} = put(__t__&i.{j},$%eval(&maxdig+&outof+1).)
                          || ' ' || right(__p__&i.{j}) ;
          %end ;
        end ;
      end ;
      length ____n&i $&maxdig ;
      %if %quote(&across)~= & %index(%str(&hideacn&hideacp),Y) %then %do ;
        %if &cbtac=C %then %do ;
          if &across ~= repeat('FE'x,&cblac - 1) then
        %end ;
        %else %do ;
          if &across ~= 99999999 then
        %end ;
        ____n&i = repeat(' ',&maxdig - 2)!!'*' ;
        else
      %end ;
      ____n&i = put(__n__&i.{0},&maxdig..) ;
    %end ;
    %if %quote(&cblby)~= %then %do ;
      if last.&cblby then output ;
    %end ;
    %else %do ;
      if eof then output ;
    %end ;
    if eof then do ;
      drop tmp maxlen ;
      length tmp $200 ;
      maxlen = 0 ;
      %do i = 1 %to &ncb ;
        do j = 1 to &&ncb&i ;
          call label(__cb_&i.{j},tmp) ;
          %if %quote(&resolve)=Y %then %do ;
            tmp = resolve(tmp) ;
          %end ;
          call symput("cb&i.l" !! left(j),trim(tmp)) ;
          if length(trim(tmp))>maxlen then maxlen = length(trim(tmp)) ;
        end ;
      %end ;
      call symput('maxcbl',left(maxlen)) ;
    end ;
    drop &cbvars ;
    run ;

  %if &maxcbl>&maxstatl %then %let maxstatl=&maxcbl ;

  proc transpose data=__corex out=__corex ;
    %if %quote(&across.&pageby.&by)~= %then %do ;
      by &across &pageby &by ;
    %end ;
    var %do i = 1 %to &ncb ;
          ____n&i %do j = 1 %to &&ncb&i ; __t&i._&j %end ;
        %end ; ;
    run ;

  data __corex ;
    set __corex(keep=&across &pageby &by _name_ col1
                rename=(col1=__cval__)) ;
    drop _name_ _cbvn_ ;
    length __stat__ $&maxstatl __name__ $8 _cbvn_ $3 ;
    retain __name__ _cbvn_ ;
    if index(_name_,'____N')=1 then do ;
      _statsrt = ._ ;
      __stat__ = "&catnlbl" ;
      _cbvn_ = substr(_name_,6) ;
      __name__ = symget('CB'!!trim(substr(_name_,6))!!'_0') ;
    end ;
    else do ;
      _statsrt = input(substr(_name_,index(substr(_name_,3),'_')+3),3.);
      __stat__ = symget('CB'!!trim(_cbvn_)!!'L'!!left(_statsrt)) ;
    end ;
    run ;

%end ;

%*---------------------------------------------------------------------*
! Convert levels of the class variables to their numeric
! counterparts (based on pre-formatted sort):
*----------------------------------------------------------------------;
data __core1 ;
  set __core1(rename=(
                     %do i = 1 %to &ncat ;
                       &&cat&i=__tmp&i
                     %end ;
                    )
            ) ;
  %do i = 1 %to &ncat ;
    select(trim(put(__tmp&i,&&fcat&i))) ;
      %do j = 1 %to &&nc&i.lev ;
        when("&&c&i.lev&j") &&cat&i = &j ;
      %end ;
      when('xxx Arbitrary Dummy Value xxx') ;
      otherwise &&cat&i = . ;
    end ;
    drop __tmp&i ;
  %end ;
  run ;

%*---------------------------------------------------------------------*
! Stack the variables on top of one another and separate the
! categorical variables from the numeric:
*----------------------------------------------------------------------;
data __core1(drop=__name__) __core2(drop=__name__)
     __corex2(keep=&pageby &by __var__ __name__) ;
  set
  %do i = 1 %to &nvar ;
    %if &&vopt&i=B %then %do ;
      __core1(keep=&across &pageby &by in=__n&i)
    %end ;
    %else %do ;
      __core1(
              keep=&across &pageby &by &&var&i
              rename=(&&var&i=__val__)
              in=__n&i
             )
    %end ;
  %end ;
  ;
  length __name__ $8 ;
  select ;
    %do i = 1 %to &nvar ;
      when(__n&i) do ;
        __var__ = &i ;
        __name__ = "&&var&i" ;
      end ;
    %end ;
    otherwise ;
  end ;
  if symget('vopt' !! left(__var__))='C' then output __core2 ;
  else if symget('vopt' !! left(__var__))='N' then output __core1 ;
  else output __corex2 ;
  run ;

%*---------------------------------------------------------------------*
! Complete check-box variable processing:
*----------------------------------------------------------------------;
%if &ncb>0 %then %do ;
  proc sort data=__corex ;
    by &pageby &by __name__ _statsrt __stat__ &across ;
    run ;

  proc sort data=__corex2 nodupkey ;
    by &pageby &by __name__ ;
    run ;

  data __corex ;
    merge __corex(in=n1) __corex2 ;
    by &pageby &by __name__ ;
    if n1 ;
    %if %quote(&across)~= %then %do ;
      drop _a_c_lev __l_stat ;
      retain _a_c_lev __l_stat ;
      length ___id___ $8 __l_stat $&maxstatl ;
      if __stat__~=__l_stat then _a_c_lev = 0 ;
      _a_c_lev + 1 ;
      ___id___ = '__C' !! trim(left(_a_c_lev)) !! '__' ;
      %if &total=Y %then %do ;
        %if &cbtac=C %then %do ;
          if &across=repeat('FE'x,&cblac - 1) then ___id___ = '__CT__' ;
        %end ;
        %else %do ;
          if &across=99999999 then ___id___ = '__CT__' ;
        %end ;
      %end ;
      __l_stat = __stat__ ;
    %end ;
    run ;

  proc datasets library=work nolist ;
    delete __corex2 ;
    run ;

  %if %quote(&across)~= %then %do ;
    proc transpose data=__corex out=__corex(drop=_name_ __name__) ;
      by &pageby &by __name__ __var__ _statsrt __stat__ ;
      var __cval__ ;
      id  ___id___ ;
      run ;

  %end ;

%end ;

%*---------------------------------------------------------------------*
! Process numeric variables:
*----------------------------------------------------------------------;
%if &nnum>0 %then %do ;
  proc univariate data=__core1&missing noprint ;
    by __var__ &across &pageby &by ;
    var __val__ ;
    output out=__core3
           %do i = 1 %to &nstat ;
             &&stat&i=_&i.&&stat2&i
           %end ;
           ;
    run ;

  proc transpose data=__core3 %if &nozero=Y %then %do ; (where=(_1n>0)) %end ;
                  out=__core3(drop=_label_ rename=(col1=__val__))
                  name=__stat__ ;
    by __var__ &across &pageby &by ;
    run ;

  %if &total=Y & %quote(&across)~= %then %do ;
    %if %quote(&by&pageby)= %then %do ;
      proc univariate data=__core1 noprint ;
        by __var__ ;
        var __val__ ;
        output out=__core1
               %do i = 1 %to &nstat ;
                 &&stat&i=_&i.&&stat2&i
               %end ;
               ;
        run ;

      proc transpose data=__core1 %if &nozero=Y %then %do ; (where=(_1n>0)) %end ;
                      out=__core1(drop=_label_ rename=(col1=__val__))
                      name=__stat__ ;
        by __var__ ;
        run ;
    %end ;
    %else %do ;
      proc sort data=__core1 ;
        by __var__ &pageby &by ;
        run ;

      proc univariate data=__core1 noprint ;
        by __var__ &pageby &by ;
        var __val__ ;
        output out=__core1
               %do i = 1 %to &nstat ;
                 &&stat&i=_&i.&&stat2&i
               %end ;
               ;
        run ;

      proc transpose data=__core1 %if &nozero=Y %then %do ; (where=(_1n>0)) %end ;
                      out=__core1(drop=_label_ rename=(col1=__val__))
                      name=__stat__ ;
        by __var__ &pageby &by ;
        run ;
    %end ;
  %end ;

  %*-------------------------------------------------------------------*
  ! Get correct numeric formats:
  *--------------------------------------------------------------------;
  %do i = 1 %to &nvar ;
    %if &&vopt&i=N %then %do ;
      %local dec&i ;
      %if &&fvar&i= %then %let dec&i = %eval(&dec + &maxdig + 1).&dec ;
      %else %if %scan(&&fvar&i,2,%str(.))= %then %let dec&i = &maxdig.. ;
      %else %do ;
        %let cnt1=%scan(&&fvar&i,2,%str(.));
        %let dec&i = %eval(&cnt1 + &maxdig + 1).&cnt1 ;
      %end ;
      %do j = 1 %to &nstat ;
        %local dec&i._&j ;
        %if &&statadj&j = INT %then %let dec&i._&j = &maxdig.. ;
        %else %if %index(0123456789,%substr(&&fvar&i,1,1))=0 %then
          %let dec&i._&j = &&fvar&i ;
        %else %if &&statadj&j = 0 %then %let dec&i._&j = &&dec&i ;
        %else %do ;
          %let dec = %eval(%scan(&&dec&i,2,%str(.)) &&statadj&j) ;
          %if &dec<0 %then %let dec=0 ;
          %let dec&i._&j = %eval(&maxdig + (&dec>0) + &dec).&dec ;
        %end ;
      %end ;
    %end ;
  %end ;

  %if %quote(&across)~= %then %do ;
    proc sort data=__core3 ;
      by &across __var__ &pageby &by __stat__ ;
      run ;
    %if &total=Y %then %do ;
      proc sort data=__core1 ;
        by __var__ &pageby &by __stat__ ;
        run ;
    %end ;

    data __core1 ;
      merge %do i = 1 %to &naclev ;
              __core3(
                      where=(
                             left(trim("&&faclev&i")) =
                                   trim(left(put(&across,&fac)))
                             %if "&&faclev&i"~=" " %then %do ;
                               and put(&across,&fac)~=' '
                             %end ;
                            )
                      rename=(__val__=__AC&i.__ __stat__=__tmp___)
                     )
            %end ;
            %if &total=Y %then %do ;
              __core1(rename=(__val__=__ACT__ __stat__=__tmp___))
            %end ;
      ;
      by __var__ &pageby &by __tmp___ ;
      length __stat__ $&maxstatl ;
      __stat__ = __tmp___ ;
      _statsrt = input(substr(__stat__,2,1),1.) ;
      %do i = 1 %to &naclev ;
        length __c&i.__ $&width ;
        if __ac&i.__<=.Z then __c&i.__=' ' ;
        else if substr(__stat__,3) in('N','NMISS','NOBS') then
          %if %length(&across)=0 or %index(%str(&hideacn&hideacp),Y)=0 %then %do ;
            __c&i.__=put(__ac&i.__,&maxdig..) ;
          %end ;
          %else %do ;
            __c&i.__=repeat(' ',&maxdig - 2) !! '*' ;
          %end ;
        else select ;
          %do j = 1 %to &nvar ;
            %do k = 1 %to &nstat ;
              %if &&vopt&j=N %then %do ;
                %if %index(0123456789,%substr(&&dec&j._&k,1,1)) %then %do ;
                  when(__var__=&j & _statsrt=&k) __c&i.__=put(__ac&i.__,&&dec&j._&k) ;
                %end ;
                %else %do ;
                  when(__var__=&j & _statsrt=&k) do ;
                    __c&i.__ = left(put(__ac&i.__,&&dec&j._&k)) ;
                    if length(trim(__c&i.__))+1>=&maxdig then
                      __c&i.__ = repeat(' ',floor((&width-length(trim(__c&i.__)))/2)-1)
                                 || __c&i.__ ;
                  end ;
                %end ;
              %end ;
            %end ;
          %end ;
          otherwise ;
        end ;
        drop __ac&i.__ ;
      %end ;
      %if &total=Y %then %do ;
        length __ct__ $&width ;
        if __act__<=.Z then __ct__=' ' ;
        else if substr(__stat__,3) in('N','NMISS','NOBS') then
          __ct__ = put(__act__,&maxdig..) ;
        else select ;
          %do j = 1 %to &nvar ;
            %do k = 1 %to &nstat ;
              %if &&vopt&j=N %then %do ;
                %if %index(0123456789,%substr(&&dec&j._&k,1,1)) %then %do ;
                  when(__var__=&j & _statsrt=&k) __ct__=put(__act__,&&dec&j._&k) ;
                %end ;
                %else %do ;
                  when(__var__=&j & _statsrt=&k) do ;
                    __ct__ = left(put(__act__,&&dec&j._&k)) ;
                    if length(trim(__ct__))+1>=&maxdig then
                      __ct__ = repeat(' ',floor((&width-length(trim(__ct__)))/2)-1)
                               || __ct__ ;
                  end ;
                %end ;
              %end ;
            %end ;
          %end ;
          otherwise ;
        end ;
        drop __act__ ;
      %end ;
      __stat__ = substr(__stat__,2) ;
      substr(__stat__,1,1)='_' ;
      drop &across __tmp___;
      run ;
  %end ;
  %else %do ;
    data __core1 ;
      set __core3(rename=(__stat__=__tmp___)) ;
      length __cval__ $&width __stat__ $&maxstatl ;
      drop __tmp___ ;
      __stat__ = __tmp___ ;
      _statsrt = input(substr(__stat__,2,1),1.) ;
      if __val__<=.Z then __cval__=' ' ;
      else if substr(__stat__,3) in('N','NMISS','NOBS') then
        __cval__ = put(__val__,&maxdig..) ;
      else select ;
        %do j = 1 %to &nvar ;
          %if &&vopt&j=N %then %do ;
            %do k = 1 %to &nstat ;
              when(__var__=&j & _statsrt=&k) __cval__=put(__val__,&&dec&j._&k) ;
            %end ;
          %end ;
        %end ;
        otherwise ;
      end ;
      __stat__ = substr(__stat__,2) ;
      substr(__stat__,1,1)='_' ;
      drop __val__ ;
      run ;
  %end ;
  proc datasets library=work nolist ;
    delete __core3 ;
    run ;
%end ;

%*---------------------------------------------------------------------*
! Process categorical variables:
*----------------------------------------------------------------------;
%if &ncat>0 %then  %do ;
  proc sort data=__core2&missing ;
    by __var__ &pageby &by ;
    run ;

  proc summary data=__core2 missing ;
    by __var__ &pageby &by ;
    class &across __val__ ;
    output out=__core2 ;
    run ;

  %local lstsrt1 lstsrt2 ;

  %if %quote(&across)~= %then %let lstsrt1=&across ;
  %else %if %quote(&lstby)~= %then %let lstsrt1=&lstby ;
  %else %if %quote(&lstpby)~= %then %let lstsrt1=&lstpby ;
  %else %let lstsrt1=__var__ ;

  %if %quote(&lstby)~= %then %let lstsrt2=&lstby ;
  %else %if %quote(&lstpby)~= %then %let lstsrt2=&lstpby ;
  %else %let lstsrt2=__var__ ;

  %if &total=Y & %quote(&across)~= %then %do ;
    data __core3 ;
      merge __core2(where=(_type_=1) rename=(__val__=_statsrt))
            __core2(
                    keep=__var__ &pageby &by _freq_ _type_
                    rename=(_freq_=_n)
                    where=(_type_=0)
                   ) ;
      by __var__ &pageby &by ;
      drop _type_ _freq_ _n &across i pct ;
      length __ct__ $&width __stat__ $&maxstatl pct $&pctstrl ;
      if 0 < _freq_/_n*100 < 10**-&pctdec then
        pct = '(<' || compress(put(10**-&pctdec,&pctfmt)) || '%)' ;
      else if 100-(10**-&pctdec)< _freq_/_n*100 < 100 then
        pct = '(>' || compress(put(100-(10**-&pctdec),&pctfmt)) || '%)' ;
      %if %quote(&pctzero)=N %then %do ;
        else if _freq_=0 then pct = ' ' ;
      %end ;
      else
        pct = '('!!compress(put((_freq_/_n)*100,&pctfmt))!!'%)' ;
      __ct__ = put(_freq_,&maxdig..)!!' '!!right(pct) ;
      %if &outof>0 %then %do ;
        __ct__ = put(_freq_,&maxdig..) || '/' || left(put(_n,&outof..)) ;
        __ct__ = put(__ct__,$%eval(&maxdig+&outof+1).) || ' ' || right(pct) ;
      %end ;
      if first.__var__ then i+1 ;
      select(i) ;
        %do i = 1 %to &ncat ;
          when(&i) do ;
            select(_statsrt) ;
              %do j = 1 %to &&nc&i.lev ;
                when(&j) __stat__ = "&&c&i.lev&j" ;
              %end ;
              when(%eval(&&nc&i.lev + 1)) ;
              otherwise do ;
                __stat__ = "&&misslb&i";
                %if %quote(&missord)=L %then %do ;
                  _statsrt=99999999 ;
                %end ;
              end ;
            end ;
          end ;
        %end ;
        otherwise ;
      end ;
      if first.&lstsrt2 then do ;
        output ;
        __ct__=put(_n,&maxdig..) ;
        _statsrt=._ ;
        __stat__="&catnlbl" ;
        output ;
      end ;
      else output ;
      run ;
  %end ;

  %if %quote(&across)~= %then %let cnt1 = 3 ;
  %else %let cnt1 = 1 ;
  %let cnt2 = %eval(&cnt1 - 1) ;

  data __core2 ;
    merge __core2(where=(_type_=&cnt1) rename=(__val__=_statsrt))
          __core2(
                  keep=__var__ &pageby &by &across _type_ _freq_
                  rename=(_freq_=_n)
                  where=(_type_=&cnt2)
                 ) ;
    by __var__ &pageby &by &across ;
    drop _type_ _freq_ _n i pct ;
    length __cval__ $&width __stat__ $&maxstatl pct $&pctstrl ;
    if 0 < _freq_/_n*100 < 10**-&pctdec then
      pct = '(<' || compress(put(10**-&pctdec,&pctfmt)) || '%)' ;
    else if 100-(10**-&pctdec)< _freq_/_n*100 < 100 then
      pct = '(>' || compress(put(100-(10**-&pctdec),&pctfmt)) || '%)' ;
    %if %quote(&pctzero)=N %then %do ;
      else if _freq_=0 then pct = ' ' ;
    %end ;
    else
      pct = '('!!compress(put((_freq_/_n)*100,&pctfmt))!!'%)' ;
    %if %length(&across)>0 and &hideacn=Y %then %do ;
      __cval__ = repeat(' ',&maxdig - 2)!!'* '!!right(pct) ;
    %end ;
    %else %if %length(&across)>0 and &hideacp=Y %then %do ;
      __cval__ = put(_freq_,&maxdig..)
                 !!repeat(' ',max(0,&pctstrl - length("&hidepct")))
                 !!"&hidepct" ;
    %end ;
    %else %do ;
      __cval__ = put(_freq_,&maxdig..)!!' '!!right(pct) ;
      %if &outof>0 %then %do ;
        __cval__ = put(_freq_,&maxdig..) || '/' || left(put(_n,&outof..)) ;
        __cval__ = put(__cval__,$%eval(&maxdig+&outof+1).) || ' ' || right(pct) ;
      %end ;
    %end ;
    if first.__var__ then i+1 ;
    select(i) ;
      %do i = 1 %to &ncat ;
        when(&i) do ;
          select(_statsrt) ;
            %do j = 1 %to &&nc&i.lev ;
              when(&j) __stat__ = "&&c&i.lev&j" ;
            %end ;
            when(%eval(&&nc&i.lev + 1)) ;
            otherwise do ;
              __stat__ = "&&misslb&i";
              %if %quote(&missord)=L %then %do ;
                _statsrt=99999999 ;
              %end ;
            end ;
          end ;
        end ;
      %end ;
      otherwise ;
    end ;
    if first.&lstsrt1 then do ;
      output ;
      %if %length(&across)=0 or %index(%str(&hideacn&hideacp),Y)=0 %then %do ;
        __cval__=put(_n,&maxdig..) ;
      %end ;
      %else %do ;
        __cval__=repeat(' ',&maxdig - 2)!!'*' ;
      %end ;
      _statsrt=._ ;
      __stat__="&catnlbl" ;
      output ;
    end ;
    else output ;
    run ;

  %if %quote(&across)~= %then %do ;
    proc sort data=__core2 ;
      by &across __var__ &pageby &by _statsrt ;
      run ;
    %if &total=Y %then %do ;
      proc sort data=__core3 ;
        by __var__ &pageby &by _statsrt ;
        run ;
    %end ;

    data __core2 ;
      merge %do i = 1 %to &naclev ;
              __core2(
                      where=(
                             left(trim("&&faclev&i")) =
                                   trim(left(put(&across,&fac)))
                             %if "&&faclev&i"~=" " %then %do ;
                               and put(&across,&fac)~=' '
                             %end ;
                            )
                      rename=(__cval__=__c&i.__)
                     )
            %end ;
            %if &total=Y %then %do ;
              __core3
            %end ;
            ;
      by __var__ &pageby &by _statsrt ;
      %if &fillzero=Y %then %do ;
        retain fill1-fill&naclev ;
        array cac {&naclev} %do i = 1 %to &naclev ; __c&i.__ %end ; ;
        array fill {&naclev} fill1-fill&naclev ;
        if first.&lstsrt2 then do i = 1 to &naclev ;
          if cac{i}=' ' then fill{i}=0 ;
          else fill{i}=1 ;
        end ;
        else do i = 1 to &naclev ;
          if cac{i}=' ' and fill{i} then do ;
            drop _t_m_p_ ;
            length _t_m_p_ $&pctstrl ;
            %if %length(&across)>0 and &hideacn=Y %then %do ;
              %if %quote(&pctzero)=Y %then %do ;
                _t_m_p_ = '(' !! compress(put(0,&pctfmt)) !! '%)' ;
              %end ;
              %else %do ;
                _t_m_p_ = ' ' ;
              %end ;
              cac{i}=repeat(' ',&maxdig - 2)!!'* ' !! right(_t_m_p_) ;
            %end ;
            %else %if %length(&across)>0 and &hideacp=Y %then %do ;
              %if %quote(&pctzero)=Y %then %do ;
                _t_m_p_ = "&hidepct" ;
              %end ;
              %else %do ;
                _t_m_p_ = ' ' ;
              %end ;
              cac{i}=put(0,&maxdig..) !! ' ' !! right(_t_m_p_)  ;
            %end ;
            %else %do ;
              %if %quote(&pctzero)=Y %then %do ;
                _t_m_p_ = '(' !! compress(put(0,&pctfmt)) !! '%)' ;
              %end ;
              %else %do ;
                _t_m_p_ = ' ' ;
              %end ;
              cac{i}=put(0,&maxdig..) !! ' ' !! right(_t_m_p_)  ;
            %end ;
          end ;
        end ;
        drop fill1-fill&naclev ;
      %end ;
      drop &across ;
      run ;
    %if &total=Y %then %do ;
      proc datasets library=work nolist ;
        delete __core3 ;
        run ;
    %end ;
  %end ;
%end ;

%*---------------------------------------------------------------------*
! Get formats ready for the report:
*----------------------------------------------------------------------;
%global __sumfmt ;
%if &__sumfmt= %then %let __sumfmt = 1 ;

proc format ;
  %if &__sumfmt=1 and %quote(&statfmt)=_DEFAULT_ %then %do ;
    %let __sumfmt = 0 ;
    value $unistat '_N'='n'
                   '_NMISS'='# Missing'
                   '_NOBS'='# Obs'
                   '_MEAN'='Mean'
                   "_STDMEA"='SE'
                   '_SUM'='Sum'
                   '_STD'='SD'
                   '_VAR'='Variance'
                   '_CV'='Coef.Var.'
                   '_USS'='Uncor.SS'
                   '_CSS'='Corr.SS'
                   '_SKEWNE'='Skewness'
                   '_KURTOS'='Kurtosis'
                   '_SUMWGT'='Sum Wghts'
                   '_MAX'='Max.'
                   '_MIN'='Min.'
                   '_RANGE'='Range'
                   '_Q3'='Upper Qrtl'
                   '_Q1'='Lower Qrtl'
                   '_MEDIAN'='Median'
                   '_QRANGE'='IQR'
                   '_P1'='1st Pctl'
                   '_P5'='5th Pctl'
                   '_P10'='10th Pctl'
                   '_P90'='90th Pctl'
                   '_P95'='95th Pctl'
                   '_P99'='99th Pctl'
                   '_MODE'='Mode'
                   '_T'='T (Mean=0)'
                   '_PROBT'='Prob>T'
                   '_MSIGN'='M(Sign St)'
                   '_PROBM'='Prob>M'
                   '_SIGNRA'='S(SgnRnk)'
                   '_PROBS'='Prob>S'
                   '_NORMAL'='Norm Stat'
                   '_PROBN'='P (Normal)'
                   ;
  %end ;
  %if %quote(&statfmt)=_DEFAULT_ %then %let statfmt = $UNISTAT. ;

  value int&__sumtab._ %do i = 1 %to &nvar ;
                           &i="&&lvar&i"
                         %end ;
               ;
  run ;

%*---------------------------------------------------------------------*
! Put the categorical and numeric data together:
*----------------------------------------------------------------------;
data __core1 ;
  set  %if &nnum %then %do ; __core1(in=num rename=(__stat__=__tmp___)) %end ;
       %if &ncat %then %do ; __core2(in=cat rename=(__stat__=__tmp___)) %end ;
       %if &ncb  %then %do ; __corex(in=cb
                                     rename=(__stat__=__tmp___)
                                     %if "&cbzero"="N" %then %do ;
                                       %if %quote(&across)= %then %do ;
                                         where=(input(scan(__cval__,1,' '),8.)>0)
                                       %end ;
                                       %else %do ;
                                         where=(
                                                input(scan(__c1__,1,' '),8.)>0
                                                %do i = 2 %to &naclev ;
                                                  | input(scan(__c&i.__,1,' '),8.)>0
                                                %end ;
                                               )
                                       %end ;
                                     %end ;
                                     ) %end ; ;
  drop __tmp___ ;
  length __stat__ $&maxstatl ;
  __stat__ = __tmp___ ;
  %if &ncat>0 & &printn=N %then %do ;
    if cat and _statsrt=._ then delete ;
  %end ;
  %if  &ncb>0 & &printn=N %then %do ;
    if cb  and _statsrt=._ then delete ;
  %end ;
  %if &nnum>0 %then %do ;
    if num then __stat__ = put(__stat__,&statfmt) ;
  %end ;
  %* See if there is a null label for any pageby variable ;
  %if &npby>0 %then %do ;
    if _n_=1 then do ;
      drop __tmplab ;
      length __tmplab $200 ;
      %do i = 1 %to &npby ;
        call label(&&pby&i,__tmplab) ;
        %if %quote(&resolve)=Y %then %do ;
          __tmplab = resolve(__tmplab) ;
        %end ;
        if trim(left(__tmplab))="&split" then call symput("lpby&i",'0') ;
        else                                  call symput("lpby&i",'1') ;
      %end ;
    end ;
  %end ;
  %if "&across"~="" %then %do ;
    %do i = 1 %to &naclev ;
      attrib __c&i.__ label="&&faclev&i" ;
    %end ;
    %if "&total"="Y" %then %do ;
      attrib __ct__ label="&totlbl" ;
    %end ;
  %end ;
  length dummy $1 variable $132 ;
  dummy = ' ' ;
  variable = put(__var__,int&__sumtab._.) ;
  run = &__sumtab ;
  run ;
%if &ncat>0 %then %do ;
  proc datasets library=work nolist ;
    delete __core2 ;
    run ;
%end ;
%if  &ncb>0 %then %do ;
  proc datasets library=work nolist ;
    delete __corex ;
    run ;
%end ;

%if %quote(&append)~= %then %do ;
  %local oldstatl dsetord ;
  data _null_ ;
    set &append end=eof ;
    retain maxstatl &maxstatl maxvarl &maxvarl ;
    if length(trim(__stat__))>maxstatl then maxstatl = length(trim(__stat__)) ;
    if length(trim(variable))>maxvarl  then maxvarl  = length(trim(variable)) ;
    if eof then do ;
      call symput('oldstatl',trim(left(put(maxstatl,8.)))) ;
      call symput('maxvarl' ,trim(left(put(maxvarl, 8.)))) ;
    end ;
    run ;

  %if &oldstatl>&maxstatl %then %do ;
    %let maxstatl=&oldstatl ;
    %let dsetord=&append __core1 ;
  %end ;
  %else %let dsetord=__core1 &append ;

  data &out ;
    set &dsetord ;
    array tmp {1} _pageno ;
    tmp{1} = . ;
    drop _pageno ;
    run ;

  proc sort data=&out ;
    by &pageby run __var__ &by _statsrt ;
    run ;
%end ;
%else %do ;
proc sort data=__core1 out=&out ;
  by &pageby __var__ &by _statsrt ;
  run ;
%end ;

%bwgettf(t=currt,f=currf,ps=currps,ls=currls,dump=N) ;

%if &print=Y %then %do ;
  %*-------------------------------------------------------------------*
  ! Calculate the total space (width) being used:
  *--------------------------------------------------------------------;
  %local ncol coltotw reptotw avsp stcol ;
  %let ncol=1 ;
  %let coltotw=&maxstatl ;
  %if &varstyle~=R & %qupcase(&varlbl)~=_NONE_ %then %do ;
    %let ncol = %eval(&ncol + 1) ;
    %let coltotw = %eval(&coltotw + &maxvarl) ;
  %end ;
  %do i = 1 %to &nby ;
    %if %index(&&by&i,NOPRINT)~=1 %then %do ;
      %let ncol = %eval(&ncol + 1) ;
      %let coltotw = %eval(&coltotw + &&maxby&i) ;
    %end ;
  %end ;
  %if %quote(&across)~= %then %do ;
    %do i = 1 %to &naclev ;
      %let ncol = %eval(&ncol + 1) ;
      %let coltotw = %eval(&coltotw + &width) ;
    %end ;
    %if &total=Y %then %do ;
      %let ncol = %eval(&ncol + 1) ;
      %let coltotw = %eval(&coltotw + &width) ;
    %end ;
  %end ;
  %else %do ;
    %let ncol = %eval(&ncol + 1) ;
    %let coltotw = %eval(&coltotw + &width) ;
  %end ;

  %*-------------------------------------------------------------------*
  ! Calculate an appropriate spacing to use, based on the total
  ! width being used:
  *--------------------------------------------------------------------;
  %let avsp = %eval(%eval(&currls - &coltotw)/&ncol) ;
  %if %quote(&spacing)= %then %do ;
    %if &avsp<=1 %then %let spacing=1 ;
    %else %if &avsp>4 %then %let spacing=4 ;
    %else %let spacing=&avsp ;
  %end ;

  %*-------------------------------------------------------------------*
  ! Make sure report is not too wide, and calculate the first
  ! column of the report:
  *--------------------------------------------------------------------;
  %local dummy ;
  %let reptotw = %eval(&coltotw + (&spacing*(&ncol-1))) ;
  %if &varstyle=R & &varlbl~=_NONE_ %then %do ;
    %let dummy=dummy ;
    %let reptotw=%eval(&reptotw + &indent) ;
  %end ;
  %if &reptotw>&currls %then %do ;
    %put WARNING: Report width exceeds the current LINESIZE;
    %put SUGGESTION: Try using VARSTYLE=ROW or reducing WIDTH or MAXDIG;
    %let stcol = 1 ;
  %end ;
  %else %let stcol=%eval(%eval((&currls - &reptotw)/2) + 1) ;
%end ;

%if &print=Y & %quote(&pageby)~= %then %do ;
  %*-------------------------------------------------------------------*
  ! Find out what titles can be used for by-line:
  *--------------------------------------------------------------------;
  %local usetitle ;
  %if &currt0<8 %then %let usetitle=%eval(&currt0 + 2) ;
  %else %let usetitle=10 ;

  /* a fix for the nobyline option screwing up pagesize */
  %let currps = %eval(&currps - 2);

  %*-------------------------------------------------------------------*
  ! Set the by-line option off and store original setting:
  *--------------------------------------------------------------------;
  %getopts(opt=byline,mv=byline,dump=N) ;
  %if &byline %then %let byline=BYLINE;
  %else %let byline=NOBYLINE;
  options nobyline ;
%end ;

%*---------------------------------------------------------------------*
! Figure out what blocks can fit on a page:
*----------------------------------------------------------------------;
%local _pgblk bkvar ;
%let _pgblk= ;
%if %quote(&lstby)= %then %let lstby = __var__ ;
%if &nby>0 & &skipby=Y %then %let bkvar=&lstby ;
%else %let bkvar=__var__ ;

%if &pgblock=Y %then %do ;
  %let _pgblk=_pageno ;
  %*-------------------------------------------------------------------*
  ! Count the number of titles and footnotes used and the pagesize:
  *--------------------------------------------------------------------;
  %local titles foots ;
  %let titles = %eval(&currt0 + 2) ;
  %if &currf0 %then %let foots = %eval(&currf0 + 1) ;
  %if &print=Y and &npby>0 %then %let titles = &usetitle ;

  %*-------------------------------------------------------------------*
  ! Find out the current skip:
  *--------------------------------------------------------------------;
  %getopts(opt=skip,mv=currsk,dump=N) ;

  %local totlines ;
  %let totlines = %eval(&currsk + &titles + &foots + &heads + 2) ;
  %let totlines = %eval(&currps - &totlines) ;
  %let cnt1 = %eval(&totlines + 1) ;

  data __core1 ;
    set &out ;
    by &pageby run __var__ &by ;
    retain _blksize ;
    if first.&lstby then _blksize=0 ;
    _blksize = _blksize + 1 ;
    %if &varstyle=R %then %do ;
      if first.__var__ then _blksize = _blksize + 2 ;
    %end ;
    if last.&lstby ;
    keep &pageby run __var__  &by _blksize ;
    run ;

  data &out ;
    merge &out __core1 ;
    by &pageby run __var__ &by ;
    retain _ll &cnt1 _pageno 1 ;
    _ll = _ll - 1 ;
    %if &npby>0 %then %do ;
      if first.&lstpby then do ;
        _ll = &totlines ;
        _pageno = 1 ;
      end ;
    %end ;
    if first.&lstby then do ;
      if first.&bkvar then _ll = _ll - 1 ;
      %if &varstyle=R & %qupcase(&varlbl)~=_NONE_ %then %do ;
        %if %qupcase(&varuline)=_NONE_ %then %do ;
          if first.__var__ then _ll = _ll - 1 ;
        %end ;
        %else %do ;
          if first.__var__ then _ll = _ll - 2 ;
        %end ;
      %end ;
      if _ll<_blksize then do ;
        _pageno = _pageno + 1 ;
        _ll = &totlines - 1 ;
        %if &varstyle=R %then %do ;
          if first.__var__ then _ll = _ll - 2 ;
        %end ;
      end ;
    end ;
    drop _ll _blksize ;
    run ;
%end ;

proc datasets library=work nolist ;
  delete __core1 ;
  run ;

%*---------------------------------------------------------------------*
! Print out a report:
*----------------------------------------------------------------------;
%if &print=Y %then %do ;

  proc report data=&out nowd headline headskip missing split="&split"
              spacing=&spacing ;
    column &_pgblk &dummy run __var__ variable &by __stat__
           %if %quote(&across)~= %then %do ;
             ("&lac" "&uline.&uline"
             %do i = 1 %to &naclev ;
               __c&i.__
             %end ;
             )
             %if &total=Y %then %do ;
               __ct__
             %end ;
           %end ;
           %else %do ;
             __cval__
           %end ;
           ;
    %if %quote(&pageby)~= %then %do ;
      by &pageby ;
    %end ;
    break after &bkvar / skip ;
    %if &pgblock=Y %then %do ;
      break after _pageno / page ;
      define _pageno / order noprint spacing=0 ;
    %end ;
    %if &varstyle~=R %then %do ;
      define run     / order order=internal noprint spacing=0 ;
      define __var__ / order order=internal noprint spacing=0 ;
      %if %upcase(&varlbl)~=_NONE_ %then %do ;
        define variable / order f=$&maxvarl.. left "&varlbl" ;
      %end ;
      %else %do ;
        define variable/ order order=internal noprint spacing=0 ;
      %end ;
    %end ;
    %else %do ;
      %if %upcase(&varlbl)~=_NONE_ %then %do ;
        define dummy / order width=&indent spacing=0 "&split" ;
        define run     / order order=internal noprint spacing=0 ;
        define __var__ / order order=internal noprint spacing=0 ;
        define variable/ order order=internal noprint spacing=0 ;
        compute before variable ;
          line @&stcol variable $&maxvarl.. ;
          %if %qupcase(&varuline)~=_NONE_ %then %do ;
            length _uline_ $&reptotw ;
            _uline_ = repeat("&varuline",length(trim(variable))-1);
            line @&stcol _uline_ $&reptotw.. ;
          %end ;
        endcomp ;
      %end ;
      %else %do ;
        define run     / order order=internal noprint spacing=0 ;
        define __var__ / order order=internal noprint spacing=0 ;
        define variable/ order order=internal noprint spacing=0 ;
      %end ;
    %end ;
    %do i = 1 %to &nby ;
      %if %index(&&by&i,NOPRINT)=1 %then %do ;
        define &&by&i / order order=internal noprint spacing=0 "&split" ;
      %end ;
      %else %do ;
        %if &i=1 & &varstyle=R %then %do ;
          define &&by&i / order order=internal width=&&maxby&i spacing=0 ;
        %end ;
        %else %do ;
          define &&by&i / order order=internal width=&&maxby&i ;
        %end ;
      %end ;
    %end ;
    %if &nby=0 & &varstyle=R %then %do ;
      define __stat__ / display width=&maxstatl "&statlbl" spacing=0 ;
    %end ;
    %else %do ;
      define __stat__ / display width=&maxstatl "&statlbl" ;
    %end ;
    %if %quote(&across)~= %then %do ;
      %do i = 1 %to &naclev ;
        define __c&i.__ / display f=$&width.. &&achead&i ;
      %end ;
      %if &total=Y %then %do ;
        define __ct__ / display f=$&width.. &totlbl ;
      %end ;
    %end ;
    %else %do ;
      %let cnt2 = %length(%bquote(&vallbl)) ;
      %if &cnt2<&width %then %let cnt2 = &width ;
      define __cval__ / display f=$&width.. width=&cnt2 "&vallbl" ;
    %end ;
    %if %quote(&pageby)~= %then %do ;
      title&usetitle %do i = 1 %to &npby ;
                       %if &&lpby&i=1 %then %do ;
                         "  #BYVAR&i = #BYVAL&i "
                       %end ;
                       %else %do ;
                         " #BYVAL&i "
                       %end ;
                     %end ;
                     ;
    %end ;
    run ;

  %*-------------------------------------------------------------------*
  ! Restore original options and titles:
  *--------------------------------------------------------------------;
  %if %quote(&pageby)~= %then %do ;
    options &byline ;
    title&usetitle "&&currt&usetitle" ;
  %end ;
%end ;

%leave:
%mend SUMTABLX ;
