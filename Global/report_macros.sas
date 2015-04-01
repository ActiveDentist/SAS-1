/*
/ PROGRAM NAME: title.sas
/  Generic listing program using PROC REPORT
/
/ PROGRAM VERSION: 1.01
/
/ PROGRAM PURPOSE: Assemble components of title lines into valid title
/   statements. For use with proc report applications.
/
/
/ SAS VERSION: 6.12 (UNIX)
/
/ CREATED BY: John Henry King, from the original by Bill Stanish.
/
/ DATE: 1997
/
/ INPUT PARAMETERS: NONE, the macro uses the global macro variables 
/    title1l-title10l 
/    title1r-title10r
/    title1c-title10c
/ 
/ OUTPUT CREATED:
/
/ MACROS CALLED:
/
/ EXAMPLE CALL: %dotitle
/
/==============================================================================
/ CHANGE LOG:
/
/ MODIFIED BY: John Henry King
/ DATE: 22MAY1997
/ MODID: 
/ DESCRIPTION: This macro was rewritten to use a more efficient method of 
/   creating the titles.  The old version used %QTRIM and was very slow.
/   
/------------------------------------------------------------------------------
/ MODIFIED BY: John Henry King
/ DATE: 19AUG1997
/ MODID: JHK001
/ DESCRIPTION: Fixed bug in DEVLINE section that I caused when I convert the 
/              macro for UNIX.
/------------------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID: JHK002
/ DESCRIPTION:
/============================================================================*/

*---------------------------------------------------------------
*  Project:    Generic listing program using PROC REPORT
*  Purpose:    Assemble components of title lines into valid title
*              statements. For use with proc report applications.
*  File Name:  bio$stat_utl:[sasmacros]title.sas
*  Created by: Bill Stanish, Statistical Insight
*  Date:       January 5, 1995
*  NOTES:      For use with the generic listing program
*                bio$stat_utl:[sasmacros]report.sas
*  History:    4/19/95  wms  Fixed centering bug when #byval used
*---------------------------------------------------------------;

%*---Initialize title macro variables---;

%let lastloc  = ;      
%let lastword = ;      
%let divline  = ;   
%let lachar   = ;

%let title1l = ' ';   %let title1c = ' ';   %let title1r = ' ';   
%let title2l = ' ';   %let title2c = ' ';   %let title2r = ' ';   
%let title3l = ' ';   %let title3c = ' ';   %let title3r = ' ';   
%let title4l = ' ';   %let title4c = ' ';   %let title4r = ' ';   
%let title5l = ' ';   %let title5c = ' ';   %let title5r = ' ';   
%let title6l = ' ';   %let title6c = ' ';   %let title6r = ' ';   
%let title7l = ' ';   %let title7c = ' ';   %let title7r = ' ';   
%let title8l = ' ';   %let title8c = ' ';   %let title8r = ' ';   
%let title9l = ' ';   %let title9c = ' ';   %let title9r = ' ';   
%let title10l= ' ';   %let title10c= ' ';   %let title10r= ' ';   

/*
/ ---Define some options and macro variables---
/--------------------------------------------------------*/

%macro div;

   /*
   / ---Set up line-across character and divider line---
   /-------------------------------------------------------*/


   /*
   / JHK001
   /----------*/

   %if %upcase(&linetype) = SOLID %then %do;
      data _null_;
         lachar   = 'd0'x;
         formchar = '|----|+|---+=|-/\<>*';
         substr(formchar,2,1) = lachar;
         call symput('formchar', formchar);
         call symput('lachar'  , lachar);
         run;
      options formchar = "&formchar";
      %end;

   %else %let lachar = %str(-);

   %let divline = %str(%')%sysfunc(repeat(&lachar, &linesize-1))%str(%');
   %put NOTE: divline=&divline;

   /*
   / ---Set up byline option, linesize, and pagesize---
   /-------------------------------------------------------------*/

   %let byln = %upcase(&bylines);
   %if &byln = SUPPRESS or &byln = SUPRESS %then %do;
      %if &sysver = 6.07 %then %do;  %* Because of a bug in SAS 6.07;
         %let newps = %eval(&pagesize+2);
         options noovp nodate nonumber ls=&linesize ps=&newps nobyline;
         %end;
      %else %do;
         options noovp nodate nonumber ls=&linesize ps=&pagesize nobyline;
         %end;
      %end;
   %else %do;
      options noovp nodate nonumber ls=&linesize ps=&pagesize byline;
      %end;
   %mend div;

%div;


