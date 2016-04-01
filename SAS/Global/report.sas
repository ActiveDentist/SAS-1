/*
/ Program name: report.sas
/
/ Program version: 2.1
/
/ Program purpose: This MACRO generates a PROC REPORT with DEFINE statements.
/                  Output is either a user-specified file or code that is
/                  immediately executed within the current SAS run.
/
/ SAS version: 6.12 TS020
/
/ Created by: Randall Austin
/ Date:       06/08/92
/
/ Input parameters: All options are optional (redundant, but true):
*                   DATA=    Input dataset (default is _last_)
*                   VARLIST= Variables (default is total dataset)
*                   LS=      Maximum number of characters per line
*                            (default is 132)
*                   SPLIT=   Split character (default is !)
*                   OUT=     Output FN. FT is REPORT. (Default is pgm name)
*                   MISSING= Turns on MISSING option in PROC REPORT.Options are
*                            MISSING (default) or anything else (becomes BLANK)
*                   MOD=     MOD=MOD or Y lets you add a number of PROC REPORT
*                            set-ups to the same output file.  Anything else
*                            is read as BLANK. (The default is BLANK.)
*                   REPOPT=  Allows user to enter special report options (e.g.,
*                            SPACING=, PANELS=, etc) in text format.  Anything
*                            entered here follows the PROC REPORT statement.
*                            (The default is BLANK).
*                   DEFOPT=  Allows user to enter special DEFINE options (e.g.,
*                   SPACING=, NOPRINT, etc) in text format.  Anything
*                            entered here follows the DEFINE statement on every
*                            record. (The default is BLANK).
*                   USAGE=   Allows user to change USAGE variable in DEFINE
*                            statement for each or all variables. Slash (/)
*                            separates VARIABLE from USAGE.  Example:
*                            USAGE=PATNO/ORDER DRUG/ACROSS
*                            To change the default for all variables omit the
*                            variable name and the slash. Example:  USAGE=ORDER
*                            (The default is DISPLAY).
*                   FLOW=    Defines FLOW variable(s) in DEFINE statement.
*                            Provide a list of variables to flow or input FLOW
*                            or Y to flow all. FLOW is automatically enabled if
*                            length of a variable exceeds 30 characters.
*                            Default is blank.
*                   JUSTIFY= Allows user to change JUSTIFY variable in DEFINE
*                            statement for each or all variables. Slash (/)
*                            separates VARIABLE from JUSTIFY.  (Default is CENTER
*                            for numeric and short character, LEFT for long
*                            character.)
*                   WIDTH=   Allows user to change WIDTH in DEFINE statement for
*                            each or all variables. Slash (/) separates VARIABLE
*                            from WIDTH.
*                   COLUMN=  Allows user input a COLUMN statement. If you input
*                            COLUMN but not VARLIST, macro will use COLUMN to
*                            guess at VARLIST.
*                            IMPORTANT: If COLUMN statement contains commas,
*                               you must enclose it in %STR().
*                   BOTLINE= BOTLINE=Y lets you add a solid underline at the
*                            bottom of the report, length calculated internally.
*                            Specify length with BOTLINE= num, where num is
*                            length. Default is BOTLINE=N.
*                   BOTCHAR= Character for BOTLINE. Default is _ .
*                   FLOWLEN= Width of column when FLOW is turned on. Default=30.
*                   CLRFMT=  CLRFMT=Y clears existing formats that
*                            begin with blank, $, or F.  Default is N.
*
*  Input Datasets:     _LAST_ (or user specified)
*  Internal Datasets:  _M_R_O_1  _M_R_O_2 _M_R_O_3 _M_R_O_C _M_R_O_N
*  Output Datasets:    REPORT.fn   (or user specified FN)
*
*  Note: The self-executing form of this macro is open-ended, i.e., you
*        may include other statements such as COMPUTE and JOBID2 after
*        the macro call and they will be included in the run.
/

/
/ Output created:
/
/ Macros called:
/
/ Example call:
/
/====================================================================================
/ Change log:
/
/    MODIFIED BY: Jonathan Fry
/    DATE:        10DEC1998
/    MODID:       JMF001
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 2.1.
/    -------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX002
/    DESCRIPTION:
/    -------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX003
/    DESCRIPTION:
/    -------------------------------------------------------------------
/====================================================================================*/

