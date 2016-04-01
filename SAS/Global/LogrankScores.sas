/*
/ PROGRAM NAME: LogrankScores
/
/ PROGRAM PURPOSE: The LOGRANKSCORES macro calculates Logrank Scores for censored data 
/                  (which are equivalent to Savage Scores in the uncensored case) using
/                  an identical algorithm to that used by StatXact-4 and as described in
/                  the StatXact-4 For Windows User Manual on p. 203.  It creates an output
/                  data set containing the results of the calculations.
/
/ SAS VERSION: 8 (Windows)
/
/ CREATED BY:  Carl Arneson
/
/ DATE:        June 2005
/
/ INPUT PARAMETERS:
/
/       data=     specifies the input data set name.  When set to _DEFAULT_ (default
/                 setting), the &SYSLAST value is used.
/
/       out=      specifies the name of the output data set.  When set to _DEFAULT_
/                 (default setting), the Logrank Scores are added as a new variable
/                 to the input data set.
/
/       by=       specifies a list of optional by-grouping variables.  The default 
/                 setting is null.
/
/       time=     specifies the name of the numeric variable corresponding to the
/                 event or censoring time.  The default setting is null and a numeric
/                 variable name from the input data set must be specified.
/
/       censor=   specifies the name of the numeric variable corresponding to the 
/                 censoring indicator.  The value of this variable should be 0 for
/                 censored observations and 1 for uncensored observations.  The default
/                 setting is null and a numeric variable name from the input data set
/                 must be specified.
/
/       logrank=  specifies the name of the variable in the output data set to contain
/                 the calculated Logrank Scores.  The default setting is Logrank.
/
/       maxn =    specifies the maximum overall sample size within a by-grouping.  The
/                 default setting is 999 and need only be reset if the maxium number of
/                 observations for any given by-grouping will exceed this.
/
/ OUTPUT CREATED: The output data set will contain all observations and variables from the
/                 input data set and will additionally include a variable (whose name will
/                 be set by the LOGRANK= parameter) containing the calculated Logrank Scores.
/
/ MACROS CALLED:
/
/                %words (to parse a list string into a macro variable array)
/
/===================================================================================
/ CHANGE LOG:
/
/     -------------------------------------------------------------------------
/     MODIFIED BY:
/     DATE:
/     DESCRIPTION:
/     -------------------------------------------------------------------------
/===================================================================================*/

%macro LogrankScores(Data=_DEFAULT_,
                     Out=_DEFAULT_,
                     By=,
                     Time=,
                     Censor=,
                     Logrank=Logrank,
                     MaxN=999) ;

%*******************************************************************************
%* Establish defaults for input and output data sets:
%******************************************************************************;
%if %quote(&data)=_DEFAULT_ | %quote(&data)= %then
  %let data = &syslast ;

%if %quote(&out)=_DEFAULT_ | %quote(&out)= %then
  %let out = &data ;

%*******************************************************************************
%* Check for required parameters (TIME=, CENSOR=, LOGRANK=, MAXN=):
%******************************************************************************;
%if %quote(&Time)= %then %do ;
  %put ERROR: (LogrankScores) Must specify TIME=. ;
  %goto leave ;
%end ;
%if %quote(&Censor)= %then %do ;
  %put ERROR: (LogrankScores) Must specify CENSOR=. ;
  %goto leave ;
%end ;
%if %quote(&Logrank)= %then %do ;
  %put ERROR: (LogrankScores) Must specify LOGRANK=. ;
  %goto leave ;
%end ;
%if %quote(&MaxN)= %then %do ;
  %put ERROR: (LogrankScores) Must specify MAXN=. ;
  %goto leave ;
%end ;

%*******************************************************************************
%* Intialize output data set and create a temporary observation ID variable 
%* and DUMMY by-variable (if no by-variables are specified)
%******************************************************************************;
data &Out ;
  set &Data ;
  __ID__ + 1 ;
  %if %length(&By)=0 %then %do ;
    %let By = _d_u_m_m_y_ ;
    &By = 1 ;
  %end ;
  %let By0 = %words(&By,root=By) ;
  run ;

%*******************************************************************************
%* Sort by TIME within CENSOR for each by-group
%******************************************************************************;
proc sort out=&Out ;
  by &By &Censor &Time __ID__ ;
  run ;

