*********************************************************************************
*	countlevels macro				   										 	*
*																			 	*
*	Purpose: provide a counter for the number of variables in a dataset that	*
*			 are relevant to the sumtab_ODS macro. These counters will be 		*
*			 used to determine the appropriate number of sumtab "boxes" that	* 
*			 can be adequately displayed in the ods pdf system					*
*																				*
*	Use: To be used within sumtab_ODS, using the sumtab_ODS arguments			*
*			data, by, & pageby													*
*			NOte: For sumtab_ODS, by= corresponds to the number of lab tests	*
*				  which is the macro variable: nlabtests						*
********************************************************************************;

%macro countlevels(data, stats, by, pageby);
options nomprint nomlogic nosymbolgen;

*declare global vars and initialize to 1;
%global nvariable;
%let nvariable = 1;
%global labtests;
%global nlabtests;
%let nlabtests=1;


*sort data to determine the number of unique categories in labtst variable;
proc sort data =&data out=uniqby nodupkey;
	by  labtst;
run;

*put count of distinct labtests into variable nlabtests
 and put each individual labtest into variable labtests;
proc sql noprint; 
	select distinct count(*), labtst into :nlabtests, :labtests
	separated by ','
	from uniqby;
	%put Number of "by" variables is: &nlabtests;
	%put LABTESTS: &labtests;
quit;

/*%WORDS(&labtests,root=w,delm=,);*/

*create a macro array that contains the number of labtests
 in the first element, and the names of the labtests in the 
 remaining elements;
%let i=1;
%let LTST0 = &nlabtests;
%do i=1 %to &nlabtests;
	%let LTST&i = %trim(%qscan(%quote(&labtests),&i,%str(,)));
	%put LABTEST: &&LTST&i;
%end;

*count the number of characters in each array element.Assign to 
the variable lenlt;
%global lenlt;
%let lenlt = 0;
%let ctmp = 0;
%do j=1 %to &LTST0;
	%let ctmp = %length(&&LTST&j);
	%put LABTST: &&LTST&j;
	%put CTMP: &ctmp;
	%if &lenlt < &ctmp %then %do;
		%let lenlt = &ctmp;
	%end;
	
%end;
%put LENLT: &lenlt;




*number of stats computed. This will be necessary to determine
 how many rows in the output, or how "high" each individual 
 output block will be;
%let cnt1 = 0 ;
%let cnt2 = 1 ;
%let piece = %qscan(&stats,&cnt2,%str( )) ;
%do %while(&piece~=) ;
  %if %substr(&piece,1,1)~={ %then %do ;
    %let cnt1 = %eval(&cnt1 + 1) ;
    %local stat&cnt1 stat2&cnt1 statadj&cnt1;
    %let statadj&cnt1 = 0 ;
    %let stat&cnt1 = %upcase(&piece) ;
    %if %length(&&stat&cnt1)>=7 %then
      %let stat2&cnt1 = %substr(&&stat&cnt1,1,6) ;
    %else %let stat2&cnt1 = &&stat&cnt1 ;
  %end ;
  %else %do ;
    %local statadj&cnt1 ;
    %let statadj&cnt1 = %upcase(%substr(&piece,2,%eval(%length(&piece)-2))) ;
  %end ;
  %let cnt2 = %eval(&cnt2 + 1) ;
  %let piece = %qscan(&stats,&cnt2,%str( )) ;
%end ;
%local nstat ;
%let nstat = &cnt1 ;

%if &nstat>9 %then
  %put WARNING: More than 9 summary statistics specified with STATS=. ;



*pageby variable count determination;
%local lstpby npby ;
%let lstpby= ;
%let cnt1=1 ;
%let piece=%scan(&pageby,&cnt1,%str( )) ;
%put PIECE: &piece;

%do %while(%quote(&piece)~=) ;
  %local pby&cnt1 lpby&cnt1 ;
  %let pby&cnt1=%upcase(&piece) ;
  %put PBYCNT1: &&pby&cnt1;

  %let lstpby=&piece ;
  %let cnt1=%eval(&cnt1+1) ;
  %let piece=%scan(&pageby,&cnt1,%str( )) ;
%end ;
%let npby=%eval(&cnt1-1) ;

********
TEST
********;
%put NPBY: &npby;
%put CNT1: &cnt1;
/*%put NPBY: &npby;*/








*validation output;
/*%put Local Variables: ;*/
/*%put _local_;*/
/*%put NLABTESTS: &nlabtests;*/
/*%put NPBYCATS: &npbycats;*/


%mend;

