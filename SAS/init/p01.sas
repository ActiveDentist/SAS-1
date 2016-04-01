%macro P01(prot=,pop=mITT) ;
%if %str(&prot)=06 & %str(&pop)=120 %then %do ; 
libname in  "c:\projects\p01\&prot\120day\data" access=readonly ;
libname raw "c:\projects\p01\&prot\120day\data\raw" access=readonly ;
libname ids "c:\projects\p01\&prot\120day\data\intermed" access=readonly ;
libname out "c:\projects\p01\&prot\120day\data\intermed" ;
%end ;
%else %if %str(&prot)=06 & %str(&pop)=FSU %then %do ; 
libname in  "c:\projects\p01\&prot\FinalSafetyUpdate\data" access=readonly ;
libname raw "c:\projects\p01\&prot\FinalSafetyUpdate\data\raw" access=readonly ;
libname ids "c:\projects\p01\&prot\FinalSafetyUpdate\data\intermed" access=readonly ;
libname out "c:\projects\p01\&prot\FinalSafetyUpdate\data\intermed" ;
%end ;
%else %if %str(&prot)=06 & %str(&pop)=FC %then %do ; 
libname in  "c:\projects\p01\&prot\FinalCut\data" access=readonly ;
libname raw "c:\projects\p01\&prot\FinalCut\data\raw" access=readonly ;
libname ids "c:\projects\p01\&prot\FinalCut\data\intermed" access=readonly ;
libname out "c:\projects\p01\&prot\FinalCut\data\intermed" ;
%end ;
%else %if %index(%str( NDS MARKETING ),%str( &prot ))>0 %then %do ;
libname ids     "c:\projects\p01\&prot\data" access=readonly ;
libname out     "c:\projects\p01\&prot\data" ;
libname in03    "c:\projects\p01\03\data" access=readonly ;
libname raw03   "c:\projects\p01\03\data\raw" access=readonly ;
libname ids03   "c:\projects\p01\03\data\intermed" access=readonly ;
libname out03   "c:\projects\p01\03\data\intermed" ;
libname in0405  "c:\projects\p01\0405\data" access=readonly ;
libname raw0405 "c:\projects\p01\0405\data\raw" access=readonly ;
libname ids0405 "c:\projects\p01\0405\data\intermed" access=readonly ;
libname out0405 "c:\projects\p01\0405\data\intermed" ;
libname in06    "c:\projects\p01\06\FinalCut\data" access=readonly ;
libname raw06   "c:\projects\p01\06\FinalCut\data\raw" access=readonly ;
libname ids06   "c:\projects\p01\06\FinalCut\data\intermed" access=readonly ;
libname out06   "c:\projects\p01\06\FinalCut\data\intermed" ;
%end ;
%else %if %index(%str( OLDMARKETING ),%str( &prot ))>0 %then %do ;
libname ids     "c:\projects\p01\marketing\data" access=readonly ;
libname out     "c:\projects\p01\marketing\data" ;
libname in03    "c:\projects\p01\03\data" access=readonly ;
libname raw03   "c:\projects\p01\03\data\raw" access=readonly ;
libname ids03   "c:\projects\p01\03\data\intermed" access=readonly ;
libname out03   "c:\projects\p01\03\data\intermed" ;
libname in0405  "c:\projects\p01\0405\data" access=readonly ;
libname raw0405 "c:\projects\p01\0405\data\raw" access=readonly ;
libname ids0405 "c:\projects\p01\0405\data\intermed" access=readonly ;
libname out0405 "c:\projects\p01\0405\data\intermed" ;
libname in06    "c:\projects\p01\06\FinalSafetyUpdate\data" access=readonly ;
libname raw06   "c:\projects\p01\06\FinalSafetyUpdate\data\raw" access=readonly ;
libname ids06   "c:\projects\p01\06\FinalSafetyUpdate\data\intermed" access=readonly ;
libname out06   "c:\projects\p01\06\FinalSafetyUpdate\data\intermed" ;
%end ;
%else %do ;
libname in  "c:\projects\p01\&prot\data" access=readonly ;
libname raw "c:\projects\p01\&prot\data\raw" access=readonly ;
libname ids "c:\projects\p01\&prot\data\intermed" access=readonly ;
libname out "c:\projects\p01\&prot\data\intermed" ;
%end ;
%local i list popprot popstub ;
%global pad nextt
        head1 head2 head3 head4 head5 head6 head7 head8 head9 head10 
        ;
%let pad='                                                                    ';

/*
%if %sysfunc(exist(ids.popdefs))=0 %then
  %let pop= ;
*/
%if %index(%str( 13 14 ),%str( &prot )) %then %do ;
  %let head1 = Protocol: REM01:&prot ;
