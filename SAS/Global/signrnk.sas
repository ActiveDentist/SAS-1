/*
/ PROGRAM NAME: signrnk
/
/ PROGRAM VERSION: 1.2
/
/ PROGRAM PURPOSE: The SIGNRNK macro calculates a nonparametric confidence interval on
/                  medians, which is often applied to differences in paired samples (e.g.,
/                  changes from baseline).  It creates an output data set containing the
/                  results of these calculations.  Later versions may perform an analagous
/                  hypothesis test (i.e., the Wilcoxon Signed Rank Test).
/
/ SAS VERSION: 6.12 (UNIX)
/
/ CREATED BY: John Henry King
/
/ DATE:       1992
/
/ INPUT PARAMETERS:
/
/       data=     specifies the input data set name.  The default setting is _LAST_.
/
/       out=      specifies the name of the output data set.  See "OUTPUT CREATED:"
/                 for a description of the variables in this data set.  The default
/                 setting is _WSRTOUT.
/
/       by=       specifies a list of stratification variables.  A value must be
/                 specified.  The default setting is null.
/
/       change=   specifies the name of the variable for which the confidence
/                 interval is being calculated (e.g., change from baseline).  The
/                 default setting is CHANGE.
/
/       maxdec=   specifies the number of decimal places to use in the confidence
/                 intervals in the output data set.  The default setting is 4.
/
/       alpha=    specifies the alpha-level at which to construct the confidence
/                 intervals.  The default setting is .05 (for a 95% confidence
/                 interval).
/
/       tails=    presently has no effect.  In future versions, it may be used to
/                 perform a one-tailed or two-tailed WSRT.  The default is 2.
/
/       exact=    specifies the number of observations in each by-group below which
/                 the Signed Rank Tables is used for the quantile calculations.
/                 The default setting 18.
/
/ OUTPUT CREATED: In addition to the following list of variables, the output data set
/                 contains all of the variables specified with BY=, and the following
/                 variables taken form PROC UNIVARIATE.
/
/                    mean = _mean
/                 stdmean = _stdmean
/                skewness = _skew
/                kurtosis = _kurt
/                  median = _median
/                      q1 = _q1
/                      q3 = _q3
/                     min = _min
/                     max = _max
/
/ _nmiss    is the number of missing observations in each by-group.
/
/ _n0       is the number of zero differences in each by-group.
/
/ _n        is the number of non-missing observations in the by-group.
/
/ _nup      is the number of positive values in each by-group.
/
/ _dn       is the number of negative values in each by-group.
/
/ _seq2     is a standard error associated with skewness for each by-group.
/
/ _q        is the p-value resulting from a test of skewness on each by-group.
/           This test is sometimes used as a test of non-normality.
/
/ _see2     is a standard error associated with kurtosis for each by-group.
/
/ _k        is a p-value resulting from a test of kurtosis on each by-group.
/           This test is also used as a test of non-normality.
/
/ _m        is the number of possible pairings within each by-group
/           (Di,Dj) fro ij=1, ... , _n where i <=j.
/
/ _exp      is _m/2.  Note that _exp is also the number of possible pairings
/           within each by-group (Di,Dj) for ij=1, ... , _n when i<j.
/
/ _var0     is a variable used for intermediate calculations
/           (= _n*(_n+1)*(2*_n+1)/24).
/
/ _probit   is the standard normal value associated with the specified
/           alpha-level.
/
/ _int      is the actual confidence level of the calculated confidence
/           interval.  This value will get adjusted if _n<=EXACT (i.e., when a
/           table look up is performed).
/
/ _ca       is the approximate alpha/2-level quantile value of all possible
/           pairs (_m).  The value is not updated if _n<=EXACT.
/
/ _ln       is equivalent to _ca if _n>EXACT, and is the result of a table
/           look up if _n<=EXACT.  The ordered pairwise mean ([Di + Dj]/2
/           for i,j=1, ... ,_n when i<=j)  associated with this observation
/           defines the lower confidence limit.
/
/ _hn       is the 1-alpha/2-level quantile value of all the possible pairs
/           (_m).  This value is the result of a table look up if _n<=EXACT.
/           The ordered pairwise mean associated with this observation defines
/           the upper confidence limit.
/
/ _lmed,    are the middele most value(s) of all the possible pairs(_m).  The
/ _hmed     mean of the ordered pairwise means associated with these
/           observations defines _theta.
/
/ _theta    is the median of all the possible pairwise means.
/
/ _lower    is the lower confidence limit on _theta.
/
/ _upper    is the upper confidence limit on _theta.
/
/ _ci       is the confidence interval represented as a character string:
/           (ll.llll,uu.uuuu)
/
/ _ru       is the value to which the numbers in _ci were rouned.
/
/ MACROS CALLED:
/
/                %jkxworks  to parse the by list into words.
/
/ SAS DATA SETS USED:
/
/                For small (_n<=EXACT) samples this macro will use tables for the upper
/                tail probabilites for the null distribution of Wilcoxon's signed rank T+
/                statistic.
/
/                /usr/local/medstat/sas/data
/
/                 n3.ssd01
/                 n4.ssd01
/                 n5.ssd01
/                 n6.ssd01
/                 n7.ssd01
/                 n8.ssd01
/                 n9.ssd01
/                n10.ssd01
/                n11.ssd01
/                n12.ssd01
/                n13.ssd01
/                n14.ssd01
/                n15.ssd01
/                n16.ssd01
/                n17.ssd01
/                n18.ssd01
/
/ EXAMPLE CALL:
/
/           Data taken from Statistics with Confidence
/              by Gardner and Altman, pages 77-78
/           ------------------------------------------
/
/           data beta;
/              retain group 1; * by variable;
/              input subj before after;
/              change = after - before;
/              cards;
/            1 10.6 14.6
/            2  5.2 15.6
/            3  8.4 20.2
/            4  9.0 20.9
/            5  6.6 24.0
/            6  4.6 25.0
/            7 14.1 35.2
/            8  5.2 30.2
/            9  4.4 30.0
/           10 17.4 46.2
/           11  7.2 37.0
/           ;;;;
/           run;
/
/           %signrnk(data = beta,
/                     out = stats,
/                      by = group,
/                  change = change)
/
/===================================================================================
/ CHANGE LOG:
/
/     MODIFIED BY: John Henry King
/     DATE:        09Jan1997
/     MODID:       JHK001
/     DESCRIPTION: Added SIGNRANK and PROBS to PROC UNIVARIATE output.
/     -------------------------------------------------------------------------
/     MODIFIED BY: John Henry King
/     DATE:
/     MODID:       JHK002
/     DESCRIPTION: Assign Value of SYSLAST.
/     -------------------------------------------------------------------------
/     MODIFIED BY: Jonathan Fry
/     DATE:        10DEC1998
/     MODID:       JMF003
/     DESCRIPTION: Tested for Y2K compliance.
/                  Add %PUT statement for Macro Name and Version Number.
/                  Change Version Number to 1.2.
/     -------------------------------------------------------------------------
/     MODIFIED BY:
/     DATE:
/     MODID:       XXX004
/     DESCRIPTION:
/     -------------------------------------------------------------------------
/===================================================================================*/

