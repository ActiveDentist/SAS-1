/*
/ PROGRAM NAME:     DTAB.SAS
/
/ PROGRAM VERSION:  3.1
/
/ PROGRAM PURPOSE:  Creates tables using a special data set that has
/                   the same structure as a SIMSTAT outstat data set.
/
/ SAS VERSION:      6.12 (UNIX)
/
/ CREATED BY:       John Henry King
/
/ DATE:             FEB1997
/
/ INPUT PARAMETERS: See details below.
/
/ OUTPUT CREATED:   A SAS print file.
/
/ MACROS CALLED:    JKCHKDAT - check input data for correct vars and type
/                   JKXWORDS - count words and create an array of the words.
/                   JKLY0T01 - setup the page layout macro variables.
/                   JKFLSZ2  - Flow text, into 2 dimensional array
/                   JKFLOWX  - Flow text, into 1 dimensional array.
/                   JKHPPCL  - My version of HPPCL, to setup printer.
/                   JKSTPR01 - Process STATS= and STATSFMT=
/                   JKRORD   - Used to order output as specified in ROWS=
/                   JKDASH   - Process dashes in ROWS=
/                   JKRLBL   - Process row labels in ROWS=
/                   JKRFMT   - Process row variable formats in ROWSFMT=
/
/ EXAMPLE CALL:     %DTAB(data=example,
/                      outfile=example,
/                          tmt=NTMT,
/                         rows=SEX AGE WGT HGT ETHORIG);
/
/====================================================================================
/ CHANGE LOG:
/
/    MODIFIED BY: John Henry King
/    DATE:        OCT1997
/    MODID:       JHK001
/    DESCRIPTION: Changes need to make macro conform to IDSG standards
/                 1) changed FOOTDASH default to NO.
/                 2) changed JOBID default to NO.
/                 3) changed PVALUE default to NO.
/                 4) removed _PATNO_ from default addition to ROWS list.
/                 5) changed presendation style of DISCrete variable to make the
/                    first row the n for that variable.
/                 6) removed the dashed line after the titles and before the
/                    column headers.
/    ---------------------------------------------------------------------------
/    MODIFIED BY: Jonathan Fry
/    DATE:        09DEC1998
/    MODID:       JMF002
/    DESCRIPTION: Tested For Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 3.1.
/    ---------------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX003
/    DESCRIPTION:
/    ---------------------------------------------------------------------------
/==================================================================================*/
/*
/
/ Macro DTAB
/
/ -----------------------------------------------------------------------------
/
/ Example programs located in:
/
/
/ -----------------------------------------------------------------------------
/
/ Use this macro to produce a demographic table, with demographic variables
/ down the left side, SEX, AGE, WEIGHT, HEIGHT and ETHORIG for example.
/ Where a treatment variable forms the columns of the table.  The macro
/ will fit the columns onto the page using as may PANELS, logical pages, as
/ needed to display all the columns.  The table may also include a p-value
/ column for an overall test of the treatments.  If the table needs more than
/ one panel then the p-value column is repeated on each panel.
/
/ -----------------------------------------------------------------------------
/
/ USING VALUE LABELING FORMATS with DTAB.........
/
/ The macro uses value labeling formats provided by the user to label various
/ parts of the table.
/
/ For each ROW variable named in the ROWS= parameter the
/ user would provide labels through a value labeling format name $_VNAME_.
/
/ For example:
/     where ROWS=SEX AGE WEIGHT, you might use.
/ value $_vname_
/    'SEX'     = 'Sex'
/    'AGE'     = 'Age (years)'
/    'WEIGHT'  = 'Weight (pounds)'
/    '_PATNO_' = 'Number of patients';
/
/ The values for _PATNO_ label the patient number row that is automatically
/ created by macro SIMSTAT.
/
/ For each discrete variable the user would need to provide a value labeling
/ format to label the coded values of the discrete variable.
/ For example the if variable SEX has values M and F.
/ The use would then provide a $SEX format.  The user
/ should be carefull to use variable names for discrete variables that can
/ also produce valid format names.  For example format names cannot end with
/ a number.  Also some commonly used variable names like DAY or DATE are
/ format names provided by SAS.  If you try to create a user format with
/ one of these
/ names you will receive an error message, however the macro will still run
/ using the SAS provided format.  This could produce very strange results.
/
/ Using the SEX variable the user would write something like the following.
/ value $sex
/    'M' = 'Male'  'F' = 'Female';
/
/ Note that the macro will print the values of the discrete variables in collating
/ sequence, alphabetical order in most cases.  If you want a different order
/ you will need to recode your discrete variables.  One character discrete
/ variables can easily be recoded with the translate function.  For example
/ to have males printed before females use:
/
/    sex = translate(sex,'12','MF');
/
/ Missing values for discrete variables are counted and given the value underscore "_".
/ If your discrete values contain missing values then you should provide an
/ approiate label, data not available, for example.
/
/
/ The uses must also provide column labels for the columns associated with the
/ levels of the TMT= variable, see TMT= below.  This value labeling format
/ must have the same name as the name of the treatment variable used in the
/ TMT= parameter.  For example.
/
/  value ntmt
/     1 = 'Placebo'
/     2 = 'Ond 25ug bid'
/     3 = 'Ond 1mg bid'
/     4 = 'Ond 4mg bid'
/     5 = 'Diazepam 5mg bid'
/     ;
/
/
/ If the user needs to print more than one p-value through the PVARS=
/ parameter the labels for there columns are given by the $PVARS value labeling
/ format.  For example.
/
/   value $pvars
/     'P1_2' = 'Pla vs 25ug'
/     'P1_3' = 'Pla vs 1mg'
/     'P1_4' = 'Pla vs 4mg'
/     'P1_5' = 'Pla vs Diaz'
/     ;
/
/ -----------------------------------------------------------------------------
/
/ USING TITLES, FOOTNOTES, ENOTES, AND RLABELS with DTAB...........
/
/ TITLES:
/ The user may specify up to 15 titles lines for the table.  These title lines
/ are centered by default.  The user may request that one or more of these
/ lines be right justified, by assigning the title line numbers to HLRIGHT a
/ global macro variable.  The user may also specify which title line will
/ contain the text (Continued), if the table has more than one panel.  See
/ example below and or the example programs referred to above.
/
/
/ FOOTNOTES:
/ Footnote lines are printed and the bottom of the table just below the dashed
/ line drawn after the last ROWS= variable.  Footnote lines that are longer
/ than the linesize are flowed to fit.  You may have up to 15 footnotes.
/
/ ENOTES:
/ End note lines are printed at the bottom of the page, starting at the last line
/ on the page and working upward.  You may have up to 10 end notes.  End notes
/ are truncated to the line size of the table.  Typically end notes are used for
/ the JOBID line.
/
/ RLABELS:
/ Row label lines are used to further annotate the rows.
/
/
/ -----------------------------------------------------------------------------
/
/ Parameter=Default    Description
/ -----------------    --------------------------------------------------------
/
/
/ DATA =               The input data set, this data set must be output from
/                      macro SIMSTAT, or data that has that same structure.
/
/ OUTFILE =            Specifies the name of the file that will receive the
/                      table.  Do NOT include an extension for the file.
/                      The default when OUTFILE is left blank is to use
/                      the named returned by %FN.
/
/ DISP =               Use DISP=MOD to cause DTAB to append its output to the
/                      file named in the OUTFILE= option.  You should not change
/                      the layout of the file that is being appended to.
/
/ TMT =                An INTEGER NUMERIC variable that represents the levels
/                      of treatments.  This is the same variable used in the
/                      TMT= parameter in SIMSTAT.
/
/ TMTFMT =             This parameter is used to specify the format for the treatment
/                      variable named in the TMT= parameter.  When this parameter is
/                      left blank the macro uses a format with the same name as the
/                      TMT= parameter.
/
/ ROWS =               This parameter specifies the names of the variables
/                      that are to be displayed in the rows of the table.
/                      For example for a DEMOGRAPHICS table you might use
/
/                      ROWS = SEX AGE WEIGHT HEIGHT ETHORIG
/
/                      The macro will produce the table with the rows ordered
/                      according to the order they appear in the ROWS =
/                      parameter.
/
/                      The user may also call for dashed lines and extra row
/                      labeling.  Dashed lines between the rows are requested
/                      by placing a dash, or minus sign, "-" in the ROWS=
/                      parameter between the variables names where a dashed line
/                      is desired.
/
/                      The user may also request extra row labels through the
/                      RLABEL global variables.  These lables are positioned by
/                      using a plus sign "+" in the ROWS= parameter where the
/                      row label text is desired.  See the discussion of RLABELS
/                      for more details.
/
/                      Use a data step to delete the observations from the SIMSTAT
/                      data if you do not want DTAB to display the _PATNO_ data.
/
/ ROWSFMT=             Specifies expliciate formats for variables named in the ROWS=
/                      parameter.  The default is to use formats with the same names
/                      as the ROWS= variables.  The option is particularly useful when
/                      the many row variables have the same format.
/
/
/ YNLABEL=NO           This parameter causes DTAB to translate DISCRETE variables
/                      with Y|N as their value to Yes|No, without giving the variables
/                      a format.  This parameter is usefull when DTAB is used to display
/                      many YES|NO variables.
/
/ ROW_OF_N=YES         This parameter causes DTAB to print the N for DISCRETE variables
/                      in a seperate row labeled 'n'.
/
/ STBSTYL=COLUMN       This parameter causes DTAB to print the table stub in a two column
/                      style as opposed to the older one column style.  Use STBSTYL=ROW
/                      to get DTAB to operate in the older column style.
/
/ MISSING=NO           This parameter causes DTAB NOT to display the missing values for
/                      discrete variables.
/
/ BOX = '!'            This parameter specifies a text string that is printed above
/                      the table stub in the row associated with the column labels.
/                      It is somewhat analogus to the BOX= parameter in PROC TABULATE.
/                      Box text is flowed into SWID and can include the new line '\'
/                      character or the HRDSPC character to control spacing.
/
/
/ STYLE = 1            Specifies the style for printing discrete variables
/                      counts and percents.
/
/                      1 = nn (pp)
/                      2 = nn/NN (pp)
/                      3 = nn
/                      4 = nn/NN
/                      0 = no adjustment
/
/                      Normally DTAB tries to center the values under the column
/                      labels.  This is done by calculating the width based on
/                      the STYLE and adding spaces until the values are centered.
/                      Some times this action is not desired.  The user can then
/                      use STYLE=0 to suppress this adjustment.  The user can
/                      then use COFF=(column offset) to adjust the values if
/                      needed.
/
/
/
/ STATS = MEAN STD MIN-MAX N
/
/                      This parameter list the statistics, to print for each
/                      _VTYPE_=CONT variable in the input data.  The order of the
/                      statistic names, specifies the order that the statistics
/                      are printed down the page.  If the user specifies MIN-MAX
/                      the macro prints min and max on the same line with a dash
/                      between them.  If the use specifies MIN space MAX then the
/                      min and max are printed on different lines.
/
/ STATHOLD = 0         Use this yes|no, 0|1 parameter to cause DTAB print a
/                      statistic on the same line as the variable that it is
/                      associated with.  You should only use this parameter when
/                      ONE statistic is requested.
/
/ STATSFMT =           This parameter is used to associate formats to the statistics
/                      named in the STATS= parameter. The format for this parameter is
/
/                      var_name(stats_list format_specification ...) ...
/
/                      where:
/                        var_name is a continuous variable named in ROWS=
/                        stats_list is a list of statistics to be printed, MEAN STD etc.
/                        format_specification if a SAS format say F6.2 perhaps.
/
/                      The list can be repeated for each continuous variable.  And the
/                      special name _ALL_ can be used to effect all continuous variables.
/
/                      Example:
/
/                         ROWS=AGE RACE SEX WT HT BSA BDMSIX,
/                         STATSFMT=wt(min max 5.1 mean median std 6.2)
/                                 bsa(min max 6.2 mean median std 7.3)
/                              bdmsix(min max 5.1 mean median std 6.2),
/
/
/ JOBID = NO           Use this parameter to control the dispay of source program
/                      tracking information.  The default is to display the JOBID
/                      data as an ENOTE.
/
/ SKIP = 0             Use this parameter to put blank lines between the values of
/                      _LEVEL_s for discrete variables.
/
/ VSKIP = 0            Controls the number of blank lines that appear between the last line
/                      of the label text associated with a variable and the statistics
/                      that are printed for that variable.
/
/ VSKIPA = 1           Controls the number of blank lines that appear after the statistics
/                      for a variable and before the label text for the next variable.
/
/ INDENT = 2           Use this parameter to indent the formatted values of discrete
/                      variables.
/
/ INDENTC = 2          This is the number of columns that the statistics labels for
/                      continious variables are indented.
/
/ INDENTF = 4          This parameter controls the number of columns that a continued
/                      footnote line is indented.  The footnotes are flowed into the
/                      linesize with the first line left justified and subsequent lines
/                      indented the number of columns specified by this parameter.
/
/                      Footnote lines may also have individual indenting controled by
/                      the FINDTn macro variables.  For example:
/
/                      %let fnote2 = this is the footnote.
/                      %let findt2 = 6;
/
/                      In this example if footnote 2 was flowed onto a second then that
/                      second line would be indented 6 spaces.
/
/ INDENTV = 0          Use this parameter to indent the formatted values of the
/                      values of _VNAME_.
/
/ INDENTVC = 0         Use this parameter to control the number of columns that
/                      the 2nd, 3rd, ... flowed values of the formatted values
/                      of the _VNAME_ variable are indented.
/
/ INDENTLC = 1         Use this parameter to control the number of columns that
/                      the 2nd, 3rd, ... flowed value of _LEVEL_ variables are
/                      indented when FLOW=_LEVEL_.
/
/ HRDSPC = !           This is the hard space parameter.  A hard or significant space
/                      is a space that holds it significance even when to text is flowed
/                      or justified, right, left, centered.  You can use the hardspace
/                      in titles, footnotes, formats associated with _VNAME_ and _LEVEL_
/                      values, and rlabels.
/
/ FLOW =               This parameter can be used to have the macro flow the
/                      text associated with the formated values of _LEVEL_ for
/                      discrete variables.  The user would specify FLOW=_LEVEL_.
/                      Use flow when the formated values of the _LEVEL_ values
/                      associated with a discrete variable are longer than the
/                      values specified by SWID.  This parameter can also be used
/                      to have the macro flow the text associated with RLABELs.
/                      The user could have the text associated with RLABEL2 flowed
/                      into the linesize of the table with FLOW=RLABEL2.
/                      The user can have the text split at a specific place by
/                      placing a backslash character at the point where the
/                      split is desired.
/
/
/ IFMT = 3.            Specifies the format for printing integer variables.
/                      Counts and totals.
/
/ RTMT = 5.1           Specifies the format for printing continious variables, if
/                      no format is specified on the STATS= parameter.
/
/ PCTFMT = JKPCT5.     Specifies the format for printing percents associated
/                      with discrete variables.  The default JKPCT5.
/
/ PCTSTYLE = 1         This parameter is used to modify the way percents are
/                      rounded when being print with the JKPCTn. format.
/
/                      PCTSTYLE=1 rounds and prints as follows.
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
/                      While PCTSTYLE=2 rounds and prints as follows.
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
/ PCTSIGN = NO         This parameter controls the inclusion of a percent sign in
/                      printing of percents
/
/ PVALUE = NO          Print p-value on the table?
/
/ PVARS  = PROB        A list of p-values to print at the right side of the table.
/                      This can be useful for printing pairwise p-values on a table.
/                      This list of p-values appears in ALL panels.
/
/ CPVARS1 =            Use CPVARS to specify extra PVARS like data that is printed
/ CPVARS2 =            below the PVARS rows.  These variable must be character.
/ CPVARS3 =            Currently CPVARSn are printed with a $char format equal to
/ CPVARS4 =            value of PWID=.
/ CPVARS5 =
/
/ PLABEL = 'p-value [1]'
/                      Plabel specifies the label for the p-value column.
/                      This is used when there is only one p-value.  If pairwise
/                      p-values are displayed then the user should supply a
/                      values labeling format $PVARS to label the p-value columns.
/
/
/ PFLAG = 0            Use the PFLAG parameter have DTAB label a p-value with
/                      and asterick when the CONTROLling variable is less than
/                      the value specified in PLEVEL.
/
/ PLEVEL = .05         The plevel parameter determines the level of significance
/                      for the controlling variable p-value to flag a treatment
/                      pvalue.
/
/
/ LAYOUT = PORT        This is the arrangement of the table on the printed
/                      page.  This parameter works the same as in the HPPCL
/                      macro developed by J.COMER.
/
/ CPI = 17             The number of characters per inch on the printed page.
/                      Possible values are 12 and 17.
/
/ LPI = 8              The number of lines per inch. Possible values are
/                      6, 8, and 10.
/
/ SWID = 20            The width of the table STUB, in number of characters.
/                      The part of the table that identifies the table rows.
/
/ RLWID=SWID           This parameter defines the width of flowed rlabel text.
/                      The default RLWID=SWID uses the same value specified by
/                      the SWID parameter.  Otherwise the value can be a positive
/                      integer less that or equal to the linesize for the table.
/                      RLWID=LS can be used to have the macro use the current
/                      linesize for the table as the value of RLWID.
/
/ RLOCATE=LAST         This parameter is used tell the macro where to place
/                      RLABEL text.  The default is to print the RLABEL text
/                      after printing the variable it is assocated.  RLOCATE=FIRST
/                      prints the RLABEL text before the variable.
/
/ CWID = 10            The number characters to allow for each treatment
/                      column in the table.
/
/ COFF =               Use this parameter to override the column offset that is
/                      calculated based on the value of the STYLE= parameter.
/                      Valid values are positive intergers less than CWID.
/
/ PWID = 8             The number of characters to allow for each P-value
/                      column.
/
/ PCOFF =              This parameter controls the number spaces printed to the
/                      left of the PVAR and CPVARSn parameters.  This parameter
/                      is especially useful when CPVARSn is specified.
/
/ BETWEEN = 0          The number of characters to place between each column.
/                      When this parameter is 0 then the columns are spaced
/                      to fill out the linesize of the table.
/
/ SBETWEEN = 2         The number of spaces between the table stub and the first
/                      treatment column.
/
/ PBETWEEN = 3         The number of spaces between the last treatment column and the first
/                      p-value column.
/
/ BETWEENP = 2         Specifies the number of spaces to put between the p-value columns.
/
/ SMIN = 20            Minimum values for each of the column width parameters
/ CMIN = 8
/ PMIN = 6
/
/ PAGENUM =            The PAGENUM=PAGEOF option allows the output from DTAB to
/                      be numbered in the style "Page n of p".  Currently this text
/                      is displayed only on the JOBID line that is printed by DTAB.
/                      If you use the DISP=MOD option in your DTAB then you should
/                      request PAGENUM=PAGEOF on the LAST call to DTAB only.
/                      When DTAB is running with DISP=DISP a cumulative total of
/                      pages and kept so that the pages can be number inclusively.
/
/ TARGET=              This option is used in association with the PAGENUM= option.
/                      TARGET= specifies a character string that will be searched
/                      for when the macro is numbering pages.  The target is used
/                      to locate the "Page n of p" text.  The default value for
/                      target is the value of OUTFILE=.
/
/ CONTMSG = NO         The contmsg parameter is used to cause DTAB to write a continued
/                      message in the footnote area.  This is useful when you are
/                      producing a table with more than one page, using two or more
/                      calls to DTAB.
/
/ FOOTDASH = NO        This parameter turns on and off the dashed line that is
/                      drawn before the footnotes are produced.
/
/-------------------------------------------------------------------------------------------------
/ EXAMPLE:
/
/ The following is an example program and output from macro DTAB.  This example uses
/ a dataset produced by macro SIMSTAT.
/
/ proc format;
/    value ntmt
/       1 = 'Placebo'
/       2 = 'Ond 25ug bid'
/       3 = 'Ond 1mg bid'
/       4 = 'Ond 4mg bid'
/       5 = 'Diazepam 5mg bid'
/       ;
/    value $ethorig
/       'A','4' = 'Asian'
/       'C','1' = 'Caucasian'
/       'H','5' = 'Hispanic'
/       'M','7' = 'Mongoloid'
/       'N','2' = 'Negroid/Black'
/       'O','6' = 'Other'
/       'U','8' = 'Unanswered'
/       'Z','3' = 'Oriental'
/       '_'     = 'Data not available';
/       ;
/    value $sex
/       'F' = '  Female'
/       'M' = '  Male'
/       '_' = '  Data not available'
/       ;
/    value $_vname_
/       '_PATNO_' = 'Number of patients who received at least one dose of the study drug'
/       'SEX'     = 'Sex, n(%)'
/       'AGE'     = 'Age (y)'
/       'WGT'     = 'Weight (lb)'
/       'HGT'     = 'Height (in)'
/       'ETHORIG' = 'Ethnic origin, n(%)'
/       ;
/    run;
/
/
/ %let  hlright = 1 2 3;
/ %let  hlcont  = 4;
/
/ %let  hl0 = 6;
/ %let  hl1 = Drug: Ondansetron;
/ %let  hl2 = Protocol: S3A210;
/ %let  hl3 = Population: Safety;
/ %let  hl4 = TABLE 4;
/ %let  hl5 = Demography;
/ %let  hl6 = Number (%) of Patients and Summary Statistics;
/
/ %let fnote0=2;
/ %let fnote1=The p-values for sex and ethnic origin based on the chi-square test and for
/ age, height, and weight on the vanElteren test.;
/ %let fnote2=This table produced with macro SIMSTAT and DTAB.;
/
/ %let enote0=3;
/ %let enote1=Supporting data listing in Appendix DL-xx, Vol ___, Page ___;
/ %let enote3=%quote(&jobid);
/
/
/ %DTAB(data=example,
/      outfile=example,
/         tmt=NTMT,
/        rows=SEX AGE WGT HGT ETHORIG)
/
/
/-------------------------------------------------------------------------------------------------
/-------------------------------------------------------------------------------------------------

                                                                                 Drug: Ondansetron
                                                                                  Protocol: S3A210
                                                                                Population: Safety
                                             TABLE 4
                                            Demography
                          Number (%) of Patients and Summary Statistics
--------------------------------------------------------------------------------------------------

                                       Ond 25ug     Ond 1mg      Ond 4mg      Diazepam    p-value
                          Placebo        bid          bid          bid        5mg bid       [1]
--------------------------------------------------------------------------------------------------

Number of patients
 who received at
 least one dose of
 the study drug            98           92           97           97           92
--------------------------------------------------------------------------------------------------

Sex, n(%)                                                                                   0.606
  Female                   45 (46)      34 (37)      46 (47)      43 (44)      43 (47)
  Male                     53 (54)      58 (63)      51 (53)      54 (56)      49 (53)

Age (y)                                                                                     0.790
  Mean                     41.4         41.8         43.5         42.4         41.8
  sd                       10.68        10.54        12.22        12.99        11.59
  Min-Max                  21-71        21-68        19-68        21-73        19-69
  n                        98           92           97           97           92

Weight (lb)                                                                                 0.892
  Mean                    172.6        173.2        170.9        168.7        171.0
  sd                       35.49        35.21        33.64        35.54        38.41
  Min-Max                 108-297      110-292      107-268       98-264       96-333
  n                        97           92           95           96           92

Height (in)                                                                                 0.462
  Mean                     67.3         67.8         67.4         67.0         67.8
  sd                        4.00         4.17         3.30         3.60         4.22
  Min-Max                  58-76        59-81        58-75        60-74        57-74
  n                        98           92           97           96           92

Ethnic origin, n(%)                                                                         0.804
Caucasian                  80 (82)      76 (84)      84 (87)      87 (90)      77 (84)
Negroid/Black               9  (9)       8  (9)       8  (8)       5  (5)      10 (11)
Oriental                    0            0            1  (1)       0            0
Asian                       0            1  (1)       1  (1)       2  (2)       0
Hispanic                    6  (6)       4  (4)       2  (2)       2  (2)       3  (3)
Other                       3  (3)       2  (2)       1  (1)       1  (1)       2  (2)
Data not available          0            1            0            0            0

--------------------------------------------------------------------------------------------------
The p-values for sex and ethnic origin based on the chi-square test and for age, height, and
     weight on the vanElteren test.
This table produced with macro SIMSTAT and DTAB.






Supporting data listing in Appendix DL-xx, Vol ___, Page ___

D:\STDMACRO\JHK27056\DT00.SAS  22DEC93:10:13:48

/ End of example:
/------------------------------------------------------------------------------*/

