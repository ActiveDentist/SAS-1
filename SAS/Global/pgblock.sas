%*******************************************************************************
%*
%*                            Glaxo Wellcome Inc.
%*
%* PURPOSE: Paginate nicely for PROC REPORT
%*  AUTHOR: Carl Arneson
%*    DATE: 1 Jun 1998
%*
%******************************************************************************;
%macro PGBLOCK(

               data=_DEFAULT_, /* Input data set name             */
               out=_DEFAULT_,  /* Output data set name            */

               pageby=,        /* list of paging variables        */
               blockby=,       /* variables to define blocks      */
               sortby=,        /* sorting variables within blocks */
               flowvars=,      /* any flow variables              */
               split=%str(*),  /* split character in flowvars     */
               maxflen=2000,   /* maximum length for flowvars     */

               /* Use either lines= OR titles=, fnotes=, headers= */

               lines=,         /* # reporting lines per page      */

               titles=,        /* # title lines used              */
               fnotes=,        /* # footnote lines used           */
               headers=,       /* # lines used in header titles   */
               headline=Yes,   /* HEADLINE option used?           */
               headskip=Yes,   /* HEADSKIP option used?           */
               adjust=0,       /* Any additional lines (eg BYLINE)*/

               pagevar=PAGE    /* Variable name for page variable */

              ) ;

%*******************************************************************************
%* Check for required parameters (BLOCKBY= and LINES= OR HEADERS=):
%******************************************************************************;
%if %quote(&blockby)= %then %do ;
  %put ERROR: (PGBLOCK) Must specify BLOCKBY=. ;
  %goto leave ;
%end ;
%else %if %quote(&lines.&headers)= %then %do ;
  %put ERROR: (PGBLOCK) Must specify either LINES= or HEADERS=. ;
  %goto leave ;
%end ;
%else %if %quote(&lines)~= & %quote(&headers)~= %then %do ;
  %put WARNING: (PGBLOCK) Cannot specify both LINES= and HEADERS=. ;
  %put NOTE:    (PGBLOCK) LINES=&lines used, HEADERS=&headers ignored. ;
%end ;

%*******************************************************************************
%* Establish defaults for input and output data sets:
%******************************************************************************;
%if %quote(&data)=_DEFAULT_ | %quote(&data)= %then
  %let data = &syslast ;

%if %quote(&out)=_DEFAULT_ | %quote(&out)= %then
  %let out = &data ;

%*******************************************************************************
%* Calculate available report lines if not specified:
%******************************************************************************;
%if %quote(&lines)= %then %do ;

  %*****************************************************************************
  %* If TITLES= or FNOTES= is not specified, use %BWGETTF to count
  %* the number of title and/or footnote lines used:
  %****************************************************************************;
  %if %quote(&titles)= | %quote(&fnotes)= %then %do ;
    %bwgettf(dump=NO) ;
    %if %quote(&titles)= %then %let titles = &_bwt0 ;
    %if %quote(&fnotes)= %then %let fnotes = &_bwf0 ;
  %end ;
  %let titles = %eval(&titles + 1) ;
  %if &fnotes > 0 %then %let fnotes = %eval(&fnotes + 1) ;

  %*****************************************************************************
  %* Add lines for HEADLINE and HEADSKIP settings:
  %****************************************************************************;
  %if %upcase(%substr(&headline,1,1))=Y %then
    %let adjust = %eval(&adjust + 1) ;
  %if %upcase(%substr(&headskip,1,1))=Y %then
    %let adjust = %eval(&adjust + 1) ;

  %*****************************************************************************
  %* Figure out current PAGESIZE and SKIP settings:
  %****************************************************************************;
  %local __ps__ __skip__ __byline ;
  %let __ps__   = %sysfunc(getoption(PAGESIZE)) ;
  %let __skip__ = %sysfunc(getoption(SKIP)) ;

  %*****************************************************************************
  %* Figure out number of lines used in a report page:
  %****************************************************************************;
  %let lines = %eval(&__ps__ - &__skip__
                     - &titles - &fnotes - &headers - &adjust) ;

%end ;

%*******************************************************************************
%* Extract last pageby variable:
%******************************************************************************;
%local i j piece lastpgby ;

%let i = 1 ;
%let piece = %qscan(&pageby,&i,%str( )) ;

