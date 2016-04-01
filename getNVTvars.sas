%macro getNVTvars;
%global username;
%global nvt;
%global userdomain;

%let userdomain = %sysfunc(sysget(userdomain)) ;
%put USERDOMAIN: &userdomain ;
%let nvt = %sysfunc(sysget(utenv)) ;
%put ENVIRONMENT: &nvt ;
%let username = %sysget(username) ;
%put USERNAME: = &username ;
%mend;
