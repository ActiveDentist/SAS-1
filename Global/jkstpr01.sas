/*
/ PROGRAM NAME: jkstpr01.sas
/
/ PROGRAM VERSION: 2.0
/
/ PROGRAM PURPOSE: This macro is use by DTAB to parse the STATS= and
/   STATSFMT=.
/
/ SAS VERSION: 6.12 (UNIX)
/
/ CREATED BY: John Henry King
/ DATE: FEB1997
/
/ INPUT PARAMETERS:
/   stats=              The stats parameter passed to DTAB.
/
/   statsfmt=           The statsfmt parameter passed to DTAB.
/
/   at=                 The @ put statement pointer.
/
/ OUTPUT CREATED:  A macro variable array of put statement parts.
/
/ MACROS CALLED: none
/
/ EXAMPLE CALL:
/   %jkstpr01(stats=&stats,
/          statsfmt=&statsfmt,
/                at=@(_tc[ncol]) +(coff) )
/
/==============================================================================
/ CHANGE LOG:
/
/ MODIFIED BY: John Henry King
/ DATE: 21OCT1997
/ MODID: JHK001
/ DESCRIPTION: This macro was re-written to allow each continious variable to 
/              use a different set of formats.  IDSG conforming.
/              
/------------------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID: JHK002
/ DESCRIPTION:
/------------------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID: JHK003
/ DESCRIPTION:
/============================================================================*/




