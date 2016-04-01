/*
/ Program name:     TOC.SAS
/
/ Program version:  2.1
/
/ Program purpose:  Table of Contents from TITLES System
/
/                   MACPAGE and TITLES call must surround this macro.
/                   datasets=Y prints contents of data library.  Default is N
/
/
/ SAS version:      6.12 TS020
/
/ Created by:       SR Austin
/ Date:             09/06/95
/
/ Input parameters: DATSETS
/
/ Output created:
/
/ Macros called:    None
/
/ Example call:
/
/===============================================================================
/ Change Log:
/
/     MODIFIED BY: SR Austin
/     DATE:        07Nov95
/     MODID:
/     DESCRIPTION: Fixed so will accept GOLD-style protocol names.
/     -------------------------------------------------------------------
/     MODIFIED BY: Jonathan Fry
/     DATE:        10DEC1998
/     MODID:       JMF001
/     DESCRIPTION: Tested for Y2K compliance.
/                  Add %PUT statement for Macro Name and Version Number.
/                  Change Version Number to 2.1.
/     -------------------------------------------------------------------
/     MODIFIED BY:
/     DATE:
/     MODID:       XXX002
/     DESCRIPTION:
/     -------------------------------------------------------------------
/===============================================================================*/

%macro toc(datasets=N);

/*--------------------------------------------------------------------------/
/ JMF001                                                                    /
/ Display Macro Name and Version Number in LOG                              /
/--------------------------------------------------------------------------*/

   %put -------------------------------------------------;
   %put NOTE: Macro called: TOC.SAS   Version Number: 2.1;
   %put -------------------------------------------------;


   %local longest;
   proc format;
      value typesort 1='Tables'
                     2='Figures'
                     3='Appendices'
                     4='X-Appendices'
                     5='Data Preparation Programs'
                     6='Other'
                     1.25='Data Summary'
                     1.50='Exhibit' ;
   run;

   %if %length(&prot) > 3 %then %let dset=in.t&prot.;
   %else %let dset=in.title&prot.;

   data temp;length splittle $200;
      set &dset.(where=(type ne ' ')) end=eof;

      retain longtitl 0;

      if type='Table' then typesort=1;
      else if type='Data Summary' then typesort=1.25;
      else if type='Exhibit' then typesort=1.50;
      else if type='Figure' then typesort=2;
      else if type='Appendix' then typesort=3;
      else if type='Dataprep' then typesort=5;
      else typesort=6;
      if indexc(tabnum,'X') > 0 then typesort=4;

/*--------------------------------------------------------------------------/
/  Fix the sort-order so B1...Bx, C1...Cx are in proper order.              /
/--------------------------------------------------------------------------*/

      length t_1 $1;
      t_0=compress(tabnum,'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz') * 1;
      t_00= left(tabnum);
      t_1 = substr(t_00,1,1);
      t_2 = index('ABCDEFGHIJKLMNOPQRSTUVWXYZ',t_1);
      tabord= (t_2 * 1000) + t_0 ;

/*--------------------------------------------------------------------------/
/ Make titles 1 - 10 one long title with split-characters                   /
/ Title lines that would make the total exceed 200 are not included.        /
/--------------------------------------------------------------------------*/

      array _title {10} $132 title1-title10 ;
      do x=1 to 10;
         if _title{x} ne ' ' &  x=1 then splittle= left(trim(_title{x}));
         else if _title{x} ne ' ' &
            (length(trim(splittle))+length(trim(_title{x})) <199)  then
            splittle= left(trim(splittle)) !! '*' !! left(trim(_title{x}));;

         longtitl=max(longtitl,length(_title{x}));
      end;
      format typesort typesort.;

      if eof then call symput("longest",longtitl);
   run;

   proc sort data=temp out=temp;
     by typesort tabord ;
   run;

   TITLE&nextt. '#byval1';
   OPTIONS nobyline ;

   proc report data=temp headline headskip ls=132
      nowindows split='*' colwidth=8 center missing;
      by typesort;
      column tabord tabnum program splittle ;
      define tabord /order order=internal noprint;
      define tabnum / order width=8 f=$8. 'Number' center;
      define program / display f=$8. 'Program' ;
      define splittle /display flow 'Title' width=&longest.;
      break after tabord / skip ;
   run;

   %if &datasets=Y %then %do;

      proc contents data=in._ALL_ out=contout noprint ;

      data contout; set contout(keep=libname memname);
         by memname;
         if first.memname;

      TITLE&nextt. 'SAS Datasets';

      proc report data=contout headline headskip ls=132 panels=4
         nowindows split='*' colwidth=8 center missing;
         column memname libname ;
         define memname / display 'File Name' width=9;
         define libname / display 'File Type' width=9;
      run;

   %end;

   run;

%mend toc;
