/*
/ Program name: setsys.sas
/
/ Program version: 4.3
/
/ Program purpose: This is the macro called in the AUTOEXEC.SAS.
/
/    1) Uses SYSGET to make global macro variables from various
/       unix environment variables.
/
/    2) Determine the pathname of the program that is being executed.
/
/    3) Issue LIBNAME and FILENAME statements for system level data libraries
/       and catalogs.
/
/    4) Print a little information about what was done.
/
/
/
/ SAS version: 6.12
/
/ Created by: John Henry King
/
/ Date: 12MAR1998
/
/ Input parameters:
/   utildata = /usr/local/medstat/sas/data,
/              Gives the directory name from utility data.  This includes
/              data from gold AEs grouping etc. and data used by RANKSUM and SIGNRNK
/              for table lookup.
/
/   utilfmt  = /usr/local/medstat/sas/formats,
/              Gives the directory for GOLD format library.
/
/   utilgdev = /usr/local/medstat/sas/gdevice,
/              Gives the directory for SAS/GRAPH device drivers.
/
/   gdevnum  = 0,
/              Gives number for GDEVICE libname.
/
/   utiltmpl = /usr/local/medstat/sas/template,
/              Gives directory of SAS/GRAPH template catalog.
/
/   utilscl  = /usr/local/medstat/sas/scl,
/              Gives directory of SCL catalog.  These SCL programs are used by
/              macros GETOPTS and BWGETTF.
/
/   utiliml  = /usr/local/medstat/sas/iml,
/              Gives directory of SAS/IML catalog.  Currently this directory is empty.
/
/   debug    = 0
/              Debug switch.
/
/
/ Output created: The macro creates a number of global macro variables and issues
/    libname and filename statements.
/
/
/ Macros called: NONE:
/
/ Example call: %setsys()
/
/------------------------------------------------------------------------------
/
/ Change log:
/
/------------------------------------------------------------------------------
/ MODIFIED BY: John Henry King
/ DATE:        09DEC1998
/ MODID:       JHK001
/ DESCRIPTION: Added code to get current directory when running interactive,
/              display manager, SAS.
/------------------------------------------------------------------------------
/ MODIFIED BY: Jonathan Fry
/ DATE:        10DEC1998
/ MODID:       JMF002
/ DESCRIPTION: Tested for Y2K compliance.
/              Add %PUT statement for Macro Name and Version Number.
/              Change Version Number to 4.1.
/ ------------------------------------------------------------------------------
/ MODIFIED BY: John Henry King
/ DATE:        24AUG1999
/ MODID:       JHK003
/ DESCRIPTION: Added code to create Project macro variable to be used to call
/              the project init.  For example the users would like to be able
/              to write %&proj(pop=something).  This will make programs easier
/              to copy from one project to another.  Changed version number to
/              4.2   
/              Adding ycutoff parameter to change the SAS yearcutoff
/              system option and also display a note in the SASLOG that the
/              yearcutoff has been changed.  Also setting SAS MSGLEVEL=I system
/              option.
/
/
/ ------------------------------------------------------------------------------
/ MODIFIED BY: John Henry King
/ DATE:        25OCT1999
/ MODID:       JHK004
/ DESCRIPTION: Remove msglevel option and add two filerefs for graphics.
/              UTILPS(postscript) UTILCGM (Computer graphics metafile)
/              Changed version number to 4.3.
 
/-------------------------------------------------------------------------------
/==========================================================================================*/


