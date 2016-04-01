/*
/ Program name: title.sas
/
/ Program version: 2
/
/ Program purpose: When used in conjuction with SETTITLE, will generate
/                  appropriate TITLE statements for given table or appendix
/                  for the current program
/
/
/ SAS version: 6.12 TS020
/
/ Created by: Carl Arneson
/ Date:
/
/ Input parameters: repeat - Repeat last set of titles?
/                   set - Specific set of titles to use (#)
/                   mock - Use mock titles if none are set?
/                   graphic - Is this a graphics title?
/                   font - Font to use for graphics titles
/                   height - Height to use for graphics titles
/                   foot - Print footnotes?
/                   label - Use title set identified by this label
/
/ Output created:
/
/ Macros called:
/
/ Example call:
/
/
/
/-----------------------------------------------------------
/
/ Change log:
/
/   13Dec94 SR Austin Added LABEL variable to select title set
/   27Mar95 SR Austin Made foot option work
/   20Jul95 SR Austin Graphics jobid offset varies by length of user name
/   3Aug95 SR Austin Offset graphics jobid a little more at request of R Toorawa
/   21Nov95 A Ratcliffe Make sure REPEAT, MOCK, GRAPHIC, and FOOT
/                   are converted to upcase even if only 1 char long.
/   15May97 C Arneson Handled justification of header titles in a cleaner way
/                     and created some global macro variables that people
/                     can stick in their inits to set default graphics
/                     fonts and heights
/   12Sep97 C Arneson Changed placement of JOBID in graphics and the
/                     placement of the FF character in footnotes to make
/                     things IDSG compliant
/   17oct97 JH King   Added companion global macro variables for TYPE NUM and TOC
/                     __type__ __num__ __toc__.  These will be used by MACPAGE if
/                     the macpage parameters TYPE= NUM= TOC= are left blank.
/
/   12nov97 JH King   Added a call to JKGETTF to allow %TITLE to create the
/                     titles as needed by macros DTAB and AETAB.
/----------------------------------------------------------------------------------*/

