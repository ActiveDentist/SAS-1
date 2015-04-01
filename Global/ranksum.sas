/*
/ PROGRAM NAME: ranksum.sas
/
/ PROGRAM VERSION: 1.1
/
/ PROGRAM PURPOSE: The ranksum macro performs the rank sum test for differences
/   in two independent populations, and calculates the analagous confidence
/   interval on the (median difference).  It creates an output dataset
/   containing the results of these caculations.
/
/   At first glance this macro may seem to work in a rather strange way.
/   The reason for this design is mostly due to the fact that depending on the
/   size of the data this macro can compute literally thousands of
/   observations in the intermediate statges.  This data is then sorted and
/   the values of interest are extracted.  Therefore each level of the
/   by variable is processed as an independent data set in the hopes that
/   each of these units will be small enought not to exceed the size of
/   the work library.
/
/
/ SAS VERSION: 6.12 (UNIX)
/
/ CREATED BY: John Henry King
/
/ DATE: 1992.
/
/ INPUT PARAMETERS:
/
/   data=       specifies the input data set name.  The default is _LAST_.
/
/   out=        specifies the name of the output data set.  See
/               (Output Data Set Variables( for a descriptions of the variables
/               The default is _WRSTOUT.
/
/   by=         specifies a list of by variables. A value must be specified.
/               The default is null.  I will try to find some time later to
/               allow the macro to have no by values.  I originally wrote it
/               this was because I invisioned that the user would almost
/               always have more that one VISIT, LAB parameter, whatever.
/
/   basis=      specifies a value of the class-variable which should be used
/               as the basis of comparison.  A value must be specified.
/               The default setting is null.
/
/   class=      specifies the name of the class variable which identifies
/               the groups (e.g. treatments) that you would like to compare.
/               There must be only 2 levels of this variable, and the macro
/               currently does no check this.
/
/   var=        Specifies the name of the variable that you are testing.
/               The default is Y.
/
/   maxdec=     specifies the number of decimal places to use in the confidence
/               intervals in the output data set.  This parameter affects the
/               value of _CI, see output details below, and not the actual
/               values of the CI.
/
/   alpha=      specifies the alpha level at which to perform the test and
/               construct the confidence intervals.  The default is .05.
/               Producing 95% CIs.
/
/   drop=       specifies the variables you would like to drop from the output
/               data set.  The default list is: _sum _nn _cf _w _a _exp _rmax
/               _z _var0 _ca _ul _uu _ml _mu _ru.
/
/   debug=      used in the development stages to turn on debug print.
/               It currently has no effect.  The default setting is YES.
/
/
/ OUTPUT CREATED: The output data set contains both the results of the
/   hypothesis test and confidence interval calculations and some intermediate
/   calculations.  Many of the intermediate calculations are dropped by
/   default, but may be left in the data set by changing DROP=.  The variables
/   described below are those that are not dropped by default.
/   The value for each of the following variables applies to its corresponding
/   by-group.
/
/ The by variables listed in the BY= parameter.
/
/ _an   is the number of observations in the (basis( class group.
/ _a0   is minimum of the variable specified by VAR= in the (basis( class-group.
/ _a25  is the low quartile
/ _a50  is the median
/ _a75  is the upper quartile
/ _a100 is the maximum
/ _bn   is the number of observations in the other class-group.
/ _b0   is minimum of the variable specified by VAR= in the other class group.
/ _b25  is the lower quartile
/ _b50  is the median
/ _b75  is the upper quartile
/ _100  is the maximum
/
/ _ties is the total number of tied observations.
/ _gties is the number of ranks whose frequency if greater than 1.
/ _sec  is either the value of the class variable for the smaller of the two
/       class-groups if the class-groups are of unequal size, or the value
/       of the class-variable if the class-groups are the same size.
/ _n    is the number of observations in the class-group indicated by _sec.
/ _m    is the number of observations in the class-group not indicated by
/       _sec.
/ _tiesp is the percentage of tied observations.
/ _gtiesp is the percentage of tied rand out of all observations.
/ _ws   is the test statistic used to test the equality of the distributions
/       of the tow populations.  It is spproximately normally distributed for
/       large samples.
/ _probw is the 2-tailed probability of a larger _ws given that the population
/       distributions are equivalent (based on the normal distribution).
/ _norma is equivalent to _probw.
/ _probit is the standard normal value associated with the specified
/       alpha level.
/ _delta is the (median difference( of all possible ordered pairs.
/ _sdelta is and adjusted version of _delta (=(_upper-_lower) / (2*_probit)).
/ _lower is the lower confidence limit on _delta.
/ _upper is the upper confidence limit on _delta.
/ _ci   is the confidence interval represented as a character string:
/       (ll.llll,uu.uuuu).
/ _int  is the true confidence level of the confidence interval.  This
/       variable exsits only in small sample situations in the the confidence
/       level is not exactly 1-alpha/2.
/
/
/
/ MACROS CALLED:
/               %jkxwords
/
/ EXAMPLE CALL:
/
/           %ranksum(data = glob,
/                     out = stats,
/                      by = visit,
/                   basis = 1,
/                   class = group,
/                     var = glob)
/
/====================================================================================
/ CHANGE LOG:
/
/    MODIFIED BY: John Henry King
/    DATE:        03MAR1997
/    MODID:       JHK001
/    DESCRIPTION: Add standard header and other internal documentation.
/    ------------------------------------------------------------------------------
/    MODIFIED BY: John Henry King
/    DATE:        03MAR1997
/    MODID:       JHK002
/    DESCRIPTION: Change error handeling to be more standard and remove the
/                 ENDSAS.  This could be very annoying to someone trying to use
/                 this macro in interactive sas.
/    ------------------------------------------------------------------------------
/    MODIFIED BY: Jonathan Fry
/    DATE:        10DEC1998
/    MODID:       JMF003
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 1.1.
/    ------------------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX004
/    DESCRIPTION:
/    ------------------------------------------------------------------------------
/===================================================================================*/

