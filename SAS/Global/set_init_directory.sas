%macro SET_INIT_DIRECTORY ;
%*******************************************************************************
%* For INTERACTIVE processes, set the current directory to that of the
%* file being opened (if any)
%******************************************************************************;
%local i InitialFile InitialPath ;
%if &UTSYSJOBINFO = INTERACTIVE %then %do ;
  %if %sysfunc(FILEREF(FL1))<=0 %then %do ;
    %let InitialPath = ;
    %let InitialFile = %sysfunc(PATHNAME(FL1)) ;
    %let i = %index(%quote(&InitialFile),%str(\)) ;
    %do %while (&i>0) ;
      %let InitialPath = &InitialPath.%qsubstr(%quote(&InitialFile),1,&i) ;
      %let InitialFile = %qsubstr(%quote(&InitialFile),%eval(&i + 1)) ;
      %let i = %index(%quote(&InitialFile),%str(\)) ;
    %end ;
    %put NOTE: Setting directory to InitialPath=&InitialPath (Initial File: &InitialFile) ;
    %sysexec CD &InitialPath ;
  %end ;
%end;
%mend SET_INIT_DIRECTORY ;


