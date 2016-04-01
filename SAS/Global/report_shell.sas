options noovp mprint;
/*--------------------------------------------------------------------
*  Project:
*  Purpose:
*  File Name:
*  Created by:
*  Date:
*  -----------------------------------------------------
*  Original File Information
*  Purpose:    Generic listing program using PROC REPORT
*  File Name:  bio$stat_utl:[sasmacros]report.sas
*  Created by: Bill Stanish, Statistical Insight
*  Date:       January 5, 1995
*-------------------------------------------------------------------*/

/*-------------------------------------------------------------------*
*  Specify a name to identify the output file.                       *
*                                                                    *
*  Examples: %let outfile = demog.l08;                               *
*            %let outfile = bio$stat_ran:[ranXXX.appendices]aa.l08;  *
*-------------------------------------------------------------------*/
%let outfile = report_shell.l08;

/*-------------------------------------------------------------------*
*  Specify the linesize and pagesize.                                *
*                                                                    *
*  Example: For landscape orientation, point size 8, use             *
*           %let linesize = 135;   %let pagesize = 43;               *
*                                                                    *
*  NOTE: Do not specify linesize or pagesize in an options           *
*        statement. This is done in one of the macros.               *
*-------------------------------------------------------------------*/
%let linesize = 135;
%let pagesize =  43;

/*-------------------------------------------------------------------*
*  Specify the type of line that should be used to separate header   *
*  lines from data lines, data lines from footnote lines, etc.       *
*  The default is dashed lines.                                      *
*                                                                    *
*  Examples: %let linetype = solid;    * To use solid lines;         *
*            %let linetype = dashed;   * To use dashed lines;        *
*                                                                    *
*  NOTE: To have these                                               *
*  lines appear ...             Specify                              *
*  --------------------------   -----------------------------------  *
*  below the page headers       &divline as the last title line      *
*                                                                    *
*  between the column headers   the HEADLINE option on the PROC      *
*    and the data lines           REPORT statement                   *
*                                                                    *
*  above the footnotes          &divline as the first footnote line  *
*-------------------------------------------------------------------*/
%let linetype = dashed;
%let linetype = solid;

/*-------------------------------------------------------------------*
*  Indicate whether the bylines (if any) should be suppressed.       *
*                                                                    *
*  Statement                 Meaning                                 *
*  ------------------------  ------------------------------------    *
*  %let bylines = ;          1. No BY statement will be used in      *
*                               the PROC REPORT step,  or            *
*                            2. Print the usual bylines generated    *
*                               by the procedure.                    *
*                                                                    *
*  %let bylines = suppress;  The usual bylines will be suppressed.   *
*                            Choose this if you prefer to print the  *
*                            by-values in the title lines. See the   *
*                            title instructions below for details.   *
*                                                                    *
*  NOTE: If the value of this macro variable is set incorrectly,     *
*        it may result in the wrong pagesize for the output file.    *
*-------------------------------------------------------------------*/
%let bylines = suppress;


*================ Custom Data Preparation Step ====================;

*---Print numeric missing values as '*'---;
options missing='*' nonumber;

*---Define libnames as needed---;
libname sasdata xport '../ran492/ran492.xpt';



*---Get the data, and sort it---;
data work;
  set sasdata.cmed;

  *---Restrict population for this example so output file is small---;
  if substr(patient,3,1) = '2';

  *---Create some new variables---;
  if medpre  ^= ' ' then dstart = 'Pre-trial';  else dstart = medstdt;
  if medpost ^= ' ' then dstop  = 'Post-trial'; else dstop  = medspdt;

  *---Print character missing values as '*'---;
  if meddos = ' ' then meddos = '*';
  if medut  = ' ' then medut  = '*';
  if medfq  = ' ' then medfq  = '*';
  if medrt  = ' ' then medrt  = '*';
  if dstart = ' ' then dstart = '*';
  if dstop  = ' ' then dstop  = '*';
run;
proc sort; by l_tmt invcd patient visit; run;


