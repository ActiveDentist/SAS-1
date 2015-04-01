/*
/ Program Name:     INFIX.SAS
/
/ Program Version:  2.1
/
/ Program purpose:  Use this macro to generate a new list from LIST seperated by
/                   OPERATORs.  The new list may be quoted with the QUOTE option.
/
/                   Ex.
/                       %INFIX(list=A B C,operator=%str(,),quote=YES)
/
/                       Produces: "A","B","C"
/
/ SAS Version:      6.12
/
/ Created By:
/ Date:
/
/ Input Parameters: LIST     - A character string containing a string of words to be
/                              processed, separated by a delimiter (default = a space).
/                   OPERATOR - An optional character which is inserted between each word
/                              in the output string.
/                   QUOTE    - When this option is set to YES, QUOTE or 1, the macro will
/                              place quotes around each word in the output string.
/                   DELM     - This defines the character to be used as a delimiter in
/                              the input string (default is a space character).
/
/ Output Created:   The words parsed from the input character string and suitably
/                   processed according to the options described above are output to
/                   macro variable OUTPUT.
/
/ Macros Called:    None.
/
/ Example Call:     %let var1=%quote(software,product,services);
/                   %let var2=%infix(list=&var1,delm=%str(,));
/
/==========================================================================================
/ Change Log:
/
/    MODIFIED BY: Jonathan Fry
/    DATE:        09DEC1998
/    MODID:       JMF001
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 2.1.
/    ------------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX002
/    DESCRIPTION:
/    ------------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX003
/    DESCRIPTION:
/    ------------------------------------------------------------------------
/=========================================================================================*/

%macro infix(list=,operator=,quote=NO,delm=%str( ));

/*--------------------------------------------------------------------------/
/ JMF001                                                                    /
/ Display Macro Name and Version Number in LOG                              /
/--------------------------------------------------------------------------*/

   %put ------------------------------------------------------;
   %put NOTE: Macro called: INFIX.SAS      Version Number: 2.1;
   %put ------------------------------------------------------;

   %if "&list"~="" %then %do;
      %let quote = %upcase(&quote);
      %local i w w0 output;
      %let i = 1;
      %let w = %scan(&list,&i,&delm);
      %do %while("&w"~="");
         %local w&i;
         %let w&i = &w;
         %let i = %eval(&i+1);
         %let w = %scan(&list,&i,&delm);
         %end;
      %let w0=%eval(&i-1);
      %do i = 1 %to &w0-1;
         %if %index(QUOTE YES 1,&quote)
            %then %let output = &output."&&w&i"&operator;
            %else %let output = &output.&&w&i.&operator;
         %end;
      %if %index(QUOTE YES 1,&quote)
         %then %let output = &output."&&w&w0";
         %else %let output = &output.&&w&w0;
      &output%str( )
   %end;
%mend infix;