%macro signrnk(data = _last_,
                out = _WSRTOUT,
                 by = ,
             change = change,
             maxdec = 4,
              alpha = .05,
              tails = 2,
              exact = 18);

   /*
   / JMF003
   / Display Macro Name and Version Number in LOG
   /-----------------------------------------------------------------*/

   %put -----------------------------------------------------;
   %put NOTE: Macro called: SIGNRNK.SAS   Version Number: 1.2;
   %put -----------------------------------------------------;


   %local j _by0 vname l u apprc loopj lastby by0 _table _set _n _n0;

   %let _by0  = 0;
   %let apprc = 0;

   /*
   / JHK002
   / Check for DATA=_LAST_ and assign value of SYSLAST.
   /----------------------------------------------------------------------*/

   %let data = %upcase(&data);
   %if "&data" = "_LAST_" %then %let data = &syslast;

   /*
   / break by list into words so lastby can be found
   /------------------------------------------------------------------*/
   %let by0    = %jkxwords(list=&by,root=by);
   %let lastby = &&by&by0;

   %put NOTE: LASTBY=*&lastby*;
   /*
   / pass through the data to find firstobs and obs for each by group
   /------------------------------------------------------------------*/
   data _null_;
      set &data(keep=&by) end=eof;
      by &by;
      retain firstobs 0;
      if first.&lastby then firstobs=_n_;
      if last.&lastby then do;
         _BY_ + 1;
         length str $60;
         str = 'FIRSTOBS='!!trim(left(put(firstobs,8.)))
                          !!' OBS='!!trim(left(put(_n_,8.)));
         /*
         / these macro vars _BYn contain firstobs and obs info
         / for each by group in the input dataset
         /------------------------------------------------------------*/
         call symput('_BY'!!left(_by_),trim(str));
         end;
      if eof then call symput('_BY0',left(_by_));
      run;
   /*
   / Now loop through the input dataset for each by group as if it
   / were a seperate dataset
   /-----------------------------------------------------------------*/
   %do J = 1 %to &_by0;
      %if &apprc~=0 %then %goto stopit;
      %put ----------------------------------------------------------;
      %put NOTE: Processing Started for _BY&j=&&_by&j;
      %put ----------------------------------------------------------;


      /*
      / Data _WRST contains _n observations and the following variables.
      /   the by variables and &change
      /
      /   _ABS the absolute differences |Zi|, ... , |Zn|.
      /
      /           1 if Zi > 0
      /   _psi <  0 if Zi = 0
      /          -1 if Zi < 0
      /
      / Data _NS contains one observation.
      /  _n     the number of non-missing differences.
      /  _nmiss the number of missing values.
      /  _n0    the number of ZERO differences.
      /  _nup   the number of positive differences.
      /  _ndn   the number of negative differences.
      /-------------------------------------------------------------------*/

      data
           _wsrt(keep = &by &change _abs _psi)
           _ns  (keep = &by _n _nmiss _n0 _nup _ndn);

         do until(eof);
            set
               &data
                  (
                   &&_by&j
                   keep=&by &change
                  )
               end=eof;

            &change = round(&change,1E-12);

            if &change <= .Z then do;
               _nmiss + 1;
               goto loop;
               end;

            if &change = 0 then _n0 + 1;
            _n   + 1;
            _psi = sign(&change);
            _nup = sum(_nup,(_psi>0));
            _ndn = sum(_ndn,(_psi<0));
            _abs = abs(&change);
            output _wsrt;

          Loop: end;

         output _ns;
         /*
         / If there are less than 3 non-missing values for this by-group
         / assign a macro variable so the processing can be skipped.
         /----------------------------------------------------------------*/
         if _n < 3
            then call symput('LOOPJ','1');
            else call symput('LOOPJ','0');
         run;

      %if &loopj %then %do;
         %put -------------------------------------------------------;
         %put NOTE: Processing Skipped For _BY&j=&&_by&j, N<3;
         %put -------------------------------------------------------;
         %goto LOOPJ;
         %end;

      /*
      / Rank the |Zi| computed above.
      /-------------------------------------------------------------------*/
      proc rank data=_wsrt out=_wsrt ties=mean;
         by &by;
         var _abs;
         ranks _rd;
         run;

      proc contents data=_wsrt;
         run;
      /*
      / compute a number of usefull statistics for the Zi
      /-----------------------------------------------------*/
      proc univariate data=_wsrt noprint;
         by &by;
         var &change;
         output out = _uni
               mean = _mean
            stdmean = _stdmean
             median = _median
                 q1 = _q1
                 q3 = _q3
                min = _min
                max = _max
           skewness = _skew
           kurtosis = _kurt
            /*
            / JHK001
            /-------------------*/
           signrank = _sgnrnk
           probs    = _probs;
         run;

      /*
      / Using data _NS and the univariate statistics from above _UNI compute
      / 1. The standard error and pvalues for the test on skewness and kurtosis.
      / 2. Also compute the observation numbers needed to look up the values for
      /    for the upper and lower confidence limist.
      / 3. For small samples _n<=EXACT lookup assign _TABLE=1 macro variable
      /    to cause to macro to use the tables.
      /--------------------------------------------------------------------------*/

      data _wsrt2;
         retain &by;
         merge _uni _ns end=eof;
         by &by;
         _seq2   = sqrt( (6*_n*(_n-1)) / ((_n-2)*(_n+1)*(_n+3)) );
         _q      = 1-probnorm(abs(_skew/_seq2));
         _see2   = sqrt((24*_n*(_n-1)**2)/((_n-2)*(_n-3)*(_n+3)*(_n+5)));
         _k      = 1-probnorm(abs(_kurt/_see2));
         _m      = _n*(_n+1) / 2;
         _exp    = _n*(_n+1) / 4;
         _var0   = ( _n*(_n+1)*(2*_n+1) ) / 24;
         _probit = probit(1-&alpha/2);
         _int    = 1 - &alpha;
         _ca     = _exp - _probit * sqrt(_var0);
         _ln     = _ca;
         _hn     = _m + 1 - _ca;
         _lmed   = floor((_m+1)/2);
         _hmed   = ceil ((_m+1)/2);
         if  _n <= &exact
            then call symput('_TABLE','1');
            else call symput('_TABLE','0');
         call symput('_N',left(put(_n,8.)));
         call symput('_N0',left(put(_n0,8.)));
         output;
         run;

      %put NOTE: _TABLE=&_table _N=&_n _N0=&_n0;

      /*
      / If the sample is small do a table lookup.
      /------------------------------------------------*/
      %if &_table %then %do;
         %put NOTE: N<=&exact using Signed Rank Table For P-Values.;

         data _wsrt2;
            set _wsrt2;
            /*
            / search the table until a value is found that is less
            / than or equal to alpha/2
            /-------------------------------------------------------*/

            do point = 1 to nobs  until(_value <= (&alpha/2));
               set
                  utildata.N&_n
                     (
                      keep   = t p
                      rename = (t = _x p = _value)
                     )
                  point = point
                  nobs  = nobs;
               end;

            _ln   = _m - _x + 1;
            _hn   = _m + 1 - _ln;
            _int  = 1 - _value*2;
            output;
            stop;
            format _value _int 6.4;
            return;
            run;

         %end;

      /*
      / Form the M = n(n + 1) / 2 averages (Zi + Zi)/2, i<=j = 1, ... , n.
      /
      / As each change is read it is placed in array _x, so that each
      / pairwise difference can be fromed by referencing the array from
      / 1 to n, for each successive observation.
      /
      / To conserve space only the differences are keep in the data set,
      / we do not even need the by values at this point.
      /-------------------------------------------------------------------*/
      data _ws(keep=_w);
         do until(eof);
            set _wsrt(keep=&change) end=eof;
            array _x{&_n} _temporary_;
            _place + 1;
            _x{_place} = &change;
            do _i = 1 to _place;
               _w = (&change + _x{_i}) / 2;
               output;
               end;
            end;
         run;

      /*
      / Form the ordered pairwise differences.
      / W(1) <= ... <= W(M)
      /----------------------------------------------*/
      proc sort data=_ws;
         by _w;
         run;



      /*
      / Using the values of _LN, _LMED, _HMED, and _HN computed above,
      / as observations numbers for the SET statement POINT= option
      / pick out the 4 values needed to compute _LOWER, _THETA, and _UPPER
      /------------------------------------------------------------------------*/

      data _wsrt2;
         set _wsrt2;

         /*
         / look up the lower confidence limit on theta
         /----------------------------------------------------------------------*/
         _place = floor(_ln); link setws; _lower = _w;

         /*
         / look up the values needed to compute the Hodges-Lehmann estimate
         / theta.
         /-----------------------------------------------------------------------*/
         _place = _lmed;      link setws;      _theta = _w;
         _place = _hmed;      link setws;      _theta = (_theta+_w)/2;

         /*
         / look up the upper confidence limit on theta
         /-----------------------------------------------------------------------*/
         _place =  ceil(_hn); link setws; _upper = _w;

         /*
         / Format the CI into a character variable.
         /-----------------------------------------------------------------------*/
         length _CI $30;
         if &maxdec<1
            then _ru = 1;
            else _ru = input('.'!!repeat('0',&maxdec-2)!!'1',16.);

         _ci = compress('('!!put(round(_lower,_ru),16.&maxdec)!!','
                           !!put(round(_upper,_ru),16.&maxdec)!!')');
         return;
       /*

       / Link to this set statement for look up values.
       /--------------------------------------------------*/
       Setws:
         set _ws(keep=_w) point=_place;
         drop _w;
         return;
         run;

      /*
      / combine the current by-group with any previous by-groups.
      /----------------------------------------------------------------------*/
      data &out;
         set &_set _wsrt2;
         by &by;
         run;

      %let _set  = &out;
      %let apprc = &syserr;

      /*
      / delete intermediate data sets
      /--------------------------------------------------*/
      proc delete data=_wsrt _wsrt2 _ns _ws;
         run;

      %loopj: %end;

  %stopit:

   %mend signrnk;
