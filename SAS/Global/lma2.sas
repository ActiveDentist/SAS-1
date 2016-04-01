%macro lma2(prot=,         /* Protocol (e.g., b2001) -- REQUIRED              */
            pop=ALL,       /* Population definition (NONE, SPEC, ALL or PREF) */
            numvar=_DEFAULT_, /* Table numbering variable in titles system       */
            _ls=132,       /* SAS linesize= option value                      */
            _ps=60,        /* SAS pagesize= option value                      */
            _skip=0) ;     /* SAS skip= option value                          */

%*******************************************************************************
*
*   STUDY: L-NMMA (546C88)
* PURPOSE: Project Initialization Macro
*  AUTHOR: Carl P. Arneson
*    DATE: 21 Apr 1997
*
*******************************************************************************;

%*  fix since %JOBINFO is broken in autoexec.sas ;
%jkfn ;

%* Make sure a protocol is specified ;
%if %quote(&prot)= %then %do ;
  %put WARNING: (LMA2) PROT= must be specified (can be NONE). ;
  %goto leave ;
%end ;

%* Establish global and local variables ;
%local i j popstr date dsid ;
%global __lma2__ pad head1 head2 type num toc tmtvar tmtval tmtfmt
        _GTFONT_ _GTHT_ ;

%* Don't bother with this stuff if the protocol hasn't changed ;
%if &__lma2__~=%upcase(&prot) %then %do ;

  %* set the default graphics font and height for titles system ;
  %let _GTFONT_ = ZAPF ;
  %let _GTHT_   = 0.6  ;

  %* set some global variables ;
  %let pad='                                                                    ';
  %if %upcase(&prot)=B2001 %then %do ;
    %let tmtvar=trtgrp ;
    %let tmtval='1' ;
    %let tmtfmt=$trtgrp ;
  %end ;
  %else %if %upcase(&prot)=B3001 %then %do ;
    %let tmtvar=tmt ;
    %let tmtval='A' ;
    %let tmtfmt=$dsmbtmt ;
  %end ;

  %*  Define LIBREFs ;
  libname lma2fmt   "&projdir/lma2/utility/formats" ;
  libname utilfmt   "/usr/local/medstat/sas/formats" ;
  libname template  "&projdir/lma2/utility/template" ;
  %if %upcase(&prot)~=NONE %then %do ;
    libname raw       "&projdir/lma2/&prot/data/raw/" ;
    libname in        "&projdir/lma2/&prot/data" ;
    libname out       "&projdir/lma2/&prot/data/intermed" ;
    libname ids       "&projdir/lma2/&prot/data/intermed" ;
  %end ;

  %* Set up hex character macro variables ;
  %hexit ;

%end ;

%*  Set SAS options  ;
options nodate nonumber ls=&_ls skip=&_skip pagesize=&_ps missing=' '
        /* formchar='B3C4DAC2BFC3C5B4C0C1D92B3D7C2D2F5C3C3E2A'X */
        %sasautos(proj=lma2) fmtsearch=(lma2fmt utilfmt) ;

%*  Find the date of the current data and establish population info  ;
%if %upcase(&prot)~=NONE %then %do ;

  %* Set date based on the latest DEMOG data retrieved ;
  %let date=??????? ;
  %if %sysfunc(exist(raw.demog)) %then %do ;
    %let dsid = %sysfunc(open(raw.demog)) ;
    %let date = %substr(%sysfunc(attrn(&dsid,CRDTE),datetime13.),1,7) ;
  %end ;
  %* In 901, no DEMOG, so use SUMMARY ;
  %else %if %sysfunc(exist(raw.summary)) %then %do ;
    %let dsid = %sysfunc(open(raw.summary)) ;
    %let date = %substr(%sysfunc(attrn(&dsid,CRDTE),datetime13.),1,7) ;
  %end ;

  %* Determine population ;
  %let pop = %upcase(&pop) ;
  %let popstr=??????? ;
  %if %upcase(&pop)=ALL %then
    %let popstr = %str(All Patients) ;
  %else %if %upcase(&pop)=BEYOND72 %then
    %let popstr = %str(All Patients Receiving Drug Past 72 Hours, Stage 1 and Stage 2 Combined) ;
  %else %if &pop=DSMB1A %then
    %let popstr = %str(All Stage 1 Patients) ;
  %else %if &pop=DSMB1B %then
    %let popstr = %str(Stage 1 Patients Receiving Drug Past 72 Hours) ;
  %else %if &pop=DSMB2 %then
    %let popstr = %str(All Stage 2 Patients) ;
  %else %if &pop=PREF %then
    %let popstr = %str(Preferred, As Treated) ;
  %else %if &pop=SPEC %then
    %let popstr = %str((As specified below));
  %else %if &pop=INTENT %then
    %let popstr = %str(All Patients, Intent-to-Treat);
  %else %if &pop=776 %then
    %let popstr = %str(Intent-to-Treat (ENL+5-FU: XX; Gemcitabine: XX)) ;
  %else %if &pop=NONE %then
    %let popstr = ;
  %else
    %put WARNING: (LMA2INIT) Unknown population information ;

  %* Find population size and put into format and labels ;
  %if %index(%str( SPEC NONE ),%str( &pop ))=0 %then %do ;

    %*pop_n(data=ids.mpl,
           pop=&pop,
           tmtvar=&tmtvar,
           tmtfmt=&tmtfmt) ;
  %end ;

%end ;

%* Define header titles ;
%if %upcase(&prot)=NONE %then %do ;
  %let head1 = L-NMMA (546C88) ;
  %let head2 = NOS Inhibitor for the Treatment of Septic Shock ;
%end ;
%else %if %upcase(&pop)=776 %then %do ;
  %let head1 = Protocol: FUMA3007 ;
  %let head2 = Population: &popstr ;
%end ;
%else %do ;
  %let head1 = Protocol: LMA%upcase(&prot);
  %if %quote(&popstr)~= %then
    %let head2 = Population: &popstr ;
  %if %quote(&date)~= %then %do ;
    %let date=(Data as of: &date) ;
    %let i = %eval(&_ls - %length(&date) - %length(&head1) - 1) ;
    %let head1 = &head1%sysfunc(repeat(%str( ),&i))&date ;
  %end ;
%end ;

title1 "&head1" &pad &pad ;
%if "&head2"~="" %then %do ;
  title2 "&head2" &pad &pad ;
%end ;

%* Initialize titles system as long as titles data set exists ;
%if %upcase(&prot)~=NONE & %sysfunc(exist(in.t&prot))
     & &__lma2__~=%upcase(&prot) %then %do ;

  %if &numvar=_DEFAULT_ %then %do ;
    %let numvar = TABNUM ;
  %end ;

  %settitle(fn=%fn,dset=in.t&prot,number=&numvar) ;

%end ;

%* update the last execution protocol global variable ;
%let __lma2__ = %upcase(&prot) ;

%leave:

%mend lma2 ;
