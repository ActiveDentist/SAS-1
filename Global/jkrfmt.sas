/*
/ PROGRAM NAME: jkrfmt.sas
/
/ PROGRAM VERSION: 1.0
/
/ PROGRAM PURPOSE: Used by standard macros to process the ROWSFMT parameter
/                  in DTAB.
/  
/
/ SAS VERSION: 6.12 (UNIX)
/
/ CREATED BY: John Henry King
/ DATE: OCT1997
/
/ INPUT PARAMETERS:
/
/   rowsfmt=        The list of words to process.
/ 
/   _name_=_vname_  The name of _VNAME_ special variable from SIMSTAT.
/ 
/   _fmt_=_vfmt_    The name of the variable created by this macro.
/
/   delm=%str( -)   The delimiter list for the scan function.
/
/
/ OUTPUT CREATED:
/
/   A select statement for processing the ROWSFMT statement in DTAB.
/
/ MACROS CALLED: none
/
/ EXAMPLE CALL:
/
/   %jkrfmt(rowsfmt=&rowsfmt,_name_=_VNAME_,_fmt_=_vfmt_);
/
/==============================================================================
/ CHANGE LOG:
/
/ MODIFIED BY:
/ DATE:
/ MODID: JHK001
/ DESCRIPTION:
/------------------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID: JHK002
/ DESCRIPTION:
/------------------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID: JHK003
/ DESCRIPTION:
/============================================================================*/

%macro jkrfmt(rowsfmt = ,
               _name_ = _VNAME_,
               _fmt_  = _VFMT_,
                delm  = %str( ));


   %let rowsfmt = %upcase(&rowsfmt);

   %local i j w c lroot lastword;

   %let lroot = _X_;

   /*                                                                                  
   / Parse the format list part of STATSFMT                                            
   /------------------------------------------*/                                      
   %let j = 1;                                                                         
   %let i = 1;                                                                         
   %let w = %scan(&rowsfmt,&i,&delm);                                                     
   %let lastword = ;                                                                   

   %do %while(%bquote(&w)^=);                                                             
      %if %index("&w",.) & ^%index("&lastword",.) %then %do;                           
         %local &lroot.F&j;                                                            
         %let &lroot.F&j = &w;                                                         
         %let j = %eval(&j + 1);                                                       
         %end;                                                                         
      %else %if ^%index("&w",.) %then %do;                                             
         %local &lroot.v&j;                                                            
         %if %bquote(&&&lroot.v&j) = 
            %then %let c = ;
            %else %let c = ,;
         %let &lroot.V&j = &&&lroot.v&j &c "&w";                                            
         %end;                                                                         
      %let lastword = &w;                                                              
      %let i        = %eval(&i + 1);                                                   
      %let w        = %scan(&rowsfmt,&i,%str( ));                                           
      %end;                                                                            

   %local &lroot.V0;                                                                   
   %let   &lroot.V0 = %eval(&j -1);                                                    
   

   length &_fmt_ $20.;
   
   select(_vname_);
      when('0');
                                                                                   
      %do i = 1 %to &&&lroot.v0;                                                          
         
         when(&&&lroot.v&i) &_fmt_ = "&&&lroot.f&i";
         
         %end;
                                                                     
      otherwise &_fmt_ = '$'||trim(_vname_)||'.';
      end;

   %mend jkrfmt;
