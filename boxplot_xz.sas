%TDE(prot=TDEPH304);

%makefmtN(data=ids.mpl, uncoded=group, coded=groupTXT, format=trial);
/*%makefmtN(data=ids.pahmeds, uncoded=group, coded=groupTXT, format=trial);*/

proc format;
	value oral 0 = 'No New Therapy'
			   1 = 'New Therapy Added'
			   ;
run;


*// get treatment assignment and previous trial;
data trialinfo;
	set ids.mpl(in=a keep=subno group DoseA_D trt trttxt grpshtxt grouptxt where=(DoseA_D ne .));
	if a;
	format group trial.;
	if group in(3) and trt in('X') then delete;
	if group in(3) then trttxt = 'Active';
	if group in(3) then grouptxt = '200 studies';
	grouptrt = catx('+',tranwrd(grouptxt, '+', '/'), trttxt);

run;

*// get walk where window is 1 year and walktest was performed;
data getWalk;
	merge trialinfo(in=info)
		  ids.walktest(in=in keep=subno walk_D walktest window dist dist0 distc where=(window in(52) and walktest ));
	by subno;
	if in & info;

run;

*//QC: 2 subjects are de novo and 1 is missing a walk test distance for week 52;
proc sql;
	create table qc as
	select *
	from ids.walktest
	where window in(52) and walktest ;
quit;


*// merge walk with pahmeds where PAH meds were given;
*// ASSUMPTION: windowing implies subject has been on OralTRE at the time of walk;
data meds;
	merge getwalk (in=in)
		  ids.pahmeds(in=in2 keep=subno anymeds atdoseA oralmed ext1_d extL_D drugname duration where=(anymeds & ~atdoseA));
	by subno;
	if in & in2;
run;

proc sort data=meds ; by subno oralmed; run;
*// get last observation;
data meds;
	set meds;
	by subno oralmed;
	if last.subno then output;
	format oralmed oral.;
run;

proc means data=meds n median q1 q3 min max ;
	class group oralmed;
	var distc;
	output out=sumstats(where=(_type_ = 3)) n=n median=median q1=q1 q3=q3 min=min max=max stddev=stddev mean=mean ;
run;

proc sort data=meds; by oralmed; run;

/*proc boxplot data=meds;*/
/*	plot distc*oralmed = grouptrt;*/
/*run;*/

proc sgplot data=meds;
   vbox distc / category=oralmed group=grouptrt groupdisplay=cluster;
   xaxis label="Treatment";
   keylegend / title="Drug Type";
run; 

proc means noprint data=meds n median q1 q3 min max ;
	class grouptrt oralmed;
	var distc;
	output out=sumstats(where=(_type_ = 3)) n=n median=median q1=q1 q3=q3 min=min max=max stddev=stddev mean=mean ;
run;

*// transposed them to make them look like the 'Sanjay' example;
proc transpose data=sumstats out=sumstats2(drop=_label_ rename=(col1=values _name_=stats));
	by grouptrt oralmed;
	var n median q1 q3 min max stddev mean;
run;
data sumstats2;
	set sumstats2;
	by grouptrt oralmed;
	retain n;
	if first.oralmed then n=values;
run;

*---------------------XZHOU 02/22/2016------------------;
data sumstats3; 
    length num $200.;
	set sumstats2;
	by grouptrt oralmed;
	if oralmed=0 then num='n=14       n=13       n=3        n=2'; *no 200 studies+Active;
    	else if oralmed=1 then num='n=87       n=75      n=85      n=30';
run;


proc template;
  define statgraph GroupedClusterBoxNs;
    begingraph;
      entrytitle "Median 6MWD Improvement (meters) Following Treatment with Oral TRE for One Year Based on Addition of Oral Therapy";
        layout overlay/xaxisopts=(display=(ticks tickvalues))  yaxisopts=(label='Change in Walk Distance (m)' linearopts=(viewmin=-250 viewmax=300))
                       y2axisopts=(display=none);
				boxplotparm y=values x=oralmed stat=stats /spread=true 
                                                           group=grouptrt 
														   groupdisplay=cluster 
														   grouporder=ascending 
														   xaxis=x name="bp";	

               *scatterplot x=grouptrt y=oralmed /markercharacter=n group=oralmed yaxis=y2;
			   blockplot x=oralmed block=num/ display=(values) valuehalign=center valuevalign=bottom;
        discretelegend 'bp' ;
        
	  endlayout;
    endgraph;
  end;
run;
*// switching between sumstats and sumstats2 gives you both (kinda... the n's along the bottom are oriented in a weird way...)
	but it seems like you can't have them both. But it's GTL, we know there's a way... ;


*ods html5 path="C:\Users\&sysuserid\Projects\TDE\TDEPH304\branches\boxplot output" (url=none) file='Tukeys.html'
                options(svg_mode='inline') ;
title;

proc sgrender data=sumstats3(where=(grouptrt ~in('200 studies+Active'))) template=GroupedClusterBoxNs;
run;


ods html5 close;



