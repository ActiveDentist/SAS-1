/*
/ Program Name : jobinfo.sas
/
/ Program Version : 4.1
/
/ Program Purpose :
/
/ SAS Version : 6.12
/
/ Created By : (A.G.Walduck)
/ Date :       (25th April 1997)
/
/ Input Parameters :
/
/ Output Created :
/
/ Macros Called :
/
/ Example Call :
/
/=============================================================================================
/ Change Log
/
/    MODIFIED BY: Ian Amaranayake
/    DATE:        04/07/97
/    MODID:       001
/    DESCRIPTION: Standard program header added.
/    -----------------------------------------------------------------------------
/    MODIFIED BY: Tony Walduck
/    DATE:        28/05/97
/    MODID:       002
/    DESCRIPTION: Truncated file names in /GW/u?medstat/ environment.
/                 Modified (ucb) ps command with wrap-around option.
/    -----------------------------------------------------------------------------
/    MODIFIED BY: Hedy Weissinger
/    DATE:        01/09/97
/    MODID:       003
/    DESCRIPTION: File names and paths not returned correctly when submitting
/                 jobs to SAS from CRISP.  Added x switch to ps command.
/    -----------------------------------------------------------------------------
/    MODIFIED BY: Jonathan Fry
/    DATE:        09DEC1998
/    MODID:       JMF004
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 4.1.
/    -----------------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX005
/    DESCRIPTION:
/    -----------------------------------------------------------------------------
/=============================================================================================*/;

%macro JOBINFO ;

      /*
      / JMF004
      / Display Macro Name and Version Number in LOG
      /--------------------------------------------------------*/

      %put -----------------------------------------------------;
      %put NOTE: Macro called: JOBINFO.SAS   Version Number: 4.1;
      %put -----------------------------------------------------;


%if %nrbquote(&sysparm)~= %then %goto exit ;

%if "&sysscp" ~= "SUN 4" %then %do ;
  %put NOTE: JOBINFO does not work with &sysscp..;
  %goto exit;
  %end;
options nonotes ;

%local user dir arg ext ;

%if &sysenv=BACK %then %do ;

  filename sasarg pipe "/usr/ucb/ps -wx | awk '/^ *&sysjobid/{print $6}' ;
        pwd ; whoami" ;

  data _null_ ;
    infile sasarg length=len ;
    input card $varying200. len ;
    select (_n_) ;
      when  (1)    call symput('arg' ,trim(card)) ;
      when  (2)    call symput('dir' ,trim(card) !! '/' ) ;
      when  (3)    call symput('user',trim(card)) ;
      otherwise    put 'WARNING: Unexpected line from pipe in %JOBINFO.' ;
    end ;
    run ;

  %if %index(&arg,%str(/))=1 %then %let dir= ;

  %local i file ;
  %let file = &arg ;
  %let i = %index(&file,%str(/)) ;
  %do %while(&i) ;
    %let file = %substr(&file,%eval(&i + 1)) ;
    %let i = %index(&file,%str(/)) ;
  %end ;

  %if %index(&file,%str(.)) %then %let ext= ;
  %else %let ext=.sas ;

%end ;

%else %do ;

  filename sasarg pipe "pwd ; whoami" ;

  data _null_ ;
    infile sasarg length=len ;
    input card $varying200. len ;
    select (_n_) ;
      when  (1)    call symput('dir' ,trim(card) !! '/') ;
      when  (2)    call symput('user',trim(card)) ;
      otherwise    put 'WARNING: Unexpected line from pipe in %JOBINFO.' ;
    end ;
    run ;

  %let arg=INTERACTIVE ;

%end ;

filename sasarg clear ;

options sysparm="&user:&dir.&arg.&ext" notes ;

%exit:

%mend JOBINFO ;