%end ;
%else %if %length(&prot)=2 & &prot~=02 %then %do ;
  %let head1=Protocol: P01:&prot ;
  %if %index(%str( pITT mITT PerProt Safety ),%str( &pop )) %then %do ;
    proc summary nway data=ids.popdefs(keep=&pop &pop._trt where=(&pop)) ;
      class &pop._trt ;
	  output out=_t_e_m_p ;
	  run ;

    data _null_ ;
      set _t_e_m_p end=eof  ;
	  retain a p 0 ;
	  if &pop._trt='A'      then a = _freq_ ;
	  else if &pop._trt='P' then p = _freq_ ;
	  if eof then do ;
	    length text $132 ;
	    select("&pop") ;
	      when ("pITT")    text = "P01:&prot pITT" ;
  		  when ("mITT")    text = "P01:&prot mITT" ;
		  when ("PerProt") text = "P01:&prot Per-Protocol" ;
		  when ("Safety")  text = "P01:&prot Safety" ;
		  otherwise ;
	    end ;
	    text = 'Population: ' || trim(text) || ' (UT-15: ' || compress(put(a,3.))
	           || ', Placebo: ' || compress(put(p,3.)) || ')' ;
	    call symput('head2',trim(text)) ;
	  end ;
	  run ;

  %end ;
  %else %if %index(%str( 120 ),%str( &pop )) %then %do ;
    %let head2 = 120 Day Safety Update (Data as of 01OCT2000) ;
  %end ;
  %else %if %index(%str( FSU ),%str( &pop )) %then %do ;
    %let head2 = Final Safety Update (Data as of 01OCT2001) ;
  %end ;
  %else %if %index(%str( FC ),%str( &pop )) %then %do ;
    %let head2 = Final Safety Data Cut (Data as of 01DEC2003) ;
  %end ;
  %else %if %upcase(&pop)=SPEC %then
    %let head2 = Population: (as specified below) ;
  %else %if %length(&pop)>0 %then
    %put WARNING: Unknown population specified (&pop). ;
%end ;
%else %if %length(&prot)=4 %then %do ;
  %let head1=United Therapeutics (NDA 21-272);
  %let head2= ;
  %if %index(%str( AC ),%str( &pop )) %then %do ;
    libname ac 'C:\Projects\P01\0405\programs\AdvisoryCommittee\data' ;
  %end ;
  %else %if %index(%str( MAA ),%str( &pop )) %then %do ;
    libname maa 'C:\Projects\P01\0405\programs\FranceMAA\data' ;
  %end ;
/*
  %let head1=Protocols: P01:%substr(&prot,1,2) and P01:%substr(&prot,3,2) ;
  %let list=pITT pITT04 pITT05 mITT mITT04 mITT05 PerProt PerProt04 PerProt05 
            Safety Safety04 Safety05 ;
  %if %index(%str( &list ),%str( &pop )) %then %do ;
    %let popprot = %substr(&pop,%eval(%length(&pop)-1),2) ;
	%if %index(%str( 04 05 ),%str( &popprot )) %then
	  %let popstub = %substr(&pop,1,%eval(%length(&pop)-2)) ;
	%else %do ;
	  %let popprot = ;
	  %let popstub = &pop ;
	%end ;

    %if %sysfunc(exist(ids.popdefs)) %then %do ;
      proc summary nway data=ids.popdefs(keep=&pop %substr(&popstub,1,4)_trt 
                                         where=(&pop)) ;
        class %substr(&popstub,1,4)_trt ;
	    output out=_t_e_m_p ;
	    run ;
	%end ;

    data _null_ ;
      %if %sysfunc(exist(ids.popdefs)) %then %do ;
        set _t_e_m_p end=eof  ;
	    retain a p 0 ;
	    if %substr(&popstub,1,4)_trt='A'      then a = _freq_ ;
	    else if %substr(&popstub,1,4)_trt='P' then p = _freq_ ;
	    if eof then do ;
	  %end ;

	  length text $132 ;
	  select("&popstub") ;
	    when ("pITT")    text = "pITT" ;
  		when ("mITT")    text = "mITT" ;
		when ("PerProt") text = "Per-Protocol" ;
		when ("Safety")  text = "Safety" ;
		otherwise ;
	  end ;
	  if "&popprot "~=" " then
	    text = "P01:&popprot " || text ;
	  else
	    text = "Combined " || text ;

      %if %sysfunc(exist(ids.popdefs)) %then %do ;
	    text = 'Population: ' || trim(text) || ' (UT-15: ' || compress(put(a,3.))
	           || ', Placebo: ' || compress(put(p,3.)) || ')' ;
	  %end ;
	  %else %do ;
	    text = 'Population: ' || trim(text) ;
	  %end ;
	    call symput('head2',trim(text)) ;
      %if %sysfunc(exist(ids.popdefs)) %then %do ;
  	  end ;
	  %end ;
	  run ;

  %end ;
  %else %if %upcase(&pop)=SPEC %then
    %let head2 = Population: (as specified below) ;
  %else %if %length(&pop)>0 %then
    %put WARNING: Unknown population specified (&pop). ;%end ;
%else %do ;
  %put WARNING: Unexpected PROT (=&prot). ;
  %goto leave ;
*/
%end ;
%else %if %length(&prot)=3 %then %do ;
  %let head1=United Therapeutics (NDA 21-272);
  %let head2= ;
%end ;

%let nextt = 1 ;
%do i = 1 %to 10 ;
  %if %length(&&head&i)>0 %then %do ;
    title&i "&&head&i" &pad &pad ;
    %let nextt = %eval(&i + 1) ;
  %end ;
%end ;

%leave:

%mend P01 ;