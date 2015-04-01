/*
/ PROGRAM NAME: aetab.sas
/
/ PROGRAM VERSION: 2.2
/
/ PROGRAM PURPOSE: Produce tables of adverse events using data from AESTAT.
/                  IDSG conforming.
/
/ SAS VERSION: 6.12
/
/ CREATED BY: John Henry King
/
/ DATE: 1993
/
/ INPUT PARAMETERS: see detailed description below.
/
/ OUTPUT CREATED: A SAS print file.
/
/ MACROS CALLED:
/
/   JKCHKDAT  Check input data for correct vars and type
/   JKCTCHR   Count characters in a string
/   JKXWORDS  Count words and create an array of the words.
/   JKPREFIX  Parse a list of words and add jkprefix constant text
/   JKRENLST  Create a "RENAME" list
/   JKLY0T01  Setup the page layout macro variables.
/   JKFLSZ2   Flow text, into 2 dimensional array
/   JKFLOWX   Flow text, into 1 dimensional array.
/   JKHPPCL   My version of HPPCL, to setup printer.
/
/ EXAMPLE CALL:
/
/   %aetab(  data = aestat,
/         outfile = ae1,
/          layout = port,
/         pagenum = pageof,
/          target = %sysget(LOGNAME),
/          level1 = bodytx,
/          style1 = 2,
/          level2 = grptx,
/         indent2 = 1,
/             tmt = tmt,
/          label2 = %str(Number of patients with any drug related event),
/          label3 = %str(Number of patients with any event),
/            swid = 20,
/            cwid = 13,
/        sbetween = 10,
/        pbetween = 10)
/
/=====================================================================================
/ CHANGE LOG:
/
/    MODIFIED BY: John Henry King
/    DATE:        28FEB1997
/    MODID:       JHK001
/    DESCRIPTION: Enhance error messages to make them more noticable.
/    ------------------------------------------------------------------------------
/    MODIFIED BY:  John Henry King
/    DATE:        28FEB1997
/    MODID:       JHK002
/    DESCRIPTION: Fixed bug on last.level2 printing when the report has more than
/                 one panel.  Also fixed problem with p-value printing in header
/                 with more than one panel.
/    ------------------------------------------------------------------------------
/    MODIFIED BY: John Henry King
/    DATE:        16JUL1997
/    MODID:       JHK003
/    DESCRIPTION: Add option CONTMSG=YES|NO to suppress the message
/                 continued...
/                 that the macro places at the bottom of the page.
/    ------------------------------------------------------------------------------
/    MODIFIED BY: John Henry King
/    DATE:        16JUL1997
/    MODID:       JHK004
/    DESCRIPTION: Increased dimension of column label array to accommodate
/                 more column label rows.
/    ------------------------------------------------------------------------------
/    MODIFIED BY: John Henry King
/    DATE:        08SEP1997
/    MODID:       JHK005
/    DESCRIPTION: Fixed bug in dim2 of JKFLSZ2 that I overlooked when I increased
/                 the column label rows.
/
/                 was
/                    %jkflsz2(in=_tl,out=_xl,size=&cwid,sizeAR=_tw,dim1=&cols,dim2=5)
/
/                 became
/                    %jkflsz2(in=_tl,out=_xl,size=&cwid,sizeAR=_tw,dim1=&cols,dim2=10)
/    ------------------------------------------------------------------------------
/    MODIFIED BY: John Henry King
/    DATE:        NOV1997
/    MODID:       JHK006
/    DESCRIPTION: Changes to make macro conform to IDSG standards.
/
/                 1) changed default PVALUE to NO.
/                 2) changed format of STYLE1=1
/                 3) added (N=XXX) to column headers.
/                 4) removed All events and number of patients from the header
/                 5) added default outfile value, user program name.
/                 6) changed defaults for CONTMSG and JOBID.
/                 7) added TOTAL= option
/                 8) added label text for columns when STYLE=2, LABEL3=
/    ------------------------------------------------------------------------------
/    MODIFIED BY: Margo S. Walden
/    DATE:        06FEB1998
/    MODID:       JHK007
/    DESCRIPTION: Correction of spelling and grammar in comments.
/    ------------------------------------------------------------------------------
/    MODIFIED BY: John Henry King
/    DATE:        17FEB1998
/    MODID:       JHK008
/    DESCRIPTION: Corrected problem with macro printing extra continued message.
/                 Added sort to sort after the formats are applied to LEVEL1 and
/                 LEVEL2.
/    ------------------------------------------------------------------------------
/    MODIFIED BY: Jonathan Fry
/    DATE:        09DEC1998
/    MODID:       JMF009
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 2.2
/    -----------------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX010
/    DESCRIPTION:
/    -----------------------------------------------------------------------------
/======================================================================================*/