%macro TITLE(
             stdmac  = YES,
             repeat  = N,
             set     = ,
             mock    = Y,
             graphic = N,
             font    = _DEFAULT_,
             height  = _DEFAULT_,
             foot    = Y,
             startf  = 0,
             label   = ,
             dump    = 1
             ) ;

   %put NOTE: using PROTOTYPE version of the TITLE macro;
   %local pad lab_mtch;
   %let pad='                                                            ';

   /*
   /   Process arguments:
   /-----------------------------------------------------------------------*/
   %if %length(&repeat)>=1  %then %let repeat  = %upcase(%substr(&repeat,1,1)) ;
   %if %length(&mock)>=1    %then %let mock    = %upcase(%substr(&mock,1,1)) ;
   %if %length(&graphic)>=1 %then %let graphic = %upcase(%substr(&graphic,1,1)) ;
   %if %length(&foot)>=1    %then %let foot    = %upcase(%substr(&foot,1,1)) ;

   %let label=%upcase(%scan(&label,1)) ;

   /*
   / if font and height is set to _DEFAULT_, look for global specs in some
   / macro variable, otherwise set them to something standard
   /------------------------------------------------------------------------*/
   %if %quote(&font)=_DEFAULT_ %then %do ;
      %global _GTFONT_ ;
      %if "&_GTFONT_"~="" %then %let font=&_GTFONT_ ;
      %else %let font=DUPLEX ;
      %end;

   %if %quote(&height)=_DEFAULT_ %then %do ;
      %global _GTHT_ ;
      %if "&_GTHT_"~="" %then %let height=&_GTHT_ ;
      %else %let height=0.6 ;
      %end;


   /*
   / Process STDMAC parameter
   /-------------------------------*/
   %let stdmac = %substr(%qupcase(&stdmac)%str( ),1,1);
   %if %index(Y1,&stdmac)
      %then %let stdmac = 1;
      %else %let stdmac = 0;


   /*
   /  Update or create a global macro variable to act as a counter
   /  for the number of times this macro has been called in the
   /  current program:
   /----------------------------------------------------------------------*/
   %global __tmcnt ;
   %if %quote(&set)= & &__tmcnt= %then
      %let __tmcnt = 1 ;
   %else %if %quote(&repeat)~=Y & %quote(&set)= %then
      %let __tmcnt = %eval(&__tmcnt + 1) ;

   %if %quote(&set)= %then %let set=&__tmcnt ;

   /*
   / If user has specified a LABEL, find the matching title set and use it
   /-----------------------------------------------------------------------*/
   %let lab_mtch=0;
   %if " &label." ne " " %then %do sc=1 %to &_t_____n;
      %if %quote(&label)=%quote(&&__LBL_&sc) %then %do;
         %let set=&sc;
         %let lab_mtch=1;
         %end;
      %end;
   %else %let lab_mtch=2;

   %if &lab_mtch=0 %then %put WARNING: Label "&label" was not found on the titles dataset.  The next available title set will be used.;


   /*
   /  For graphics, build a strings that contain the graphics options:
   /----------------------------------------------------------------------*/

   %local gopt ;
   %if %quote(&graphic)=Y %then %do ;
      %if %quote(&font)~= %then %let gopt = &gopt F=&font ;
      %if %quote(&height)~= %then %let gopt = &gopt H=&height ;
      %end ;

   /*
   /  Put in %JOBID stamp for graphics:
   /--------------------------------------------*/
   %if &graphic=Y %then %do ;
      %local jobid ;
      %let jobid=%jobid(NOQUOTE,info=PATH) ;
      %end ;

   /*
   /  Figure out what the deal is with header titles by searching for
   /  HEADn global macro variables, then generate TITLE statments for
   /  the headers and set a variable for the next available title line:
   /---------------------------------------------------------------------*/
   %global head1 head2 head3 head4 head5 head6 head7 head8 head9 head10 ;
   %local i startn _left;
   %let startn=1 ;

   %do %while (%quote(&&head&startn)~=) ;
      %if %quote(&graphic)=Y %then %do ;
         /*
         / look for padding in header titles
         /------------------------------------------*/
         %let i=%index(%quote(&&head&startn),%str(               )) ;

         /*
         / if it at front, assume right justified title
         /------------------------------------------------*/
         %if &i=1 %then %do ;
            TITLE&startn
               &gopt J=R
               "%left(%nrbquote(&&head&startn))"
              ;
            %end ;
         /*
         / if it is in the middle, assume a left AND right justified piece
         /------------------------------------------------------------------*/
         %else %if &i>1 %then %do ;
            TITLE&startn &gopt J=L
            "%trim(%qsubstr(&&head&startn,1,&i))"
            &gopt J=R
            "%left(%qsubstr(&&head&startn,&i))"
            ;
            %end ;

         /*
         / otherwise, assume it should be left justified
         /-------------------------------------------------*/

         %else %do ;
            TITLE&startn &gopt J=L
            "%trim(%nrbquote(&&head&startn))"
            ;
            %end ;
         %end ;

      %else %do ;
         TITLE&startn "&&head&startn" &pad &pad &pad ;
         %end ;
      %let _left  = &_left &startn;
      %let startn = %eval(&startn + 1) ;
      %end /* end for do while */;


   /*
   / Calculate the maximum number of title lines left after headers:
   /------------------------------------------------------------------*/
   %local titles ;
   %let titles = %eval(10 - &startn) ;

   /*
   /  If no titles have been established for the current piece of
   /  output, create dummy value for the table numbers and titles:
   /------------------------------------------------------------------*/
   %local check ;
   %let check = 1 ;
   %do i = 1 %to &titles ;
      %global ttl&i._&set ;
      %if %nrbquote(&&ttl&i._&set)~= %then %let check = 0 ;
      %end ;

   %if &check & %quote(&mock)=Y %then %do;
      %do i = 1 %to 3 ;
         %let ttl&i._&set = Sample title line number &i ;
         %end;
      %end;

   %global tnstr&set __type&set __num&set ;
   %if %quote(&mock)=Y & %nrbquote(&&tnstr&set)= %then %do ;
      %let tnstr&set = Appendix/Table # ;
      %let __type&set   = A ;
      %let __num&set    = 0 ;
      %let foot=N;
      %end ;

   /*
   /  Count the non-null titles and footnotes:
   /---------------------------------------------------------------------*/
   %local ntitle nfoot;
   %let ntitle = 0 ;
   %do i = 1 %to &titles ;
      %if %nrbquote(&&ttl&i._&set)~= %then %let ntitle = &i ;
      %end ;

   %if &ntitle=0 & %quote(&&tnstr&set)= %then %do ;
      %let startn = %eval(&startn - 1) ;
      %goto texit ;
      %end ;

   /*
   / Generate FOOTNOTE statements:
   /--------------------------------------------------------------------*/
   %if &foot=Y %then %do;

      %let nfoot = 0 ;

      %do i = 1 %to 10 ;
         %if %length(%nrbquote(&&fnt&i._&set)) gt 1 %then %let nfoot = &i ;
         %end ;

      %do i = 1 %to &nfoot ;
         %if &graphic~=Y %then %do ;
            footnote&i "&&fnt&i._&set" &pad &pad &pad ;
            %end ;
         %else %do ;
            footnote&i j=l "&&fnt&i._&set" ;
         %end ;
      %end ;

      %if &nfoot=0 %then %let i=%eval(&startf + 1) ;
      %else              %let i=%eval(&i + 1) ;

      %if &graphic=Y %then %do ;
        footnote&i j=l f=&font h=%sysevalf(&height * 0.8) "&jobid" ;
        %end ;

      %else %do ;
        footnote&i 'FF'x ;
        %end ;

      %end;

   %else %if &graphic~=Y %then %do;
      footnote1 'FF'x  &pad &pad &pad;
      %end;
   %else %do ;
     footnote%eval(&startf+1) j=l f=&font h=%sysevalf(&height * 0.8) "&jobid" ;
     %end ;
   /*
   / -----  end footnote segment -----
   /------------------------------------------------*/

   /*
   /  Generate TITLE statement for table number:
   /-----------------------------------------------------------*/
   %if &graphic=Y %then %let gopt=&gopt J=C ;

   %if %quote(&&tnstr&set)~= %then %do ;
      title&startn &gopt
      %if &startn=1 & &graphic=Y %then %do ;
          ' ' move=(+0.0 in, -0.4 in)
         %end ;
      "&&tnstr&set" ;
      %end ;

   %else %do ;
      %let startn = %eval(&startn - 1) ;
      %end ;

   /*
   /  Set the global macro variables TYPE and NUM and initialize the
   /  global macro variable TOC:
   /----------------------------------------------------------------------*/
   /*
   / Changed by JHK to include __type__ __num__ __toc__;
   / These global macro variable will be used by MACPAGE the MACPAGE
   / parameters with the same name are not specified.
   /-----------------------------------------------------------------------*/

   %global type num toc __type__ __num__ __toc__;
   %let type = &&__type&set ;
   %let num = &&__num&set ;
   %let toc = ;
   %let __type__ = &type;
   %let __num__  = &num;
   %let __toc__  = &toc;

   %do i = 1 %to &ntitle ;
      %let startn = %eval(&startn + 1) ;
      /*
      / Generate TITLE statements for each title line of the current for
      / the current set of titles:
      /--------------------------------------------------------------------*/
      title&startn &gopt
         %if &startn=1 & &graphic=Y %then %do ;
            ' ' move=(+0.0 in, -0.4 in)
            %end ;
         "&&ttl&i._&set" ;

      /*
      / Build the TOC macro variable by concatenating each title line,
      / excluding:
      /     1. lines beginning with "(Part"
      /     2. lines containing #BYVAR, #BYVAL, #BYLINE
      /     3. null lines
      /     4. ??? anything else ????
      /------------------------------------------------------------------*/
      %local key ;
      %let key = (PART ;
      %if %index(%upcase("%nrbquote(&&ttl&i._&set)"),%nrbquote(&key))=0
         and %index(%upcase("%nrbquote(&&ttl&i._&set)"),#BYVAR)=0
         and %index(%upcase("%nrbquote(&&ttl&i._&set)"),#BYVAL)=0
         and %index(%upcase("%nrbquote(&&ttl&i._&set)"),#BYLINE)=0
         and %nrbquote(&&ttl&i._&set)~= %then %do;
         %let toc = %nrbquote(&toc) %nrbquote(&&ttl&i._&set) ;
         /*
         / Added by JHK.
         / Im not sure what, if any, kind of quoting I needed here,
         / so I just nrbquoted it.
         /---------------------------------------------------------------*/
         %let __toc__ = %nrbquote(&toc);
         %end;

      %end ;

 %texit:

   /*
   / Set the global macro variable NEXTT:
   /---------------------------------------------------------------------*/
   %global nextt _set_ ;
   %let nextt = %eval(&startn + 1) ;
   %let _set_ = &set ;

   %if &dump %then %do;
      %put NOTE: -----------------------------------------------------------------------;
      %put NOTE: The following Global macro variables have been set.;
      %put NOTE: NEXTT    = *&NEXTT*;
      %put NOTE: _SET_    = *&_set_*;
      %put NOTE: __TYPE__ = *&__type__*;
      %put NOTE: TYPE     = *&type*;
      %put NOTE: __NUM__  = *&__num__*;
      %put NOTE: NUM      = *&num*;
      %put NOTE: __TOC__  = %bquote(*&__toc__*);
      %put NOTE: TOC      = %bquote(*&toc*);
      %put NOTE: -----------------------------------------------------------------------;
      %end;

   %if &stdmac %then %do;
      %jkgettf(_left=&_left)
      %end;

%mend TITLE ;