*============= Title and Footnote Preparation Step =============;

*------------------Include the needed macros------------------;

%inc 'report_macros.sas'; 

/*------------------------------------------------------------------*
*                       Set up titles                               *
*                                                                   *
*  You can specify up to 10 title lines by specifying text strings  *
*  that will be either left-justified, centered, or right-justified *
*  on the indicated lines.                                          *
*                                                                   *
*  To left-justify    Use macro variable names that end in 'l'.     *
*  some text on ..    For example, ...                              *
*  ---------------   ---------------------------------------------  *
*      Line 1        %let title1l = 'Protocol RAN-123';             *
*      Line 2        %let title2l = 'Ranitidine Tablets';           *
*      Line 3        %let title3l = 'Population: All Patients';     *
*       etc.                                                        *
*                                                                   *
*  To center          Use macro variable names that end in 'c'.     *
*  some text on ..    For example, ...                              *
*  ---------------   ---------------------------------------------  *
*      Line 1        %let title1c = 'Protocol RAN-123';             *
*      Line 2        %let title2c = 'Ranitidine Tablets';           *
*      Line 3        %let title3c = 'Population: All Patients';     *
*       etc.                                                        *
*                                                                   *
*  To right-justify   Use macro variable names that end in 'r'.     *
*  some text on ..    For example, ...                              *
*  ----------------  ---------------------------------------------  *
*      Line 1        %let title1r = 'Protocol RAN-123';             *
*      Line 2        %let title2r = 'Ranitidine Tablets';           *
*      Line 3        %let title3r = 'Population: All Patients';     *
*       etc.                                                        *
*                                                                   *
*                                                                   *
*  EXAMPLE: To create the following 3 titles:                       *
*  ------------------------------------------                       *
*  Appendix 8.3                                  Ranitidine Study   *
*                                                    All Patients   *
*                           DEMOGRAPHICS                            *
*                                                                   *
*  you would specify the following statements:                      *
*                                                                   *
*    %let title1l = 'APPENDIX 8.3';                                 *
*    %let title1r = 'Ranitidine Study';                             *
*    %let title2r = 'All Patients';                                 *
*    %let title3c = 'DEMOGRAPHICS';                                 *
*                                                                   *
*  Special Features Available                                       *
*  --------------------------                                       *
*  1. You can use macro variable references in the titles, provided *
*     that you use double quotes (") rather than single quotes (')  *
*     to enclose the title string.                                  *
*                                                                   *
*  2. You can use the macro variable reference &divline to specify  *
*     a divider line that stretches across the entire width of the  *
*     page. Do not enclose it in quotes: %let title4l = &divline;   *
*                                                                   *
*  3. You can number the pages in one of three ways.                *
*     a. For page numbers in the upper right-hand corner of each    *
*        page, specify the statement: %let page = upper right;      *
*        Be careful not to right-justify a title on line 1 in this  *
*        case, since the page number will over-write the last word. *
*        However, you could use a statement like the following:     *
*            %let title1r = 'Protocol S2B-353   X';                 *
*        since only the X would be overwritten by the page number.  *
*     b. For the form '(Page 1 of 57)', specify the string          *
*        '(Page of)' at the end of a left-justified or centered     *
*        title text string.                                         *
*     c. For the form 'Page 1 of 57', specify the string            *
*        'Page of' at the end of a left-justified or centered       *
*        title text string.                                         *
*                                                                   *
*  4. If you want the titles to contain data values that correspond *
*     to the records on that page, then you need to use a BY        *
*     statement in the PROC REPORT step.  In that case, you can     *
*     insert the by-values into a title line in one of 2 ways:      *
*                                                                   *
*     Suppose the BY statement is:  by ptcd invcd;                  *
*                                                                   *
*     a. You can use:                                               *
*        #byval1 to refer to values of first  by-variable (ptcd)    *
*        #byval2 to refer to values of second by-variable (invcd)   *
*                                                                   *
*     b. You can use:                                               *
*        #byval(ptcd) to refer to values of ptcd                    *
*        #byval(invcd) to refer to values of invcd                  *
*                                                                   *
*     There is 1 restriction for inserting by-values. For any title *
*     line in which you insert by-values, you may specify only      *
*     one text component: either the left-justified text string or  *
*     the centered text string (but not the right-justified one).   *
*                                                                   *
*  EXAMPLES                                                         *
*  ------------------------------------------------                 *
*  %let page = ;                                                    *
*  %let title1l = "APPENDIX &appnum  (Page of)";                    *
*  %let title1r = 'DEMOGRAPHICS';                                   *
*  %let title2r = 'Patient Listing:  All Patients';                 *
*  %let title3l = 'Investigator: #byval(invid)';                    *
*  %let title4l = &divline;                                         *
*-------------------------------------------------------------------*/
%let page = upper right;

