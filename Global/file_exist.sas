********************************************************************************
*
*                         United Therapeutics Corp
* MACRO TITLE: chk_file
*     PURPOSE: Determine existence of a file and set global macro var flags
*        NAME: David M Pressley
*        DATE: 03 APR 2008

*EXAMPLE CALL: %chk_file(C:\Projects\RIN\RINPH301\programs\fsr\formats.sas);

*******************************************************************************;


%macro chk_file(fname);
%global chk_flag;
%let chk_flag = 0;
 %if %sysfunc(fileexist(&fname)) %then %do;
  %put The file &FNAME exists.;
  %let chk_flag = 1;
/*  %put CHECK_FLAG= &chk_flag;*/
%end;
   %else %do;
   	%put %sysfunc(sysmsg());
/*	%put CHECK_FLAG= &chk_flag;*/
%end;

%mend;

