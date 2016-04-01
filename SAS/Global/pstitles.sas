/**************************************************************************
/
/ PROGRAM NAME: pstitles.sas
/
/ PROGRAM VERSION: 0.99 [validation not complete]
/
/ PROGRAM PURPOSE: 
/
/ This SAS macro uses GOPTIONS GPROLOGUE = to insert a comment into the first line
/ of a PostScript output file containing donelist attribute information.
/
/ Attributes included are: document type; document sequence number; and document 
/ title.
/
/ Default behaviour is to extract this information from the values that 
/ were set by TITLE statements and current when the macro is called.  
/
/ A parameter switch is available to direct the macro to use the values set by
/ the "Titles System"
/
/ The macro should be called after the file name and titles have been defined, but
/ before the call to the SAS/Graph Procedure.
/
/ SAS VERSION: 6.12 (UNIX)
/
/ CREATED BY: Jim Comer
/
/ DATE: APR1999.
/
/ INPUT PARAMETERS: 
/   useMDS=FALSE - get attribute information from SAS System values (DEFAULT)
/   useMDS=TRUE  - get attribute information stored by the TITLES SYSTEM
/
/ usage:   %pstitles;
/          %pstitles(usemds=false);
/          %pstitles(usemds=true);
/
************************************************************************/

%macro pstitles(useMDS="FALSE");

%if %upcase(&useMDS)=TRUE %then %do;

   %* when using the titles system,              ;
   %* recode 'type' value                        ;
   %* 'num' and 'toc' are passed along as found  ;

   %if &type = F %then %let type = F;  %else
   %if &type = T %then %let type = X;  %else
   %if &type = S %then %let type = XS; %else
   %if &type = X %then %let type = Y;  %else
   %if &type = A %then %let type = Z;  %else
   %if &type = Y %then %let type = Z3; %else
   %if &type = C %then %let type = Z4;

   goptions gprolog = "%nrstr(%! )<!&type &num &toc!>";

   %end;

%else %do;

%* When the titles system is not used, the information can be extracted from SAS;

   %let tval1 = ;
   %let tval2 = ;
   %let tval3 = ;
   %let tval4 = ;
   %let tval5 = ;
   %let tval6 = ;
   %let tval7 = ;
   %let tval8 = ;
   %let tval9 = ;
   %let tval10 = ;
   
   data _null_; set sashelp.vtitle(where=(type="T")); by number;
   
   length word1 word2 word3 docnum $ 10;
   retain found nn doctype docnum;
   
   if _n_ = 1 then do;
      found = 0;
      doctype = '  ';
      end;
   
   word1 = upcase(scan(text,1));
   word2 = upcase(scan(text,2));
   word3 = upcase(scan(text,3));
   
   if found = 0 then do;
   
      if word1 = "FIGURE" then do;
         doctype = "F";
         docnum = word2;
         end;
   
      else if word1 = "TABLE" then do;
         doctype = "X";
         docnum = word2;
         end;
   
      else if word1 = "SUPPORTING" and word2 = "TABLE" then do;
         doctype = "XS";
         docnum = word3;
         end;
   
      else if word1 = "LISTING" then do;
         doctype = "Y";
         docnum  = word2;
         end;
   
      else if word1 = "DATA" and word2 = "LISTING" then do;
         doctype = "Z3";
         docnum = word3;
         end;
   
      else if word1 = "TABULATION" then do;
         doctype = "Z4";
         docnum = word2;
         end;
   
      else if word1 = "APPENDIX" then do;
         doctype = "Z";
         docnum = word2;
         end;
      end;
   
   if found = 0 and doctype ne " " then do;
      found = 1;
      nn = 0;
      end;
   
   if found then do;
      nn = nn + 1;
      call symput('tval' || left(nn), left(trim(text)));
      end;
   
   if last.number then do;
      call symput('type',left(trim(doctype)));
      call symput('num',left(trim(docnum)));
   
      end;
   run;

   %put _all_;
   %* TITLE information should be in TVAL2-TVAL10;
   goptions gprolog = 
"%nrstr(%! )<! &type &num &tval2 &tval3 &tval4 &tval5 &tval6 &tval7 &tval8 &tval9 &tval10 !>";
   %end;

%mend;

***********************************************************************;
