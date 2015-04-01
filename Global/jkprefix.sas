/*
/ PROGRAM NAME: jkprefix.sas
/
/ PROGRAM VERSION: 1.0
/
/ PROGRAM PURPOSE: Parse the words in a macro variable and add a specified
/   prefix string the each word.
/
/ SAS VERSION: 6.12
/
/ CREATED BY: John Henry King
/
/ DATE: 1992 perhaps.
/
/ INPUT PARAMETERS:
/   string    The string to parse and prefix.
/   
/   prefix    The character to prefix to each word.
/
/   delm =    Specifies the word delimiter.
/
/ OUTPUT CREATED: Returns the new string.
/
/ MACROS CALLED: none
/
/ EXAMPLE CALL: 
/
/   %let new = %prefix(A B C D E, PRE_);
/    
/   Assigns NEW the value: PRE_A PRE_B PRE_C PRE_D PRE_E
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

%macro jkprefix(string,prefix,delm=%str( ));                     
   %local count word newlist;
   %if "&delm"="" %then %let delm = %str( );
   %let count = 1;                                                     
   %let word  = %scan(&string,&count,&delm);                           
   %do %while("&word"^="");                                        
      %let newlist = &newlist &prefix.&word;                           
      %let count   = %eval(&count + 1);                                
      %let word    = %scan(&string,&count,&delm);                      
      %end;                                                            
   &newlist                                                            
   %mend jkprefix;                                                       
