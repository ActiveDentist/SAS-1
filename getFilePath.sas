
%macro getFilePath;

	%global filepath;

	%if &SYSPROCESSNAME=DMS Process %then
		%let filepath = %sysget(SAS_EXECFILEPATH);
	%else %if &SYSPROCESSNAME = Object Server %then
		%let filepath = &_SASPROGRAMFILE;
	%else %if &SYSPROCESSNAME ~= %then
		%let filepath = &SYSPROCESSNAME;
	%else
		%put "ERROR: Unable to determine file path.";
	%put FILEPATH: &filepath;
	%getProject(%words(&filepath, DELM="\,/"));
%mend;
