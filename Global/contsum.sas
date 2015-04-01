********************************************************************************
*
*                            Glaxo Wellcome Inc.
*
*   STUDY: L-NMMA (546C88)
* PURPOSE: Continuous Data Summary Dataset
*  AUTHOR: Jack Nyberg
*    DATE: 24 Nov 1997
*
* LIMITATIONS: Currently set up for a maximum of 2 categories in the BY variable 
*              and a maximum of 9999 total patients.   
*
*   NOTES: DATA1  = data set that contains the variable to be summarized.
*          VAR1   = variable to be summarized.
*          BYVAR1 = By Variable.  Usually Treatment and designated A and B.
*          NUM1   = Numerical Identifier.
*          DEC1   = Decimal places of MEAN, STD, and MEDIAN.
*          DEC2   = Decimal places of MIN and MAX.
*
*	   A total column is calculated that combines the information in the BY 
*   	   variable.  This column is designated by a 'C'.
*
*******************************************************************************;
%macro contsum(_data1,_var1,_byvar1,_num1,_dec1,_dec2);

proc sort data=&_data1; by &_byvar1; run;

proc univariate data=&_data1 noprint;
   by &_byvar1;
   var &_var1;
   output out=uni1 n=n mean=mean std=std median=median min=min max=max;
run;

proc univariate data=&_data1 noprint;
   var &_var1;
   output out=uni2 n=n mean=mean std=std median=median min=min max=max;
run;

data out1;
   set uni1 uni2(in=a);
   if a then &_byvar1='C';
run;

proc transpose data=out1 out=tranout1;
   var n mean std median min max;
   id &_byvar1;
run;

data dummy;
   length _name_ $ 8;
   _name_='N';      a=0; b=0; c=0; output;
   _name_='MEAN';   a=0; b=0; c=0; output;
   _name_='STD';    a=0; b=0; c=0; output;
   _name_='MEDIAN'; a=0; b=0; c=0; output;
   _name_='MIN';    a=0; b=0; c=0; output;
   _name_='MAX';    a=0; b=0; c=0; output;
run;

proc sort data=dummy;    by _name_; run;
proc sort data=tranout1; by _name_; run;

data tranout1;
   update dummy tranout1;
   by _name_;
run;

data dat&_num1;
   set tranout1;
   length cola colb colc $ 20 cat1 $ 60 factor1 $ 8;
   factor1="&_var1";
   cat1=_name_;
   if cat1='N' then order3=1;
   if cat1='MEAN' then order3=2;
   if cat1='STD' then order3=3;
   if cat1='MEDIAN' then order3=4;
   if cat1='MIN' then order3=5;
   if cat1='MAX' then order3=6;
   order2=&_num1;
   order1=int(&_num1/10);
   if cat1 in ('N') then do;
      cola=put(a,4.0);
      colb=put(b,4.0);
      colc=put(c,4.0);
   end;   
   else if cat1 in ('MEAN','MEDIAN','STD') then do;
      cola=put(a,&_dec1);
      colb=put(b,&_dec1);
      colc=put(c,&_dec1);
   end;   
   else if cat1 in ('MIN','MAX') then do;
      cola=put(a,&_dec2);
      colb=put(b,&_dec2);
      colc=put(c,&_dec2);
   end;   
   keep factor1 cat1 cola colb colc order1 order2 order3;
run;

%mend contsum;