%macro
   setsys
      (
       utildata = /usr/local/medstat/sas/data,
       utilfmt  = /usr/local/medstat/sas/formats,
       utilgdev = /usr/local/medstat/sas/gdevice,
       gdevnum  = 0,
       utiltmpl = /usr/local/medstat/sas/template,
       utilscl  = /usr/local/medstat/sas/scl,
       utiliml  = /usr/local/medstat/sas/iml,
       ycutoff  = 1950,
       msglevel = I,
       debug    = 0
      )
      /*==storeops==*/
   ;

   /*
   / JMF002
   / Display Macro Name and Version Number in LOG
   /--------------------------------------------------------------------*/

   %put ----------------------------------------------------;
   %put NOTE: Macro called: SETSYS.SAS   Version Number: 4.3;
   %put ----------------------------------------------------;



   /*
   / Use PRINTTO to suppress messages to the SAS log
   /--------------------------------------------------------------------*/
   %if ^&debug %then %do;
      filename dummy dummy;
      proc printto log=dummy;
         run;
      %end;
                               
   /*                          
   / JHK003
   / Set yearcutoff and msglevel
   /----------------------------------------------*/

   /*                          
   / JHK004
   / Remove msglevel
   /----------------------------------------------*/
    
   options yearcutoff=&ycutoff;
   

   /*
   / define global and local macro variables
   /----------------------------------------------------------------------*/

   %global _DOCMAN_  projdir sasin logname _proj_ _prot_ _fname_;
   %local rc output proj temp sassysin delm;


   /*
   / Define macro variables that come from system environment variables.
   / OUTPUT and PROJ are usually blank until set in a MAKE file.
   /----------------------------------------------------------------------*/

   %if %bquote(&sysscp)=%str(SUN 4) %then %do;
      %let projdir = %sysget(PD);
      %let output  = %sysget(OUTPUT);
      %let proj    = %sysget(PROJ);
      %let logname = %sysget(LOGNAME);
      %let delm    = /;
      %end;

   %else %if %bquote(&sysscp)=%str(WIN) %then %do;
      %let projdir = %sysget(PD);
      %let output  = %sysget(OUTPUT);
      %let proj    = %sysget(PROJ);
      %let logname = %sysget(USERNAME);
      %let delm    = \;
      %end;
             
   
             
             
   /*
   / Set DOCMAN switch if output directory, or proj directory is specified
   / The DOCMAN switch is used by MACPAGE to control various actions
   / associated with the publishing system.
   /-----------------------------------------------------------------------*/
   %if %bquote(&output)= | %bquote(&proj)=
      %then %let _docman_ = 0;
      %else %let _docman_ = 1;

   /*
   / Get the sas program name that is currently being executed.
   / I am trying to keep this within SAS, i.e. no unix pipes etc.
   /
   / The value of SYSIN may not always be the fully qualified name.
   / Therefore I will issue a FILEREF using the value of SYSIN and then
   / use the PATHNAME function to return the full path name.
   /-----------------------------------------------------------------------*/

   %let sassysin = %sysfunc(getoption(sysin));

   %if %bquote(&sassysin)= %then %do;
      /*
      / JHK001
      / Changed to pick up current directory when running interactive
      /---------------------------------------------------------------*/
      filename autotemp './';
      %let sasin = %sysfunc(pathname(autotemp))&delm.INTERACTIVE;
      filename autotemp clear;
      %end;
   %else %do;
      filename autotemp "&sassysin";
      %let sasin = %sysfunc(pathname(autotemp));
      filename autotemp clear;
      %end;

   /*
   / SYSPARM is used by MACPAGE for the JOBID information.
   /-----------------------------------------------------------------------*/
   %let sysparm  = &logname:&sasin;

   /*
   / Get just the filename part of SASIN to use in the FILENAME statement below.
   /-------------------------------------------------------------------------------*/
   %let fn = %sysfunc(reverse(%substr(%sysfunc(reverse(&sasin)),1+%index(%sysfunc(reverse(&sasin)),.)) ));

   /*
   / JHK003
   / 
   / Remove directory qualifying information from the value of FN and assign it to 
   / global macro variable _fname_.
   /---------------------------------------------------------------------------------*/
   
   %let _fname_ = %sysfunc(reverse(%scan(%sysfunc(reverse(&fn)),1,&delm)));
   
   
   /*
   / JHK003
   /
   / Extract the project name from the program name and assign to global
   / macro variable _proj_.
   /-------------------------------------------------------------------------*/   
   %if %index(%qupcase(&sasin),%qupcase(&projdir)) %then %do;   
      %local cl;
      /*
      / Locate colon if running on a PC
      /-------------------------------------*/
      %let cl = %index(&sasin,:);
      
      /*
      / Scan out the first word following PROJDIR and that should
      / be the PROJECT.  Assign to _proj_.
      /-------------------------------------------------------------*/
      %let _proj_ = %scan(%substr(&sasin,1+&cl+%length(&projdir)),1,&delm);
             

      /*
      / Search for the protocol in the program name.
      /---------------------------------------------------*/

      %if %index(%qupcase(&sasin),&delm.USERS&delm.) 
         %then %let _prot_ = %sysfunc(reverse(%scan(%sysfunc(reverse(&sasin)),2,%str(&delm.))));
      %else %if %index(%qupcase(&sasin),&delm.PROGRAMS&delm.) 
         %then %let _prot_ = %sysfunc(reverse(%scan(%sysfunc(reverse(&sasin)),3,%str(&delm.))));
      %else %let _prot_=UNKNOWN;
      %end;
   %else %do;
      %let _proj_ = UNKNOWN;
      %let _prot_ = UNKNOWN;
      %end;
                    
   /*
   / Issue system level libnames
   /-------------------------------------------------------------------------*/
   %local rc1 rc2 rc3 rc4 rc5 rc6 msg1 msg2 msg3 msg4 msg5 msg6 
          utildata utilfmt utilscl utiliml utilgdev utiltmpl;
   %let rc1      = %sysfunc(libname(utildata,&utildata,,access=readonly));
   %let msg1     = %sysfunc(sysmsg());
   %let utildata = %sysfunc(pathname(utildata));

   %let rc2      = %sysfunc(libname(library,&utilfmt,,access=readonly));
   %let msg2     = %sysfunc(sysmsg());
   %let utilfmt  = %sysfunc(pathname(library));

   %let rc3      = %sysfunc(libname(utilscl,&utilscl,,access=readonly));
   %let msg3     = %sysfunc(sysmsg());
   %let utilscl  = %sysfunc(pathname(utilscl));

   %let rc4      = %sysfunc(libname(utiliml,&utiliml,,access=readonly));
   %let msg4     = %sysfunc(sysmsg());
   %let utiliml  = %sysfunc(pathname(utiliml));

   %let rc5      = %sysfunc(libname(gdevice&gdevnum,&utilgdev,,access=readonly));
   %let msg5     = %sysfunc(sysmsg());
   %let utilgdev = %sysfunc(pathname(gdevice&gdevnum));

   %let rc6      = %sysfunc(libname(utiltmpl,&utiltmpl,,access=readonly));
   %let msg6     = %sysfunc(sysmsg());
   %let utiltmpl = %sysfunc(pathname(utiltmpl));



   /*
   / Issue filename for UTILGSF.
   / If a fn.gsf file exists delete it.  We want to start the program with
   / no GSF from the last time it was executed.
   /--------------------------------------------------------------------------*/
   /*
   / JHK004
   / Add two new graphics file references for post script and cmg.
   /--------------------------------------------------------------------------*/
   filename utilgsf        "&fn..gsf";
   filename utilps         "&fn..ps";
   filename utilcgm        "&fn..cgm";
   %if %sysfunc(fexist(utilgsf)) %then %let rc = %sysfunc(fdelete(utilgsf));
   %if %sysfunc(fexist(utilps))  %then %let rc = %sysfunc(fdelete(utilps));
   %if %sysfunc(fexist(utilcgm)) %then %let rc = %sysfunc(fdelete(utilcgm));

   %if ^&debug %then %do;
      proc printto;
         run;
      filename dummy clear;
      %end;

   %put NOTE: ----------------------------------------------------------------------------------;
   %put NOTE: The following global macro variables have been created or altered:;
   %put NOTE:   PROJDIR  = *&projdir*;
   %put NOTE:   _DOCMAN_ = *&_docman_*;
   %put NOTE:   SYSPARM  = *&sysparm*;
   %put NOTE:   SASIN    = *&sasin*;
   %put NOTE:   LOGNAME  = *&logname*;
   %put NOTE:   _PROJ_   = *&_proj_*;  
   %if %quote(&_proj_)=UNKNOWN %then %do;
      %put NOTE: _PROJ_ was set to UNKNOWN because the project directory was not part of SYSIN.;
      %end;
   %put NOTE:   _PROT_   = *&_prot_*;  
   %if %quote(&_prot_)=UNKNOWN %then %do;
      %put NOTE: _PROT_ was set to UNKNOWN because the project directory was not part of SYSIN,;
      %put NOTE: or the program was not being run from the /programs or /users directory as expected.;
      %end;
      
   %put NOTE:   _FNAME_  = *&_fname_*;
   %put NOTE:;                                   
   
   %put NOTE: SAS System option YEARCUTOFF has been set to %sysfunc(getoption(yearcutoff)).;
   
   %put NOTE:;                                   
   %put NOTE: The following LIBREFS have been created.;
   %if &rc1=0
      %then %put NOTE:   UTILDATA = &utildata (dat_dict dis_dict grpvw ingvw invcnty invest stdunits);
      %else %put &msg1;

   %if &rc2=0
      %then %put NOTE:   LIBRARY = &utilfmt (Gold FORMATS);
      %else %put &msg2;

   %if &rc3=0
      %then %put NOTE:   UTILSCL  = &utilscl (SCL Catalogs sclutl and topslog);
      %else %put &msg3;


   %if &rc4=0
      %then %put NOTE:   UTILIML  = &utiliml (IML Catalog currently this catalog is empty);
      %else %put &msg4;

   %if &rc5=0
      %then %put NOTE:   GDEVICE&gdevnum = &utilgdev (SAS/GRAPH device driver catalog);
      %else %put &msg5;

   %if &rc6=0
      %then %put NOTE:   UTILTMPL = &utiltmpl (SAS/GRAPH template catalog);
      %else %put &msg6;

   %put NOTE: ;
   %put NOTE: The following FILEREFs, for use with SAS/GRAPH, have been created.;
   %put NOTE:   UTILGSF  = &fn..gsf (Graphics stream file);
   %put NOTE:   UTILPS   = &fn..ps  (Postscript);
   %put NOTE:   UTILCGM  = &fn..cgm (Computer graphics metafile);
   %put NOTE: ----------------------------------------------------------------------------------;


   %mend;
