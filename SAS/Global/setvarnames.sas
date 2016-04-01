%macro setvarnames(lib=,dsn=,mvar=);

proc sql noprint;
	select distinct(name) into :mvar
	separated by " "
	from sashelp.vcolumn
	where libname in("%upcase(&lib)") & memname in("%upcase(&dsn)") ;
quit;

%put %upcase(mvar):  &mvar;

%mend setvarnames;



/*proc sql;*/
/*	select distinct(name) into :varnames*/
/*	separated by " "*/
/*	from sashelp.vcolumn*/
/*	where libname in("WORK") & memname in("TEST") ;*/
/*quit;*/
/*%put VARNAMES:  &varnames;*/
