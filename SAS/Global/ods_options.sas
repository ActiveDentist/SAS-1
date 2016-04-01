%macro ods_options;
	options mprint symbolgen nodate orientation=landscape;
	ods escapechar="^";
	ods trace on;
	*%put _user_;
%mend; 

