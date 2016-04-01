********************************************************************************
*
*                            Glaxo Wellcome Inc.
*
*   STUDY: L-NMMA (546C88)
* PURPOSE: Creates summary dataset of Categorical Variables
*  AUTHOR: Jack Nyberg
*    DATE: 24 Nov 1997
*
* LIMITATIONS: Currently set up for a maximum of 2 categories in treatment 
*              and a maximum of 9999 total patients.  Treatment should be 
*              assigned values of A or B.   
*
*   NOTES: DATA1 = Data set that contains the variable to be summarized.
*          VAR1  = Variable to be summarized.
*          NUM1  = Numerical Identifier.
*
*	   A Dummy dataset must be created that includes dummy observations for
*          each possible value of VAR1.  The data set should include at least
*          the following additional dummy variables set to zero: A, B, and C.  
*          Also the data set must be named DUMMY and be created prior to 
*          invocation of CATSUM.
*
*	   A total column is calculated that combines the information in the BY 
*   	   variable.  This column is designated by a 'C'.
*
*******************************************************************************;
%macro catsum(_data1,_var1,_num1);
	 
proc freq data=&_data1;
   where &_var1 ne '';
   tables &_var1.*tmt / out=out1 noprint;
   tables &_var1      / out=out2 noprint;
run;

proc freq data=&_data1;
   where &_var1 ne '';
   tables tmt / out=out3 noprint;
   tables all / out=out4 noprint;
run;

data out1;
   set out1 out2(in=a) out3(in=b) out4(in=c);
   if a then tmt='C';
   if b then &_var1 = '0';
   if c then do;
      tmt='C'; &_var1 = '0';
   end;
run;

proc sort data=out1; by &_var1; run;

proc transpose data=out1 out=tranout1;
   var count;
   by &_var1;
   id tmt;
run;

proc sort data=dummy;    by &_var1; run;
proc sort data=tranout1; by &_var1; run;

data tranout1;
   update dummy tranout1;
   by &_var1;
run;

data dat&_num1;
   set tranout1;
   retain tota totb totc 0;
   length cola colb colc $ 20 sa sb sc $ 10 cat1 $ 60 factor1 $ 8;
   factor1="&_var1";
   cat1=&_var1;
   order1=int(&_num1/10);
   order2=&_num1;
   if a=. then a=0;
   if b=. then b=0;
   if c=. then c=0;

   if &_var1 = '0' then do;
      tota=a; totb=b; totc=c; 
      
      cola=put(a,4.0);
      colb=put(b,4.0);
      colc=put(c,4.0);
   end;
   else do;
      if tota ne 0 then pa=100*a/tota; else pa=0;
      if totb ne 0 then pb=100*b/totb; else pb=0;
      if totc ne 0 then pc=100*c/totc; else pc=0;
      
      if pa = 0 then sa='    ';
      else if 0 < pa < 1 then sa='(<1%)';
      else if 99 < pa < 100 then sa='(>99%)';
      else sa='('||compress(put(pa,3.0))||'%)';

      if pb = 0 then sb='    ';
      else if 0 < pb < 1 then sb='(<1%)';
      else if 99 < pb < 100 then sb='(>99%)';
      else sb='('||compress(put(pb,3.0))||'%)';

      if pc = 0 then sc='      ';
      else if 0 < pc < 1 then sc='(<1%)';
      else if 99 < pc < 100 then sc='(>99%)';
      else sc='('||compress(put(pc,3.0))||'%)';
      
      cola=put(a,4.0)||' '||right(put(sa,$6.));
      colb=put(b,4.0)||' '||right(put(sb,$6.));
      colc=put(c,4.0)||' '||right(put(sc,$6.));
   end;
   drop a b c _name_ _label_ tota totb totc sa sb sc pa pb pc;
run;

%mend catsum;