%macro report(data=_LAST_,varlist=,ls=132,split=!,out=,missing=MISSING,
              mod=,repopt=,defopt=,usage=DISPLAY,justify=,clrfmt=N,
              column=,botline=N,botchar=_,flow=,width=,flowlen=30);

    /*
    / JMF001
    / Display Macro Name and Version Number in LOG
    /----------------------------------------------------------*/

    %put ----------------------------------------------------;
    %put NOTE: Macro called: REPORT.SAS   Version Number: 2.1;
    %put ----------------------------------------------------;


/*   Liberalize some option choices (allow for Y)              */
   %if %upcase(&MISSING)=Y !
       %upcase(&MISSING)=MISSING %then %let MISSING=MISSING ;
           %else %let MISSING=;
   %if %upcase(&MOD)=Y! %upcase(&MOD)=MOD %then %let MOD=MOD;
           %else %let MOD=;

   %if &out= %then %let out=%fn;
;
   %if &botline=N %then %let BOTLEN=0;

   %let CHARLST= ; %let NUMLST= ; %let S=;
   proc format;
      value __f__ 0 = '      ';
   proc contents data=&data out=_M_R_O_1 noprint;

   data _M_R_O_C _M_R_O_N; SET _M_R_O_1 end=eof;
      retain _x _z 0 ;
       %if %scan(&varlist,1)= &
         %scan(%bquote(&column),1)= %then %do;
       * If no VARLIST or COLUMN given, then use all variables ;
           _x+1;
           IF type=1 then output _M_R_O_N ;   else
           IF type=2 then output _M_R_O_C ;
       %end;

       %else %if %scan(&varlist,1)~= %then %do;
       * If a VARLIST is given, then only use specified variables ;
         _x=1;
         do while(scan("&varlist",_x)~=' ');
           choice=upcase(compress(scan("&varlist",_x)));
           if NAME= choice and type=1 then output _M_R_O_N ; else
           if NAME= choice and type=2 then output _M_R_O_C ;
           _x=_x+1;
         end;

           _x=_x-1;
       %end;

       %else %do;
       * If only COLUMN is given, then guess at desired variables ;
         _x=1;
         do while(scan("%bquote(&column)",_x)~=' ');
           choice=upcase(compress(scan("%bquote(&column)",_x)));
           if NAME= choice and type=1 then do;
              _z=_z+1;
              output _M_R_O_N ;
           end;else
           if NAME= choice and type=2 then do;
              _z=_z+1;
              output _M_R_O_C ;
           end;
           _x=_x+1;
         end;
           _x = _z ;*  Record the number of 'hits' ;
       %end;

         if eof then do;
           call symput("NWANT",_x);
           if "&data"="_LAST_" then
              call symput("DATA",compress(libname !! "." !! memname));
         end;