%macro jkstpr01(
                stats=,
             statsfmt=,
                   at=@(_tc[ncol]) +(coff)
               );




   %local w ww g h i j k lastword lroot;
   %let lroot = _&sysindex._;

   %let statsfmt = %qupcase(&statsfmt);
   %let stats    = %qupcase(&stats);

   %local
      SSE DFE MSE ROOTMSE
      LSM LSMSE
      CSS CV KURTOSIS MAX MEAN MEDIAN MIN MODE MSIGN N NMISS NOBS NORMAL
      P1 P10 P5 P90 P95 P99 PROBM PROBN PROBS PROBT Q1 Q3 QRANGE RANGE
      SIGNRANK SKEWNESS STD STDMEAN SUM SUMWGT T USS VAR
      L95 U95 L90 U90 L99 U99
      ;



   /*
   / Scan the format lists from &STATSFMT and pull out _ALL_ if found.
   /-----------------------------------------------------------------------------*/

   %local vl0 vlall vlallx;
   %let i = 1;
   %let w = %scan(&statsfmt,&i,%str(%)));
   %do %while(%bquote(&w) ^= );
      %if %substr(%bquote(&w),1,5)=_ALL_ %then %do;
         %let vlall  = %bquote(&w%str(%)));
         %let vlallx = %scan(&vlall,2,%str(%(%)));
         %end;
      %else %do;
         %let vl0 = %eval(&vl0 + 1);
         %local vl&vl0;
         %let vl&vl0 = %bquote(&w%str(%)));
         %end;
      %let i = %eval(&i + 1);
      %let w = %scan(&statsfmt,&i,%str(%)));
      %end;

   %if %bquote(&vlall)^= %then %do;
      %let vl0 = %eval(&vl0 + 1);
      %let vl&vl0 = &vlall;
      %end;
   %else %do;
      %let vl0 = %eval(&vl0 + 1);
      %let vl&vl0 = _all_();
      %end;

   %global jku0_0;
   %let jku0_0 = 0;

   /*
   / Loop through macro variable STATSFMT to get the pieces for each variable.
   /
   /--------------------------------------------------------------------------------*/

   %do h = 1 %to &vl0;


      /*
      / reinitialize the default formats and update with all if available.
      /------------------------------------------------------------------------------*/
      %let dfe       = 3.0;
      %let rootmse   = 5.1;
      %let mse       = 5.1;
      %let sse       = 5.1;
      %let LSM       = 5.1;
      %let LSMSE     = 5.1;
      %let CSS       = 5.1;
      %let CV        = 5.1;
      %let KURTOSIS  = 5.1;
      %let MAX       = 3.0;
      %let MEAN      = 5.1;
      %let MEDIAN    = 5.1;
      %let MIN       = 3.0;
      %let MODE      = 5.1;
      %let MSIGN     = 5.1;
      %let N         = 3.0;
      %let NMISS     = 3.0;
      %let NOBS      = 3.0;
      %let NORMAL    = 5.1;
      %let P1        = 5.1;
      %let P10       = 5.1;
      %let P5        = 5.1;
      %let P90       = 5.1;
      %let P95       = 5.1;
      %let P99       = 5.1;
      %let PROBM     = 6.4;
      %let PROBN     = 6.4;
      %let PROBS     = 6.4;
      %let PROBT     = 6.4;
      %let Q1        = 5.1;
      %let Q3        = 5.1;
      %let QRANGE    = 5.1;
      %let RANGE     = 5.1;
      %let SIGNRANK  = 5.1;
      %let SKEWNESS  = 5.1;
      %let STD       = 5.1;
      %let STDMEAN   = 5.1;
      %let SUM       = 5.1;
      %let SUMWGT    = 5.1;
      %let T         = 6.1;
      %let USS       = 6.1;
      %let VAR       = 6.1;
      %let L95       = 5.1;
      %let U95       = 5.1;
      %let L90       = 5.1;
      %let U90       = 5.1;
      %let L99       = 5.1;
      %let U99       = 5.1;

      /*
      / Scan &VLALLX and update the defaults formats.
      /---------------------------------------------------------------------------*/
      %let j = 1;
      %let i = 1;
      %let w = %scan(&vlallx,&i,%str( ));
      %let lastword   = ;
      %do %while("&w" ^= "");
         %if %index("&w",.) & ^%index("&lastword",.) %then %do;
            %local &lroot.F&j;
            %let &lroot.F&j = &w;
            %let j = %eval(&j + 1);
            %end;
         %else %if ^%index("&w",.) %then %do;
            %local &lroot.v&j;
            %let &lroot.V&j = &&&lroot.v&j &w;
            %end;
         %let lastword = &w;
         %let i = %eval(&i + 1);
         %let w = %scan(&vlallx,&i,%str( ));
         %end;
      %local &lroot.V0;
      %let   &lroot.V0 = %eval(&j -1);


      %let k = 0;
      %do i = 1 %to &&&lroot.v0;
         %let j = 1;
         %let w = %scan(&&&lroot.v&i,1,%str( ));
         %do %while("&w"^="");
            %let k = %eval(&k + 1);
            %let &w = &&&lroot.f&i;

            %let j  = %eval(&j + 1);
            %let w  = %scan(&&&lroot.v&i,&j,%str( ));
            %end;

         %let &lroot.v&i = ;
         %let &lroot.f&i = ;
         %end;


      /*
      / Now process the individual format lists for each variable.
      / X is the variable name
      / WW is the statsfmt sub list.
      /----------------------------------------------------------------------------*/

      %let x =  %scan(&&vl&h,1,%str(%());
      %let ww = %scan(&&vl&h,2,%str(%(%)));

      /*
      / Parse the format list part of STATSFMT
      /-------------------------------------------*/
      %let j = 1;
      %let i = 1;
      %let w = %scan(&ww,&i,%str( ));
      %let lastword = ;
      %do %while("&w" ^= "");
         %if %index("&w",.) & ^%index("&lastword",.) %then %do;
            %local &lroot.F&j;
            %let &lroot.F&j = &w;
            %let j = %eval(&j + 1);
            %end;
         %else %if ^%index("&w",.) %then %do;
            %local &lroot.v&j;
            %let &lroot.V&j = &&&lroot.v&j &w;
            %end;
         %let lastword = &w;
         %let i        = %eval(&i + 1);
         %let w        = %scan(&ww,&i,%str( ));
         %end;
      %local &lroot.V0;
      %let   &lroot.V0 = %eval(&j -1);


      %let k = 0;
      %do i = 1 %to &&&lroot.v0;
         %let j = 1;
         %let w = %scan(&&&lroot.v&i,1,%str( ));
         %do %while("&w"^="");
            %let k = %eval(&k + 1);
            %let &w = &&&lroot.f&i;

            %let j  = %eval(&j + 1);
            %let w  = %scan(&&&lroot.v&i,&j,%str( ));
            %end;

         %let &lroot.v&i = ;
         %let &lroot.f&i = ;
         %end;



      %let i = 1;
      %let w = %qscan(&stats,&i,%str( ));

      %global jku&h._0 jku&h._v;
      %let    jku&h._0 = 0;
      %let    jku&h._v = &x;

      %do %while("&w"^="");

         %global jku&h._&i;

         %if "&w"="MIN-MAX" %then %do;
            %let jku&h._&i = n(min,max)>0 then put &at MIN &min '-' MAX &max-l;
            %end;
         %else %if "&w"="N-MEAN(STD)" %then %do;
            %let jku&h._&i = n(n,mean,std)>0 then put &at N &n +1 MEAN &mean '(' STD :&std +(-1) ')';
            %end;
         %else %if "&w"="N-MEAN(STD)-MIN+MAX" %then %do;
            %let jku&h._&i = n>0 then put &at N &n +1 MEAN &mean '(' STD  &std ')' MIN &min ',' MAX &max;
            %end;
         %else %if "&w"="N-MEAN-STD-MIN-MAX" %then %do;
            %let jku&h._&i = n>0 then put &at N &n +1 MEAN &mean  STD  &std MIN &min ',' MAX &max;
            %end;
         %else %if "&w"="N-MEAN(STDMEAN)" %then %do;
            %let jku&h._&i = n(n,mean,stdmean)>0 then put &at N &n +1 MEAN &mean '(' STDMEAN :&stdmean +(-1) ')';
            %end;
         %else %if "&w"="MEAN(STD)" %then %do;
            %let jku&h._&i = n(mean,std)>0 then put &at MEAN &mean '(' STD :&std +(-1) ')';
            %end;
         %else %if "&w"="MEAN(STDMEAN)" %then %do;
            %let jku&h._&i = n(mean,stdmean)>0 then put &at MEAN &mean '(' STDMEAN :&stdmean +(-1) ')';
            %end;
         %else %if "&w"="LSM(LSMSE)" %then %do;
            %let jku&h._&i = n(lsm,lsmse)>0 then put &at lsm &lsm '(' LSMSE :&lsmse +(-1) ')';
            %end;
         %else %if "&w"="N-LSM(LSMSE)" %then %do;
            %let jku&h._&i = n(lsm,lsmse,n)>0 then put &at N &n +1 LSM &lsm '(' LSMSE :&lsmse +(-1) ')';
            %end;
         %else %if "&w"="L95-U95" %then %do;
            %let jku&h._&i = n(l95,u95)>0 then put &at L95 &l95 '-' U95 &u95-l;
            %end;
         %else %if "&w"="L90-U90" %then %do;
            %let jku&h._&i = n(l90,u90)>0 then put &at L90 &l90 '-' U90 &u90-l;
            %end;
         %else %if "&w"="L99-U99" %then %do;
            %let jku&h._&i = n(l99,u99)>0 then put &at L99 &l99 '-' U99 &u99-l;
            %end;
         %else %do;
            %let jku&h._&i = %unquote(&w > . then put &at &w &&&w);
            %end;

         %*put NOTE: JKU&h._&i = &&jku&h._&i;

         %let i = %eval(&i + 1);
         %let w = %qscan(&stats,&i,%str( ));

         %end;

      %let jku&h._0 = %eval(&i - 1);
      %end;


   %let jkU0_0 = %eval(&h-1);

   %mend jkstpr01;
