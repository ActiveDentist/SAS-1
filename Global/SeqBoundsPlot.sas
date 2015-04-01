%macro SeqBoundsPlot(data=,
                     gout=,
                     xlabel=%str(Sample Size),
					 ylabel=%str(Standardized Test Statistic),
					 line_types=1 2 4 8 14 5 9 15,
					 free_axis=1,
					 free_legend=1,
					 free_symbol=1,
				     legend=_DEFAULT_,
					 legend_offset=(0pct, 0pct),
					 legend_text_size=,
                     lower=,
                     upper=) ;
%let SBP_LT0 = %words(&line_types,root=SBP_LT) ;
%let SBP_Lower0 = %words(&lower,root=SBP_Lower) ;
%let SBP_Upper0 = %words(&upper,root=SBP_Upper) ;

%local i j ;

%if &SBP_Lower0=&SBP_Upper0 %then %do ;
  %let SBP_Equal = 1 ;
  %do i = 1 %to &SBP_Lower0 ;
    %if &&SBP_Lower&i ~= &&SBP_Upper&i %then %let SBP_Equal = 0 ;
  %end ;
%end ;
%else %let SBP_Equal = 0 ;

%let legend = %upcase(&legend) ;
%if %quote(&legend)=_DEFAULT_ %then %do ;

proc sort data=&data out=SBP_plot ;
  by id look ;
  run ;

%local futility FutGamma FutLevel FutMean ;
data _null_ ;
  set SBP_plot(obs=1) ;
  %chkvar(var=futility FutGamma FutLevel FutMean,
         flag=futility_flag FutGamma_flag FutLevel_flag FutMean_flag) ;
  if futility_flag then call symput('futility','futility') ;
  else                  call symput('futility',"'_NULL_'") ;
  if FutGamma_flag then call symput('FutGamma','FutGamma') ;
  else                  call symput('FutGamma',"0") ;
  if FutLevel_flag then call symput('FutLevel','FutLevel') ;
  else                  call symput('FutLevel',"0") ;
  if FutMean_flag  then call symput('FutMean','FutMean') ;
  else                  call symput('FutMean',"0") ;
  run ;

data _null_ ;
  set SBP_plot ;
  by id ;

  %if SBP_lower0>0 %then %do ;
    array lower_id {&SBP_lower0} _temporary_ (&lower) ;
  %end ;
  %if SBP_upper0>0 %then %do ;
    array upper_id {&SBP_upper0} _temporary_ (&upper) ;
  %end ;

  length look_str lower_str upper_str $200 ;
  retain look_str ;
  if first.id then look_str = compress(put(ss,8.)) ;
  else look_str = trim(look_str) || ', ' || compress(put(ss,8.)) ;
  if last.id then do ;

    select(&futility) ;
	  when ('BETENSKY') 
        lower_str = 'f=ZAPF "Betensky''s Conditional Power [" f=GREEK "g" f=ZAPF "='
		            || compress(put(&FutGamma,best8.)) 
                    || ', " f=GREEK "g" f=ZAPF "''='
                    || compress(put(&FutLevel,best8.))
                    || ']"' ;
	  when ('STOCHCURT') 
        lower_str = 'f=ZAPF "Stochastic Curtailment [" f=GREEK "g" f=ZAPF "='
		            || compress(put(&FutGamma,best8.)) 
                    || ', " f=GREEK "u" f=ZAPF "='
                    || compress(put(&FutMean,best8.))
                    || ']"' ;
	  when ('WIEAND') 
        lower_str = 'f=ZAPF "Wieand Futility Rule"' ;
	  when ('_NULL_')
	    lower_str = ' ' ;
	  otherwise do ;
	    put 'WARNING: Unknown futility rule (' &futility ').' ;
		lower_str = 'f=ZAPF "Futility Boundary"' ;
	  end ;
	end ;

	select(aSpend) ;
	  when ('OBFL') upper_str = 'O''Brien-Fleming' ;
	  when ('POCOCK') upper_str = 'Pocock' ;
	  otherwise do ;
	    put 'WARNING: Unknown futility rule (' futility= ').' ;
		upper_str = 'Sequential Boundary' ;
	  end ;
	end ;
    upper_str = 'f=ZAPF "' || trim(upper_str) || ' [" f=GREEK "a" f=ZAPF "='
	            || compress(put(alpha,best8.))
				|| ' (' || put(sides,1.) || '-sided); n='
				|| trim(left(look_str)) || ']' ;

    if (&SBP_Equal) then do ;
	  tick = 0 ;
	  do i = 1 to &SBP_upper0 ;
	    if id=upper_id{i} then tick = i ;
	  end ;
	  if tick then do ;
	    if lower_str=' ' then
		  call symput('SBP_TICK'||compress(put(tick,3.)),
		              trim(upper_str) || '"') ;
		else
		  call symput('SBP_TICK'||compress(put(tick,3.)),
		              trim(upper_str) || ';" J=LEFT ' || trim(lower_str)) ;
	  end ;
	end ;
	else do ;
	  tick = 0 ;
	  do i = 1 to &SBP_upper0 ;
	    if id=upper_id{i} then tick = i ;
	  end ;
	  if tick then 
        call symput('SBP_TICK'||compress(put(tick,3.)),
		            trim(upper_str) || '"') ;

	  tick = 0 ;
	  do i = 1 to &SBP_lower0 ;
	    if id=lower_id{i} then tick = i ;
	  end ;
	  if tick then do ;
	    tick = tick + &SBP_upper0 ;
        call symput('SBP_TICK'||compress(put(tick,3.)),
		            trim(lower_str)) ;
	  end ;
	end ;
  end ;
  run ;

