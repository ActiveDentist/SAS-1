%macro PCTTXT(var,r,n,          /* Variable name, numerator and denominator */
              digits=3,         /* Maximum digits to use for counts         */
              dec=0,            /* Decimal places for percents              */
              pct=Yes,          /* Display "%" in string?                   */
              FullZero=No,      /* Display "0" as "0/nnn   (0%)"?           */
              denom=No) ;       /* Display numerator in string?             */

%if %length(&var)=0 | %length(&r)=0 | %length(&n)=0 %then %do ;
  %put ERROR: (PCTTXT) Must Specify variable, numerator and denominator. ;
  %goto leave ;
%end ;

%***********************************************************************
%* Determine necessary length of string:
%**********************************************************************;
%local strlen ;
%let strlen = %eval(
                    &digits + 6
                    + (&dec>0)*(&dec + 1)
                    + (%upcase(%substr(&pct,1,1))=Y)
                    + (%upcase(%substr(&denom,1,1))=Y)*(&digits + 1)
                   ) ;
%if %index(&var,%str({))=0 %then %do ;
  length &var $&strlen ;
%end ;

%***********************************************************************
%* Create string:
%**********************************************************************;
if &n>.Z then do ;

  if &r<=.Z then &r = 0 ;

  %* start out with just frequency ;
  %if %upcase(%substr(&FullZero,1,1))=N %then %do ;
  if &r then do ;
  %end ;
  %else %do ;
  if (1) then do ;
  %end ;
    &var = put(&r,&digits..)

           %* tack on denominator if specified ;
           %if %upcase(%substr(&denom,1,1))=Y %then %do ;
             || '/' || left(put(&n,&digits..))
           %end ;

           || ' (' ;

    %* figure out if we fall below smallest displayable percent ;
    if 0 < ( &r / &n * 100 ) <  ( 10**-&dec ) then
      &var = trim(&var) || ' <' ||
             left(put(10**-&dec,%eval(3+(&dec>0)*(&dec+1)).&dec)) ;
    else if 100-(10**-&dec)< ( &r / &n * 100 ) < 100 then
      &var = trim(&var) || '>' ||
             left(put(100-(10**-&dec),%eval(3+(&dec>0)*(&dec+1)).&dec)) ;
    %if %upcase(%substr(&FullZero,1,1))=N %then %do ;
      else if &n = 0 then
        &var = trim(&var) || put(0,%eval(3+(&dec>0)*(&dec+1)).&dec) ;
    %end ;
    else
      &var = trim(&var) || put(&r/&n*100,%eval(3+(&dec>0)*(&dec+1)).&dec) ;

    %* finish off string ;
    &var = trim(&var) ||
           %if %upcase(%substr(&pct,1,1))=Y %then %do ;
             '%' ||
           %end ;
           ')' ;

    %* throw out spaces following open paren ;
    do while(index(&var,'( ')) ;
      &var = tranwrd(&var,'( ',' (') ;
    end ;

  end ;
  else do ;
    &var = put(&r,&digits..)

           %* tack on denominator if specified ;
           %if %upcase(%substr(&denom,1,1))=Y %then %do ;
             || '/' || left(put(&n,&digits..))
           %end ;
           ;

  end ;

end ;

%leave:

%mend PCTTXT ;
