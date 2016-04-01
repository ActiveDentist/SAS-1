/*
/ Program Name:     BWCONT.SAS
/
/ Program Version:  3.1
/
/ Program purpose:  An enhanced version of PROC CONTENTS
/
/ SAS Version:      6.12
/
/ Created By:       John H. King
/ Date:
/
/ Input Parameters: DATA     - name of dataset being processed
/                   OUT      - name of dataset containing information on the DATA
/                              dataset
/                   ROUND    - parameter for defining level of rounding for numeric
                               variables (optional)
/                   REPORT   - (Y/N) option specifying whether to produce a report
/                   ALLMISSC - list of character variables with all values missing
/                   ALLMISSN - list of numeric variables with all values missing
/
/ Output Created:   Standard dataset information is obtained using PROC CONTENTS.
/                   The following addition information is obtained:
/
/                       - Number of observations with missing values for each variable
/                       - Number of variables where all values are missing
/                       - Length of format required for printing
/
/                   The extra information is stored in a set of macro variables. If the REPORT
/                   option is specified, output is produced in a format similar to PROC CONTENTS,
/                   with the extra information printed on the report.
/
/ Macros Called:    BWGETTF
/
/ Example Call:
/
/================================================================================================
/ Change Log
/
/    MODIFIED BY: KK
/    DATE:        31.3.95
/    MODID:       001
/    DESCRIPTION: Changed NUM -> CHAR conversion method.
/    --------------------------------------------------------------------------------
/    MODIFIED BY: Jonathan Fry
/    DATE:        09DEC1998
/    MODID:       JMF002
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 3.1.
/    --------------------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX003
/    DESCRIPTION:
/    --------------------------------------------------------------------------------
/================================================================================================*/

