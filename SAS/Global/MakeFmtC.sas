%macro MakeFmtC(uncoded=,
                coded=,
				        format=,
			          data=,
                codelen=16,
                labellen=132,
			          lib=WORK,
			          tmproot=_MFC_) ;
%let _MFC_UNCODED0 = %words(&uncoded,root=_MFC_UNCODED) ;
%let _MFC_CODED0   = %words(&coded,  root=_MFC_CODED) ;
%let _MFC_FORMAT0  = %words(&format, root=_MFC_FORMAT) ;

%if (&_MFC_UNCODED0 ~= &_MFC_CODED0) | (&_MFC_CODED0 ~= &_MFC_FORMAT0) %then %do ;
  %put WARNING: Must specify same number of UNCODED=, CODED=, and FORMAT=. ;
  %goto leave ;
%end ;
%if %quote(&data)= %then %do ;
  %put WARNING: Must specify DATA=. ;
  %goto leave ;
%end ;

%local i ;
%do i = 1 %to &_MFC_UNCODED0 ;
proc sort data=&data(keep=&&_MFC_UNCODED&i &&_MFC_CODED&i)
          out=&tmproot.&&_MFC_FORMAT&i nodupkey ;
  by &&_MFC_UNCODED&i ;
  run ;
%end ;

data &tmproot ;
  length fmtname $8 type $1 start $&codelen end $&codelen label $&labellen ;
  set %do i = 1 %to &_MFC_UNCODED0 ;
        &tmproot.&&_MFC_FORMAT&i (
		                          in=&&_MFC_FORMAT&i
								  rename=(
								          &&_MFC_UNCODED&i = start
										  &&_MFC_CODED&i   = label
								         )
		                         ) 
      %end ;
	  ;
  select ;
    %do i = 1 %to &_MFC_UNCODED0 ;
	  when(&&_MFC_FORMAT&i) fmtname = "%upcase(&&_MFC_FORMAT&i)" ;
	%end ;
	otherwise put 'WARNING: Fix logic.' / _all_ / ;
  end ;
  type = 'C' ;
  end = start ;
  run ;

proc format lib=&lib cntlin=&tmproot ;
  run ;

%if %upcase(&tmproot)=_MFC_ %then %do;

proc datasets library=work nolist ;
  delete _MFC_ 
         %do i = 1 %to &_MFC_UNCODED0 ;
		   _MFC_&&_MFC_FORMAT&i
		 %end ;
		 ;
              
  run ;

%end ;
      
%leave:

%mend MakeFmtC ;