/* 
/ ---The title macro---
/---------------------------------*/
%macro dotitles;


   %if &sysver >= 6.12 %then %do;
      /*
      / Construct the titles
      /------------------------*/

      data _null_;

         length emsg $6;
         emsg = reverse(':RORRE');

         array title[10] $&linesize _temporary_;

         %unquote(array tl[10] $&linesize _temporary_ 
            ( &title1l , &title2l , &title3l , &title4l , &title5l ,
              &title6l , &title7l , &title8l , &title9l , &title10l );)

         %unquote(array tr[10] $&linesize _temporary_ 
            ( &title1r , &title2r , &title3r , &title4r , &title5r ,
              &title6r , &title7r , &title8r , &title9r , &title10r );)

         %unquote(array tc[10] $&linesize _temporary_ 
            ( &title1c , &title2c , &title3c , &title4c , &title5c ,
              &title6c , &title7c , &title8c , &title9c , &title10c );)



         do i = 1 to dim(title);
            bvalflag = 0;

            /*
            / check for use of #BY and issue error message if there is 
            / a problem
            /-----------------------------------------------------------*/

            if index(upcase(tr[i]),'#BY') then do;
               put emsg 'Title lines containing BY values may be formed from'
                        ' the left or center component, but not the right component.';
               end;

            if ((index(upcase(tl[i]),'#BY')>0) + (index(upcase(tc[i]),'#BY')>0)) > 1 then do;
               put emsg 'Title lines containing BY values may have '
                        'only one component: left or center.  You have specified '
                        '> 1 components for title' i;
               end;

            if tl[i] > ' ' then title[i] = tl[i];

            if tc[i] > ' ' then do;
               if index(upcase(tc[i]),'#BY') then bvalflag = 1;
               substr
                  (
                     title[i],
                     floor( (&linesize-length(tc[i]) ) / 2 ),
                     length(tc[i])
                  ) = tc[i];
               end;

            if tr[i] > ' ' then do;
               substr
                  (
                     title[i],
                     &linesize - length(tr[i]) + 1,
                     length(tr[i])
                  ) = tr[i];
               end;
   


            if title[i] > ' ' then do;
               if bvalflag then do;
                  call 
                     execute
                        (
                           'TITLE'||trim(left(put(i,2.)))
                           ||
                           ' "'
                           ||
                           trim(left(title[i]))
                           ||
                           '";'
                        );
                  end;
               else do;
                  call 
                     execute
                        (
                           'TITLE'||trim(left(put(i,2.)))
                           ||
                           ' "'
                           ||
                           title[i]
                           ||
                           '";'
                        );
                  end;
               end;
            end; 
         run;

      %end;
   %else %do;
      %put ERROR: this version of dotitles is only for SAS 6.12 or higher.;
      %end;

   %mend dotitles;

/*
/ PROGRAM NAME: footnote.sas, 
/  Generic listing program using PROC REPORT
/
/ PROGRAM VERSION: 1.01
/
/ PROGRAM PURPOSE: Left-justify the footnote lines, preserving leading
/  blanks. For use with proc report applications.
/
/ SAS VERSION: 6.12 (UNIX)
/
/ CREATED BY: John Henry King, from the original by Bill Stanish.
/
/ DATE: 1997
/
/ INPUT PARAMETERS: NONE, the macro uses the global macro variables 
/    foot1-foot10 to create left justified footnotes.
/ 
/ OUTPUT CREATED:
/
/ MACROS CALLED:
/
/ EXAMPLE CALL: %footnote
/
/==============================================================================
/ CHANGE LOG:
/
/ MODIFIED BY: John Henry King
/ DATE: 22MAY1997
/ MODID: 
/ DESCRIPTION: This macro was rewritten to use a more efficient method of 
/   creating the titles.  The old version used %QTRIM and was very slow.
/   
/------------------------------------------------------------------------------
/ MODIFIED BY: 
/ DATE: 
/ MODID: JHK001
/ DESCRIPTION: 
/------------------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID: JHK002
/ DESCRIPTION:
/============================================================================*/

*---------------------------------------------------------------
*  Project:    Generic listing program using PROC REPORT
*  Purpose:    Left-justify the footnote lines, preserving leading
*              blanks. For use with proc report applications.
*  File Name:  bio$stat_utl:[sasmacros]footnote.sas
*  Created by: Bill Stanish, Statistical Insight
*  Date:       January 5, 1995
*  NOTES:      For use with the generic listing program
*                bio$stat_utl:[sasmacros]report.sas
*---------------------------------------------------------------;

/*
/ ---Initialize foot macro variables---
/--------------------------------------------*/

%let foot1 = ' ';   %let foot6 = ' ';
%let foot2 = ' ';   %let foot7 = ' ';
%let foot3 = ' ';   %let foot8 = ' ';
%let foot4 = ' ';   %let foot9 = ' ';
%let foot5 = ' ';   %let foot10= ' ';