%macro dtab(  data=,
           outfile=,
              disp=,

               tmt=,
            tmtfmt=,

              rows=,
           rowsfmt=,

           ynlabel=NO,
          row_of_n=YES,
           stbstyl=COLUMN,
           missing=NO,

              ifmt=3.,
              rfmt=5.1,
            pctfmt=jkpct5.,
          pctstyle=1,
           pctsign=YES,
              flow=,
             style=1,
             stats=n mean std median min max,
          stathold=0,
          statsfmt=,
            pvalue=NO,
             pvars=,
           pvalfmt=,
             pflag=0,
            plevel=.05,
            pvcomp=_pvars[i],
            pfltxt='#',
            plabel='p-value [1]',

           cpvars1=,
           cpvars2=,
           cpvars3=,
           cpvars4=,
           cpvars5=,
               box='!',
              skip=0,
             vskip=0,
            vskipa=1,
            indent=,
           indentc=,
           indentf=4,
           indentv=0,
          indentvc=0,
          indentlc=1,
            hrdspc=!,
              swid=,
             rlwid=swid,
           rlocate=LAST,
              smin=8,
              cwid=10,
              cmin=8,
              pwid=8,
              pmin=6,
              coff=,
             pcoff=,
           between=0,
          sbetween=2,
          pbetween=3,
          betweenp=2,
            layout=DEFAULT,
               cpi=17,
               lpi=10,
          footdash=NO,
           contmsg=NO,
             jobid=NO,
             ruler=NO,

           pagenum=NONE,
            target=,
             debug=0,
           sasopts=NOSYMBOLGEN NOMLOGIC);

   /*
   / Issue SAS system options specified in the SASOPTS parameter
   /-------------------------------------------------------------------------*/

   options &SASOPTS;

   /*
   / JMF002
   / Display Macro Name and Version Number in LOG
   /-------------------------------------------------------------------------*/

      %put ------------------------------------------------------;
      %put NOTE: Macro called: DTAB.SAS       Version Number: 3.1;
      %put ------------------------------------------------------;


   /*
   / If DATA= was not specified then use _LAST_
   /-------------------------------------------------------------------------*/

   %if &sysscp=VMS %then %do;
      options cc=cr;
      %end;

   %global vdtab vsimstat jkpg0;
   %let    vdtab = 3.1;



   %let data = %upcase(&data);
   %if &data=_LAST_ | %length(&data)=0 %then %let &data=&syslast;
   %if &data=_NULL_ %then %do;
      %put ER!ROR: There is no data to be processed;
      %goto EXIT;
      %end;


   /*
   / Run the check data utility macro CHKDATA to verify the existance
   / of the input data and variable names.
   /-------------------------------------------------------------------------*/

   %jkchkdat(data=&data,
            nvars=&tmt,
            cvars=_vname_ _vtype_)

   %if &RC %then %goto EXIT;



   /*
   / Set up local macro variables to hold temporary data set names.
   /-----------------------------------------------------------------*/

   %local i temp0 temp1 constant temp3 temp4 temp5;
   %let temp0    = _0_&sysindex;
   %let temp1    = _1_&sysindex;
   %let constant = _2_&sysindex;
   %let temp3    = _3_&sysindex;
   %let temp4    = _4_&sysindex;
   %let temp5    = _5_&sysindex;

   /*
   / Upper case various input parameters as needed.
   /-------------------------------------------------------------------------*/

   %let row_of_n = %upcase(&row_of_n);
   %let stbstyl  = %upcase(&stbstyl);
   %let missing  = %upcase(&missing);
   %let ynlabel  = %upcase(&ynlabel);
   %let pvalue   = %upcase(&pvalue);
   %let layout   = %upcase(&layout);
   %let rows     = %upcase(&rows);
   %let pctfmt   = %upcase(&pctfmt);
   %let pctsign  = %upcase(&pctsign);
   %let style    = %upcase(&style);
   %let flow     = %upcase(&flow);
   %let ruler    = %upcase(&ruler);
   %let footdash = %upcase(&footdash);
   %let contmsg  = %upcase(&contmsg);
   %let stats    = %upcase(&stats);
   %let stathold = %upcase(&stathold);
   %let statsfmt = %upcase(&statsfmt);
   %let jobid    = %upcase(&jobid);
   %let disp     = %upcase(&disp);
   %let pagenum  = %upcase(&pagenum);
   %let rlwid    = %upcase(&rlwid);
   %let rlocate  = %upcase(&rlocate);
   %let pflag    = %upcase(&pflag);


   /*
   / Assign default value to OUTFILE and create GLOBAL macro variable
   / to use in INFILE= parameter in MACAPGE.
   /-------------------------------------------------------------------*/
   %global _outfile;

   %if %bquote(&outfile)=
      %then %let outfile = %fn;

   %put NOTE: outfile = &outfile;

   %if %bquote(&row_of_n)=YES | %bquote(&row_of_n)=1
      %then %let row_of_n = 1;
      %else %let row_of_n = 0;

   %if %bquote(&missing)=YES  | %bquote(&missing)=1
      %then %let missing = 1;
      %else %let missing = 0;

   %if %bquote(&ynlabel)=YES | %bquote(&ynlabel)=1
      %then %let ynlabel = 1;
      %else %let ynlabel = 0;


   %if %bquote(&tmtfmt)= %then %do;
      %let tmtfmt = &tmt%str(.);
      %end;



   /*
   / Set up for IDSG column style.
   /--------------------------------------------------*/

   %if %bquote(&stbstyl)=COLUMN %then %do;
      %if %bquote(&swid)=    %then %let swid    = 50;
      %if %bquote(&indent)=  %then %let indent  = 30;
      %if %bquote(&indentc)= %then %let indentc = 30;
      %end;
   %else %do;
      %if %bquote(&swid)=    %then %let swid    = 20;
      %if %bquote(&indent)=  %then %let indent  = 3;
      %if %bquote(&indentc)= %then %let indentc = 3;
      %end;

   %if "&debug"="YES" | "&debug"="1"
      %then %let debug=1;
      %else %let debug=0;

   %if "&stathold"="YES" | "&stathold"="1"
      %then %let stathold=1;
      %else %let stathold=0;

   %if "&pvalue"="YES"
      %then %let pvalue=1;
      %else %let pvalue=0;

   %if "&ruler"="YES"
      %then %let ruler=1;
      %else %let ruler=0;

   %if "&jobid"="YES"
      %then %let jobid=1;
      %else %let jobid=0;

   %if %length(&target)=0
      %then %let target = "&outfile";
      %else %let target = "&target";

   %if %length(&pflag)=0
      %then %let pflag=0;

   %if "&pflag"="YES" | "&pflag"="1"
      %then %let pflag = 1;
      %else %let pflag = 0;

   %if %length(&plevel)=0
      %then %let plevel=.05;

   %if "&rlocate"^="FIRST" %then %let rlocate = LAST;


   %if "&disp"^="MOD" %then %do;
      %let disp=;
      %let jkpg0 = 0;
      %end;

   %if "&pctsign"="YES" %then %do;
      %let pctsign = %str(%%);
      %if "&pctfmt"="JKPCT5." %then %let pctfmt = JKPCT6.;
      %end;
   %else %let pctsign = ;

   %if ^("&pctstyle"="1" | "&pctstyle"="2") %then %let pctstyle=1;

   %put NOTE: PCTSIGN=&pctsign, PCTFMT=&pctfmt, PCTSTYLE=&pctstyle;


   /*
   / Prepare the STATS= parameter for use in the final data step
   /-----------------------------------------------------------------*/

   %jkstpr01(stats=&stats,
          statsfmt=&statsfmt,
                at=@(_tc[ncol]) +(coff) )


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
           fnote12 fnote13 fnote14 fnote15
           fnote16 fnote17 fnote18 fnote19 fnote20;


   %global findt0  findt1  findt2  findt3  findt4  findt5
           findt6  findt7  findt8  findt9  findt10 findt11
           findt12 findt13 findt14 findt15
           findt16 findt17 findt18 findt19 findt20;

   %global enote0 enote1 enote2 enote3 enote4 enote5
                  enote6 enote7 enote8 enote9 enote10;

   %if "&enote0"="" %then %let enote0 = 0;
   %if "&fnote0"="" %then %let fnote0 = 0;


   /*
   / Process Pvars;
   / I have added (22FEB96) the option for aditional varaiables to
   / be displayed in the PVAR area.  These CPVARSn are character
   / variables that are in multiple rows.  I am adding this and
   / trying to keep the functionality that exist in DTAB.
   / This action has caused this portion of code to become more
   / obscure than before, so I will try to document in more detail.
   /----------------------------------------------------------------*/

   %let  pvars  = %upcase(&pvars);
   %let cpvars1 = %upcase(&cpvars1);
   %let cpvars2 = %upcase(&cpvars2);
   %let cpvars3 = %upcase(&cpvars3);
   %let cpvars4 = %upcase(&cpvars4);
   %let cpvars5 = %upcase(&cpvars5);

   %local cpvars0;
   %let cpvars0 = 0;
   %do i = 1 %to 5;
      %if "&&cpvars&i" ^= "" %then %let cpvars0 = %eval(&cpvars0 + 1);
      %end;

   %put NOTE: There are &cpvars0 CPVARS lines to be printed.;

   %local pvarflag;
   %let   pvarflag = 1;

   /*
   / If the user specifies only CPVARS then assign the value of CPVARS1
   / to PVARS so that the label routine will work and generate labels
   / for the PVAR columns in the table.
   /-------------------------------------------------------------------*/
   %if       "&cpvars1"^="" & "&pvars"="" %then %do;
      %let pvars    = &cpvars1;
      %let pvarflag = 0;
      %end;
   %else %if &pvalue & "&pvars"=""        %then %do;
      %let pvars    = PROB;
      %let pvarflag = 1;
      %end;

   %local p_var0;

   %if ^&pvalue
      %then %let p_var0 = 0;
      %else %let p_var0 = %jkxwords(list=&pvars,root=p_var);


   /*
   / Declare some macro variables
   /
   / COLS    The maximum number of columns in the panels.
   /-----------------------------------------------------------------*/

   %local cols colsplus maxwid;

   /*
   / Set up flags to use to control printing of the appendix note,
   / the jobname information, and the table continued notes.
   /-----------------------------------------------------------------*/

   %local cont;

   %if    "&hl0"="" %then %let    hl0=10;

   %if "&hlcont"="" %then %do;
      %let cont   = 0;
      %let hlcont = 1;
      %end;
   %else %let cont=1;

   %local ls ps dashchr file_ext file_dsp hppcl;

   %jklyot01

   %put NOTE: LS=&ls PS=&ps DASHCHR=&dashchr FILE_EXT=&file_ext;

   %local jkrlwid;
   %if "&rlwid"="LS" | "&rlwid"="SWID"
      %then %let jkrlwid = &&&rlwid;
      %else %let jkrlwid = &rlwid;


   /*
   / Compute PANELS based on the number of treatments, the presence
   / of p-values and the width of the various column components of the
   / table.
   /--------------------------------------------------------------------------*/


   options nofmterr;

   /*
   / Create new LEVEL for DISC variable that for N row.
   /-------------------------------------------------------*/

   %if &row_of_n %then %do;
      data &temp0;
         set
            &data
               (
                %if ^&missing %then %do;
                  where = (_level_^='_')
                  %end;
               )
            ;



         by _vname_ _level_;

         output;

         retain _flag_ 0;

         if first._vname_ & first._level_ & _vtype_='DISC' then _flag_ = 1;

         if _flag_ then do;
            _level_ = '01'x;
            count   = n;
            n       = .;
            pct     = .;
            output;
            end;

         if _flag_ & last._level_ then _flag_ = 0;

         run;

      %let data = &temp0;
      %end;

   proc summary data=&data nway missing;
      class &tmt;
      output out=&temp1(drop=_type_ _freq_);
      run;


   %local cantdoit;
   %let cantdoit = 0;

   /*
   / This data set will contain various column location constants.  This data
   / will be SET into the FILE PRINT data step below.
   /--------------------------------------------------------------------------*/
   data &constant;

      if 0 then set &temp1(drop=_all_) nobs=nobs;

      retain style "&style" pvalue &pvalue p_var0 &p_var0;

      drop i;

      p_var0 = max(p_var0,0);

      skip     = max(0,&skip     + 0);
      vskip    = max(0,&vskip    + 0);
      vskipa   = max(0,&vskipa   + 0);
      indent   = max(0,&indent   + 0);
      indentc  = max(0,&indentc  + 0);
      indentv  = max(0,&indentv  + 0);
      indentvc = max(0,&indentvc + 0);
      indentlc = max(0,&indentlc + 0);

      tmt0 = nobs;

      iwid = int(&ifmt);
      rwid = int(&rfmt);

      pctwid = int(input(compress("&pctfmt",'_ABCDEFGHIJKLMNOPQRSTUVWXYZ'),8.));

      /*
      / Compute CCWID the width taken up by the contents of the columns.
      /----------------------------------------------------------------------*/

      select(style);
         when('0') ccwid = &cwid;
         when('1') ccwid = iwid + pctwid;
         when('2') ccwid = 1 + iwid * 2 + pctwid;
         when('3') ccwid = iwid;
         when('4') ccwid = 1 + iwid * 2;
         otherwise do;
            ccwid = iwid + pctwid;
            call symput('STYLE','1');
            style = '1';
            end;
         end;


      swid     = max(&swid,&smin);

      cwid     = max(&cwid,ccwid,&cmin);

      pwid     = max(&pwid,&pmin);

      btwn     = max(&between,1);

      between  = &between;
      pbetween = max(&pbetween,1);
      sbetween = max(&sbetween,0);
      betweenp = max(&betweenp,1);

      ls       = &ls;

      /*
      / Compute SPWID the total number of columns occupied by the table stub
      / and p-values if requested by the user.
      /-------------------------------------------------------------------------*/
      spwid = swid + sbetween;

      if pvalue then spwid = spwid + ((pwid*p_var0)+(betweenp*(p_var0-1))+pbetween);

      /*
      / Now see how many TREATMENT columns will fit in the space left after
      / the stub and p-values.
      /-------------------------------------------------------------------------*/

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
      / COFF is the column ofset for the statistics printed in a treatment
      / column.  This centers the statistics under the column heading.
      / PCOFF is similar to COFF but is for the p-value column.
      /-----------------------------------------------------------------------*/

   %if "&coff"= "" %then %do;
      coff  = max(floor((cwid-ccwid) / 2),0);
      %end;
   %else %do;
      coff  = &coff;
      %end;

   %if "&pcoff"="" %then %do;
      pcoff = max(floor((pwid-6) / 2),0);
      %end;
   %else %do;
      pcoff = &pcoff;
      %end;


      /*
      / When no between value is specified, BETWEEN=0, the macro computes
      / between to space the columns so that they fill up the available space.
      /-----------------------------------------------------------------------*/


      if between = 0 then do;

         between = floor( (ls - spwid - tcols*cwid) / max(tcols-1,1) );

         xxx     = between;

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

      tmtreq = (tcols * cwid)  + (between * (tcols-1));
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
      / in array declareations.
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
      %put ER!ROR: Your choices of    STUB: SWID=&swid, SBETWEEN=&sbetween;
      %put ER!ROR:              TX COLUMNS: CWID=&cwid, BETWEEN=&between;
      %put ER!ROR            P-VAL COLUMNS: PWID=&pwid, PBETWEEN=&pbetween, BETWEENP=&betweenp;
      %put ER!ROR: will not allow the display of any treatment columns.;
      %put ER!ROR: Please choose smaller values for one or more of these parameters and resubmit.;
      %goto exit;
      %end;

   %if &debug %then %do;
      title4 'DATA=CONSTANT';
      proc print data=&constant;
         run;
      %end;


   /*
   / Using the data set of treatment values divide the treatments into panels
   / using TCOLS from above.  This data will be merged with the input data
   / below.
   /--------------------------------------------------------------------------*/

   data &temp1;
      set &temp1;
      if _n_ = 1 then set &constant(keep=tcols);
      drop tcols;
      retain panel 0;
      if                tcols  = 1 then panel = panel + 1;
      else if mod(_n_ , tcols) = 1 then panel = panel + 1;
      run;

   %if &debug %then %do;
      title4 'DATA=TEMP1';
      proc print data=&temp1;
         run;
      %end;


   /*
   / Now using the treatment data set that has been divided up into panels
   / flow the column header text into the space provided by the column width
   / array.
   /--------------------------------------------------------------------------*/

   proc summary data=&temp1 nway missing;
      class panel &tmt;
      output out=&temp3(drop=_type_ _freq_);
      run;

   proc transpose data=&temp3 out=&temp3 prefix=tc;
      by panel;
      var &tmt;
      run;

   /*
   / create value label format with _PATNO_ information
   /-------------------------------------------------------*/
   data _for;
      set
         &data
            (
             keep = _vname_ &tmt n
            )
         ;

      if _vname_ = '_PATNO_';

      fmtname  = 'tmtnnn';
      start    = &tmt;
      length label $40;
      label    = compress('(N='||put(n,8.)||')');
      run;
   proc format cntlin=_for;
      run;

   data &temp3(keep=panel _cl:);

      set &temp3;
      by panel;

      array _tc[*] tc:;

      if _n_ = 1 then set &constant(keep=_tw1-_tw&cols tcols swid);
      array _tw[&colsplus] _tw1-_tw&cols swid;

      array _tl[&colsplus] $200;

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
         _tl[i] = put(_tc[i],%unquote(&tmtfmt))||' \ '||put(_tc[i],tmtnnn.);
         if &ruler then _tl[i] = trim(_tl[i])||' '|| substr('....+....+....+....+',1,&cwid);
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
      / flow the labels into the columns based on the column
      / width. CWID may be different for treatments and
      / p-values.
      /------------------------------------------------------*/

      %jkflsz2(in = _tl,
              out = _xl,
             size = &maxwid,
           sizeAR = _tw,
             dim1 = &colsplus,
             dim2 = 10,
          newline = '\');


      /*
      / Move the labels down so that they will look pushed up
      / rather that hung down.
      /------------------------------------------------------*/
      array   _cl[&colsplus,10] $&maxwid;
      array _cl0_[&colsplus];

      _cl0 = _xl0;
      max = max(of _xl0_[*],0);

      do i = 1 to _cl0;
         _cl0_[i] = max;
         offset = max - _xl0_[i];
         do k = 1 to _xl0_[i];
            _cl[i,k+offset] = _xl[i,k];
            end;
         end;
      run;

   %if &debug %then %do;
      title4 "DATA=TEMP3 the formatted column labels";
      proc contents data=&temp3;
         run;
      proc print data=&temp3;
         run;
      title4;
      %end;


   /*
   / Flow the footnote data so that the footnotes will fit in
   / the linesize chosen for the table.
   /---------------------------------------------------------*/

   data &temp5(keep=_fn: _en: _fi:);
      array _xn[20] $200 _temporary_
         ("&fnote1",  "&fnote2",  "&fnote3",  "&fnote4",  "&fnote5",
          "&fnote6",  "&fnote7",  "&fnote8",  "&fnote9",  "&fnote10",
          "&fnote11", "&fnote12", "&fnote13", "&fnote14", "&fnote15",
          "&fnote16", "&fnote17", "&fnote18", "&fnote19", "&fnote20");

      array _xi[20] $2 _temporary_
         ("&findt1",  "&findt2",  "&findt3",  "&findt4",  "&findt5",
          "&findt6",  "&findt7",  "&findt8",  "&findt9",  "&findt10",
          "&findt11", "&findt12", "&findt13", "&findt14", "&findt15",
          "&findt16", "&findt17", "&findt18", "&findt19", "&findt20");

      array _fi[20];
      array _sz[20];

      do i = 1 to dim(_xi);
         if _xi[i]=' '
            then _fi[i] = max(&indentf,0);
            else _fi[i] = input(_xi[i],2.);
         _sz[i] = &ls - _fi[i];
         end;


      do i = 1 to dim(_xn);
         _xn[i] = compbl(_xn[i]);
         end;


      %jkflsz2(in=_xn,out=_fn,size=&ls,sizear=_sz,dim1=20,dim2=5,newline='\')

      do i = 1 to dim1(_fn);
         do j = 1 to dim2(_fn);
            _fn[i,j] = translate(_fn[i,j],' ',"&hrdspc");
            end;
         end;


      _en0 = min(&enote0 + &jobid, 10);

      array _en[10] $200
         ("&enote1","&enote2","&enote3","&enote4","&enote5",
          "&enote6","&enote7","&enote8","&enote9","&enote10");


   %if &jobid %then %do;
      %if &sysscp = SUN 4 %then %do;
         set
            sashelp.vextfl
               (
                keep  = xpath fileref
                where = (fileref='_TMP0002')
               );

         /*
         / I am not sure if I want LOGNAME or USER environment variable
         /----------------------------------------------------------------*/
         login = sysget('USER');
         _en[_en0] = trim(login)||' '
                     ||trim(xpath)
                     ||" SMBv:(&vsimstat,&vdtab) &sysdate:&systime";

         %end;
      %else %if &sysscp=VMS | &sysscp=VMS_AXP %then %do;
         login    = getjpi('USERNAME');

         _en[_en0] = trim(login)||' '
                     ||compress(tranwrd("&vmssasin",'000000.',' '),' ')
                     ||" SMBv:(&vsimstat,&vdtab) &sysdate:&systime";
         %end;


      %else %do;
         login    = 'NOT VAX';
         _en[_en0] = trim(login)||' '
                     ||compress(tranwrd("&vmssasin",'000000.',' '),' ')
                     ||" SMBv:(&vsimstat,&vdtab) &sysdate:&systime";

         %end;

      %end;


      run;

   %if &debug %then %do;
      title4 'DATA=TEMP5 titles and footnotes';
      proc print data=&temp5;
         run;
      %end;



   /*
   / Sort the input data by TREATMENT and merge with the data set of
   / treatments and panels.
   /--------------------------------------------------------------------------*/

   proc sort data=&data out=&temp4;
      by &tmt;
      run;

   data &temp4;
      merge &temp4 &temp1;
      by &tmt;

      /*
      / Compute an ORDER variable for the row variables based on the order
      / of the ROW= macro parameter.
      /-----------------------------------------------------------------------*/

      %jkrord(rowvars=&rows,_name_=_VNAME_,_row_=_ROW_)

      %jkdash(rowvars=&rows,_name_=_VNAME_,_dash_=_DASH_)

      %jkrlbl(rowvars=&rows,_name_=_VNAME_,_rlbl_=_RLBL_)

      %jkrfmt(rowsfmt=&rowsfmt,_name_=_VNAME_,_fmt_=_VFMT_)

   /*
   / The percents will be printed with a PICTURE format.  Due to
   / limitations of PICTURE and specilized rounding requriements
   / the value of PCT is recalculated in this step.
   /--------------------------------------------------------------*/

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


   proc sort data=&temp4;
      by panel _row_ _vname_ _order_ _level_ &tmt;
      run;

   %if &debug %then %do;
      title4 'DATA=TEMP4 The modified input data';
      proc contents data=&temp4;
         run;
      proc print data=&temp4;
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

   options missing =' ';

   data _null_;

      file "&outfile%str(.)&file_ext" &file_dsp print
           notitles n=ps ll=ll ls=200 ps=&ps line=line col=col;


      /*
      / Note this where INDEXW clause may cause a problem and needs to
      / be rewritten.
      /-----------------------------------------------------------------*/

      set
         &temp4(where=(indexw("&rows",_vname_)))
         end=eof;

      by panel _row_ _vname_ _order_ _level_ &tmt;

      /*
      / Declare arrays.
      / _CL is the column labels.
      / _FN is the footnotes
      / _TC is print positions for the table columns
      /------------------------------------------------*/

      retain _one_ 1;

      if _n_=1 then do;
         set
            &temp5
               (
                keep = _en: _fn: _fi:
               )
            ;
         array _fn0_[20];
         array _fn[20,5];
         array _fi[20];
         array _en[10];

         set
            &constant
               (
                keep = _tc1-_tc&cols _tw1-_tw&cols skip vskip vskipa
                       indent indentc indentv indentvc indentlc
                       tcols cols coff pcoff style pvalue between swid
               )
            ;

         array _tc[&colsplus] _tc1-_tc&cols _one_;
         array _tw[&colsplus] _tw1-_tw&cols swid;
         end;


      if first.panel then set &temp3(keep=_cl:);

      array _cl0_[&colsplus];
      array _cl[&colsplus,10];

      /*
      / Declare and initialize various constants
      /-------------------------------------------*/
      retain thisline homeline;
      retain flow "&flow" stats "&stats";
      retain ls &ls cont &cont;

      length cnted $&ls;
      retain cnted 'Continued...';

      length xlblx $40;

      /*
      / Start a new page when the value of panel changes
      /---------------------------------------------------*/

      if first.panel then do;
         put _page_ @;
         link header;
         end;


   %if "&rlocate" = "FIRST" %then %do;
      if first._vname_ then do;
         if _rlbl_ > ' ' then do;
            rlbl_i + 1;
            array _rlbl[1] _rlbl_;
            if indexw(flow,'RLABEL'||left(put(rlbl_i,5.))) then do;

               %jkflowx(in=_rlbl,out=_frlbl,dim=10,size=&jkrlwid,delm=' ',newline='\')

               do k = 1 to _frlbl0;

                  _frlbl[k] = translate(_frlbl[k],' ',"&hrdspc");
                  put _frlbl[k] $&ls..;

                  end;
               end;
            else do;
               _rlbl_ = translate(_rlbl_,' ',"&hrdspc");
               put _rlbl_ $&ls..;
               end;
            end;
         end;
      %end;




      /*
      / When the value of _VNAME_ changes we need to print the
      / print the table stub information.
      /-------------------------------------------------------*/

      if first._vname_ then do;
         /*
         / THISLINE is used to remember where to started printing.
         /---------------------------------------------------------*/
         thisline = line;
         homeline = line;

         /*
         / print the group heading for each _VNAME_ using the
         / $_VNAME_ format that was supplied by the user.  This text
         / is then flowed into to space provided by SWID=.  The
         / _VNAME_ labels are indented 1 space on lines 2 on up.
         /---------------------------------------------------------*/

         array _stb[1] $200. _temporary_;
         _stb[1] = put(_vname_,$_vname_.);

         %jkflowx(in=_stb,out=_fstb,dim=10,size=&swid,delm=' ',newline='\')

         _fstb[1] = translate(_fstb[1],' ',"&hrdspc");
         put #(thisline) +(indentv) _fstb[1] $char&swid..;
         do i = 2 to _fstb0;
            thisline = thisline + 1;

            _fstb[i] = translate(_fstb[i],' ',"&hrdspc");
            put #(thisline) +(indentv+indentvc) _fstb[i] $char&swid..;
            end;


         if (_vtype_='DISC')
            | (_vtype_='CONT'
            &
             ^(
                 index(upcase(stats),'N-MEAN(STD)')
               | index(upcase(stats),'N-MEAN(STDMEAN)')
               | index(upcase(stats),'N-LSM(LSMSE)')
              )
            )
            then do;
            do i = 1 to vskip;
               put;
               thisline = thisline + 1;
               end;
            end;

         /*
         / if the user requested PVALUE=YES
         /----------------------------------------------------------*/
         %if &pvalue %then %do;
            if pvalue & _vtype_ ^in('PTNO','PVALUE') then do;

               if _vtype_='CONT' then do;
                  if index(upcase(stats),'N-MEAN(STD)')
                   | index(upcase(stats),'N-MEAN(STDMEAN)')
                   | index(upcase(stats),'N-LSM(LSMSE)')
                     then pv_adj=0;
                     else pv_adj=1;
                  end;
               else if _vtype_ in('YESNO','DISC') then pv_adj = -1 * vskip;



            %if &pvarflag %then %do;
               array _pvars[*] &pvars;
               j = tcols;
               do i = 1 to dim(_pvars);
               j = j + 1;

               /*
               / flag pvalue with asterics if pr_cntl < &plevel
               /--------------------------------------------------*/

               %if &pflag %then %do;
                  if _pvars[i] > .Z then do;
                     if .Z < &pvcomp <= &plevel then pfltxt = &pfltxt;
                     end;
                  else pfltxt = ' ';
                  %end;
               %else %do;
                  retain pfltxt ' ';
                  %end;
                  %if "&pvalfmt" = "" %then %do;
                     if .Z < _pvars[i] < 0.001 then do;
                        cprob = '<0.001';
                        put   #(thisline+pv_adj) @(_tc[j]+pcoff) cprob $6. pfltxt $1. #(thisline);
                        end;
                     else put #(thisline+pv_adj) @(_tc[j]+pcoff) _pvars[i] 6.3 pfltxt $1. #(thisline);
                     %end;
                  %else %do;
                     put #(thisline+pv_adj) @(_tc[j]+pcoff) _pvars[i] &pvalfmt pfltxt $1. #(thisline);
                     %end;
                  end;
               %end;


            %do i = 1 %to &cpvars0;
               array _cpv&i[*] &&cpvars&i;

               j = tcols;
               do i = 1 to min(dim(_cpv&i),&p_var0);
                  j = j + 1;
                  put   #(&i+thisline+pv_adj-(^&pvarflag))
                        @(_tc[j]+pcoff) _cpv&i[i] $char&pwid..
                        #(thisline);
                  end;
               %end;
            end /*if pvalue & _vtype_^='PTNO' then do; */;
            %end;


         /*
         / For continuious variables the table stub labels will also
         / include the ROW labels for the statistics associated with
         / them.  So print them now.
         /------------------------------------------------------------------*/
         thisline = line;
      /*
      / Move back to the home line for this _VNAME_
      /----------------------------------------------*/
      %if %bquote(&stbstyl)=COLUMN %then %do;
         thisline = homeline;
         %end;

         if _vtype_ = 'CONT' then do;
            stats = upcase(stats);
            i = 1;
            thestat = scan(stats,i,' ');
            do while(thestat^=' ');
               select(thestat);
                  when('MEAN')          call label(mean,xlblx);
                  when('STD' )          call label(std,xlblx);
                  when('MIN-MAX')       xlblx = 'Min-Max';
                  when('MIN')           call label(min,xlblx);
                  when('MAX')           call label(max,xlblx);
                  when('N')             call label(n,xlblx);
                  when('MEDIAN')        call label(median,xlblx);
                  when('STDMEAN')       call label(stdmean,xlblx);
                  when('MODE')          call label(mode,xlblx);
                  when('LSM')           call label(lsm,xlblx);
                  when('LSMSE')         call label(lsmse,xlblx);
                  when('ROOTMSE')       call label(rootmse,xlblx);
                  when('MEAN(STD)')     xlblx = 'Mean(STD)';
                  when('MEAN(STDMEAN)') xlblx = 'Mean(SEM)';
                  when('LSM(LSMSE)')    xlblx = 'Mean adj(se)';
                  when('L95-U95')       xlblx = '95% C.I.';
                  when('L90-U90')       xlblx = '90% C.I.';
                  when('L99-U99')       xlblx = '99% C.I.';
                  when('SSE')           call label(sse     ,xlblx);
                  when('DFE')           call label(def     ,xlblx);
                  when('MSE')           call label(mse     ,xlblx);
                  when('ROOTMSE')       call label(rootmse ,xlblx);
                  when('CSS')           call label(css     ,xlblx);
                  when('CV')            call label(cv      ,xlblx);
                  when('KURTOSIS')      call label(kurtosis,xlblx);
                  when('MSIGN')         call label(msign   ,xlblx);
                  when('NMISS')         call label(nmiss   ,xlblx);
                  when('NOBS')          call label(nobs    ,xlblx);
                  when('NORMAL')        call label(normal  ,xlblx);
                  when('P1')            call label(p1      ,xlblx);
                  when('P10')           call label(p10     ,xlblx);
                  when('P5')            call label(p5      ,xlblx);
                  when('P90')           call label(p90     ,xlblx);
                  when('P95')           call label(p95     ,xlblx);
                  when('P99')           call label(p99     ,xlblx);
                  when('PROBM')         call label(probm   ,xlblx);
                  when('PROBN')         call label(probn   ,xlblx);
                  when('PROBS')         call label(probs   ,xlblx);
                  when('PROBT')         call label(probt   ,xlblx);
                  when('Q1')            call label(q1      ,xlblx);
                  when('Q3')            call label(q3      ,xlblx);
                  when('QRANGE')        call label(qrange  ,xlblx);
                  when('RANGE')         call label(range   ,xlblx);
                  when('SIGNRANK')      call label(signrank,xlblx);
                  when('SKEWNESS')      call label(skewness,xlblx);
                  when('SUM')           call label(sum     ,xlblx);
                  when('SUMWGT')        call label(sumwgt  ,xlblx);
                  when('T')             call label(t       ,xlblx);
                  when('USS')           call label(uss     ,xlblx);
                  when('VAR')           call label(var     ,xlblx);
                  when('L95')           call label(l95     ,xlblx);
                  when('U95')           call label(u95     ,xlblx);
                  when('L90')           call label(l90     ,xlblx);
                  when('U90')           call label(u90     ,xlblx);
                  when('L99')           call label(l99     ,xlblx);
                  when('U99')           call label(u99     ,xlblx);
                  otherwise             xlblx = thestat;
                  end;
               if thestat in('N-MEAN(STD)'  , 'N-MEAN(STDMEAN)',
                             'N-LSM(LSMSE)' , 'N-MEAN(STD)-MIN+MAX' ,
                             'N-MEAN-STD-MIN-MAX')
                          | (&stathold)
                  then thisline=thisline-1;
               else if "COLUMN"="&stbstyl" then put #(thisline+i-1) +(indentc) xlblx;
               else put +(indentc) xlblx;
               i = i + 1;
               thestat = scan(stats,i,' ');
               end;
            end;
         end;


      /*
      / When the value of level changes a new row in the table will start.
      / The data is arranged with TMT within _LEVEL_.  So at each new value
      / of _LEVEL_ we need to reset the column pointer.
      /----------------------------------------------------------------------*/
      if first._level_ then ncol=0;

      /*
      / Each time the value of TMT changes increment the column pointer.
      /----------------------------------------------------------------------*/
      if first.&tmt then ncol+1;


      /*
      / Now depending on the type of variable DISC CONT YESNO PTNO print
      / the various statistics associated with them.
      /----------------------------------------------------------------------*/
      if _vtype_ = 'CONT' then do;

         put #(thisline) @;

         select(_vname_);
            when('0');
            %do i = 1 %to &jku0_0-1;
               when("&&jku&i._v") do;
               %do j = 1 %to &&jku&i._0;
                  if &&jku&i._&j; else put @(_tc[ncol]) ' ';
                  %end;
               end;
               %end;
            otherwise do;
               %let i = &jku0_0;
               %do j = 1 %to &&jku&i._0;
                  if &&jku&i._&j; else put @(_tc[ncol]) ' ';
                  %end;
               end;
            end;


         end;

      else if _vtype_ = 'PVALUE' then do;
         put #(thisline-1) @;
         if .Z < prob < 0.001 then do;
            cprob = '<0.001';
            put @(_tc[ncol]+pcoff) cprob $6.;
            end;
         else put @(_tc[ncol]+pcoff) prob 6.3;
         end;

      else if _vtype_ in('DISC','YESNO') then do;
         /*
         / For DISC variables we need to print stub labels.  These labels are
         / supplied by the user in the formats with the same name as the
         / discrete variables.  That is to format SEX the user creates $SEX
         / value labeling format.
         /
         / If the user has labels that are longer than the SWID then he may
         / specify that they be flowed.  This is done by using FLOW=_LEVEL_.
         / The _LEVEL_ labels are not flowed by default because flowing removes
         / leading spaces that the user way want to use to achive indending.
         /-------------------------------------------------------------------*/
         if _vtype_ = 'DISC' then do;

            if first._level_ then do;
               array _slbl[1] $200 _temporary_;

               %if &ynlabel %then %do;
                  select(_level_);
                     when('N') _slbl[1] = 'No';
                     when('Y') _slbl[1] = 'Yes';
                     otherwise _slbl[1] = _level_;
                     end;
                  %end;
               %else %do;
                  _slbl[1] = putc(_level_,_vfmt_);
                  %end;

               if      _slbl[1] = '01'x then _slbl[1] = 'n';
               else if _slbl[1] = '_'   then _slbl[1] = 'Data not available';
               else if _slbl[1] = ' '   then _slbl[1] = _level_;


               if index(flow,'_LEVEL_') then do;
                  %jkflowx(in=_slbl,out=_fslbl,dim=10,size=&swid,delm=' ',newline='\')
                  do k = 1 to _fslbl0;

                     _fslbl[k] = translate(_fslbl[k],' ',"&hrdspc");

                     if k=1
                        then put #(thisline) +(indent)          _fslbl[k] $char&swid..;
                        else put #(thisline) +(indent+indentlc) _fslbl[k] $char&swid..;
                     if k < _fslbl0 then thisline = thisline + 1;

                     end;
                  end;
               else do;

                  _slbl[1] = translate(_slbl[1],' ',"&hrdspc");
                  put #(thisline) +(indent) _slbl[1] $char&swid..;

                  end;
               end;
            end;
         else if _vtype_ = 'YESNO' & first._level_ then thisline=thisline-1;

         /*
         / Print the counts and percents according to the value of style
         /--------------------------------------------------------------------*/
         select(style);
            when('1','0') do;
               if _level_='_'
                  then put #(thisline) @(_tc[ncol]+coff) count &ifmt;
                  else put #(thisline) @(_tc[ncol]+coff) count &ifmt pct &pctfmt;
               end;
            when('2') do;
               if _level_='_'
                  then put #(thisline) @(_tc[ncol]+coff) count &ifmt;
                  else put #(thisline) @(_tc[ncol]+coff) count &ifmt '/' n &ifmt-l pct &pctfmt;
               end;
            when('3') put #(thisline) @(_tc[ncol]+coff) count &ifmt;
            when('4') do;
               if _level_='_'
                  then put #(thisline) @(_tc[ncol]+coff) count &ifmt;
                  else put #(thisline) @(_tc[ncol]+coff) count &ifmt '/' n &ifmt-l;
               end;
            end;

         /*
         / After printing all the columns for a given _LEVEL_ increment the
         / line pointer to setup for the next row.
         /--------------------------------------------------------------------*/
         if last._level_ then thisline = thisline + 1 + skip;
         end;

      /*
      / For the special case of the patient numbers print them on the same
      / line as the table stub label. i.e. THISLINE-1.  Also print a dashed
      / line under this data.
      /---------------------------------------------------------------------*/
      else if _vtype_='PTNO' then do;
         put #(thisline-1)  @(_tc[ncol]+coff) n &ifmt;
         end;


      /*
      / Put a blank line between each section (row name)  of the table.
      /----------------------------------------------------------------------*/
      if last._vname_ then do;
         if _DASH_ then put &ls*&dashchr;
         do i = 1 to vskipa;
            put;
            end;
         end;

   %if "&rlocate" = "LAST" %then %do;
      if last._vname_ then do;
         if _rlbl_ > ' ' then do;
            rlbl_i + 1;
            array _rlbl[1] _rlbl_;
            if indexw(flow,'RLABEL'||left(put(rlbl_i,5.))) then do;

               %jkflowx(in=_rlbl,out=_frlbl,dim=10,size=&jkrlwid,delm=' ',newline='\')

               do k = 1 to _frlbl0;

                  _frlbl[k] = translate(_frlbl[k],' ',"&hrdspc");
                  put _frlbl[k] $&ls..;

                  end;
               end;
            else do;
               _rlbl_ = translate(_rlbl_,' ',"&hrdspc");
               put _rlbl_ $&ls..;
               end;
            end;
         end;
      %end;


      /*
      / Print the table footer text at the end of the panels.
      /----------------------------------------------------------------------*/
      if last.panel then link footer;
      if eof then do;
         call symput('JKPG0',trim(left(put(page+&jkpg0,8.))));
         end;
      return;

    Header:
      Page + 1;

      /*
      / Print the TITLE lines. centering where need and adding
      / continued messages.
      /----------------------------------------------------------------------*/


      retain _hl0 &hl0;
      array _hl[15] $&ls _temporary_
         ("&hl1","&hl2","&hl3","&hl4","&hl5","&hl6","&hl7","&hl8","&hl9","&hl10",
          "&hl11","&hl12","&hl13","&hl14","&hl15");

      if page > 1 & cont then do;
         _hl[&hlcont] = trim(_hl[&hlcont])||' (Continued)';
         cont = 0;
         end;

      length _tempvar $&ls;
      do i = 1 to _hl0;
         select;
            when(indexw("&hlright",put(i,2.))) do;
               _tempvar = _hl[i];
               _tempvar = right(_tempvar);
               _tempvar = translate(_tempvar,' ',"&hrdspc");
               put #(i) _tempvar $char&ls..;
               end;
            when(indexw("&hlleft", put(i,2.))) do;
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


      %if 0 %then %do;
         put &ls*&dashchr;
         %end;

         put;

      /*
      / Print the column headers
      /------------------------------------------------------------------*/

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
      %if "&footdash"="YES" %then %do;
         put &ls*&dashchr;
         %end;

      %if "&contmsg"="YES" %then %do;
         put cnted $char&ls..-r;
         %end;

      if cont & ^eof then put cnted $char&ls..-r;

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

   proc delete data=&temp1 &constant &temp3 &temp4 &temp5;
      run;

   %put NOTE: JKPG0=&jkpg0;

   %if "&pagenum"="PAGEOF" %then %do;
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


 %EXIT:
   %PUT NOTE: Macro DTAB ending execution.;
   %mend dtab;
