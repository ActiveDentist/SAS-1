/*
/ PROGRAM NAME: jkchklst.sas
/
/ PROGRAM VERSION: 1.0
/
/ PROGRAM PURPOSE: Uses this utility to check a user specified value (list)
/  against a list of possible values.
/
/ SAS VERSION: 6.12 (UNIX)
/
/ CREATED BY: John Henry King
/
/ DATE: FEB1997
/
/ INPUT PARAMETERS:
/
/ LIST=               The list of words to be compared.                             
/                                                                                   
/ AGAINST=UNISTATS    The list to compare to.  The default is the statistics        
/                     computed by PROC univariate.                                  
/                                                                                   
/ RETURN=RC           A macro variable set to 0 if no errors were found,            
/                     1 otherwise.                                                  
/
/ OUTPUT CREATED: The macro variable named in RETURN= is modified.
/ 
/ MACROS CALLED:
/
/   
/
/==============================================================================
/ CHANGE LOG:
/
/ MODIFIED BY:
/ DATE:
/ MODID: JHK001
/ DESCRIPTION:
/------------------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID: JHK002
/ DESCRIPTION:
/------------------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID: JHK003
/ DESCRIPTION:
/============================================================================*/


%macro jkchklst(list = ,
             against = UNISTATS,
              return = RC);

   %let return = %upcase(&return);

   %global &return;
   %let &return = 0;

   %if %length(&list)=0 %then %goto EXIT;

   %let list    = %upcase(&list);
   %let against = %upcase(&against);

   %if "&against" = "UNISTATS" %then %let against=
CSS CV KURTOSIS MAX MEAN MEDIAN MIN MODE MSIGN N NMISS NOBS NORMAL 
P1 P10 P5 P90 P95 P99 PROBM PROBN PROBS PROBT Q1 Q3 QRANGE RANGE 
SIGNRANK SKEWNESS STD STDMEAN SUM SUMWGT T USS VAR;

   data _null_;

      if _n_ = 1 then do;
         length err $28 dash $80;
         retain err dash;
         err = left(reverse('RORRE TSLKHCKJ ORCAM :RORRE'));
         dash = repeat('_+',39);
         end;

      length list against $200 w $20;
      retain list "&list";
      retain against "&against";
 
      i = 1;
      w = scan(list,i,' ');

      do while(w ^= ' ');
         if ^indexw(against,w) then do;
            put / dash / err ' The requested statistic ' w 'is not valid, Check your spelling.' / dash / ' ';
            call symput("&return",'1');
            end;
         i = i + 1;
         w = scan(list,i,' ');
         end;

      stop;
      run;

 %EXIT:
   %mend jkchklst;