/*
/ ---Define the footnote lines---
/--------------------------------------------*/

%macro footnote;

   %if &sysver >= 6.12 %then %do;

      data _null_;
         %unquote(array foot[10] $&linesize _temporary_
                     ( &foot1 , &foot2 , &foot3 , &foot4 , &foot5 ,
                       &foot6 , &foot7 , &foot8 , &foot9 , &foot10 );)

         do i = 1 to dim(foot);
            if foot[i] > ' ' then do;
               call 
                  execute
                     (
                        'FOOTNOTE'||trim(left(put(i,2.)))
                        ||
                        ' "'
                        ||
                        foot[i]
                        ||
                        '";'
                     );
               end;
            end;
         run;
     %end;
   %else %do;
      %put ERROR: this macro is for SAS 6.12 or higher.;
      %end;
   %mend footnote;

/*
/ PROGRAM NAME: page2.sas
/  Generic listing program using PROC REPORT
/
/ PROGRAM VERSION: 1.01
/
/ PROGRAM PURPOSE: Read a data listing from temporary file, insert  
/   page numbers and total number of pages.          
/   Write to permanent file.                         
/
/ SAS VERSION: 6.12 (UNIX)
/
/ CREATED BY: Bill Stanish.
/
/ DATE: 1995
/
/ INPUT PARAMETERS: NONE, the macro uses the global macro variables 
/    foot1-foot10 to create left justified footnotes.
/ 
/ OUTPUT CREATED: Writes to &outfile the contents of temp&time with the pages
/   numbered. 
/
/ MACROS CALLED: none
/
/ EXAMPLE CALL: %page2
/
/==============================================================================
/ CHANGE LOG:
/
/ MODIFIED BY: John Henry King
/ DATE: 22MAY1997
/ MODID: 
/ DESCRIPTION: Modified for use on UNIX.
/   
/------------------------------------------------------------------------------
/ MODIFIED BY: 
/ DATE: 
/ MODID: JHK001
/ DESCRIPTION: 
/------------------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID: JHK002
/ DESCRIPTION:
/============================================================================*/

/*---------------------------------------------------------------
*  Project:    Generic listing program using PROC REPORT
*  Purpose:    Read a data listing from temporary file, insert
*              page numbers and total number of pages.
*              Write to permanent file.
*  File Name:  bio$stat_utl:[sasmacros]page2.sas
*  Created by: Bill Stanish, Statistical Insight
*  Date:       January 5, 1995
*  NOTES:      For use with the generic listing program
*                bio$stat_utl:[sasmacros]report.sas
*---------------------------------------------------------------*/

/*
/ ---Initialize global variable outside of macro---
/---------------------------------------------------------*/
%let page = ;

/*
/ Macro that reads in an appendix, inserts page numbers  
/ and the total number of pages.                         
/---------------------------------------------------------------*/

%macro page2;

   /*
   / ---Compute number of pages in the file---
   /-----------------------------------------------*/

   data _null_;
      infile "temp&time" length=len missover end=lastrec;
      input;
      retain nrec 0;  


      nrec = nrec + 1;
      if lastrec then do;
         numpage = ceil(nrec / &pagesize);
         call symput('numpage', trim(left(put(numpage,6.))));
         end;
      run;

   /*
   / ---Fill in the page number info---
   /--------------------------------------------------------*/

   data _null_;
      file   "&outfile"  notitles noprint ll=ll n=ps;
      infile "temp&time" length=len missover end=lastrec;

      input line $varying200. len @1 @;
      length string $ 20;
      retain pg firstlin 0;

      /*
      / ---Insert page numbers at top of each page---
      / '0c'x  vms new page character 
      / ascii 12 or hex '0c' is the UNIX new page character.
      /-----------------------------------------------------*/
      if substr(line,1,1) = byte(12) then do;  
         firstlin = 1;
         end;

      ind = index(line, 'Page of');
      rp  = index(line, 'Page of)');

      if ind then do;
         pg + 1;
         if rp 
            then string = "Page " || trim(left(put(pg,4.))) || " of &numpage)";
            else string = "Page " || trim(left(put(pg,4.))) || " of &numpage";
         j = length(string);
         substr(line,ind,j) = string;
         end;
   
      put @1 line $varying200. len;
      run;

   /*
   / ---Delete the temporary file---
   /---------------------------------------------*/

   data _null_; 
      rc  = filename('_temp_',"temp&time"); 
      rc  = fdelete('_temp_'); 
      run;


   /*
   / ---Reset titles and footnotes to blank---
   /---------------------------------------------*/
   title ' ';
   footnote ' ';

   %mend page2;