run;

    data _NULL_ ; set _M_R_O_N ; by libname;
         length numlst $200;
         retain numlst;
         numlst = left(trim(numlst)) !! ' ' !! NAME ;
            if last.libname then do;
              call symput("NUMLST",left(trim(NUMLST)));
            END;

    data _NULL_ ; set _M_R_O_C;by libname;
         length numlst $200;
         retain numlst;
         numlst = left(trim(numlst)) !! ' ' !! NAME ;
            if last.libname then do;
              call symput("CHARLST",left(trim(NUMLST)));
            END;
   run;
   /*-----------------------------------------------------------------
   / now read the input data and calculate
   / 1) calculated length for character and numeric vars
   / 2) calculated formats for each var
   /-----------------------------------------------------------------*/
   data _M_R_O_3 ;
         set &data(keep=&CHARLST &NUMLST) end=eof;
         length name $8 ;
         keep _format_ name _length_ ;
    %if &NUMLST ~= %then %do;
         retain NA1-NA200 NB1-NB200;
         array __N {*} &NUMLST ;
         array NA  {*} NA1 - NA200 ;
         array NB  {*} NB1 - NB200 ;
         length __best __dig1-__dig2 $32;

         do _x=1 to dim(__N) ;
            __best = put(__N(_x),best32.);
            __dig1 = left(scan(__best,1,'.'));
            __dig2 = left(scan(__best,2,'.'));
            NA(_x)=max(1,length(__dig1)-(__dig1=' '),NA(_x));
            NB(_x)=max(length(__dig2)-(__dig2=' '),NB(_x));

            if eof then do;
              _format_=put( (NB(_x)>0) + NB(_x) + NA(_x),4.)!!'.'!!
                       left(put(NB(_x),__F__.));
              _length_=NB(_x)+NA(_x)+min(1,NB(_x)*1);
              call vname(__N{_x},NAME);
                output;
            end;
         end;
    %end;
    %if &CHARLST ~= %then %do;
         retain CL1-CL200 ;
         array __C {*} $200 &CHARLST ;
         array __CL {*} cl1-cl200;
         do _z=1 to dim(__C) ;
            __CL{_z} = max(__CL{_z},length(__C{_z})-(__C{_z}=' '));
            CFM= put(max(__CL{_z},1),4.)!!'.';
            if eof then do;
             substr(CFM,verify(CFM,' ')-1,1)='$';
              _format_=CFM;
              _length_=__CL{_z};
              call vname(__C{_z},NAME);
                output;
            end;
         end;
    %end;
   *-------------------------------------------------------------------*
   ! Find desired print-order of requested variables
   *-------------------------------------------------------------------;
   proc sort data=_M_R_O_3 out=_M_R_O_3 ;  by NAME ;
   proc sort data=_M_R_O_1 out=_M_R_O_1 ;  by NAME ;

%IF &varlist= %THEN %DO;
   data _NULL_ ;
      merge _M_R_O_1 _M_R_O_3(in=WANTED) end=eof;by NAME ;
        _var_cnt= VARNUM ;

     /*     (This data step code joins up with more down below)   */

%END; %ELSE %DO;

   data _M_R_O_2 ;
     _x=1;
     do while(scan("&varlist",_x)~=' ');
        NAME = upcase(compress(scan("&varlist",_x)))  ;
        _var_cnt= _x ;
        output;
        _x=_x+1;
     end;
   proc sort data=_M_R_O_2 out=_M_R_O_2 ; by NAME;

   *-------------------------------------------------------------------*
   ! Select from the dataset only those variables requested
   *-------------------------------------------------------------------;
   data _null_ ;
     merge _M_R_O_1 _M_R_O_3 _M_R_O_2(in=WANTED);
       by NAME ;