%let title1l = "APPENDIX 8.7  (Page of)";
%let title3l = 'Protocol RAN-492';
%let title5l = 'Randomized Treatment: #byval(l_tmt)';

%let title1r = 'CONCURRENT MEDICATION';
%let title2r = 'Patient Listing:  All Patients';
%let title3r = '      with Numbers Ending in 2';
%let title6l = &divline;

/*------------------------------------------------------------------*
*                       Set up footnotes                            *
*                                                                   *
*  You can specify up to 10 footnotes by defining macro variables   *
*  foot1-foot10 as text strings (or as data step expressions that   *
*  result in text strings). As with title definitions, macro        *
*  variable references may be used inside the strings, provided     *
*  that the strings are enclosed in double quotes (").              *
*                                                                   *
*  You can use the macro variable reference &divline to specify     *
*  a divider line that stretches across the entire width of the     *
*  page. Do not enclose it in quotes: %let foot1 = &divline;        *
*                                                                   *
*  EXAMPLES                                                         *
*  --------                                                         *
*  %let foot1 = &divline;                                           *
*  %let foot2 = '* Indicates missing data.';                        *
*  %let foot3 = 'A blocking factor of 6 was used in ' ||            *
*               'generating all random codes.';                     *
*  %let foot4 = '[1] This footnote illustrates that the second';    *
*  %let foot5 = '    line of a footnote may be indented easily.';   *
*  %let foot6 = &divline;                                           *
*  %let foot7 = "&vmssasin : &sysdate";                             *
*-------------------------------------------------------------------*/
%let foot1 = &divline;
%let foot2 = '* Indicates missing data.';
%let foot3 = "    This footnote has leading blanks and an unmatched single' quote"; 
%let foot4 = &divline;
%let foot5 = "m:\utl\sasmacro\report02.sas: &sysdate";

*---Call the title and footnote macros---;

%dotitles;

%footnote;


*======================= Proc Report Step =========================;

*---Generate macro variable containing current time---;
data _null_; 
   call symput('time', trim(left(put(time(),12.))) ); 
   run;

*---Send the proc report output to a temporary file---;
proc printto file="temp&time" new;  run;

%*---Produce the report---;
proc report data=work headline nowindows split='~' missing;
  by l_tmt;
  column invcd patient medtx meddos medut medfq medrt dstart dstop
    medindtx;
  break after patient / skip;
  define invcd    / order                   'Inv.';
  define patient  / order                   'Patient'
                    center  width=7;
  define medtx    / display                 'Drug Name'
                            width=20  flow;
  define meddos   / display                 'Unit Dose';
  define medut    / display                 'Units';
  define medfq    / display                 'Freq';
  define medrt    / display                 'Route';
  define dstart   / display                 'Date~Started';
  define dstop    / display                 'Date~Stopped';
  define medindtx / display                 'Indication'
                            width=30  flow;
run;

*---Close the temporary output file---;
proc printto;  run;

*==================== Output File Modification =====================;
options mprint;

*---Read temp file, & insert page numbers and total no. of pages---;
%page2;
