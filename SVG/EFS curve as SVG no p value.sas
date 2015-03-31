*************************************************************************
*        CLIENT NAME:   United Therapeutics
*        PROTOCOL   :   DIV-NB-301
*       PROGRAM NAME:   F_14_2_1_1.SAS  
*	     SAS VERSION:   V9.2	
*            PURPOSE:   To Create Figure 14.2.1.1
*                       Event-Free Survival Analysis (primary analysis): ITT Population
*        USAGE NOTES:   PC SAS 
*        INPUT FILES:   ADSL, ADTTE
*       OUTPUT FILES:   F_14_2_1_1.png, F_14_2_1_1.RTF  
*
*             AUTHOR:   Jiangtang Hu
*       DATE CREATED:   02Aug2012
*
*   MODIFICATION LOG:   
* 	        Date of Last commit: $Date: 2014-07-07 15:50:36 -0400 (Mon, 07 Jul 2014) $
*	      Author of last commit: $Author: sgali $
*	                 Repository: $URL: svn+ssh://dpressley@utprodsvn.d-wise.com/programs/DIV/DIVNB301/programs/csr/F_14_2_1_1_3_EFS_NEJM.sas $
*	    Revision of last commit: $LastChangedRevision: 6706 $
*		  			        
*   
*************************************************************************
*   © 2012 United Therapeutics Corporation
*  All Rights Reserved.
*************************************************************************;

%inc "C:\sas\template\DIVNB301\F_14_2_1_1_EFS_template.sas";


%let ODSESCAPECHAR = ~;

%let execpath=" ";
%macro setexecpath;
   %let execpath=%sysfunc(GetOption(SYSIN));
   %if %length(&execpath)=0
      %then %let execpath=%sysget(SAS_EXECFILEPATH);
%mend setexecpath;
%setexecpath;
%put &execpath;