%macro bwcont(data=,
              out=_OUT_,
            round=,
           report=Y,
         allmissC=MISSC,
         allmissN=MISSN);
   %let data   =%upcase(&data);

      /*
      / JMF002
      / Display Macro Name and Version Number in LOG.
      /------------------------------------------------------------------*/

      %put ------------------------------------------------------;
      %put NOTE: Macro called: BWCONT.SAS     Version Number: 3.1;
      %put ------------------------------------------------------;


   /*
   / declare macro variables
   /
   /------------------------------------------------------------------*/
   %if %length(&report)>0 %then
     %let report=%upcase(%substr(&report,1,1)) ;
   %let allmissC=%upcase(&allmissC);
   %let allmissN=%upcase(&allmissN);
   %local rv l type1 type2 linesize
      vnum1 vnum2 vnum3 vnum4 vnum5 vnum6 vnum7 vnum8 vnum9 vnum10
      vchr1 vchr2 vchr3 vchr4 vchr5 vchr6 vchr7 vchr8 vchr9 vchr10;
   %global &allmissn.0 &allmissn &allmissc.0 &allmissc;
   %local ___n1 ___n2 ___n3 ___n4 ___n5 ___n6 ___n7 ___n8 ___n9 ___n10;
   %local ___c1 ___c2 ___c3 ___c4 ___c5 ___c6 ___c7 ___c8 ___c9 ___c10;
   %if %substr(&sysver,1,1)=6
      %then %let rv=varnum=var0;
      %else %let rv=;
   proc contents data=&data out=&out(rename=(&rv)) noprint;
      run;
   %if &syserr>0 %then %do;
      %put NOTE: SYSERR=&syserr SYSINFO=&sysinfo;
      %put NOTE: Program terminated by invoked macro BWCONT.;
      ;endsas;
      %end;
   proc format;
      value __f__ 0 = '      ';
      value __t__ 1 = 'NUM' 2 = 'CHAR';
      run;
   proc sort data=&out;
      by name;
      run;
   /*
   / create character variables from proc contents format and infromat
   / variables this will be used for printing later on.
   /------------------------------------------------------------------*/
   /*
   / in this next step create macro variable arrays of all the numeric
   / and character variables in the input data set. this is done by
   / processing the output from proc cotents
   /------------------------------------------------------------------*/
   %let l = 200;
   data _null_;
      array _n(n0)  $&l n1-n10;
      array _c(c0)  $&l c1-c10;
      n0=1; c0=1;
      do until(eof);
         set &out end=eof;
         nvars + 1;
         type1 + type=1;
         type2 + type=2;
         if type = 1 then do;
            if length(_N) + length(name) + 3 > &l then n0=n0+1;
            _N = trim(_N)||' '||name;
            end;
         else if type = 2 then do;
            if length(_C) + length(name) + 3 > &l then c0=c0+1;
            _C = trim(_C)||' '||name;
            end;
         end;
      call symput('NVARS',left(put(nvars,8.)));
      call symput('TYPE1',left(put(type1,8.)));
      call symput('TYPE2',left(put(type2,8.)));
      call symput('VNUM1',left(trim(n1)));
      call symput('VNUM2',left(trim(n2)));
      call symput('VNUM3',left(trim(n3)));
      call symput('VNUM4',left(trim(n4)));
      call symput('VNUM5',left(trim(n5)));
      call symput('VNUM6',left(trim(n5)));
      call symput('VNUM7',left(trim(n5)));
      call symput('VNUM8',left(trim(n5)));
      call symput('VNUM9',left(trim(n5)));
      call symput('VNUM10',left(trim(n5)));
      call symput('VCHR1',left(trim(c1)));
      call symput('VCHR2',left(trim(c2)));
      call symput('VCHR3',left(trim(c3)));
      call symput('VCHR4',left(trim(c4)));
      call symput('VCHR5',left(trim(c5)));
      call symput('VCHR6',left(trim(c5)));
      call symput('VCHR7',left(trim(c5)));
      call symput('VCHR8',left(trim(c5)));
      call symput('VCHR9',left(trim(c5)));
      call symput('VCHR10',left(trim(c5)));
      run;
   /*
   / now read the input data and calculate the added information to
   / include in the new proc contents output.
   / 1) number of missing values per variable
   / 2) calculated length for character and numeric vars
   / 3) calculated formats for each var
   /------------------------------------------------------------------*/
   data _out2_(rename=(__NAME__=name));
      keep _format_ __name__ _length_ _MISS_;
      length __name__ $8. _format_ $8;
      format __name__ _format_ $char8.;
      do until(eof);
         set &data end=eof;
      %if &type1^=0 %then %do;
         array __N &vnum1 &vnum2 &vnum3 &vnum4 &vnum5
                   &vnum6 &vnum7 &vnum8 &vnum9 &vnum10;
         array __NA __na1-__na&type1;
         array __NB __nb1-__nb&type1;
         array __NMIN __m1-__m&type1;
         array __NMAX __x1-__x&type1;
         array __NMIS __y1-__y&type1;
         length __best __dig1-__dig2 $32;
         do over __N;
         %if "&round"="" %then %do;
