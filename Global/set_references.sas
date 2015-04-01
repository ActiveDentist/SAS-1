%macro SET_REFERENCES (
    utildata = c:\sas\data,
	utilfmt  = c:\sas\formats,
	utilgdev = c:\sas\gdevice,
	utilscl  = c:\sas\scl,
	utiliml  = c:\sas\iml,
	utiltmpl = c:\sas\template
                      ) ;

   %local rc1 rc2 rc3 rc4 rc5 rc6 msg1 msg2 msg3 msg4 msg5 msg6 
          utildata utilfmt utilscl utiliml utilgdev utiltmpl;
   %let rc1      = %sysfunc(libname(utildata,&utildata,,access=readonly));

   %let msg1     = %sysfunc(sysmsg());
   %let utildata = %sysfunc(pathname(utildata));

   %let rc2      = %sysfunc(libname(library,&utilfmt,,access=readonly));
   %let msg2     = %sysfunc(sysmsg());
   %let utilfmt  = %sysfunc(pathname(library));

   %let rc3      = %sysfunc(libname(utilscl,&utilscl,,access=readonly));
   %let msg3     = %sysfunc(sysmsg());
   %let utilscl  = %sysfunc(pathname(utilscl));

   %let rc4      = %sysfunc(libname(utiliml,&utiliml,,access=readonly));
   %let msg4     = %sysfunc(sysmsg());
   %let utiliml  = %sysfunc(pathname(utiliml));

   %let rc5      = %sysfunc(libname(utilgdev,&utilgdev,,access=readonly));
   %let msg5     = %sysfunc(sysmsg());
   %let utilgdev = %sysfunc(pathname(utilgdev));

   %let rc6      = %sysfunc(libname(utiltmpl,&utiltmpl,,access=readonly));
   %let msg6     = %sysfunc(sysmsg());
   %let utiltmpl = %sysfunc(pathname(utiltmpl));

   filename utilgsf        "%quote(%fn).gsf";
   %if %sysfunc(fexist(utilgsf)) %then %let rc = %sysfunc(fdelete(utilgsf));

   %put NOTE: ----------------------------------------------------------------------------------;
   %put NOTE: The following LIBREFS have been created.;
   %if &rc1=0
      %then %put NOTE:   UTILDATA = &utildata ;
      %else %put &msg1;

   %if &rc2=0
      %then %put NOTE:   LIBRARY = &utilfmt ;
      %else %put &msg2;

   %if &rc3=0
      %then %put NOTE:   UTILSCL  = &utilscl ;
      %else %put &msg3;


   %if &rc4=0
      %then %put NOTE:   UTILIML  = &utiliml ;
      %else %put &msg4;

   %if &rc5=0
      %then %put NOTE:   UTILGDEV = &utilgdev ;
      %else %put &msg5;

   %if &rc6=0
      %then %put NOTE:   UTILTMPL = &utiltmpl ;
      %else %put &msg6;

   %put NOTE: ;
   %put NOTE: The following FILEREFs, for use with SAS/GRAPH, have been created.;
   %put NOTE:   UTILGSF  = %quote(%fn).gsf ;
   %put NOTE: ----------------------------------------------------------------------------------;