%*******************************************************************************
%* Calculate Logrank Scores in a temporary data set
%******************************************************************************;
data _internal_ ;
  set &Out(keep=&By &Censor &Time __ID__) ;
  by &By &Censor &Time ;
  keep &By &Censor &Time __ID__ &Logrank ;

  %* create arrays to store input data vectors ;
  array ___ID   {&MaxN} _temporary_ ;
  array ___Cens {&MaxN} _temporary_ ;
  array ___Time {&MaxN} _temporary_ ;

  %* Unique event or censor time # counter for each observation;
  array ___l {&MaxN} _temporary_ ;

  %* Unique event times ;
  array ___a {0:&MaxN} _temporary_ ;
  %* # events per unique event time ;
  array ___d {&MaxN}   _temporary_ ;
  %* cumulative # events per unique event time ;
  array ___v {0:&MaxN} _temporary_ ;

  %* # observations censored in interval (__v{i-1},__v{i}] ;
  array ___c {&MaxN} _temporary_ ;
  %* # observations censored up to & including i-th event ;
  array __C_ {&MaxN} _temporary_ ;

  %* Unique censor times ;
  array ___b       {&MaxN} _temporary_ ;
  %* # censored observations per unique censor time ;
  array ___x       {&MaxN} _temporary_ ;

  %* retain all arrays and create variables for:                                        ;
  %*   Overall sample size (__N__), # unique event times (__g__), # unique censor times (__h__) ;
  retain ___ID ___Cens ___Time ___l 
         ___a ___d ___v
         ___c __C_ 
         ___b ___x 
         __N__ __g__ __h__ 
         ;

  %* Initialize all arrays and retained variables for each by-group ;
  if first.&&By&By0 then do ;

    __N__ = 0 ;
    __g__ = 0 ;
    __h__ = 0 ;
    ___a{0} = 0 ;
    ___v{0} = 0 ;

    do xIx = 1 to dim(___ID) ;
      ___ID{xIx} = . ;
      ___Cens{xIx} = . ;
      ___Time{xIx} = . ;
      ___a{xIx} = . ;
      ___b{xIx} = . ;
      ___d{xIx} = . ;
      ___c{xIx} = . ;
      __C_{xIx} = . ;
      ___v{xIx} = . ;
      ___l{xIx} = . ;
      ___x{xIx} = . ;
    end ;

  end ;

  %* load up the by-unique-censor-time arrays ;
  if &Censor=0 then do ;
    if first.&Time then do ;
       __h__ + 1 ;
       ___b{__h__} = &Time ;
       ___x{__h__} = 1 ;
    end ;
    else ___x{__h__} = ___x{__h__} + 1 ;
  end ;

  %* load up the by-unique-event-time arrays ;
  else do ;
    if first.&Time then do ;
      __g__ + 1 ;
      ___a{__g__} = &Time ;
      ___a{__g__+1} = 10E99 ;
      ___d{__g__} = 1 ;
    end ;
    else ___d{__g__} = ___d{__g__} + 1 ;
  end ;

  %* load up the by-observation arrays (data vectors) ;
  __N__ + 1 ;
  ___ID{__N__}   = __ID__ ;
  ___Cens{__N__} = &Censor ;
  ___Time{__N__}   = &Time ;
  if &Censor=0 then ___l{__N__} = __h__ ;
  else              ___l{__N__} = __g__ ;

  %* once all data for by-group has been read, process data ;
  if last.&&By&By0 then do ;
    
    %* loop through the unique event times ;
    do xLx = 1 to __g__+1 ;

      %* count # censored observations in (.,.]-type intervals between unique event times ;
      ___c{xLx} = 0 ;
      do xIx = 1 to __h__ ;
        if ___a{xLx-1}<=___b{xIx}<___a{xLx} then ___c{xLx} = ___c{xLx} + ___x{xIx} ;
      end ;

      %* count cumulative # events at each unique event time ;
      if xLx=1 then do ;
        ___v{xLx}  = ___d{xLx} ;
      end ;
      else if xLx<__g__+1 then do ;
        ___v{xLx}  = ___v{xLx-1} + ___d{xLx} ;
      end ;

    end ;

    %* count cumulative number of censored observations at each event time ;
    %*   -- index __C_ by OVERALL event number (NOT by UNIQUE event number) ;
    xIx = 0 ;
    %* loop over each unique event time ;
    do xLx = 1 to __g__ ;
      %* loop over each event within each unique event time ;
      do xJx = 1 to ___d{xLx} ;
        %* Increment overall event number counter ;
        xIx + 1 ;
        %* for each individual event, count the number of censored observations up to & including that time point ;
        __C_{xIx} = 0 ;
        do xKx = 1 to xLx ;
          __C_{xIx} = __C_{xIx} + ___c{xKx} ;
        end ;
      end ; 
    end ;

    %* loop over all observations within by-group ;
    do xKx = 1 to __N__ ;

      %* output original variable values ;
      __ID__ = ___ID{xKx} ;
      &Censor = ___Cens{xKx} ;
      &Time = ___Time{xKx} ;

      %* calculate Logrank Score for the uncensored case ;
      if &Censor then do ;

        %* look up unique event time number ;
        xLx = ___l{xKx} ;

        %* apply StatXact-4 algorithm -- Equation (9.17) on p. 203 of manual ;
        &Logrank = 0 ;
        do xIx = ___v{xLx-1} + 1 to ___v{xLx} ;
          do xJx = 1 to xIx ;
            &Logrank = &Logrank + (1/(__N__ - __C_{xJx} - xJx + 1)) ;
          end ;
        end ;
        &Logrank = (&Logrank/___d{xLx}) - 1;

      end ;

      %* calculate Logrank Score for the censored case ;
      else do ;

        %* Set score to zero for censored observations prior to first event time ;
        if &Time<___a{1} then &Logrank = 0 ;

        %* otherwise, calculate score based on at-risk set ;
        else do ;

          %* ;
          do xIx = 1 to __g__ ;
            if ___a{xIx}<=&Time<___a{xIx+1} then xLx = xIx ;
          end ;

          %* apply StatXact-4 algorithm -- Equation (9.18) on p. 203 of manual ;
          &Logrank = 0 ;
          do xJx = 1 to ___v{xLx} ;
            &Logrank = &Logrank + (1/(__N__ - __C_{xJx} - xJx + 1)) ;
          end ;

        end ;

      end ;

      output ;

    end ;
  end ;

  run ;

%*******************************************************************************
%* Sort by TIME within CENSOR for each by-group
%******************************************************************************;
data &Out ;
  merge &Out _internal_ ;
  by &By &Censor &Time __ID__ ;
  run ;

%*******************************************************************************
%* Delete temporary data set
%******************************************************************************;
proc datasets library=work nolist ;
  delete _internal_ ;
  run ;

%*******************************************************************************
%* Restore original sort order and delete temporary variables
%******************************************************************************;
proc sort data=&Out out=&Out(drop=__ID__ %if &By=_d_u_m_m_y_ %then %str( _d_u_m_m_y_ ); ) ;
  by __ID__ ;
  run ;

%leave:

%mend LogrankScores ;