*        KK 31/3/95 Change num -> char method due to rounding error;
*            __best = put(__N,best32.);
             __best = compress(__N||' ');
            %end;
         %else %do;
            if __N > .Z
               then __best = put(round(__N,&round),best32.);
               else __best = ' . ';
            %end;
            __dig1 = left(scan(__best,1,'.'));
            __dig2 = left(scan(__best,2,'.'));
            __NA   = max(1,__NA,length(__dig1)-(__dig1=' '));
            __NB   = max(__NB,length(__dig2)-(__dig2=' '));
            __NMAX = max(__NMAX,__N);
            __NMIN = max(__NMIN,__N);
            __NMIS + .Z >= __N;
            end;
         %end;
      %if &type2^=0 %then %do;
         array __C &vchr1 &vchr2 &vchr3 &vchr4 &vchr5
                   &vchr6 &vchr7 &vchr8 &vchr9 &vchr10;
         array __CL __cl1-__cl&type2;
         array __CMIS __cy1-__cy&type2;
         do over __C;
            __CL    = max(__CL,length(__C)-(__C=' '));
            __CMIS + __C=' ';
            end;
         %end;
         end;
      %if &type1^=0 %then %do;
         do over __N;
            _format_ = put((__NB>0) + __NB + __NA,4.)||'.'||
                       left(put(__NB,__F__.));
            if __NB=0 then select;
               when(__NMIN>=-255             & __NMAX<=255)
                  _length_=2;
               when(__NMIN>=-65535           & __NMAX<=65535)
                  _length_=3;
               when(__NMIN>=-16777215        & __NMAX<=16777215)
                  _length_=4;
               when(__NMIN>=-4294967295      & __NMAX<=4294967295)
                  _length_=5;
               when(__NMIN>=-1099511627775   & __NMAX<=1099511627775)
                  _length_=6;
               when(__NMIN>=-281474946710655 & __NMAX<=281474946710655)
                  _length_=7;
               otherwise _Length_=8;
               end;
            else _length_ = 8;
            _MISS_ = __NMIS;
            call vname(__N,__name__);
            output;
            end;
         __name__=' '; _format_=' ';
         %end;
      %if &type2^=0 %then %do;
         length _length_ 8;
         do over __C;
            _length_ = __CL;
            _format_ = put(max(_length_,1),4.)||'.';
            substr(_format_,verify(_format_,' ')-1,1)='$';
            _miss_ = __CMIS;
            call vname(__C,__name__);
            output;
            end;
         %end;
      run;
   /*
   / sort and merge the original proc contents output dataset to the
   / added information calculated in the step above
   /------------------------------------------------------------------*/
   proc sort data=_out2_;
      by name;
      run;
   data &out;
      merge &out _out2_;
      by name;
      retain nvars &nvars;
      length fmt  ifmt $16.;
      fmt  = input(compress(trim(format)||
             put(formatl,__F__.)||'.'||put(formatd,__F__.)),$16.);
      ifmt = input(compress(trim(informat)||
             put(informl,__F__.)||'.'||put(informd,__F__.)),$16.);
      run;
   proc sort data=&out;
      by var0;
      run;
   /*
   / now process the enhanced proc contents output data set to provide
   / information on variables with all missing values. this info will
   / be displayed in the printed output and provided as variables lists
   / in two macro variables.
   /------------------------------------------------------------------*/
   data _null_;
      retain ___cidx ___nidx 1;
      array __C(___cidx) $200 ___c1-___c10;
      array __N(___nidx) $200 ___n1-___n10;
      retain ___c1-___c10 ___n1-___n10;
      set &out(keep=name type nobs _miss_) end=eof;
      retain nvars &nvars;
      if nobs=_miss_ then do;
         if type=1 then do;
            ___mn0 + 1;
            if length(__n) + length(name) + 1 > 200 then ___nidx + 1;
            __n = trim(__n)||' '||name;
            end;
         else if type=2 then do;
            ___mc0 + 1;
            if length(__c) + length(name) + 1 > 200 then ___cidx + 1;
            __c = trim(__c)||' '||name;
            end;
         end;
      if eof then do;
         call symput("&allmissn"||'0',left(put(___mn0,8.)));
         call symput('___N1' ,trim(___n1));
         call symput('___N2' ,trim(___n2));
         call symput('___N3' ,trim(___n3));
         call symput('___N4' ,trim(___n4));
         call symput('___N5' ,trim(___n5));
         call symput('___N6' ,trim(___n6));
         call symput('___N7' ,trim(___n7));
         call symput('___N8' ,trim(___n8));
         call symput('___N9' ,trim(___n9));
         call symput('___N10',trim(___n10));

         call symput("&allmissc"||'0',left(put(___mc0,8.)));
         call symput('___C1' ,trim(___c1));
         call symput('___C2' ,trim(___c2));
         call symput('___C3' ,trim(___c3));
         call symput('___C4' ,trim(___c4));
         call symput('___C5' ,trim(___c5));
         call symput('___C6' ,trim(___c6));
         call symput('___C7' ,trim(___c7));
         call symput('___C8' ,trim(___c8));
         call symput('___C9' ,trim(___c9));
         call symput('___C10',trim(___c10));
         end;
      run;
   %let &allmissn=&___n1 &___n2 &___n3 &___n4 &___n5 &___n6 &___n7 &___n8 &___n9
 &___n10;
   %let &allmissc=&___c1 &___c2 &___c3 &___c4 &___c5 &___c6 &___c7 &___c8 &___c9
 &___c10;

