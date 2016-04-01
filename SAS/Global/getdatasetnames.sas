%macro getdatasetnames(lib=);

%global dsnames;

proc sql;
	select distinct(memname) into :dsnames
	separated by " &lib.."
	from sashelp.vcolumn
	where libname in("%upcase(&lib)");
quit;

%let dsnames = &lib..&dsnames;

%put DSNAMES:  &dsnames;

%mend getdatasetnames;