/*
/-------------------------------------------------------------------------------
/ Macro AETAB
/
/ Use this macro to produce a table of adverse events, with two levels of
/ grouping in the body of the table.  With further grouping on PAGEBY
/ variables.
/
/ The macro will fit the columns on the page using as many PANELS, or logical
/ pages, as needed to display all the columns.
/
/-------------------------------------------------------------------------------
/ Parameter=Default    Description
/ -----------------    ---------------------------------------------------------
/ DATA=                Names the input data set.  This data set must be output
/                      from macro AESTAT or a data set with that same structure.
/
/ OUTFILE=             Names the ASCII file that will receive the table.  Do NOT
/                      include an extension for this file the macro will use
/                      PCL or Pnn or Lnn for HPPCL(postscript portrait &
/                      postscript landscape, respectively).
/
/ DISP=                Use DISP=MOD to cause AETAB to append its output to the
/                      file named in the OUTFILE= option.  You should not change
/                      the layout of the file that is being appended to.
/
/ PAGENUM=             The PAGENUM=PAGEOF option allows the output from AETAB to
/                      be numbered in the style "Page n of  p".
/                      If you use the DISP=MOD option in your AETAB, then you should
/                      request PAGENUM=PAGEOF on the LAST call to AETAB only.
/                      When AETAB is running with DISP=MOD, a cumulative total of
/                      pages is kept so that they can be numbered inclusively.
/
/ TARGET=              This option is used in association with the PAGENUM= option.
/                      TARGET= specifies a character string that will be searched
/                      for when the macro is numbering pages.  The target is used
/                      to locate the "Page n of p" text.  The default value for
/                      target is the value of OUTFILE=.
/
/ CONTMSG = YES        This parameter turns on or off the continued message that the
/                      macro writes at the bottom of the page.  Use CONTMSG=OFF when
/                      you use PAGENUM= or if you are using MACPAGE to number the pages.
/
/
/ TMT=                 An INTEGER NUMERIC variable that defines the columns.
/                      If you used AESTAT to create the input data for AETAB,
/                      then TMT would be the same variable used in TMT in that
/                      macro call.
/
/ TMTFMT =             This parameter is used to specify the format for the treatment
/                      variable named in the TMT= parameter.  When this parameter is
/                      left blank, the macro uses a format with the same name as the
/                      TMT= parameter.
/
/
/ PAGEBY=              List the variable(s) that were used the in PAGEBY option
/                      of AESTAT.  When the value of the BY group changes, AETAB
/                      will start a new page.  The values of the PAGEBY variables
/                      are written on each page after the titles are printed.
/                      You can use the PUTBY option described below to control
/                      the printing of the BY variables.  The default action is
/                      to print the PAGEBY variables in the style of a SAS by line.
/
/                      pageby_var1=pageby_var1_value pageby_var2=pageby_var2_value...
/
/ PUTBY=               The PUTBY parameter allows the user to change the way
/                      the PAGEBY variables are printed.  Use put statement
/                      specifications as the value of the PUTBY parameter.
/                      For example:  If
/                         PAGEBY=PTCD STDYPHZ
/
/                      then PUTBY might look like this
/                         PUTBY='Protocol: ' ptcd :$ptcdfmt. / 'Study Phase: ' stdyphz :$phzfmt.
/
/                      and would produce the following PAGEBY line.
/                         Protocol: S2CT89
/                         Study Phase: Treatment
/
/                      You can use almost any PUT statement specifcation in the
/                      PUTBY parameter.  Do not use
/                         Line Pointer controls(#, OVERPRINT, or _PAGE_)
/                                          OR
/                         Line-hold specifiers(@ or @@)
/
/                      The macro determines the number of lines that PUTBY will
/                      produce by counting the number of "/", pointer controls.
/
/                      The default PUTBY is
/                         (&pageby) (=)
/
/
/ LEVEL1=              This parameter names the first level of adverse event
/                      classification, typically some type of body system
/                      grouping(SYMPCLASS or the first letter of a DISS code).
/
/ FINDENT1=0           Specifies the number of spaces to indent the second line
/                      of LEVEL1 text that is produced by flowing.
/
/ FMTLVL1=             Names the format used to print the values of LEVEL1.
/                      This can be a value labeling format, or if the values of
/                      LEVEL1 are not codes, then this could be left blank.
/
/ DISPLVL1=YES         This parameter turns off the number displays for the
/                      LEVEL1 rows.
/
/ ORDER1=_ORDER1_      Names the variable in the input data set that orders
/                      the values of LEVEL1
/
/ STYLE1=1             Use this parameter to control the look of the LEVEL1 rows
/
/                      1=   level1 value
/                           &label3        ee nn(pp)  ee nn(pp)
/
/                      2=   level1 value   ee nn(pp)  ee nn(pp)
/
/ SKIP1=1              Use this parameter to control the number of lines that are
/                      skipped at the end of a LEVEL1 group.
/
/ LEVEL2=              This parameter names the second level of adverse event
/                      classification(DISS code or SYMPGP).
/
/ INDENT2=0            Specifies the number of spaces to indent LEVEL2 text.
/
/ FINDENT2=1           Specifies the number of spaces to indent the second line
/                      of LEVEL2 text that is produced by flowing.  This is in
/                      addition to INDENT2 indentation.
/
/ FMTLVL2=             Names the format used to print the values of LEVEL2.
/                      This can be a value labeling format, or if the values of
/                      LEVEL2 are not codes, then this could be left blank.
/
/ ORDER2=_ORDER2_      Names the variable in the input data set that orders the
/                      levels of LEVEL2
/
/
/ LABEL1='ANY EVENT'   This parameter provides the label text for the overall
/                      number of subjects with any adverse event.
/
/
/ LABEL2='Any Event'   This parameter provides the label text for the counts
/                      associated with the LEVEL1= variable, when STYLE1=1.
/
/ LABEL3='No.!!!n!!!!%'
/                      This parameter provides the label text for the columns
/                      of the report when STYLE=2 is used.
/
/ STYLE=1              Specifies the printing style of counts and percents.
/
/                      1 = nn (pp)
/                      2 = EE nn (pp)
/                      where nn=number of patients
/                            pp=percent
/                            EE=number of events
/                      3 = nn/NN (pp)
/                      where nn=number of patients
/                            NN=population
/                            pp=percent
/
/ IFMT=3.              The format for printing the counts.
/
/ PCTFMT=JKPCT5.       The format for printing percents.  The default, JKPCT5.,
/                      is an internally created picture format.
/
/ PCTSIGN=NO           Used to include a percent sign (nn%) for printing the
/                      percents when using the PCTFMT.
/
/ PCTSTYLE=1           This parameter is used to modify the way percents are
/                      rounded when being print with the JKPCTn. format.
/
/                      PCTSTYLE=1 rounds and prints as follows:
/
/
/                             values
/                      ------------------------
/                      internal       formated
/
/                       >0 to <1        (<1)
/                        1 to 99        (pp)   rounded to integer
/                      >99 to <100     (>99)
/                         100          (100)
/                           0          blank
/                        missing       blank
/
/                      While PCTSTYLE=2 round and print as follows:
/
/                             values
/                      ------------------------
/                      internal       formated
/
/                       >0.5 to <1        (<1)
/                        1 to 99.5        (pp)   rounded to integer
/                      >99.5 to <100     (>99)
/                           100          (100)
/                             0          blank
/                          missing       blank
/
/
/
/
/ L1SIZE=10            This parameter determines maximum size of a LEVEL1 group that
/                      will be kept together on a page.  Any LEVEL1 group, including
/                      the LEVEL2 values associated with it, will be kept together
/                      if the total number lines needed to print them is less than
/                      L1SIZE.
/
/ L1PCT=.40            For LEVEL1 groups that are larger than L1SIZE, the parameter
/                      specifies the percent of the group to keep together on a page.
/
/ L1PCTMIN=5           If the value of L1PCT is smaller than L1PCT, then L1PCTMIN lines
/                      of a LEVEL1 group are kept together.
/
/
/ PVALUE = YES         Print p-value on the table?
/
/ PLABEL = 'p-value [1]'
/                      Plabel specifies the label for the p-value column.
/
/ INDENTF = 4          This parameter controls the number of columns that a continued
/                      footnote line is indented.  The footnotes are flowed into the
/                      linesize with the first line left justified and subsequent lines
/                      indented the number of columns specified by this parameter.
/
/                      Footnote lines may also have individual indenting controlled by
/                      the FINDTn macro variables.  For example:
/
/                      %let fnote2 = this is the footnote.
/                      %let findt2 = 6;
/
/                      In this example, if footnote 2 was flowed onto a second line, then
/                      that line would be indented 6 spaces.
/
/ HRDSPC = !           This is the hard space parameter.  This parameter specifies which
/                      character in a FOOTNOTE line will represent a hard space.
/                      By default, footnote text will have the occurrences of multiple
/                      spaces removed by flow macro.  You would need to use this
/                      parameter to indent the first line of a footnote.
/
/ LAYOUT = DEFAULT     This is the arrangement of the table on the printed
/                      page.  This parameter works the same as in the HPPCL
/                      macro developed by J.COMER.
/
/ CPI = 17             The number of characters per inch on the printed page.
/                      Possible values are 12 and 17.
/
/ LPI = 8              The number of lines per inch. Possible values are
/                      6, 8, and 10.
/
/ SWID = 20            The width of the table STUB in number of characters.
/                      The STUB is the part of the table that identifies the table
/                      rows.
/
/ CWID = 10            The number of characters to allow for each treatment
/                      column in the table.
/
/ PWID = 8             The number of characters to allow for each P-value
/                      column.
/
/ BETWEEN = 0          The number of characters to place between each column.
/                      When this parameter is 0, the columns are spaced
/                      to fill out the linesize of the table.
/
/ SBETWEEN = 2         Specifies extra spaces between the table stub and the
/                      first treatment column.
/
/ PBETWEEN = 3         Specifies the number of spaces between the last treatment
/                      column and the first p-value column.
/
/ BETWEENP = 2         Specifies the number of spaces between the p-value columns.
/
/
/ SMIN = 20            Minimum values for each of the column width parameters
/ CMIN = 8
/ PMIN = 6
/
/-----------------------------------------------------------------------------*/


