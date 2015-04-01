*************************************************************
*	Program: REVIVE
*	Purpose: Takes the project name as an argument with no
*			 spaces or hyphens in the name (i.e.- TDEPH106)
*			 and creates:
*					1) libname pointer for raw and intermediate
*					   datasets
*					2) libname pointer for user defined formats
*					3) local macro variables:
*						a. i
*						b. list
*					4) global variables:
*						a. pad
*						b. nextt
*						c. head1-head10
***************************************************************	;				


%macro REVIVE(prot=);

libname in  "c:\projects\TDE\&prot\data" access=readonly ;
libname raw "c:\projects\TDE\&prot\data\raw" access=readonly ;
libname ids "c:\projects\TDE\&prot\data\intermed" access=readonly ;
libname out "c:\projects\TDE\&prot\data\intermed" ;
libname TDEfmt "c:\projects\TDE\&prot\formats" ;

filename trt "c:\projects\TDE\&prot\data\raw\&prot._trt.xls" ;

options fmtsearch=(TDEfmt utilfmt) ;


%set_init_directory ;

%local i list ;
%global pad nextt
        head1 head2 head3 head4 head5 head6 head7 head8 head9 head10 
        ;
***********************************************************
*	define a macro variable:
*		pad - a series of 69 blank spaces
***********************************************************;
%let pad='                                                                    ';
************************************************************
*	create macro variable: head1
*	fxn: i.e.-prints "Protocol: TDE-PH-105"
*	NOTE: head1 is the only head that has value to it, and
*	therefore the only head in the symbol table with a value 
************************************************************;
%let head1=Protocol: REVIVE ;
%put 'Head 1 is:' &head1;
%put 'Head 2 is:' &head2;
%put 'Head 3 is:' &head3;
%put 'Head 4 is:' &head4;
%put 'Head 5 is:' &head5;
%put 'Head 6 is:' &head6;
%put 'Head 7 is:' &head7;
%put 'Head 8 is:' &head8;
%put 'Head 9 is:' &head9;
%put 'Head 10 is:' &head10;



*************************************************************
*	not entirely sure what this is used for. Ask Carl.
************************************************************;
%if &prot=REVIVE %then %let head2=(TESTDATA) ;
*************************************************************
*	Purpose: Create global macro variables which contain the 
*	string i.e. - "Protocol: TDE-PH-105"
*
*	create macro variable "nextt". Assign one to it.
*	loop from 1 to 10 (same as number of heads that were created)
*	if length of head is positive, create titles from head variables
*	concatenated by loop iterations
*
*	NOTE: head1 is the only head that has value to it, and
*	therefore the only head in the symbol table with a value 
*
*************************************************************;

%*put _global_;
%let nextt = 1 ;
%do i = 1 %to 10 ;
  %if %length(&&head&i)>0 %then %do ;
    title&i "&&head&i" &pad &pad ;
    %let nextt = %eval(&i + 1) ;
  %end ;
%end ;


%leave:

%mend REVIVE ;
