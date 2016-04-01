%macro comp(var1,var2);
%let var1=0;
%let var2=0;
%if &var1=&var2 %then %put EQUAL;
%else %put NOT EQUAL;
%mend;