%macro AETAB(  data=,
            outfile=,
               disp=,
            pagenum=NONE,
             target=,
            contmsg=NO,
              jobid=NO,

             pageby=,
              putby=,

             level1=,
            fmtlvl1=$200.,
           displvl1=YES,

             order1=_ORDER1_,
             style1=1,
              skip1=0,
           findent1=0,

             l1size=10,
              l1pct=.40,
           l1pctmin=5,

             level2=,
            fmtlvl2=$200.,
            indent2=3,
           findent2=1,
             order2=_ORDER2_,

                tmt=,
             tmtfmt=,

             pvalue=NO,
              pvars=PROB,
             plabel='p-value [1]',

                box='BODY SYSTEM \ !!!Event',
             label1='ANY EVENT',
             label2='Any Event',
             label3='No.!!!n!!!!%',

              style=1,
               ifmt=3.,

             pctfmt=jkpct6.,
            pctsign=YES,
           pctstyle=1,

            indentf=4,
             hrdspc=!,

             layout=DEFAULT,
                cpi=17,
                lpi=8,
               swid=30,
               cwid=10,
               pwid=8,
            between=0,
           sbetween=5,
           pbetween=3,
           betweenp=2,
               smin=20,
               cmin=8,
               pmin=6,
              ruler=NO,
            sasopts=NOSYMBOLGEN NOMLOGIC,
              debug=0,
              rbit1=0);

   options &sasopts;

   %if %substr(&sysscp%str(   ),1,3) = VMS %then %do;
      options cc=cr;
      %end;

      /*
      / JMF009
      / Display Macro Name and Version Number in LOG
      /-------------------------------------------------------------------*/

      %put ------------------------------------------------------ ;
      %put NOTE: Macro called: AETAB.SAS      Version Number: 2.2 ;
      %put ------------------------------------------------------ ;


   %global vaestat vaetab jkpg0;
   %let    vaetab = 1.0;

   /*
   / Assign default value to OUTFILE and create GLOBAL macro variable
   / to use in INFILE= parameter in MACAPGE.
   /-------------------------------------------------------------------*/
   %global _outfile;

   %if %bquote(&outfile)= %then %let outfile = %fn;

   /*
   / JHK001
   / New macro variable added to make error message more noticable.
   / All ! mark removed from old error messages.
   /--------------------------------------------------------------------------*/

   %local erdash;
   %let erdash = ERROR: _+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_;

   %if "&data"="" %then %do;
      %put &erdash;
      %put ERROR: There is no DATA= data set.;
      %put &erdash;
      %goto exit;
      %end;

   %if "&level1"="" %then %do;
      %put &erdash;
      %put ERROR: The macro parameter LEVEL1 must not be blank.;
      %put &erdash;
      %goto exit;
      %end;



   /*
   / Set up local macro variables to hold temporary data set names.
   /-----------------------------------------------------------------*/

   %local panel cnst header footer bign dclrows fprint lines
          panel2 flowed;
   %let panel    = _1_&sysindex;
   %let cnst     = _2_&sysindex;
   %let clabels  = _3_&sysindex;
   %let headfoot = _4_&sysindex;
   %let bign     = _5_&sysindex;
   %let dclrows  = _6_&sysindex;
   %let fprint   = _A_&sysindex;
   %let lines    = _B_&sysindex;
   %let panel2   = _E_&sysindex;
   %let flowed   = _F_&sysindex;



   /*
   / Upper case various input parameters as needed.
   /-------------------------------------------------------------------------*/

   %let outfile = &outfile;
   %let pvalue  = %upcase(&pvalue);
   %let pvars   = %upcase(&pvars);
   %let layout  = %upcase(&layout);
   %let pageby  = %upcase(&pageby);
   %let level1  = %upcase(&level1);
   %let order1  = %upcase(&order1);
   %let level2  = %upcase(&level2);
   %let order2  = %upcase(&order2);
   %let contmsg = %upcase(&contmsg);

   %let pctfmt  = %upcase(&pctfmt);
   %let pctsign = %upcase(&pctsign);
   %let style   = %upcase(&style);

   %let ruler   = %upcase(&ruler);
   %let disp    = %upcase(&disp);
   %let pagenum = %upcase(&pagenum);

   %let jobid   = %upcase(&jobid);
   %let displvl1= %upcase(&displvl1);

   %if %bquote(&tmt)= %then %do;
      %put &erdash;
      %put ERROR: The macro parameter TMT must not be blank.;
      %put &erdash;
      %goto exit;
      %end;

   %if %bquote(&tmtfmt)= %then %do;
      %let tmtfmt = %str(&tmt).;
      %end;


   %if %bquote(&contmsg)=YES | %bquote(&contmsg)=1
      %then %let contmsg = 1;
      %else %let contmsg = 0;

   %if "&pvalue"="YES" | "&pvalue"="1"
      %then %let pvalue=1;
      %else %let pvalue=0;


   %if "&displvl1"="NO" | "&displvl1"="0" | "&displvl1"="N"
      %then %let displvl1=0;
      %else %let displvl1=1;

   %if "&ruler"="YES" | "&ruler"="1"
      %then %let ruler=1;
      %else %let ruler=0;

   %if "&jobid"="YES" | "&jobid"="1"
      %then %let jobid = 1;
      %else %let jobid = 0;

   %if %length(&target)=0
      %then %let target = "&outfile";
      %else %let target = "&target";

   %if "&disp"^="MOD" %then %do;
      %let disp=;
      %let jkpg0 = 0;
      %end;


   %if "&pctsign"="YES" %then %do;
      %let pctsign = %str(%%);
      %if "&pctfmt" = "JKPCT5." %then %let pctfmt = JKPCT6.;
      %end;
   %else %do;
      %let pctsign = ;
      %end;

   %if ^("&pctstyle"="1" | "&pctstyle"="2") %then %let pctstyle=1;

   %put NOTE: PCTSIGN=&pctsign, PCTFMT=&pctfmt, PCTSTYLE=&pctstyle;



   %if "&order1" = "NONE" %then %let order1 = ;

   %if "&order2" = "NONE" %then %let order2 = ;
   %if "&level2"= ""      %then %let order2 = ;


   /*
   / Run the check data utility macro CHKDATA to verify the existence
   / of the input data and variable names.
   /-------------------------------------------------------------------------*/

   %jkchkdat(data=&data,
            nvars=&tmt _aetype_ n_pats n_evts denom pct,
            cvars=,
             vars=&pageby &level1 &order2 &level2 &order2)

   %if &RC %then %goto EXIT;



   /*
   / Global all the macro variables supplied by the user outside
   / the macro.  This insures that these variables are all defined
   / even if the user does not supply them all.
   /-----------------------------------------------------------------*/

   %global hl0 hl1 hl2 hl3 hl4 hl5 hl6 hl7 hl8 hl9 hl10
           hl11 hl12 hl13 hl14 hl15;

   %global hlright hlleft hlcont;

   %global fnote0  fnote1  fnote2  fnote3  fnote4  fnote5
           fnote6  fnote7  fnote8  fnote9  fnote10 fnote11
           fnote12 fnote13 fnote14 fnote15;

   %global findt0  findt1  findt2  findt3  findt4  findt5
           findt6  findt7  findt8  findt9  findt10 findt11
           findt12 findt13 findt14 findt15;

   %global enote0 enote1 enote2 enote3 enote4 enote5
                  enote6 enote7 enote8 enote9 enote10;

   %if %bquote(&fnote0) = %then %let fnote0 = 0;
   %if %bquote(&enote0) = %then %let enote0 = 0;

   /*
   / Process the pvars
   /----------------------------------------------------------------*/

   %local p_var0;

   %if ^&pvalue %then %let p_var0  = 0;
   %else              %let p_var0  = %jkxwords(list=&pvars,root=p_var);





   /*
   /
   / COLS      The maximum number of columns in the panels.
   / _PGBY0    The number of PAGEBY variables.
   / _PGBYLST  The last PAGEBY variable.
   / _PBYLINES The number of lines required to print the PAGEBY line(s).
   /----------------------------------------------------------------------*/

   %local cols colsplus maxwid _pgby0 _pgbylst pbylines idx;

   %if %bquote(&pageby) > %then %do;

      %let _pgby0   = %jkxwords(list=&pageby ,root=_pgby,delm=%str( ));
      %let _pgbylst = &&&_pgby&_pgby0;

      %if %length(&putby) = 0 %then %let putby = (&pageby) (=);

      %let pbylines = %eval(%jkctchr(&putby,%str(/)) + 1);

      %put NOTE: _PGBY0=&_pgby0, _PGBYLST=&_pgbylst PBYLINES=&pbylines;

      %let idx      = panpage;

      %end;

   %else %do;
      %let _pgby0   = 0;
      %let pbylines = 0;
      %let idx      = panel;
      %end;


   /*
   / Set up flags used to control printing of the appendix note,
   / the jobname information, and the table continued notes.
   /-----------------------------------------------------------------*/

   %local xcont;

   %if %bquote(&hl0)=  %then %let    hl0=10;

   %if %bquote(&hlcont)=
      %then %let xcont=0;
      %else %let xcont=1;


   %local flev1;

   %if %bquote(&style1) = %then %let style1 = 1;
   %if %bquote(&skip1)  = %then %let skip1  = 1;
   %if %bquote(&level2) > %then %let skip1  = 1;

   %if %bquote(&level2)= %then %let style1 = 2;

   %if       %bquote(&style1) = 1 %then %let flev1 = 2;
   %else %if %bquote(&style1) = 2 %then %let flev1 = 1;



   /*
   / Set up the page size based on user input.  The macro will try to
   / fit the table into the linesize implied by the user's selection
   / of LAYOUT, CPI, and LPI
   /----------------------------------------------------------------------*/

   %local ls ps dashchr file_ext file_dsp hppcl;

   %jklyot01

   %put NOTE: LAYOUT=&layout, CPI=&cpi, LPI=&lpi, LS=&ls, PS=&ps;


   /*
   / In this step, the values of the LEVELn variables are FLOWED
   / into the stub width.
   /------------------------------------------------------------------*/
   data &flowed;
      set &data;

      /*
      / JHK008 Changing temporary array to perminant.
      /------------------------------------------------*/

      /*
      / LEVEL1 variable
      /---------------------------------------------------*/
      array _y[1] $200;

      select(_aetype_);
         when(0)    _y[1] = &label1;
         otherwise  _y[1] = put(&level1,&fmtlvl1);
         end;


      %jkflowx(in=_y,out=_1lv,dim=10,size=%eval(&swid-&findent1))

      _1lv0 = max(1,_1lv0);


      /*
      / LEVEL2 variable
      /---------------------------------------------------*/
   %if %bquote(&level2) > %then %do;
      array _x[1] $200;

      select(_aetype_);
         when(0);
         when(1)   _x[1] = &label2;
         otherwise _x[1] = put(&level2,&fmtlvl2);
         end;

      %jkflowx(in=_x,out=_2lv,dim=10,size=%eval(&swid-&indent2-&findent2))

      %end;

   %else %do;
      retain _2lv0 0;
      %end;
      run;

   %let data = &flowed;
   /*
   / JHK008
   / Change level1 and level2 variable to Y1 and X1 respecively
   / and sort.
   /---------------------------------------------------------------*/


   %let level1 = _y1;
   %if %bquote(&level2) > %then %do;
      %let level2 = _x1;
      %end;

   proc sort data=&flowed out=&flowed;
      by &pageby &order1 &level1 &order2 &level2 _aetype_ &tmt;
      run;

   %if &debug %then %do;
      title5 "DATA=FLOWED(&flowed) with flowed text";
      proc print data=&flowed;
         run;
      %end;


   /*
   / Compute PANELS based on the number of treatments, the presence
   / of p-values, and the width of the various column components of the
   / table.
   /--------------------------------------------------------------------------*/

   options nofmterr;


   proc summary data=&data(where=(_aetype_=0)) nway missing;
      class &pageby &tmt;
      var denom;
      output out=&panel(drop=_type_ _freq_) sum=N_N_N;
      run;




   %if &debug %then %do;
      title5 "DATA=PANEL(panel) WITH BIG N for (N=xxx) in column headers";
      proc contents data=&panel;
         run;
      proc print data=&panel;
         run;
      %end;

   proc summary data=&data(where=(_aetype_=0)) nway missing;
      class &tmt;
      output out=&panel2(drop=_type_ _freq_);
      run;

   /*
   / This data set will contain column location constants.  This data
   / will be SET into the FILE PRINT data step below.
   /--------------------------------------------------------------------------*/

   %local candoit;
   %let cantdoit = 0;

   data &cnst;

      if 0 then set &panel2(drop=_all_) nobs=nobs;

      retain style "&style" pvalue &pvalue p_var0 &p_var0;

      retain ps &ps l1size &l1size l1pct &l1pct l1pctmin &l1pctmin pbylines &pbylines;

      drop i;

      tmt0 = nobs;

      iwid = int(&ifmt);

      pctwid = int(input(compress("&pctfmt",'ABCDEFGHIJKLMNOPQRSTUVWXYZ'),8.));

      /*
      / Compute CCWID-the width taken up by the contents of the columns.
      /----------------------------------------------------------------------*/

      select(style);
         when('1') ccwid = iwid + pctwid;
         when('2') ccwid = 1 + iwid * 2 + pctwid;
         when('3') ccwid = 1 + iwid * 2 + pctwid;
         otherwise do;
            ccwid = iwid + pwid;
            call symput('STYLE','1');
            style = '1';
            end;
         end;


      swid     = max(&swid,&smin);
      cwid     = max(&cwid,ccwid,&cmin);
      pwid     = max(&pwid,&pmin);

      btwn     = max(&between,1);
      between  = max(&between,0);
      pbetween = max(&pbetween,1);
      sbetween = max(&sbetween,0);
      betweenp = max(&betweenp,0);

      ls      = &ls;

      /*
      / Compute SPWID-the total number of columns occupied by the table stub
      / and p-values if requested.
      /-----------------------------------------------------------------------*/

      spwid = swid + sbetween;
      if pvalue then spwid = spwid + (pwid*p_var0)+(betweenp*(p_var0-1))+pbetween;

      /*
      / Now see how many TREATMENT columns will fit in the space left after
      / the stub and p-values.
      /-----------------------------------------------------------------------*/

      req = spwid;

      do tcols = 1 to tmt0;
         req = req + (cwid + btwn);
         if req > &ls then leave;
         end;


      /*
      / Tcols is the number of TREATMENT columns that will fit in 1 panel
      /-----------------------------------------------------------------------*/
      tcols = tcols - 1;

      if tcols=0 then do;
         call symput('CANTDOIT','1');
         stop;
         end;

      cols    = tcols + p_var0;

      /*
      / COFF is the column offset for the statistics printed in a treatment
      / column.  This centers the statistics under the column heading.
      / PCOFF is similar to COFF but is for the p-value column.
      /-----------------------------------------------------------------------*/

      coff  = max(floor((cwid-ccwid) / 2),0);
      pcoff = max(floor((pwid-6) / 2),0);


      /*
      / When no between value is specified, BETWEEN=0, the macro computes
      / BETWEEN to space the columns so that they fill up the available space.
      /-----------------------------------------------------------------------*/


      if between = 0 then do;

         between = floor( (ls - spwid - tcols*cwid) / max(tcols-1,1) );

         xxx = between;

         between = between - floor(between / tcols);

         between = max(between,1);

         end;



      /*
      / The array _TC will hold the column locations for each treatment column
      / and the p-value column.
      / The array _TW hold the width of each of these columns.  This is used by
      / the flow macro JKFLSZ2 to vary the size of the columns of flowed text.
      /-----------------------------------------------------------------------*/
      array _tc[40];
      array _tw[40];

      tmtreq = (tcols  * cwid) + (between  * (tcols-1));
      prbreq = (p_var0 * pwid) + (betweenp * (p_var0-1));

      _tc[1] = 1 + swid + sbetween;
      _tw[1] = cwid;

      do i = 2 to tcols;
         _tc[i] = _tc[i-1] + cwid + between;
         _tw[i] = cwid;
         end;

      do i = tcols+1 to cols;
         if i = tcols+1
            then _tc[i] = _tc[i-1] + _tw[i-1] + pbetween;
            else _tc[i] = _tc[i-1] + pwid     + betweenp;
         _tw[i] = pwid;
         end;


      /*
      / Create macro variable to hold COLS the number of columns, to use
      / in array declarations.
      /-----------------------------------------------------------------------*/

      call symput('COLS',    trim(left(put(cols,8.))));
      call symput('COLSPLUS',trim(left(put(1+cols,8.))));
      call symput('CWID',    trim(left(put(cwid,8.))));
      call symput('PWID',    trim(left(put(pwid,8.))));
      call symput('MAXWID',  trim(left(put(max(cwid,pwid,swid),8.))));

      output;
      stop;
      run;




   %if &cantdoit %then %do;
      %put ERROR: &erdash;
      %put ERROR: Your choices of    STUB: SWID=&swid, SBETWEEN=&sbetween;
      %put ERROR:              TX COLUMNS: CWID=&cwid, BETWEEN=&between;
      %put ERROR:           P-VAL COLUMNS: PWID=&pwid, PBETWEEN=&pbetween, BETWEENP=&betweenp;
      %put ERROR: will not allow the display of any treatment columns.;
      %put ERROR: Please choose smaller values for one or more of these parameters and resubmit.;
      %put ERROR: &erdash;
      %goto exit;
      %end;

   %if &debug | &rbit1 %then %do;
      title5 "DATA=CNST(&cnst) various constants associated with column and header placement";
      proc print data=&cnst;
         run;
      %end;


   /*
   / Using the data set of treatment values divide the treatments into panels
   / using TCOLS from above.  This data will be merged with the input data
   / below.
   /--------------------------------------------------------------------------*/

   data &panel;
      set &panel;
      by &pageby;
      if _n_ = 1 then set &cnst(keep=tcols);
      drop tcols n;

      retain panel n;

   %if %bquote(&pageby) > %then %do;
      if first.&_pgbylst then do;
         panel = 0;
         n     = 0;
         end;
      %end;
   %else %do;
      if _n_ = 1 then do;
         panel = 0;
         n     = 0;
         end;
      %end;

      n = n + 1;

      if mod(n , tcols) = 1 then panel = panel + 1;

      run;

   %if &debug %then %do;
      title5 "DATA=PANEL(&panel)";
      proc print data=&panel;
         run;
      title5;
      %end;


   /*
   / Now using the treatment data set that has been divided up into panels,
   / flow the column header text into the space provided by the column width
   / array.
   /--------------------------------------------------------------------------*/

   proc summary data=&panel nway missing;
      class &pageby panel &tmt;
      var n_n_n;
      output out=&clabels(drop=_type_ _freq_) sum=;
      run;
   %if &debug %then %do;
      title5 "DATA=CLABELS(&clabels) with BIG N. for N=xxx";
      proc print data=&clabels;
         run;
      %end;

   proc transpose data=&clabels out=&bigN prefix=bn;
      by &pageby panel;
      var n_n_n;
      run;

   proc transpose data=&clabels out=&clabels prefix=tc;
      by &pageby panel;
      var &tmt;
      run;

   %if &debug %then %do;
      title5 "DATA=CLABELS(&clabels) the transpose column labels before flowing.";
      proc print data=&clabels;
         run;
      title5 "DATA=BIGN(&bign) the transpose column big Ns";
      proc print data=&bign;
         run;
      %end;


   data &clabels(keep=&pageby panel max _xl:);

      merge
         &clabels
         &bign
         ;

      by &pageby panel;

      array _tc[*] tc:;
      array _bn[*] bn:;

      if _n_ = 1 then set &cnst(keep=_tw1-_tw&cols tcols swid style);

      array _tw[&colsplus] _tw1-_tw&cols swid;

      array _tl[&colsplus] $100;

      /*
      / Assign TL[cols+1] the value of the BOX parameter
      /-----------------------------------------------------------------*/

      _tl[&colsplus] = &box;
      if _tl[&colsplus] = ' ' then _tl[&colsplus] = '!';


      /*
      / Create the format labels using the TMT format
      /------------------------------------------------*/

      ntmts = n(of _tc[*]);

      do i = 1 to dim(_tc);
         if _tc[i] <= .Z then continue;
         _tl[i] = put(_tc[i],&tmtfmt) || ' \ (N=' || trim(left(put(_bn[i],best8.))) ||')';
         if style=2 then do;
            _tl[i] = trim(_tl[i])||' \ '||repeat(&dashchr,&cwid-1)||' \ '||&label3;
            end;
         if &ruler then _tl[i] = trim(_tl[i])||' '|| substr(repeat('....+',10),1,&cwid);
         end;

      %if &pvalue %then %do;
         j = 0;
         if &p_var0=1 & "&p_var1"='PROB' then do;
            _tl[&cols]= &plabel;
            if &ruler  then _tl[&cols]= trim(_tl[&cols])||' '||substr('....+....+....+....+',1,&pwid);
            end;
         else do i = tcols+1 to &cols;
            j = j + 1;
            VAR = SYMGET('P_VAR'||left(put(j,4.)));
            _tl[i] = put(var,$pvars.);
            if &ruler then _tl[i]= trim(_tl[i])||' '||substr('....+....+....+....+',1,&pwid);
            end;
         %end;


      /*
      / Flow the labels into the columns based on the column
      / width. CWID may be different for treatments and
      / p-values.
      /------------------------------------------------------*/

      /*
      / JHK005
      /--------*/
      %jkflsz2(in=_tl,
              out=_xl,
             size=&maxwid,
           sizeAR=_tw,
             dim1=&colsplus,
             dim2=10);

      max = max(of _xl0_[*],0);
      run;

   %if &debug %then %do;
      title5 "DATA=CLABELS(&clabels) after flowing";
      proc print data=&clabels;
         run;
      %end;


   proc summary data=&clabels nway missing;
      var max;
      output out=&dclrows(drop=_type_ _freq_)
             max=clrows;
      run;

   data &clabels
         (
         keep  = &pageby panel clrows _cl:
         index = (&idx=(&pageby panel) / unique)
         );

      set &clabels(drop=max);

      if _n_ = 1 then set &dclrows;

      /*
      / JHK004
      / changed 5 to 10 in _xl array
      / and in _cl array below
      /---------------------------------*/
      array   _xl[&colsplus,10];
      array _xl0_[&colsplus];


      /*
      / Move the labels down so that they will look pushed up
      / rather that hung down.
      /------------------------------------------------------*/
      array   _cl[&colsplus,10] $&maxwid;
      array _cl0_[&colsplus];

      _cl0 = _xl0;

      do i = 1 to _cl0;
         _cl0_[i] = clrows;
         offset = clrows - _xl0_[i];
         do k = 1 to _xl0_[i];
            _cl[i,k+offset] = _xl[i,k];
            end;
         end;
      run;
   %if &debug %then %do;
      title5 "DATA=CLABELS(&clabels)";
      proc contents data=&clabels;
         run;
      proc print data=&clabels;
         run;
      %end;


   /*
   / Flow the footnote data so that the footnotes will fit in
   / the linesize chosen for the table.
   /---------------------------------------------------------*/

   data
      &headfoot
         (
          keep = _fn: _fi:  _en:  tfnlines hlleft hlright
                 _hl:
         )
      ;

      retain _hl0 &hl0 _hl1-_hl15;
      retain hlleft "&hlleft" hlright "&hlright";

      array _hl[15] $&ls
         ("&hl1","&hl2","&hl3","&hl4","&hl5","&hl6","&hl7","&hl8","&hl9","&hl10",
          "&hl11","&hl12","&hl13","&hl14","&hl15");


      array _xn[15] $200 _temporary_
         ("&fnote1",  "&fnote2",  "&fnote3",  "&fnote4",  "&fnote5",
          "&fnote6",  "&fnote7",  "&fnote8",  "&fnote9",  "&fnote10",
          "&fnote11", "&fnote12", "&fnote13", "&fnote14", "&fnote15");

      array _xi[15] $2 _temporary_
         ("&findt1",  "&findt2",  "&findt3",  "&findt4",  "&findt5",
          "&findt6",  "&findt7",  "&findt8",  "&findt9",  "&findt10",
          "&findt11", "&findt12", "&findt13", "&findt14", "&findt15");

      array _fi[15];
      array _sz[15];

      do i = 1 to dim(_xi);
         if _xi[i]=' '
            then _fi[i] = max(&indentf,0);
            else _fi[i] = input(_xi[i],2.);
         _sz[i] = &ls - _fi[i];
         end;


      do i = 1 to dim(_xn);
         _xn[i] = compbl(_xn[i]);
         end;


      %jkflsz2(in=_xn,out=_fn,size=&ls,sizear=_sz,dim1=15,dim2=5)

      do i = 1 to dim1(_fn);
         do j = 1 to dim2(_fn);
            _fn[i,j] = translate(_fn[i,j],' ',"&hrdspc");
            end;
         end;

      tfnlines = sum(of _fn0_[*]);

      _en0 = min(&enote0, 10);
      array _en[10] $200
         ("&enote1","&enote2","&enote3","&enote4","&enote5",
          "&enote6","&enote7","&enote8","&enote9","&enote10");


      output;
      run;

   %if &debug %then %do;
      title5 "DATA=HEADFOOT(&headfoot) The titles footnotes and endnotes data";
      proc print data=&headfoot;
         run;
      %end;


   /*
   / Reduce the data to one observation per AE.
   / This dataset will be used to pre-print the table
   /----------------------------------------------------------*/

   proc summary data=&data nway missing;
      class &pageby &order1 &level1 &order2 &level2;
      var _1lv0 _2lv0;
      output out = &fprint(drop=_type_ _freq_)
             max = ;
      run;

   %if &debug %then %do;
      title5 "DATA=FPRINT(&fprint) created by PROC SUMMARY";
      proc print data=&fprint;
         run;
      %end;


   proc summary data=&fprint nway missing;
      class &pageby &order1 &level1;
      var _2lv0;
      output out=&lines(drop=_type_ rename=(_freq_=_lines_))
             sum=sum_2lv0;
      run;

   %if &debug %then %do;
      title5 "DATA=LINES(&lines)";
      proc print data=&lines;
         run;
      %end;




   data &fprint;
      merge
         &fprint
         &lines;

      by &pageby &order1 &level1;

      if _n_ = 1 then do;
         set     &cnst(keep=ps ls l1size l1pct l1pctmin pbylines);
         set  &clabels(keep=clrows);
         set &headfoot(keep=tfnlines _en0 _hl0);

         retain fline0 hline0;

         retain flev1 &flev1 skip1 &skip1;

         hline0 = _hl0 + clrows + 3 + pbylines;

         /*
         / JHK003
         / Changed +2 to +1 + &contmsg
         /----------------------------------------------*/
         fline0 = tfnlines + _en0 + &contmsg + 1;

      %if ^&rbit1 %then %do;
         drop ps ls l1size l1pct l1pctmin clrows _hl0
              tfnlines _en0 pbylines cll need1 need2  l1flag
               _1lv0  _2lv0  _lines_  sum_2lv0  fline0  hline0
               ll  effps used flev1 skip1;
         %end;

         end;

      retain ll effps l1flag;

   %if %bquote(&pageby) > %then %do;
      if first.&_pgbylst then link header;
      %end;
   %else %do;
      if _n_=1 then link header;
      %end;

      cll = ll;

      if first.&level1 then do;
         l1flag = 0;
         need1 = sum_2lv0 + (_1lv0-1) + &flev1 + &skip1;
         need2 = max(ceil(need1 * l1pct),l1pctmin);
         link level1;
         end;
      else if ^l1flag then do;
         link ll;
         end;

      select;
         when(first.&level1 & last.&level1) used = (&flev1 + &skip1 + (_1lv0-1));
         when(first.&level1)                used = (&flev1 + (_1lv0-1));
         when(last.&level1)                 used = (max(1,_2lv0) + &skip1);
         otherwise                          used =  _2lv0;
         end;

      ll = ll - used;

      return;

    Header:
      /*
      / Subtract the lines taken up by the header
      / and footer.
      /------------------------------------------------------*/
      page + 1;
      ll    = ps - (hline0 + fline0 + ^first.&level1);
      effps = ll;
      return;

    LL:

      if ll < (first.&level1*&flev1 + (_1lv0-1))
            + (last.&level1*&skip1) + _2lv0 + 1 then do;
         link header;
         end;

      return;

    Level1:

      if need1 < l1size then do;
         l1flag = 1;
         if ll < need1 then do;
            link header;
            end;
         end;
      else if need1 <= ll then do;
         l1flag = 1;
         end;
      else do;
         if ll < need2 then link header;
         end;

      return;

      run;

   data &fprint;
      /*
      / JHK008
      / Added end=eof and IF EOF statement
      / And last.&_pgbylst
      /----------------------------------------------------------*/
      set &fprint end=eof;
      by &pageby &order1 &level1 page;
      if last.page  & ^(last.&level1)  then cont=1;
      if first.page & ^(first.&level1) then cont=1;
      if eof then cont = 0;

      %if %bquote(&pageby) > %then %do;
         if last.&_pgbylst then cont=0;
         %end;

      run;


   %if &debug | &rbit1 %then %do;
      title5 "DATA=FPRINT(&fprint) before sort and merge";
      proc contents data=&fprint;
         run;
      proc print data=&fprint;
         format &level1 &level2 $8.;
         run;
      %end;


   proc sort data=&fprint;
      by &pageby &order1 &level1 &order2 &level2;
      run;

   %if &debug %then %do;
      title5 "DATA=FPRINT(&fprint) after sorting, before merge to AEdata";
      proc print data=&fprint;
         run;
      %end;

   data &fprint;
      merge &fprint &data;
      by &pageby &order1 &level1 &order2 &level2;
      run;


   %if &debug %then %do;
      title5 "DATA=FPRINT(&fprint) after merge to FLOWED AEdata";
      proc print data=&fprint;
         run;
      %end;


   /*
   / Sort the input data by TREATMENT and merge with the data set of
   / treatments and panels.
   /--------------------------------------------------------------------------*/

   proc sort data=&fprint;
      by &pageby &tmt;
      run;

   data &fprint;

      retain &pageby page panel &order1 &level1 &order2 &level2 &tmt;
      merge &fprint &panel;
      by &pageby &tmt;


   %if %index(&pctfmt,JKPCT) %then %do;

      %if &pctstyle=1 %then %do;
         if pct > .Z  then do;
            pct = pct * 1E2;
            select;
               when(0 <  pct < 1)   pct=.A;
               when(99 < pct < 100) pct=.B;
               otherwise            pct=round(pct,1);
               end;
            end;
         %end;
      %else %if &pctstyle=2 %then %do;
         if pct > .Z then do;
            pct = pct * 1e2;
            select;
               when(0    < pct < 0.5) pct=.A;
               when(99.5 < pct < 100) pct=.B;
               otherwise              pct=round(pct,1);
               end;
            end;
         %end;
      %end;

      run;

   proc sort data=&fprint;
      by &pageby page panel &order1 &level1 &order2 &level2 &tmt;
      run;

   %if &debug %then %do;
      title5 "DATA=FPRINT(&fprint) Ready to be printed by data _null_";
      proc contents data=&fprint;
         run;
      proc print data=&fprint;
         format _character_ $8.;
         run;
      %end;

   proc format;
      picture jkpct
           1-99,100 = " 009&pctsign)" (prefix='(')
                  0 = "     "         (noedit)
                 .A = " (<1&pctsign)" (noedit)
                 .B = "(>99&pctsign)" (noedit);
      run;


   %if &hppcl %then %do;
      /*
      / Call JKHPPCL to setup printing environment
      /-------------------------------------------*/
      %jkhppcl(cpi=&cpi,lpi=&lpi,layout=&layout)

      data _null_;
         file "&outfile..PCL" print notitles ls=200;
         &setup
         run;
      %end;

   %let _outfile = &outfile%str(.)&file_ext;

   options missing=' ';

   data _null_;
      file "&outfile%str(.)&file_ext"
            &file_dsp
            print
            notitles
            ls   = 200
            ps   = &ps
            n    = ps
            line = putline;

      set &fprint end=eof;
      by &pageby page panel &order1 &level1 &order2 &level2 &tmt;

      retain xcont &xcont style1 "&style1" skip1 &skip1 _one_ 1;

      if _n_ = 1 then do;
         set
            &cnst
               (
                keep = _tc1-_tc&cols _tw1-_tw&cols cols coff pcoff tcols
                       style pvalue between iwid swid
               )
            ;

         array _tc[&colsplus] _tc1-_tc&cols _one_;
         array _tw[&colsplus] _tw1-_tw&cols swid;

         set &headfoot;
         array _fn0_[15];
         array   _fn[15,5];
         array   _fi[15];

         array _en[10];
         array _hl[15];

         end;


      array _1lv[10];
      array _2lv[10];


      if first.panel then do;
         set &clabels(keep=&pageby panel clrows _cl:) key=&idx / unique;

         array _cl0_[&colsplus];

         /*
         / JHK004
         / changed 5 to 10
         /---------------------------*/
         array   _cl[&colsplus,10];

         put _page_ @;
         link header;
         end;

      if first.&level1 | _top_ then do;
         if cont then put '... continuing ' &level1:&fmtlvl1;
         else do;
            if style1='2' then do;
               select(_1lv0);
                  when(1) put _1lv[1] @;
                  otherwise do;
                     put _1lv[1];
                     do i = 2 to _1lv0-1;
                        put +(&findent1) _1lv[i];
                        end;
                     put +(&findent1) _1lv[_1lv0] @;

                     end;
                  end;
               end;

            else if style1='1' then do;
               select(_aetype_);
                  when(0) select(_1lv0);
                     when(1) put _1lv[1] @;
                     otherwise do;
                        put _1lv[1];
                        do i = 2 to _1lv0-1;
                           put +(&findent1) _1lv[i];
                           end;
                        put +(&findent1) _1lv[_1lv0] @;
                        end;
                     end;
                  otherwise do;
                     put _1lv[1];
                     do i = 2 to _1lv0;
                        put +(&findent1) _1lv[i];
                        end;
                     end;
                  end;
               end;

            end;
         end;


   %if %bquote(&level2) > %then %do;

      if first.&level2 then do;
         ncol = 0;
         select(style1);
            when('1')                      put +(&indent2) _2lv[1] @;
            when('2') if _aetype_ > 1 then put +(&indent2) _2lv[1] @;
            otherwise;
            end;
         end;

      %end;
   %else %do;
      if first.&level1 then ncol = 0;
      %end;

      if first.&tmt then ncol + 1;

   %if ^(&displvl1) %then %do;
      if _aetype_ > 1 then do;
         select(style);
            when('1') put @(_tc[ncol]+coff) n_pats &ifmt pct &pctfmt @;
            when('2') put @(_tc[ncol]+coff) n_evts &ifmt +1 n_pats &ifmt pct &pctfmt @;
            when('3') put @(_tc[ncol]+coff) n_pats &ifmt "/" denom &ifmt pct &pctfmt @;
            end;
         end;
      %end;
   %else %do;
      select(style);
         when('1') put @(_tc[ncol]+coff) n_pats &ifmt pct &pctfmt @;
         when('2') put @(_tc[ncol]+coff) n_evts &ifmt +1 n_pats &ifmt pct &pctfmt @;
         when('3') put @(_tc[ncol]+coff) n_pats &ifmt "/" denom &ifmt pct &pctfmt @;
         end;
      %end;

   %if %bquote(&level2) > %then %do;
      if last.&level2 then do;
      %end;
   %else %do;
      if last.&level1 then do;
      %end;

      /*
      / If the user requested PVALUE=YES
      /----------------------------------------------------------*/
      %if &pvalue %then %do;
         array _pvars[*] &pvars;
         j = tcols;
         do i = 1 to dim(_pvars);
            j = j + 1;
            if .Z < _pvars[i] < 0.001 then do;
               cprob = '<0.001';
               put   @(_tc[j]+pcoff) cprob $6. @;
               end;
            else do;
               put @(_tc[j]+pcoff) _pvars[i] 6.3 @;
               end;
            end;
         %end;

         put;

         do i = 2 to _2lv0;
            put +(&findent2+&indent2) _2lv[i];
            end;

         end;



   %if %bquote(&level2) > %then %do;

      if style1 = '1' then do;
         if last.&level1 & ^last.panel then put;
         end;
      else do;
         if last.&level1 & ^last.panel then put;
         end;
      %end;

   %else %do;
      if style1 = '1'  | style1='2' then do;
         if last.&level1 & ^last.panel then do i = 1 to skip1;
            put;
            end;
         end;
      %end;

      if last.panel then link footer;

      if eof then do;
         call symput('JKPG0',trim(left(put(realpage+&jkpg0,8.))));
         end;

      return;

    Header:

      realpage + 1;

      _top_ = 1;

      length _tempvar $&ls;

      do i = 1 to _hl0;
         select;
            when(indexw(hlright,put(i,2.))) do;
               _tempvar = _hl[i];
               _tempvar = right(_tempvar);
               _tempvar = translate(_tempvar,' ',"&hrdspc");
               put #(i) _tempvar $char&ls..;
               end;
            when(indexw(hlleft, put(i,2.))) do;
               _tempvar = _hl[i];
               _tempvar = left(_tempvar);
               _tempvar = translate(_tempvar,' ',"&hrdspc");
               put #(i) _tempvar $char&ls..;
               end;
            otherwise do;
               _tempvar = left(_hl[i]);
               _tempvar = repeat(' ',floor((&ls-length(_tempvar))/2)-1)||_tempvar;
               _tempvar = translate(_tempvar,' ',"&hrdspc");
               put #(i) _tempvar $char&ls..;
               end;
            end;
         end;

   %if %bquote(&pageby) > %then %do;
      put %unquote(&putby);
      %end;

      put;

      do i = 1 to max(of _cl0_[*],0);
         do j = _cl0;
            _wid     = _tw[j];
            _cl[j,i] = translate(_cl[j,i],' ',"&hrdspc");
            put @(1) _cl[j,i] $varying100. _wid @;
            end;

         do j = 1 to _cl0-1;
            _wid     = _tw[j];
            _offset  = floor( (_tw[j]-length(_cl[j,i])) / 2 );
            _cl[j,i] = translate(_cl[j,i],' ',"&hrdspc");
            put @(_tc[j]+_offset) _cl[j,i] $varying100. _wid @;
            end;
         put;
         end;





      put &ls*&dashchr;
      put;

      return;

    Footer:

      if cont then put &level1:&fmtlvl1 'continues ...';
      put;

   /*
   / JHK003
   / CONTMSG, added macro if statement
   /-------------------------------------------------------*/
   %if &contmsg %then %do;
      if ^eof then do;
         length xnote $&ls;
         retain xnote 'Continued...';
         put xnote $&ls..-r;
         end;
      %end;

      do i = 1 to _fn0;
         do k = 1 to _fn0_[i];
            if k = 1
               then put    _fn[i,k] $char&ls..;
               else put +(_fi[i]+0) _fn[i,k] $char&ls..;
            end;
         end;

      k = _en0;
      do i = 1 to _en0;
         put #(&ps-k+1) _en[i] $&ls..-l;
         k = k - 1;
         end;
      return;
      run;

   proc delete
      data = &panel &bign &cnst &header &footer &dclrows &fprint &lines
             &panel2 &flowed
         ;
      run;


   %put NOTE: JKPG0=&jkpg0;

   %if %bquote(&pagenum) = PAGEOF %then %do;
      data _null_;

         infile "&outfile%str(.)&file_ext" sharebuffers n=1 length=l;
         file   "&outfile%str(.)&file_ext";

         input line $varying200. L;

         if index(line,&target) then do;
            page + 1;

            text = Compbl('Page '||put(page,8.)||" of &jkpg0");
            tlen = length (text);

            substr(line,1+&ls-tlen,tlen) = text;

            put line $varying200. L;

            end;

         run;
      %end;

   %GOTO EXIT;

 %EXIT:
   %PUT NOTE: Macro AETAB ending execution.;

   %mend AETAB;
