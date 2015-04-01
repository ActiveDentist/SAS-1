/*
/ Program Name: SASAUTOS.SAS
/
/ Program Version: 4.1
/
/ Program purpose: Include a standard SASAUTOS statment in an OPTIONS statement
/
/ SAS Version: 6.12
/
/ Created By: Carl Arneson
/ Date:       6 Feb 1995
/
/ Input Parameters: PROJ = MDP name (GOLD studies)
/                          Project ID number (ex-Wellcome studies)
/
/ Output Created:
/
/ Macros Called: %datatyp (provided by SAS)
/
/ Example Call:  %sasautos(proj=S3A);
/
/============================================================================================
/ Change Log
/
/    MODIFIED BY: SR Austin
/    DATE:        19SEP95
/    MODID:       001
/    DESCRIPTION: If proj num starts with a number, put P in front, otherwise assume
/                 its a GLAXO-type name and take as given.
/    --------------------------------------------------------------------------------
/    MODIFIED BY: S Mallett
/    DATE:        18MAR97
/    MODID:       002
/    DESCRIPTION: Pathnames changed in accordance with the subdirectory
/                 structure on UNIX (UKWSV17) platform.
/    --------------------------------------------------------------------------------
/    MODIFIED BY: S Mallett
/    DATE:        11APR97
/    MODID:       003
/    DESCRIPTION: Pathnames changed in accordance with the revised subdirectory
/                 structures on UNIX (UKWSV17/USSUN9A) platforms.
/    --------------------------------------------------------------------------------
/    MODIFIED BY: John Henry King
/    DATE:        18Janurary1998
/    MODID:       JHK004
/    DESCRIPTION: Parameter to add the PRE-IDSG macro to the search order.
/    --------------------------------------------------------------------------------
/    MODIFIED BY: Jonathan Fry
/    DATE:        10DEC1998
/    MODID:       JMF005
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 4.1.
/    --------------------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX006
/    DESCRIPTION:
/    --------------------------------------------------------------------------------
/=============================================================================================*/

%macro SASAUTOS (proj = ,
                 use  = IDSG,
                );

   /*
   / JMF005
   / Display Macro Name and Version Number in LOG
   /--------------------------------------------------------------*/

   %put ------------------------------------------------------;
   %put NOTE: Macro called: SASAUTOS.SAS   Version Number: 4.1;
   %put ------------------------------------------------------;


sasautos=(

%let projdir = %sysget(PD);
%let use     = %upcase(&use);

%* Docman reference not needed at present;
%* %if &_docman_ = 1 %then %do ;
%*            "/export/opt/wellcome/csd/sas/macros/docman",
%* %end ;

%* Users'' personal macros;
"~/sas/macros",

%* Project area macros;
%if %length(&proj)>0 %then %do ;
  %if %datatyp(%substr(&proj,1,1))=NUMERIC %then %do;
    "&projdir/p&proj/utility/macros",
  %end;
  %else %do;
    "&projdir/&proj/utility/macros",
  %end;
%end ;

   /*
   / JHK004
   / Adding %IF for USE= parmater.
   /--------------------------------------------------------------*/

   %if (%index(PREIDSG PRE_IDSG PRE-IDSG PRE IDSG,%bquote(&use)) & %length(%bquote(&use))>=7) %then %do;
      "/usr/local/medstat/sas/macros/pre_idsg",
      %end;


%* Departmental macros;
    "/usr/local/medstat/sas/macros",

%* SAS supplied macros;
    "!SASROOT/sasautos")

%mend SASAUTOS;
