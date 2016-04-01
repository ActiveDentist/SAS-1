/* --------------------------------------------------------------------------- 
 Program : getIncr.sas 
 
 Purpose : Obtain small increment (BY-Value) for an underlying hidden 
 axis from the RANGE parameter. The return value is used 
 to stretch out the axis minimum and maximum so that value 
 labels (created in annotate) are fully visible. 
 The return value also becomes the factor if relative units are 
 specified for the XMIN and XMAX parameters in MKUNDERLYINGSCALE. 
 For example, XMIN=-3 tells MKUNDERLYINGSCALE to decrease the 
 horizontal axis by 3*factor. 
 
 Parms : Name Description Default 
 --------- ------------------------------- -------- 
 RANGE Data MAX - Data MIN (where MAX none (required) 
 and MIN are internally defined 
 with any degree of precision) 
 
 Usage : %let RangeX = %sysevalf(&calcXMax - &calcXmin); 
 %let _Xby= %getIncr(range=&RangeX); 
SAS Global Forum 2009 Posters
 10 
 Notes : From the manual: ROUND(argument, round-off-unit) 
 The ROUND function returns a value rounded to the nearest 
 round-off unit. So for example: 
 Range=40.35(days) - 12.65(days) = 27.7 
 %let x=%getincr(range=27.7); 
 LOOP1 NOTFOUND=1: round range and result = 1 0.277 0 
 LOOP2 NOTFOUND=0: round range and result = 0.1 0.277 0.3 
 %put x=&x; 
 x=0.3 
 ------------------------------------------------------------------------ */ 
%macro getINCR(Range=); 
 %local notfound found result round; 
 %let range=%sysevalf(&range/100); 
 %let notFound = 1; 
 %let round = 1; 
 %do %while (&notFound); 
 %let result=%sysfunc(round(&range, &round)); 
 %if &result gt 0 %then %let notFound=0; 
 %else %do; 
 %let round = %sysevalf(&round / 10.0); 
 %end; 
 %end; 
 &result 
%mend getIncr; 