%do %while(&piece~=) ;
  %let lastpgby = &piece ;
  %let i = %eval(&i + 1) ;
  %let piece = %qscan(&pageby,&i,%str( )) ;
%end ;

%*******************************************************************************
%* Parse up BLOCKBY= list (pulling out {+#} as appropriate):
%******************************************************************************;
%local bby0 ;

%let i = 0 ;
%let j = 1 ;
%let piece = %qscan(&blockby,&j,%str( )) ;

%do %while(&piece~=) ;

  %* stack array with variable name pieces ;
  %if %substr(&piece,1,1)~={ %then %do ;
    %let i = %eval(&i + 1) ;
    %local bby&i badj&i badjP&i ;
    %let badj&i = +0 ;
    %let badjP&i = +0 ;
    %let bby&i = %upcase(&piece) ;
  %end ;

  %* stack array with adjust line pieces ;
  %else %do ;
    %let badj&i = %substr(&piece,2,%eval(%length(&piece)-2)) ;
    %if %qsubstr(&&badj&i,1,1)=%str(@) %then %do ;
      %let badj&i = %substr(&&badj&i,2) ;
      %let badjP&i = &&badj&i ;
    %end ;
    %else %do ;
      %let badjP&i = +0 ;
    %end ;
  %end ;

  %* grab next piece ;
  %let j = %eval(&j + 1) ;
  %let piece = %qscan(&blockby,&j,%str( )) ;

%end ;

%let bby0 = &i ;

%*******************************************************************************
%* Parse up SORTBY= list (pulling out {+#} as appropriate):
%******************************************************************************;
%local sby0 ;

%let i = 0 ;
%let j = 1 ;
%let piece = %qscan(&sortby,&j,%str( )) ;

%do %while(&piece~=) ;

  %* stack array with variable name pieces ;
  %if %substr(&piece,1,1)~={ %then %do ;
    %let i = %eval(&i + 1) ;
    %local sby&i sadj&i sadjP&i ;
    %let sadj&i = +0 ;
    %let sadjP&i = +0 ;
    %let sby&i = %upcase(&piece) ;
  %end ;

  %* stack array with adjust line pieces ;
  %else %do ;
    %let sadj&i = %substr(&piece,2,%eval(%length(&piece)-2)) ;
    %if %qsubstr(&&sadj&i,1,1)=%str(@) %then %do ;
      %let sadj&i = %substr(&&sadj&i,2) ;
      %let sadjP&i = &&sadj&i ;
    %end ;
    %else %do ;
      %let sadjP&i = +0 ;
    %end ;
  %end ;

  %* grab next piece ;
  %let j = %eval(&j + 1) ;
  %let piece = %qscan(&sortby,&j,%str( )) ;

%end ;

%let sby0 = &i ;

%*******************************************************************************
%* Parse up FLOWVARS= list (pulling out {fmt:len} as appropriate):
%******************************************************************************;
%local flv0 ;

%let i = 0 ;
%let j = 1 ;
%let piece = %qscan(&flowvars,&j,%str( )) ;

%do %while(&piece~=) ;

  %* stack array with variable name pieces ;
  %if %substr(&piece,1,1)~={ %then %do ;
    %let i = %eval(&i + 1) ;
    %local flv&i flf&i fll&i ;
    %let flv&i = %upcase(&piece) ;
    %let flf&i = $&maxflen.. ;
    %let fll&i = 30 ;
  %end ;

  %* stack arrays with format and length info pieces ;
  %else %do ;
    %let flf&i = %substr(&piece,2,%eval(%length(&piece)-2)) ;
    %let fll&i = %scan(&&flf&i,2,%str(:)) ;
    %let flf&i = %scan(&&flf&i,1,%str(:)) ;
  %end ;

  %* grab next piece ;
  %let j = %eval(&j + 1) ;
  %let piece = %qscan(&flowvars,&j,%str( )) ;

%end ;

%let flv0 = &i ;

%*******************************************************************************
%* Put data in correct sort order:
%******************************************************************************;
proc sort data=&data out=&out ;
  by &pageby
     %do i = 1 %to &bby0 ;
       &&bby&i
     %end ;
     %do i = 1 %to &sby0 ;
       &&sby&i
     %end ;
     ;

%*******************************************************************************
%* Count number of lines per block:
%******************************************************************************;
data __temp__ ;
  set &out (
            keep=&pageby
                 %do i = 1 %to &bby0 ;
                   &&bby&i
                 %end ;
                 %do i = 1 %to &sby0 ;
                   &&sby&i
                 %end ;
                 %do i = 1 %to &flv0 ;
                   &&flv&i
                 %end ;
           ) ;
  by &pageby
     %do i = 1 %to &bby0 ;
       &&bby&i
     %end ;
     %do i = 1 %to &sby0 ;
       &&sby&i
     %end ;
     ;

  drop __flad__
       %do i = 1 %to &sby0 ;
         &&sby&i
       %end ;
       %do i = 1 %to &flv0 ;
         &&flv&i
       %end ;
       ;

  %* initialize a block size counter ;
  retain _b_l_k_ ;

  %* reset block size counter for first observation in each block ;
  if first.&&bby&bby0 then _b_l_k_ = 0 ;

  %* increment block size counter for each line of data ;
  _b_l_k_ + 1 ;

  %* add in any specified adjustments for each blocking variable ;
  %do i = 1 %to &bby0 ;
    if first.&&bby&i then _b_l_k_ = _b_l_k_ &&badj&i ;
  %end ;

  %* add in any specified adjustments for each sorting variable ;
  %do i = 1 %to &sby0 ;
    if first.&&sby&i then _b_l_k_ = _b_l_k_ &&sadj&i ;
  %end ;

  %* add additional lines for any flow variables ;
  __flad__ = 0 ;
  %if &flv0>0 %then %do ;

    drop __fidx__ __fltx__ __ix__ ;
    length __fltx__ $&maxflen ;

    %do i = 1 %to &flv0 ;

      __fidx__ = 0 ;
      __fltx__ = put(&&flv&i,&&flf&i) ;

      %* if there are early split characters, break there ;
      if 0<index(__fltx__,"&split")<=(&&fll&i + 1) then
        __fltx__ = substr(__fltx__,index(__fltx__,"&split")+1) ;
      %* for late split characters in the string, hitting a space at a break,
      %*   having no spaces to break on, break just based on length ;
      else if index(__fltx__,"&split")>(&&fll&i + 1)
            | substr(__fltx__,&&fll&i,1)=' '
            | index(trim(__fltx__),' ')=0
            | index(trim(__fltx__),' ')>&&fll&i
            | length(trim(__fltx__))<=&&fll&i then
        __fltx__ = substr(__fltx__,&&fll&i + 1) ;
      %* otherwise, search back to first space ;
      else do ;
        do __ix__ = %eval(&&fll&i - 1) to 1 by -1 while(substr(__fltx__,__ix__,1)~=' ') ;
        end ;
        __fltx__ = substr(__fltx__,__ix__+1) ;
      end ;

      do while(__fltx__~=' ') ;
        __fidx__ + 1 ;
        %* if there are early split characters, break there ;
        if 0<index(__fltx__,"&split")<=(&&fll&i + 1) then
          __fltx__ = substr(__fltx__,index(__fltx__,"&split")+1) ;
        %* for late split characters in the string, hitting a space at a break, ;
        %*   having no spaces to break on, break just based on length           ;
        else if index(__fltx__,"&split")>(&&fll&i + 1)
              | substr(__fltx__,&&fll&i,1)=' '
              | index(trim(__fltx__),' ')=0
              | index(trim(__fltx__),' ')>&&fll&i
              | length(trim(__fltx__))<=&&fll&i then
          __fltx__ = substr(__fltx__,&&fll&i + 1) ;
        %* otherwise, search back to first space ;
        else do ;
          do __ix__ = %eval(&&fll&i - 1) to 1 by -1 while(substr(__fltx__,__ix__,1)~=' ') ;
          end ;
          __fltx__ = substr(__fltx__,__ix__+1) ;
        end ;
      end ;

      if __fidx__>__flad__ then __flad__ = __fidx__ ;

    %end ;

  %end ;

  _b_l_k_ = _b_l_k_ + __flad__ ;

  %* output only one observation per block ;
  if last.&&bby&bby0 then output ;

  run ;

%*******************************************************************************
%* Merge block sizes in with main data:
%******************************************************************************;
data &out ;
  merge &out __temp__ ;
  by &pageby
     %do i = 1 %to &bby0 ;
       &&bby&i
     %end ;
     ;
  run ;

%*******************************************************************************
%* Calculate page variable to be used preceding all BY= varialbes
%* to define page breaks in a report:
%******************************************************************************;
data &out ;
  set &out ;
  by &pageby
     %do i = 1 %to &bby0 ;
       &&bby&i
     %end ;
     %do i = 1 %to &sby0 ;
       &&sby&i
     %end ;
     ;

  drop _b_l_k_ __ll__ __flad__ ;

  %* initialize page counter and line count ;
  retain &pagevar 1 __ll__ &lines ;

  %* update page counter and line count when a new page is necessary ;
  if (first.&&bby&bby0 & __ll__<_b_l_k_)
    %if %quote(&lastpgby)~= %then %do ;
      | first.&lastpgby
    %end ;
    then do ;
      &pagevar + 1 ;
      __ll__ = &lines ;
      %do i = 1 %to &bby0 ;
        if ~first.&&bby&i then __ll__ = __ll__ - (0 &&badjP&i) ;
      %end ;
      %do i = 1 %to &sby0 ;
        if ~first.&&sby&i then __ll__ = __ll__ - (0 &&sadjP&i) ;
      %end ;
  end ;

  %* update line count ;
  __ll__ = __ll__ - 1 ;

  %* update line count for each block variable adjustment ;
  %do i = 1 %to &bby0 ;
    if first.&&bby&i then __ll__ = __ll__ - (0 &&badj&i) ;
  %end ;

  %* update line count for each sort variable adjustment ;
  %do i = 1 %to &sby0 ;
    if first.&&sby&i then __ll__ = __ll__ - (0 &&sadj&i) ;
  %end ;

  %* add additional lines for any flow variables ;
  __flad__ = 0 ;
  %if &flv0>0 %then %do ;

    drop __fidx__ __fltx__ __ix__ ;
    length __fltx__ $&maxflen ;

    %do i = 1 %to &flv0 ;

      __fidx__ = 0 ;
      __fltx__ = put(&&flv&i,&&flf&i) ;

      %* if there are early split characters, break there ;
      if 0<index(__fltx__,"&split")<=(&&fll&i + 1) then
        __fltx__ = substr(__fltx__,index(__fltx__,"&split")+1) ;
      %* for late split characters in the string, hitting a space at a break,
      %*   having no spaces to break on, break just based on length ;
      else if index(__fltx__,"&split")>(&&fll&i + 1)
            | substr(__fltx__,&&fll&i,1)=' '
            | index(trim(__fltx__),' ')=0
            | index(trim(__fltx__),' ')>&&fll&i
            | length(trim(__fltx__))<=&&fll&i then
        __fltx__ = substr(__fltx__,&&fll&i + 1) ;
      %* otherwise, search back to first space ;
      else do ;
        do __ix__ = %eval(&&fll&i - 1) to 1 by -1 while(substr(__fltx__,__ix__,1)~=' ') ;
        end ;
        __fltx__ = substr(__fltx__,__ix__+1) ;
      end ;

      do while(__fltx__~=' ') ;
        __fidx__ + 1 ;
        %* if there are early split characters, break there ;
        if 0<index(__fltx__,"&split")<=(&&fll&i + 1) then
          __fltx__ = substr(__fltx__,index(__fltx__,"&split")+1) ;
        %* for late split characters in the string, hitting a space at a break, ;
        %*   having no spaces to break on, break just based on length           ;
        else if index(__fltx__,"&split")>(&&fll&i + 1)
              | substr(__fltx__,&&fll&i,1)=' '
              | index(trim(__fltx__),' ')=0
              | index(trim(__fltx__),' ')>&&fll&i
              | length(trim(__fltx__))<=&&fll&i then
          __fltx__ = substr(__fltx__,&&fll&i + 1) ;
        %* otherwise, search back to first space ;
        else do ;
          do __ix__ = %eval(&&fll&i - 1) to 1 by -1 while(substr(__fltx__,__ix__,1)~=' ') ;
          end ;
          __fltx__ = substr(__fltx__,__ix__+1) ;
        end ;
      end ;

      if __fidx__>__flad__ then __flad__ = __fidx__ ;

    %end ;

  %end ;

  __ll__ = __ll__ - __flad__ ;

  run ;

%leave:

%mend PGBLOCK ;