%macro ranksum(data = _last_,
                out = _WRSTOUT,
                 by = ,
              basis = ,
              class = TMT,
                var = y,
             maxdec = 4,
              alpha = .05,
               drop = _sum _nn _cf _w _a _exp _rmax _z _var0
                      _ca _ul _uu _ml _mu _ru,
              debug = YES);

   /*
   / JMF003
   / Display Macro Name and Version Number in LOG
   /------------------------------------------------------------*/

   %put -----------------------------------------------------;
   %put NOTE: Macro called: RANKSUM.SAS   Version Number: 1.1;
   %put -----------------------------------------------------;


   %let debug  = %upcase(&debug);
   %local j _by0 _byw0 _lstby _table _set;
   %let _by0   = 0;
   %let _byw0  = %jkxwords(list=&by,root=_BYW,delm=%str( ));
   %let _lstby = &&_byw&_byw0;

   /* JHK002 */
   %local edash;
   %let edash = _+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+;

   %if &basis= %then %do;
      %put ERROR: &edash;
      %put ERROR: You have not specified a BASIS variable! RANKSUM will not work!;
      %put ERROR: &edash;
      %goto endmac;
      %end;
   %if &by= %then %do;
      %put ERROR: &edash;
      %put ERROR: You have not specified a BY variable! RANKSUM will not work!;
      %put ERROR: &edash;
      %goto endmac;
      %end;

 /*%sysdump(_lstby) */

   /*
   / JHK001
   /
   / For each level of the by group find the first observation and last
   / observation.  These value are written to a macro variable array in
   / the from of a data set option.
   /   FIRSTOBS=value OBS=value.
   / The macro variables _BY1 to _BYn hold the code fragements.
   / Macro variable _BY0 gives the dimension of this array.
   /
   /-------------------------------------------------------------------------*/

   data _null_;
      set &data(keep=&by) end=eof;
      by &by;
      retain firstobs 0;
      if first.&_lstby then firstobs=_n_;
      if last.&_lstby then do;
         _BY_ + 1;
         length str $60;
         str = 'FIRSTOBS='!!trim(left(put(firstobs,8.)))
                          !!' OBS='!!trim(left(put(_n_,8.)));
         call symput('_BY'!!left(_by_),trim(str));
         end;
      if eof then call symput('_BY0',left(_by_));
      run;
   /*
   / JHK001
   /
   / Start processing from 1 to &_by0 each level of the by groups.
   /--------------------------------------------------------------------*/

   %do J = 1 %to &_by0;

      %put ------------------------------------------------;
      %put NOTE: Processing Started for _BY&j=&&_by&j ;
      %put ------------------------------------------------;

      /*
      / JHK001
      / Read the data as specified by the values of FIRSTOBS and OBS
      / given in the ith value of _BYi.
      / Remove any missing values.  Now we have a "working subset" of
      / the data.
      /-----------------------------------------------------------------*/
      data _wrst;
         do until(eof);
            set &data(&&_by&j keep=&by &class &var) end=eof;
            &var = round(&var,1e-12);
            if &class=' ' then delete;
            if &var  =' ' then delete;
            _N + 1;
            output;
            end;
         drop _n;
         run;

      /*
      / JHK001
      / Rank the values of VAR save ranks in _R
      /------------------------------------------*/
      proc rank data=_wrst out=_wrst ties=mean;
         by &by;
         var &var;
         ranks _r;
         run;

      /*
      / JHK001
      / Find the sum of the ranks and N for each level of CLASS
      /-----------------------------------------------------------*/
      proc summary data=_wrst nway;
         class &by &class;
         var _r;
         output out=_wrst2(drop=_type_ _freq_)
                  n=_nn
                sum=_sum;
         run;
      /*
      / JHK001
      / Compute descriptive statistics to be added to the output
      / data set.
      /-----------------------------------------------------------*/
      proc univariate data=_wrst noprint pctldef=5;
         by &by &class;
         var &var;
         output out=_median
                   n=_n
                 min=_0
                  q1=_25
              median=_50
                  q3=_75
                 max=_100;
         run;
      /*
      / JHK001
      / Transpose the stats from above,
      / this produces observations from variables.
      /----------------------------------------------------------*/
      proc transpose data=_median out=_median(drop=_label_);
         by &by &class;
         var _n _0 _25 _50 _75 _100;
         run;
      /*
      / JHK001
      / Compute and ID variable for the next transpose based on the
      / value of BASIS.
      /------------------------------------------------------------------*/
      data _median;
         set _median;
         by &by &class;
         length _id $8;
         if &class=&basis
            then _id='_A'!!substr(_name_,2);
            else _id='_B'!!substr(_name_,2);
         run;
      /*
      / JHK001
      / Using the ID variable from above transpose back to variables.
      /-------------------------------------------------------------------*/
      proc transpose data=_median out=_median(drop=_name_ /* _label_*/);
         by &by;
         var col1;
         id _id;
         run;

      /*
      / JHK001
      / Now the fun starts.
      / I think I will need Hollander and Wolf again to make any comments
      / on how this next few steps works.
      /-------------------------------------------------------------------*/

      /*
      / JHK001
      / Compute the number of observations for each RANK.
      /-------------------------------------------------------------------*/
      proc summary data=_wrst nway;
         class &by _r;
         output out=_cf(drop=_type_);
         run;
      /*
      / JHK001
      / From the above data compute
      /  _cf    SUM(Ri(Ri**2-1)
      /  _ties  the total number of tied observations.
      /  _gties the number of ranks whos frequency is greater than one
      /-------------------------------------------------------------------*/
      data _cf;
         _cf=0;
         do until(eof);
            set _cf end=eof;
            _cf    + _freq_*(_freq_**2-1);
            _ties  + (_freq_>1) * _freq_;
            _gties + (_freq_>1);
            end;
         drop _freq_ _r;
         run;

      /*
      / JHK001
      / Merge the three data sets from above
      /  _wrst2  the sum of the ranks
      /  _cf     the correction factor data.
      /  _median the descrptive statistics for VAR=
      /--------------------------------------------------------------------*/

      data _wrst2;
         drop &class;
         do until(eof);
            merge _wrst2 _cf _median end=eof;
            by &by;
            _n = min(_n,_nn);
            _m = max(_m,_nn);
            if _nn=_n then do;
               _ssc = &class;
               _w = _sum;
               end;
            end;
         _a      = _n*(_m+_n+1);
         _exp    = _a / 2;
         _rmax   = _n*(2*_m + _n + 1) / 2;
         _z      = _w - _exp;
         _var0   = (_m*_n/12)*((_m+_n+1)-((_cf/((_m+_n)*(_m+_n-1)))));
         _tiesp  = _ties /(_n+_m);
         _gtiesp = _gties/(_n+_m);
         _ws     = (_z - sign(_z)*.5) / sqrt(_var0);
         _probw  = min(1,2*(1-probnorm(abs(_ws))));
         _norma  = _probw;
         _probit = probit(1-&alpha/2);
         _ca     = (_m*_n/2)-_probit*sqrt(_var0);
         _Ul     = _ca;
         _Uu     = (_m * _n + 1) - _ca;
         _Ml     = floor((_m * _n + 1) / 2);
         _Mu     = ceil ((_m * _n + 1) / 2);

         call symput('_N',trim(left(put(_n,8.))));
         call symput('_M',trim(left(put(_m,8.))));
         if ((1<=_n<=10) & (1<=_m<=20))
            then call symput('_TABLE','1');
            else call symput('_TABLE','0');
         run;
      %if &_table %then %do;
         data _wrst2;
            set _wrst2;
            do point = 1 to _rmax until(.Z < _value <= (&alpha/2));
               link set;
               end;
            _UL   = _rmax - _x + 1;
            _UU   = (_m * _n + 1) - _UL;
            _int  = 1 - _value*2;
            if (_a-_x) < _w < _x
               then h0='Accept';
               else h0='Reject';
            output;
            stop;
            format _value _int 6.4;
            drop _value _x;
            return;
          Set:
            set utildata.N&_n.TO20
                  (keep=x _&_m rename=(_&_m=_value x=_x))
                point=point nobs=nobs;
            return;
            run;
         %end;
      data _u;
         array _y{&_n};
         array _x{&_m};
         set _wrst2(keep=_ssc);
         do until(eof);
            set _wrst end=eof;
            if &class=_ssc then do;
               _j + 1; _y{_j} = &var;
               end;
            else do;
               _i + 1; _x{_i} = &var;
               end;
            end;
         do _i = 1 to dim(_x);
            do _j = 1 to dim(_y);
               _U = _y{_j} - _x{_i};
               output;
               end;
            end;
         stop;
         keep _u;
         run;
      proc sort data=_u;
         by _u;
         run;
    /*proc print;*/
         run;
      data _wrst2;
         set _wrst2;
         point = round(_ul); link setu; _lower  = _u;
         point = _ml; link setu; _delta = _u;
         point = _mu; link setu; _delta = (_delta + _u) / 2;
         point = round(_uu); link setu; _upper  = _u;
         if upcase(_ssc)~=upcase(&basis) then do;
            _temp   = _lower;
            _lower  = _upper  * -1;
            _upper  = _temp   * -1;
            _delta  = _delta * -1;
            end;
         _sdelta = (_upper-_lower)/(2*_probit);
         length _CI $30;
         if &maxdec<1
            then _ru = 1;
            else _ru = input('.'!!repeat('0',&maxdec-2)!!'1',16.);

         _ci = compress('('!!put(round(_lower,_ru),16.&maxdec)!!','
                           !!put(round(_upper,_ru),16.&maxdec)!!')');
         output;
         stop;
         return;
       Setu:
         set _u point=point;
         drop _u _temp;
         run;
      data &out;
         set &_set _wrst2(drop=&drop);
         by &by;
         run;
      %let _set=&out;
      %let apprc=&syserr;
      proc delete data=_wrst _wrst2 _cf _u _median;
         run;
      %end;

  %endmac:
   %put NOTE: -----------------------------------------------------------------;
   %put NOTE: Macro RANKSUM ending execution.;
   %put NOTE: -----------------------------------------------------------------;

   %mend ranksum;
