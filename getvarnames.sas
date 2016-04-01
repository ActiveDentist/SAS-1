%macro getvarnames(lib=,dsn=);

%global varnames;

proc sql noprint;
	select distinct(name) into :varnames
	separated by " "
	from sashelp.vcolumn
	where libname in("%upcase(&lib)") & memname in("%upcase(&dsn)") ;
quit;

%put %upcase(VARNAMES):  &varnames;

%mend getvarnames;



/*proc sql;*/
/*	select distinct(name) into :varnames*/
/*	separated by " "*/
/*	from sashelp.vcolumn*/
/*	where libname in("WORK") & memname in("TEST") ;*/
/*quit;*/
/*%put VARNAMES:  &varnames;*/
