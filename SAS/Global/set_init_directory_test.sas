%macro SET_INIT_DIRECTORY_TEST ;

  	data _null_;
		set sashelp.vlibnam;
		if libname = 'IN';
			v = scan(path,-1,'.');
			put Path: &path;
			put V= &v;
			xx=input(substrn(fileref,4,length),5.);
			call symput('InitialPath',trim((path));
			put InitialPath= &InitialPath;

	run;

	
	*parse pathname and change directory;
	%let InitialFile = &initialpath;
	%let initialpath =;
    %let i = %index(%quote(&InitialFile),%str(\)) ;
    %do %while (&i>0) ;
      %let InitialPath = &InitialPath.%qsubstr(%quote(&Initialfile),1,&i) ;
      %let InitialFile = %qsubstr(%quote(&InitialFile),%eval(&i + 1)) ;
      %let i = %index(%quote(&InitialFile),%str(\)) ;
    %end ;
/**/
/**/
/*	%put NOTE: Setting directory to InitialPath=&InitialPath (Initial File: &InitialFile) ;*/
/*    %sysexec CD &InitialPath ;*/
/**/
/*  %end ;*/

%mend SET_INIT_DIRECTORY_TEST ;

%set_init_directory_test;