%if &report=Y %then %do ;
   /*
   / Call macro bwgettf to get the current titles and footnotes so
   / they can be printed in the report just like a sas proc would do
   /------------------------------------------------------------------*/
   %bwgettf(dump=NO)
   %let linesize=&_bwls;

   /*
   / if the linesize is less than 125 then set it to 125 because the
   / report need at least that large of a linesize. not exactly like
   / a sas proc now is it.
   /------------------------------------------------------------------*/
   %if &_bwls<125 %then %do;
      %let linesize=&_bwls;
      options ls=125;
      %bwgettf(dump=NO)
      %end;

   data _null_;
      file print notitles ls=&_bwls ps=&_bwps ll=ll header=header;
      retain missc &missc0 missn &missn0;
      retain ps &_bwps ls &_bwls _f0 &_bwf0 _t0 &_bwt0;
      retain adjust 0 center &_bwct;
      if _n_=1 & center then adjust=int((ls-125)/2);
      set &out end=eof;
      link ll;
      put + adjust
          +0  VAR0            4.
          +1  NAME       $CHAR8.
          +1  _MISS_          7.
          +2  TYPE        __T__.
          +1  _length_        5.
          +1  length          5.
          +1  NPOS            7.
          +2  _FORMAT_       $7.
          +3  FMT       $CHAR11.
          +2  IFMT      $CHAR11.
          +2  label     $CHAR40. ;
      if eof then link footer;
      return;
    LL:
      if ll < (2 + _f0) then do;
         link footer;
         put _page_ @;
         end;
      return;
    Footer:
      put +adjust 125*'-';
      array _f{10} $200 _temporary_
         ("&_bwf1","&_bwf2","&_bwf3","&_bwf4","&_bwf5",
          "&_bwf6","&_bwf7","&_bwf8","&_bwf9","&_bwf10");
      if _f0 > 0 then do;
         line = ps - _f0 + 1;
         do i = 1 to _f0;
            put #line _f{i} $varying200. ls;
            line = line + 1;
            end;
         end;
      return;
    Header:
      array _t{10} $200 _temporary_
         ("&_bwt1","&_bwt2","&_bwt3","&_bwt4","&_bwt5",
          "&_bwt6","&_bwt7","&_bwt8","&_bwt9","&_bwt10");
      do line = 1 to _t0;
         put #line _t{line} $varying200. ls;
         end;

      length __h $ 200;
      __h = 'Burroughs Wellcome Co. Contents Procedure';
      link cprint;

      __h = 'Contents of Sas Member '
             ||trim(libname)||'.'||trim(memname);
      link cprint;
      put //;
      if memlabel^='' then do;
         __h = 'Data Set Label: '||trim(memlabel);
         link lprint;
         end;

      __h = 'Number of Observations: '||trim(left(put(nobs,16.)))||
             '   Number of Variables: '||left(put(nvars,16.));
      link lprint;
      if missn>0 then do;
         __h=put(missn,5.)||
             ' Numeric variables have all missing values';
         link lprint;
         end;
      if missc>0 then do;
         __h=put(missc,5.)||
             ' Character variables have all missing values';
         link lprint;
         end;

      __h = '----List of Variables and Attributes by Position----';
      __h=repeat(' ',round((125-length(__h))/2)-1) || trim(left(__h));
      __hl = length(__h);
      put // +adjust __h $varying200. __hl;

      put +adjust +17 '# of';
      put +adjust +5
     'Variable Missing        ---Length--         ------Format------';
      put +adjust +3
         '# Name      Values  Type  Calc Actual    Pos  Calc'
         '      Actual       Informat     Label';
      put +adjust 125*'-';
      return;
    Lprint:
      __hl = length(__h);
      put +adjust __h $varying200. __hl;
      return;
    Cprint:
     if center then
         __h=repeat(' ',round((ls-length(__h))/2)-1) || trim(left(__h));
      __hl = length(__h);
      put @1 __h $varying200. __hl;
      return;
      run;
   options _last_=&data linesize=&linesize;
   %put ---------------------------------------------------------------;
   %put List of variables with all missing values.;
   %put -  Numeric &allmissn.0=&&&allmissn.0;
   %put -  &allmissn=&&&allmissn;
   %put -  Character &allmissc.0=&&&allmissc.0;
   %put -  &allmissc=&&&allmissc;
   %put ---------------------------------------------------------------;
%end ;
   %mend bwcont;
