********************************************************************************
*
*                            Glaxo Wellcome Inc.
*
*   STUDY: L-NMMA (546C88)
* PURPOSE: Odds Ratio Summary
*  AUTHOR: Jack Nyberg
*    DATE: 24 Nov 1997
*
*   NOTES: Works for trials with 2 study drugs, designated tmt A and tmt B.  Must
*          create a variable called ODDSVAR that takes on values of 1 or 0.  A value
*   	   of 1 indicates that the variable in question takes a value of interest, and
*          a value of 0 indicates that the variable in question takes another value.
*
*     	   DAT1  = Data inwhich variable is located.
*          NUM1  = Numerical Identifier.
*          VAR1  = Variable of Interest.
*	   CAT1  = A name for the category of interest (ie, what corresponds to oddvar=1).
*
*	   An odds ratio of > 1 indicates that tmt B has a greater proportion of events
*          occurring than does tmt A, ie OR = (B_YES*A_NO)/(B_NO*A_YES).
*
*	   The calculation for odds ratio is based upon the Fleiss definition in his
*          "Statistical Methods for Rates and Proportions".  Basically, he takes the 
*          usual definitions of OR and SE(OR) and adds 0.5 to each count.  The 95%
*          CI for OR is based upon the natural log odds ratio and its SE, ie 
*	      lower=exp(ln(OR)-1.96*se(ln(OR)))
*	      upper=exp(ln(OR)+1.96*se(ln(OR)))
*
*
*******************************************************************************;
%macro orsum(dat1,num1,var1,cat1);

proc freq data=&dat1;
   tables tmt*oddsvar/noprint out=fred;
run;

data dummy;
   oddsvar='0'; tmt='A'; output;
   oddsvar='1'; tmt='A'; output;
   oddsvar='0'; tmt='B'; output;
   oddsvar='1'; tmt='B'; output;
run;

proc sort data=dummy; by tmt oddsvar; run;

data fred;
   merge fred dummy;
   by tmt oddsvar;
run;

data fred;
   set fred;
   if count=. then count=0;
   grp=compress(tmt)||compress(oddsvar);
   count=count+0.5; * Add 0.5 to each count, as per Fleiss recommendation (Fleiss, Rates and Pro.);
run;

proc transpose data=fred out=tranfred;
   var count;
   id grp;
run;

data ball&num1;
   set tranfred;
   length factor1 ps1 ps2 $ 8 cat1 $ 35;
   o=(b1*a0)/(b0*a1);
   lno=log(o);
   selno=sqrt((1/a0)+(1/b0)+(1/a1)+(1/b1));
   low=exp(lno-(1.96*selno));
   hi=exp(lno+(1.96*selno));
   p1=100*(a1-0.5)/(a1+a0-1);
   p2=100*(b1-0.5)/(b1+b0-1);
   if (low < 1 and hi < 1) or (low > 1 and hi > 1) then star='*';
   else star='';
   ci='('||compress(put(low,6.2))||','||compress(put(hi,6.2))||') '||compress(star);

   if p1 ne 0 then ps1='('||compress(put(p1,3.0))||'%)';
   else ps1='';
   if p2 ne 0 then ps2='('||compress(put(p2,3.0))||'%)';
   else ps2='';
   
   freq1=put(a1-0.5,4.0)||'/'||compress(a1+a0-1)||right(put(ps1,$7.));
   freq2=put(b1-0.5,4.0)||'/'||compress(b1+b0-1)||right(put(ps2,$7.));

   factor1="&var1";
   cat1="&cat1";
   order0=int(&num1/10);
   order1=&num1;
   keep order0 order1 factor1 cat1 o freq1 freq2 ci;
run;

%mend orsum;

