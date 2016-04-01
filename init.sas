

%macro init();
	/*turn on display information for macro autocall location*/
	option mautolocdisplay;
	%let userdomain = %sysfunc(sysget(userdomain)) ;
	%put USERDOMAIN: &userdomain ;
	%let username = %sysget(username) ;
	%put USERNAME: = &username ;

	/*	get current directory path and tokenize compound and protocol to use in libname statements	*/
	%getFilePath;

	/*	set up libnames for project area from global macro variables returned  by %getFilePath	*/
	libname adam "C:\Users\&username\Projects\&cpd\&prot\production\ADaM";
	libname CDISCfmt "C:\Users\&username\projects\&cpd\&prot\production\formats";
	libname dm "S:\stats\Data Management\SAS Datasets\&dm_cpd\&dm_prot\" access=readonly;
	libname noncrf "C:\Users\&username\Projects\&cpd\&prot\production\sourceData";
	libname output "C:\Users\&username\projects\&cpd\&prot\production\TLF\output";
	libname src "C:\Users\&username\Projects\&cpd\&prot\production\sourceData" access=readonly;
	libname sdtm "C:\Users\&username\Projects\&cpd\&prot\production\SDTM";
	libname PERM "C:\Users\&username\Projects\&cpd\&prot\production\sourceData" outrep=WINDOWS_64;
	libname TDEfmt "C:\Users\&username\projects\&cpd\&prot\production\formats";
	filename trt "c:\Users\&username\projects\&cpd\&prot\data\sourceData\&prot._trt.xls";

	/* * Do we need this?; */
	options fmtsearch=(TDEfmt /*UTILfmt CDISCFMT.TLFfmt CDISCFMT.CDISCFMT*/);

	/* * Do we need this? ; */
	%local i list;
	%global pad nextt head1 head2 head3 head4 head5 head6 head7 head8 head9 head10;
	%let pad='                                                                    ';
	%let head1=Protocol: &dm_prot ;
	%let nextt = 1 ;


	%do i=1 %to 10;

		%if %length(&&head&i)>0 %then
			%do;
				title&i "&&head&i" &pad &pad;
				%let nextt = %eval(&i + 1) ;
			%end;
	%end;
	/*	Call xcopy batch script to copy files from S:/stats/Data Management area	*/
	option noxwait;
	%SYSEXEC(C:\sas\macros\scripts\CARP_Admin\xcopy.bat &cpd &prot &dm_cpd &dm_prot &username);
	%put SYSECXEC return code (0:OK, 1:ERROR): &sysrc;

%leave:
	option nomautolocdisplay;



%mend;