%let legend=LEGEND&free_legend ;

%if &SBP_Equal=1 %then %let j = &SBP_upper0 ;
%else                  %let j = %eval(&SBP_upper0 + &SBP_lower0) ;

&legend across=1
        frame 
        mode=PROTECT 
        position=(MIDDLE LEFT INSIDE)
		offset=&legend_offset
        label=NONE
		shape=line(5)
		value = (
				 %if %quote(&legend_text_size)~= %then %do ;
				   h=&legend_text_size
				 %end ;
                 %do i = 1 %to &j ;
                   TICK=&i &&SBP_TICK&i
		         %end ;
		        )
		;

%end ;
%else %if %index(%str(x&legend),LEGEND)~=2 & %quote(&legend)~=NONE %then %do ;
  %put WARNING: Unexpected LEGEND= so no legend will be used. ;
  %let legend = NONE ;
%end ;

proc sort data=&data
           out=SBP_plot ;
  by ss id ;
  run ;

proc sort nodupkey 
          data=SBP_plot(where=(index(" &lower &upper "," "||compress(put(id,8.))||" ")))
           out=SBP_ss ;
  by SS ;
  run ;

data _null_ ;
  set SBP_ss end=eof ;
  i + 1 ;
  call symput('SBP_SS' || compress(put(i,8.)),compress(put(ss,8.))) ;
  if eof then call symput('SBP_SS0',compress(put(i,8.))) ;
  run ;

proc summary nway data=SBP_plot(where=(index(" &lower &upper "," "||compress(put(id,8.))||" "))) ;
  var lowerZ upperZ ;
  output out=SBP_ss(keep=min max) min(lowerZ)=min max(upperZ)=max ;
  run ;

%local SBP_yorder ;
data _null_ ;
  set SBP_ss ;
  rmin = round(min,1) ;
  if rmin>min then rmin = rmin - 1 ;
  rmax = round(max,1) ;
  if rmax<max then rmax = rmax + 1 ;
  call symput('SBP_yorder',put(rmin,2.) || ' to ' || put(rmax,2.)) ;
  run ;

proc transpose data=SBP_plot out=SBP_upper(drop=_name_) prefix=upper ;
  by ss ;
  var upperZ ;
  id id ;
  run ;

proc transpose data=SBP_plot out=SBP_plot(drop=_name_) prefix=lower ;
  by ss ;
  var lowerZ ;
  id id ;
  run ;

data SBP_plot ;
  merge SBP_plot SBP_upper ;
  by ss ;
  run ;

axis&free_axis label=(a=0  r=0 "&xlabel") ;
axis%eval(&free_axis + 1) label=(a=90 r=0 "&ylabel") minor=(n=4)
                          order=(&SBP_yorder)
                          ;
axis%eval(&free_axis + 2) label=NONE value=NONE major=NONE minor=NONE
                          order=(&SBP_yorder)
                          ;

%let j = 0 ;
%do i = &free_symbol %to %eval(&free_symbol + &SBP_Upper0 - 1) ;
  %let j = %eval(&j + 1) ;
  symbol&i c=BLACK i=JOIN l=&&SBP_LT&j v=DOT h=0.5 ;
%end ;

%if &SBP_Equal=0 %then %do ;

  %do i = %eval(&free_symbol + &SBP_Upper0) %to 
          %eval(&free_symbol + &SBP_Lower0 + &SBP_Upper0 - 1) ;
    %let j = %eval(&j + 1) ;
   symbol&i c=BLACK i=JOIN l=&&SBP_LT&j v=DOT h=0.5 ;
  %end ;

%end ;

proc gplot data=SBP_plot %if %quote(&gout)~= %then %do ; gout=&gout %end ; ;
  plot %if &SBP_Equal=1 %then %do ;
		 %let j = &free_symbol ;
         %do i = 1 %to &SBP_upper0 ;
		   upper&&SBP_upper&i * SS = &j
		   %let j = %eval(&j + 1) ;
		 %end ;
       %end ;
	   %else %do ;
	     %let j = &free_symbol ;
		 %do i = 1 %to &SBP_upper0 ;
		   upper&&SBP_upper&i * SS = &j
		   %let j = %eval(&j + 1) ;
		 %end ;
		 %do i = 1 %to &SBP_lower0 ;
		   lower&&SBP_lower&i * SS = &j
		   %let j = %eval(&j + 1) ;
		 %end ;
	   %end ;
       / overlay frame haxis=axis&free_axis vaxis=axis%eval(&free_axis + 1) 
	     %if %quote(&legend)~=NONE %then %do ;
           legend=&legend
		 %end ;
         autovref cvref=GRAYA0 lvref=1 
         href=%do i = 1 %to &SBP_SS0 ; &&SBP_SS&i %end ; chref=GRAYA0 lhref=1
         ;
  %if &SBP_Equal=1 %then %do ;
    plot2 %let j = &free_symbol ;
          %do i = 1 %to &SBP_upper0 ;
		    lower&&SBP_upper&i * SS = &j
		    %let j = %eval(&j + 1) ;
		  %end ;
		  / overlay haxis=axis&free_axis vaxis=axis%eval(&free_axis + 2) ;
  %end ;
  run ;
  quit ;

proc datasets library=work nolist ;
  delete SBP_plot SBP_upper SBP_ss ;
  run ;
  quit ;

%mend SeqBoundsPlot ;