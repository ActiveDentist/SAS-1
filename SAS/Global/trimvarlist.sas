%macro trimvarlist(list=);

%local b x;
 %global varnamex;
 %let b=1;
 %let x = %scan(&varnames, &b);
 %do %while(%quote(&x) ~=);
 	%if %substr(&x,1,1)=%quote(_) /* %substr(&x,1,1)=0-9 */ %then %do;
		%let varnamex = %eval(cat(&x,&varnamex));
		%let b = %eval(&b+1);
		%let x = %scan(&varnames, &b);
	%end;
	%else %do;
		%let b = %eval(&b+1);
		%let x = %scan(&varnames, &b);
	%end;
 %end;
%put VARNAMEX: &varnamex;

%mend trimvarlist;