%let shortpath1=%scan(%quote(&execpath),5,"\");
%let shortpath2=%scan(%quote(&execpath),6,"\");
%let shortpath3=%scan(%quote(&execpath),7,"\");
%let shortpath4=%scan(%quote(&execpath),8,"\");
%let shortpath5=%scan(%quote(&execpath),9,"\");
%let shortpath6=%scan(%quote(&execpath),10,"\");
%let shortpath =&shortpath1\&shortpath2\&shortpath3\&shortpath4\&shortpath5\&shortpath6;
%put &shortpath;

*** set the input data path;
%DIV(prot=DIVNB301);


%macro dotable(data=, pop=, pgmname=,  titl6=, fignum=);

	libname nejm "S:\Neuroblastoma\Ch14.18\COG documents\ANBL0032 DATA TRANSFER_JUNE2009\2012_Sept_Transfer" access=readonly;

	proc sql noprint;
	   create table tte as
	   select pt_id, treat_no as trtp, stratum7, efs as cnsr,(efs_d-date_reg+1)/365.25 as aval_Y "Years since Randomization",
				   case
				       when trtp=2 then "Unituxin+RA Arm"
					   when trtp=1 then "RA Arm"
					   else ""
					   end as Group " " 
	   from nejm.survival_12jan2009
	   where stratum7 ne 1;
	quit;

	*** per Larry, censoring is reversed in NEJM data ***;
	data tte;
	  set tte;
	  usubjid=put('ANBL0032-' || put(pt_id, 6.), $char40.);

	  if cnsr=0 then cnsr=1;
	    else if cnsr=1 then cnsr=0;
	run;

	data tte;
	  merge tte(in=in1) 
	        adam.adsl(in=in2 keep=usubjid ittfl inssstag);
			by usubjid;
			if in1;
    run;


/*
	proc sql;
		create table tte as
			select a.*,b.ITTFL,a.aval/365.25 as aval_Y "Years since Randomization",
				   case
				       when b.trt01p="Immunotherapy + RA" then "Immunotherapy"
					   when b.trt01p="RA alone"           then "Standard therapy"
					   else ""
					   end as Group " "
			from      adam.adtte as a
			left join adam.adsl  as b
			on a.usubjid=b.usubjid

			where ITTFL="Y" and PARAMCD="EFS" and &pop
			;
	quit;
*/

	options nodate nonumber missing=' ' orientation=landscape;;
	ods escapechar='~' ;
	title1 j=l 'United Therapeutics Corporation' j=r 'Page ~{thispage} of ~{lastpage}';
	title2 justify=left "Protocol: ANBL0032 (Data as of 13-Jan-2009)";

	title3; 
	title4 justify=center "Figure &fignum";
	title5 justify=center 'Event-Free Survival Analysis (primary analysis): ITT Population';
	title6 j=c "&titl6. Population";

	footnote1 "___________________________________________________________________________________________________________";
	footnote2 justify=right "&shortpath   Executed: &sysdate9. &systime (&sysuserid.)";
	 
	ods listing close ;

	*ods pdf file="S:\Stat Programming\Projects\DIV\DIVNB301\output\csr\&pgmname..pdf" style=TLF  notoc;
/*	ods rtf file="S:\Stat Programming\Projects\DIV\DIVNB301\output\csr\&pgmname..rtf" style=TLF  notoc_data;*/

	proc template;
       define statgraph Stat.Lifetest.Graphics.ProductLimitSurvival;
          dynamic NStrata xName plotAtRisk plotCensored plotCL plotHW plotEP labelCL labelHW labelEP maxTime method StratumID
             classAtRisk plotBand plotTest GroupName yMin Transparency SecondTitle /*TestName pValue*/;
          BeginGraph;
             if (NSTRATA=1)
                if (EXISTS(STRATUMID))
                entrytitle " ";
             else
                entrytitle " ";
             endif;
             if (PLOTATRISK)
                entrytitle " " / textattrs=GRAPHVALUETEXT;
             endif;
             layout overlay / xaxisopts=(shortlabel=XNAME offsetmin=.05 linearopts=(viewmax=MAXTIME tickvaluelist=(0 1 2 3 4 5 6 7 8
                9 10))) yaxisopts=(label="Event-free Survival" shortlabel="Survival" linearopts=(viewmin=0 viewmax=1 tickvaluelist=(0
                .25 .5 .75 1.0)));
                if (PLOTHW=1 AND PLOTEP=0)
                   bandplot LimitUpper=HW_UCL LimitLower=HW_LCL x=TIME / modelname="Survival" fillattrs=GRAPHCONFIDENCE name="HW"
                   legendlabel=LABELHW;
                endif;
                if (PLOTHW=0 AND PLOTEP=1)
                   bandplot LimitUpper=EP_UCL LimitLower=EP_LCL x=TIME / modelname="Survival" fillattrs=GRAPHCONFIDENCE name="EP"
                   legendlabel=LABELEP;
                endif;
                if (PLOTHW=1 AND PLOTEP=1)
                   bandplot LimitUpper=HW_UCL LimitLower=HW_LCL x=TIME / modelname="Survival" fillattrs=GRAPHDATA1 datatransparency=
                   .55 name="HW" legendlabel=LABELHW;
                bandplot LimitUpper=EP_UCL LimitLower=EP_LCL x=TIME / modelname="Survival" fillattrs=GRAPHDATA2 datatransparency=.55
                   name="EP" legendlabel=LABELEP;
                endif;
                if (PLOTCL=1)
                   if (PLOTHW=1 OR PLOTEP=1)
                   bandplot LimitUpper=SDF_UCL LimitLower=SDF_LCL x=TIME / modelname="Survival" display=(outline) outlineattrs=
                   GRAPHPREDICTIONLIMITS name="CL" legendlabel=LABELCL;
                else
                   bandplot LimitUpper=SDF_UCL LimitLower=SDF_LCL x=TIME / modelname="Survival" fillattrs=GRAPHCONFIDENCE name="CL"
                   legendlabel=LABELCL;
                endif;
                endif;
                stepplot y=SURVIVAL x=TIME / name="Survival" rolename=(_tip1=ATRISK _tip2=EVENT) tip=(y x Time _tip1 _tip2)
                   legendlabel="Survival";
                if (PLOTCENSORED=1)
                   scatterplot y=CENSORED x=TIME / markerattrs=(symbol=plus) name="Censored" legendlabel="Censored";
                endif;
                if (PLOTCL=1 OR PLOTHW=1 OR PLOTEP=1)
                   discretelegend "Censored" "CL" "HW" "EP" / location=outside halign=center;
                else
                   if (PLOTCENSORED=1)
                   discretelegend "Censored" / location=inside autoalign=(topright bottomleft);
                endif;
                endif;
                if (PLOTATRISK=1)
                   innermargin / align=bottom;
                   blockplot x=TATRISK block=ATRISK / repeatedvalues=true display=(values) valuehalign=start valuefitpolicy=truncate
                      labelposition=left labelattrs=GRAPHVALUETEXT valueattrs=GRAPHDATATEXT (size=7pt) includemissingclass=false;
                endinnermargin;
                endif;
             endlayout;
             else
                entrytitle " ";
             if (EXISTS(SECONDTITLE))
                entrytitle " " / textattrs=GRAPHVALUETEXT;
             endif;
             layout overlay / xaxisopts=(shortlabel=XNAME offsetmin=.05 linearopts=(viewmax=MAXTIME tickvaluelist=(0 1 2 3 4 5 6 7 8
                9 10))) yaxisopts=(label="Event-free Survival" shortlabel="Survival" linearopts=(viewmin=0 viewmax=1 tickvaluelist=(0
                .25 .5 .75 1.0)));
                if (PLOTHW)
                   bandplot LimitUpper=HW_UCL LimitLower=HW_LCL x=TIME / group=STRATUM index=STRATUMNUM modelname="Survival"
                   datatransparency=Transparency;
                endif;
                if (PLOTEP)
                   bandplot LimitUpper=EP_UCL LimitLower=EP_LCL x=TIME / group=STRATUM index=STRATUMNUM modelname="Survival"
                   datatransparency=Transparency;
                endif;
                if (PLOTCL)
                   if (PLOTBAND)
                   bandplot LimitUpper=SDF_UCL LimitLower=SDF_LCL x=TIME / group=STRATUM index=STRATUMNUM modelname="Survival"
                   display=(outline);
                else
                   bandplot LimitUpper=SDF_UCL LimitLower=SDF_LCL x=TIME / group=STRATUM index=STRATUMNUM modelname="Survival"
                   datatransparency=Transparency;
                endif;
                endif;
                stepplot y=SURVIVAL x=TIME / group=STRATUM curvelabel=STRATUM index=STRATUMNUM name="Survival" rolename=(_tip1=ATRISK
                   _tip2=EVENT) tip=(y x Time _tip1 _tip2);
                if (PLOTCENSORED)
                   scatterplot y=CENSORED x=TIME / group=STRATUM index=STRATUMNUM markerattrs=(symbol=plus);
                endif;
                if (PLOTATRISK)
				   entry "Number of Subjects at Risk" / valign=bottom;
                   innermargin / align=bottom;
                   blockplot x=TATRISK block=ATRISK / class=STRATUM repeatedvalues=true display=(label values) valuehalign=start
                      valuefitpolicy=truncate labelposition=left labelattrs=GRAPHVALUETEXT valueattrs=GRAPHDATATEXT (size=7pt)
                      includemissingclass=false;
                endinnermargin;
                endif;
                if (PLOTCENSORED)
                   if (PLOTTEST)
                   layout gridded / rows=2 autoalign=(TOPRIGHT BOTTOMLEFT TOP BOTTOM) border=true BackgroundColor=GraphWalls:Color
                   Opaque=true;
                   entry "+ Censored";
/*                   if (PVALUE < .0001)*/
/*                      entry TESTNAME " p " eval (PUT(PVALUE, PVALUE6.4));*/
/*                   else*/
/*                      entry TESTNAME " p=" eval (PUT(PVALUE, PVALUE6.4));*/
/*                   endif;*/
                endlayout;
                else
                   layout gridded / rows=1 autoalign=(TOPRIGHT BOTTOMLEFT TOP BOTTOM) border=true BackgroundColor=GraphWalls:Color
                   Opaque=true;
                   entry "+ Censored";
                endlayout;
                endif;
                else
                   if (PLOTTEST)
                   layout gridded / rows=1 autoalign=(TOPRIGHT BOTTOMLEFT TOP BOTTOM) border=true BackgroundColor=GraphWalls:Color
                   Opaque=true;
/*                   if (PVALUE < .0001)*/
/*                      entry TESTNAME " p " eval (PUT(PVALUE, PVALUE6.4));*/
/*                   else*/
/*                      entry TESTNAME " p=" eval (PUT(PVALUE, PVALUE6.4));*/
/*                   endif;*/
                endlayout;
                endif;
                endif;
             endlayout;
             endif;
          EndGraph;
       end;
    run;

	ods html5 path='C:\Users\dpressley\Projects\DIV\DIVNB301\branches\SVG' (url=none) file='EFS_nopval.html'
                options(svg_mode='inline');

    ods graphics / outputfmt=svg;

	ods graphics on /reset=all imagename="&pgmname" ;
/*	ods html style=journal gpath="S:\Stat Programming\Projects\DIV\DIVNB301\output\csr" ;*/

	ods output SurvivalPlot=SurvivalPlot;
	ods select SurvivalPlot;
	proc lifetest data=tte   plots=survival( test atrisk=0 to 10 by 1)
	                ;
		time aval_Y*cnsr(1);
		strata Group;
		id pt_id /*usubjid*/;
	run;


	ods listing;

	ods graphics off;
	ods rtf close;
	ods html5 close;

%mend;

%dotable(data=DIVNB301, pop=%str(where ittfl='Y'), pgmname = F_14_2_1_1_3_EFS_NEJM, titl6=Randomized, fignum=14.2.1.1.3);
%*dotable(data=DIVNB301, pop=%str(where ittfl='Y' and inssstag='Stage 4' ), pgmname = F_14_2_1_2_3_EFS_NEJM_INSS4, titl6=INSS Stage 4 Randomized, fignum=14.2.1.2.3);