%END;
       IF WANTED;

     *-----------------------------------------------------------------*
     ! If we already have a specified format (e.g., DATE7.), we want to
     ! use that length instead of the calculated length.
     *-----------------------------------------------------------------;
     if formatl > 0 then _length_=formatl;

          length fmt $16 ;
          fmt = input(compress(trim(format)!!
                put(formatl,__F__.)!!'.'!!put(formatd,__F__.)),$16.);
          if fmt='.' ! fmt=' ' !
            (upcase("&CLRFMT")="Y" &
              (format=' ' ! format='$' ! format='F'))
                then fmt=_format_;

          if fmt='...' then do;
               put "ERROR:  You have specified a variable in VARLIST"
                   " called " NAME    ;
               put "        that is not in %upcase(&data)." ;
               put "        This program will terminate.";
               call symput("S","ENDSAS");
           end;

          if label~=' ' then lab=label;  else lab=NAME;

   ***********************************************************;
   ** if we have split-delimiters in our labels, find the ****;
   ** longest segment for WIDTH parameter                 ****;
   ***********************************************************;

   if index(lab,"&split") then do;
          * find the length of the longest delimited segment ;
            _comp_  = lab ;
            _labcnt = 1 ;
          do while(index(_comp_,"&split")>0);
             _wordpos=index(_comp_,"&split");
              if _labcnt=1 then
                 _wordlen=_wordpos-1;
              _oldpos =_wordpos;
             substr(_comp_,index(_comp_,"&split"),1)=' ';
             _labcnt+1 ;
          end;*   now find the length of the tail-end segment ;
             _wordlen=max(_wordlen,length(_comp_) - _oldpos);
   end; else _wordlen=length(lab);
   ***********************************************************;

          width=max(_wordlen,_length_);

     call symput("NAME"!!compress(_var_cnt),NAME);
     if fmt ne ' ' then
        call symput("FMT"!!compress(_var_cnt),compress("FORMAT="!!FMT));
     else
        call symput("FMT"!!compress(_var_cnt),compress(" "));

     length usage $8. jst $8. flow $8. ;
    *------------------------------------------------------------------*
    ! Set FLOW parameter and change individual values or global default
    *------------------------------------------------------------------;
    if type = 2 & _length_ > &FLOWLEN
      then FLOW='FLOW'; * AutoFlow if > &FLOWLEN chars;
    *****  User-Defined FLOW for DEFINE statement                ;
             _zz=1;
            do while (scan("&FLOW",_zz) ne ' ');
             if upcase(scan("&FLOW",_zz))=upcase(NAME) then FLOW="FLOW";
             _zz+1;
            end;
    *****  User is allowed to set FLOW as default for all ;
   if upcase("&FLOW") = "FLOW" ! upcase("&FLOW") = "Y"
      then flow="FLOW" ;
      if flow ne 'FLOW' then flow=' ';

      if flow="FLOW" & _length_ > &FLOWLEN
        then width=max(_wordlen,&FLOWLEN);

    *------------------------------------------------------------------*
    ! Set USAGE parameter and change individual values or global default
    *------------------------------------------------------------------;
    usage='DISPLAY';
    *****  User-Defined USAGE for DEFINE statement                ;
    if index("&USAGE","/") then do;
            _xx=1;
            do while (scan("&USAGE",_xx) ne ' ');
              if upcase(scan("&USAGE",_xx))=upcase(NAME) then
                 USAGE=scan("&USAGE",_xx+1);
              _xx+2;
            end;
    end;

    *****  User is allowed to provide a new default USAGE for all ;
   if scan("&USAGE",1) ~= ' ' & scan("&USAGE",2) = ' '
    then usage="&USAGE"     ;
    usage=upcase(USAGE)     ;
    *****  CHECK for VALID USAGE                               ;
    IF usage ne 'ACROSS' &     usage ne 'ANALYSIS' &
       usage ne 'COMPUTED' &   usage ne 'DISPLAY' &
       usage ne 'GROUP' &      usage ne 'ORDER' then usage=' ' ;

    *------------------------------------------------------------------*
    ! Set JUSTIFY parameter and change individual values or default
    *------------------------------------------------------------------;
    if type = 2 & _length_ > 5 then JST='LEFT'; else JST='CENTER';
    *****  User-Defined JUSTIFY for DEFINE statement                ;
    if index("&JUSTIFY","/") then do;
            _xx=1;
            do while (scan("&JUSTIFY",_xx) ne ' ');
              if upcase(scan("&JUSTIFY",_xx))=upcase(NAME) then
                 JST=scan("&JUSTIFY",_xx+1);
              _xx+2;
            end;
    end;

    *****  User is allowed to provide a new default JUSTIFY for all ;
   if scan("&JUSTIFY",1) ne ' ' & scan("&JUSTIFY",2) = ' '
    then jst="&JUSTIFY"  ;
    jst=upcase(jst);
    *****  CHECK for VALID JUSTIFY                                ;
    IF JST ne 'CENTER' &  JST ne 'RIGHT' &
       JST ne 'LEFT'   then JST=' ';

    *------------------------------------------------------------------*
    ! Set WIDTH parameter and change individual values or default
    *------------------------------------------------------------------;
    *****  User-Defined WIDTH for DEFINE statement                ;
    if index("&WIDTH","/") then do;
            _xz=1;
            do while (scan("&WIDTH",_xz) ne ' ');
              if upcase(scan("&WIDTH",_xz))=upcase(NAME) then
                 width=scan("&WIDTH",_xz+1)*1;
              _xz+2;
            end;
    end;

    *****  User is allowed to provide a new default WIDTH for all ;
   if scan("&WIDTH",1) ne ' ' & scan("&WIDTH",2) = ' '
    then width="&WIDTH"*1;

     if LABEL=' ' then LABEL=compress(NAME);

     *-----------------------------------------------------------------*
     ! Calculate the length of the headline so we can add a footline
     ! to match.  Assume the default spacing = 2.
     *-----------------------------------------------------------------;
      retain botlen 0 ;
      botlen= width + 2 + botlen ;
      botput= put(botlen-2,3.0);

     if upcase("&botline") = "Y" then
       call symput("BOTLEN",compress(botput));
     else
     if indexc("&botline","1234567890") then
       call symput("BOTLEN",compress("&botline"));

     call symput("TITLE"!!compress(_var_cnt),left(trim(LABEL)));
     call symput("WIDTH"!!compress(_var_cnt),compress("WIDTH="!!WIDTH));
     call symput("USG"!!compress(_var_cnt),compress(USAGE));
     call symput("JST"!!compress(_var_cnt),compress(JST));
     call symput("FLOW"!!compress(_var_cnt),compress(FLOW));
