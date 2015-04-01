%macro binning(data=,
               by=,
               out=,
               binning_var=,
               response_var=,
               class=,
			   basis=,
               bin_size=10,
               median=N) ;

data &out ;
  set &data(keep=&by &binning_var &response_var &class
            where=(&binning_var + &response_var > .Z)) ;
  _sub_by_ = ranuni(-1) ;
  _ByVar_ = (&class = &basis) ;
  %if %quote(&by)= %then %do ;
    %let by = _dummy_ ;
	_dummy_ = 1 ;
  %end ;
  run ;

proc sort data=&out out=&out(drop=_sub_by_) ;
  by &by &binning_var _sub_by_ ;
  run ;

proc summary data=&out nway ;
  by &by ;
  output out=_nobs_(keep=&by _freq_ rename=(_freq_=_nobs_)) ;
  run ;

%local i lastby ;
%let i = 1 ;
%do %while(%scan(&by,&i,%str( ))~=) ;
  %let lastby = %scan(&by,&i,%str( )) ;
  %let i = %eval(&i + 1) ;
%end ;

data &out ;
  merge &out _nobs_ ;
  by &by ;
  drop _size_ _bins_ _U_ _L_ _order_ _nobs_ ;
  retain _order_ ;
  if first.&lastby then _order_ = 0 ;
  _order_ + 1 ;
  _size_ = &bin_size ;
  _bins_ = _nobs_ - _size_ + 1 ;
  _U_ = min(_order_,_bins_) ;
  _L_ = max(1,_order_ - _size_ + 1) ;
  do _bin_ = _L_ to _U_ ;
    output ;
  end ;
  run ;
  
proc sort data=&out ;
  by &by _bin_ _byvar_ ;
  run ;

proc summary data=&out ;
  by &by _bin_ ;
  class _byvar_ ;
  var &binning_var &response_var ;
  output out=_means_ mean=bin_mean mean 
         %if %upcase(%substr(&median,1,1))=Y %then %do ;
           median(&binning_var)=bin_median 
		 %end ;
         ;
  run ;

%if %upcase(%substr(&median,1,1))=Y %then %do ;
  %ranksum(data=&out,
           by=&by _bin_,
		   var=&response_var,
		   class=_byvar_,
		   basis=1,
		   out=_hl_) ;
%end ;

data &out ;
  merge _means_(keep=_type_ &by _bin_ bin_mean 
                %if %upcase(%substr(&median,1,1))=Y %then %do ;
                  bin_median
				%end ;
                where=(_type_=0))
		_means_(keep=_type_ &by _bin_ _byvar_ mean
		        where=(_type_=1 & _byvar_=1))
		_means_(keep=_type_ &by _bin_ _byvar_ mean
		        rename=(mean=mean0)
		        where=(_type_=1 & _byvar_=0))
        %if %upcase(%substr(&median,1,1))=Y %then %do ;
		  _hl_(keep=&by _bin_ _delta rename=(_delta=HL_diff))
		%end ;
		;
  by &by _bin_ ;
  drop _type_ _byvar_ mean mean0 ;
  MeanDiff = mean - mean0 ;
  run ;

%mend binning ;