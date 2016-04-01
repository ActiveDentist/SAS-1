/*
/ Program name: jobid.sas
/
/ Program version: 2
/
/ Program purpose: Creates jobid information in various titles
/                  footnotes etc. (username, program name etc.).
/
/ SAS version: 6.12 TS020
/
/ Created by:
/ Date:
/
/ Input parameters: arg - area to print jobid info
/                   info - information to print
/                   datefmt - date format
/                   time - include time of day
/                   before - text to print before jobid string
/                   after - text to print after jobid string
/                   font - graphics font
/                   height - font height
/                   colour - font colour
/                   premove - starting point for relative moves
/                   move - location of id string
/
/ Output created:
/
/ Macros called:
/
/ Example call:
/
/   %jobid(title);
/
/-----------------------------------------------------------
/
/ Change log:
/
/
/-----------------------------------------------------------*/

%macro jobid(arg, /* FOOTNOTE, TITLE, GRAPHICS, NOQUOTE, PLATE
                      pointer control */
            info=USERID, /* or PATH for /path/file.ext
                            or LONG for userid(/path/file.ext)
                            NOTE: exact form depends on operating system */
         datefmt=DATE, /* date style MDY, DMY, YMD, DATE7 */
            time=YES, /* include time of day? */
          before=,    /* character constant "before" jobid string */
           after=,    /* character constant "after"  jobid string */
                                  /* Options for Graphics only */
            font=SIMPLEX,            /* graphics font */
          height=0.5,                /* font height */
           color=BLACK,              /* font color */
         premove=,                   /* Starting point for relative moves */
            move=(0.0 IN, 0.01 IN)); /* location of id string */

   /* Note:  This version runs on VMS and UNIX systems only */
   %if %index(%str( VMS SUN 4 ),%str( &sysscp ))=0 %then %do;
     %put ERROR: Unsuported platform for current version of JOBID.;
     %goto endtag;
   %end;

   %let arg = %upcase(&arg);
   %if "&arg"="" %then %let arg=FOOTNOTE1;
   %let info = %upcase(&info);
   %local date time;
   %let datefmt=%upcase(&datefmt);
   %if %index(&datefmt,DATE) %then %let date=&sysdate;
   %else %do;
      %local mm dd yy ml;
      %let mm=%scan(&sysdate,1,0123456789);
      %let dd=%substr(&sysdate,1,%index(&sysdate,&mm)-1);
      %let yy=%substr(&sysdate,%index(&sysdate,&mm)+3);
      %let ml=%str(XX JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC);
      %let mm=%eval(%index(&ml,&mm)/4);
      %let mm=%substr(0&mm,%length(&mm),2);
      %let dd=%substr(0&dd,%length(&dd),2);
      %if       "&datefmt"="YMD" %then %let date=&yy/&mm/&dd;
      %else %if "&datefmt"="DMY" %then %let date=&dd..&mm..19&yy;
      %else                            %let date=&mm/&dd/&yy;
      %end;
   %local jobid;
   %if "&info" = "USERID" %then %do;
       %local userid filen;
       %if "&sysscp"="VMS" %then %do;
         %let userid=%scan(&sysparm,1,%str( ()));
         %let filen=%scan(&sysparm,2,%str(]));
         %let filen=%scan(&filen,1,%str(.));
       %end;
       %else %if "&sysscp"="SUN 4" %then %do;
         %local cnt;
         %let userid=%scan(&sysparm,1,%str(:));
         %let filen=%substr(&sysparm,%eval(%index(&sysparm,%str(:))+1));
         %let cnt=%index(&filen,%str(/));
         %do %while(&cnt);
           %let filen=%substr(&filen,%eval(&cnt+1));
           %let cnt=%index(&filen,%str(/));
         %end;
         %if %substr(&filen,%eval(%length(&filen)-3))=.sas %then
           %let filen=%scan(&filen,1,%str(.));
       %end;
       %let jobid=%str(&userid(&filen));
   %end;
   %else %if "&info" = "PATH" %then %do;
     %if "&sysscp"="VMS" %then %let jobid=%scan(&sysparm,2,%str( ()));
     %else %if "&sysscp"="SUN 4" %then %let jobid=%scan(&sysparm,2,%str(:));
   %end;
   %else %do;
     %if "&sysscp"="VMS" %then %let jobid=&sysparm;
     %else %if "&sysscp"="SUN 4" %then %do;
       %local filen userid;
       %let filen=%scan(&sysparm,2,%str(:));
       %let userid=%scan(&sysparm,1,%str(:));
       %let jobid=%str(&userid(&filen));
     %end;
   %end;
   %let time = %upcase(&time);
   %if %substr(&time,1,1)=Y %then %let time=%str( )&systime;
   %else                          %let time=;

   %local pad;
   %let pad='                                                      ';
   %if %index(&arg,FOOTNOTE) | %index(&arg,TITLE) %then %do;
      &arg &before "&jobid &date&time" &after &pad &pad &pad;
      %end;
   %else %if %index(GRAPHICS,&arg) %then %do;
      %if %length(&font)   =0 %then %let font   =SIMPLEX;
      %if %length(&height) =0 %then %let height =0.5;
      %if %length(&color)  =0 %then %let color  =BLACK;
      %if %length(&move)   =0 %then %let move   =(0.0 IN, 0.01 IN);
      %if %length(&premove)>0 %then
          %let premove=%str(MOVE=&premove ' ') ;
      NOTE &premove MOVE=&move F=&font H=&height  C=&color
           &before "&jobid &date&time" &after;
      %end;
   %else %if %index(NOQUOTE,&arg) %then %do;
      &before &jobid &date&time &after %str( )
      %end;
   %else %if %index(PLATE,&arg) %then %do;
      "&jobid"!!' '!!"&date&time" %str( )
      %end;
   %else %do;
      &arg &before "&jobid &date&time" &after %str( )
      %end;
%endtag:
   %mend jobid;