run;
&S;

   %if %upcase(&out) ~= N %then %do;
/**********************************************************************
 * Produce a PROC REPORT setup and save to an ASCII file
 *********************************************************************/
       data _null_ ;
          file "&out..report" &mod ;
PUT "PROC REPORT NOWD DATA=&data CENTER HEADLINE HEADSKIP LS=&ls COLWIDTH=8";
PUT "            &MISSING SPLIT=""&SPLIT"" &REPOPT.;"  ;
%if %scan(%bquote(&COLUMN),1)= %then %do;
PUT "COLUMN ";
        %do _x=1 %to &NWANT ;
PUT " &&NAME&_X ";
        %end;
PUT ";";
%end; %else
PUT "COLUMN %bquote(&COLUMN);";;
        %do _x=1 %to &NWANT ;
PUT
"DEFINE &&NAME&_X / &&USG&_X &&FMT&_X &&WIDTH&_X "
 "&&JST&_X &&FLOW&_X &DEFOPT"
 /  "                  %str(%")&&TITLE&_X.%str(%");";
        %end;
%if &BOTLEN~=0 %then %do;
PUT "COMPUTE AFTER;";
PUT "LINE &BOTLEN*%str(%')&BOTCHAR.%str(%');";
PUT "ENDCOMP;";
%end;

PUT "RUN;";

   %end;  %else %do;
/**********************************************************************
 * Produce a PROC REPORT setup and run PROC REPORT
 *********************************************************************/

PROC REPORT NOWD DATA=&data CENTER HEADLINE LS=&ls COLWIDTH=8 SPLIT="&SPLIT"
                 HEADSKIP &repopt ;
COLUMN
%if %scan(%bquote(&COLUMN),1)= %then %do;
        %do _x=1 %to &NWANT ;
 &&NAME&_X
        %end;
%end; %else &COLUMN ;
;
        %do _x=1 %to &NWANT ;
DEFINE &&NAME&_X / &&USG&_X &&FMT&_X &&WIDTH&_X &&JST&_X &&FLOW&_X
       &DEFOPT "&&TITLE&_X";
        %end;
%if &BOTLEN~=0 %then %do;
compute after ;
line &BOTLEN * "&BOTCHAR" ;
endcomp;
%put "Bottom Line Length= &BOTLEN";
%end;
   %end;
%mend report;
