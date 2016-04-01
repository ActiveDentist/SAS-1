%macro MakeFmtN(uncoded=,
                coded=,
				        format=,
			          data=,
			          lib=WORK,
			          tmproot=_MFN_) ;
%let _MFN_UNCODED0 = %words(&uncoded,root=_MFN_UNCODED) ;
%let _MFN_CODED0   = %words(&coded,  root=_MFN_CODED) ;
%let _MFN_FORMAT0  = %words(&format, root=_MFN_FORMAT) ;

%if (&_MFN_UNCODED0 ~= &_MFN_CODED0) | (&_MFN_CODED0 ~= &_MFN_FORMAT0) %then %do ;
  %put WARNING: Must specify same number of UNCODED=, CODED=, and FORMAT=. ;
  %goto leave ;
%end ;
%if %quote(&data)= %then %do ;
  %put WARNING: Must specify DATA=. ;
  %goto leave ;
%end ;

%local i ;
%do i = 1 %to &_MFN_UNCODED0 ;
proc sort data=&data(keep=&&_MFN_UNCODED&i &&_MFN_CODED&i)
          out=&tmproot.&&_MFN_FORMAT&i nodupkey ;
  by &&_MFN_UNCODED&i ;
  run ;
%end ;

data &tmproot ;
  length fmtname $8 type $1 start 8 end 8 label $132 ;
  set %do i = 1 %to &_MFN_UNCODED0 ;
        &tmproot.&&_MFN_FORMAT&i (
		                          in=&&_MFN_FORMAT&i
								  rename=(
								          &&_MFN_UNCODED&i = start
										      &&_MFN_CODED&i   = label
								         )
		                         ) 
      %end ;
	  ;
  select ;
    %do i = 1 %to &_MFN_UNCODED0 ;
	  when(&&_MFN_FORMAT&i) fmtname = "%upcase(&&_MFN_FORMAT&i)" ;
	%end ;
	otherwise put 'WARNING: Fix logic.' / _all_ / ;
  end ;
  type = 'N' ;
  end = start ;
  run ;

proc format lib=&lib cntlin=&tmproot ;
  run ;

%if %upcase(&tmproot)=_MFN_ %then %do;

proc datasets library=work nolist ;
  delete _MFN_ 
         %do i = 1 %to &_MFN_UNCODED0 ;
		   _MFN_&&_MFN_FORMAT&i
		 %end ;
		 ;
              
  run ;

%end ;
      
%leave:

%mend MakeFmtN ;