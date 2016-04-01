/*
/ PROGRAM NAME:     STACKVAR>SAS
/
/ PROGRAM VERSION:  1.1
/
/ PROGRAM PURPOSE:  Utility to use with PROC REPORT listings that will
/                   take the values of a number of variables and create
/                   a new variable that can be used by REPORT with the FLOW
/                   option.  Examples of stacked variables can be found in the
/                   IDSG document "Reports and General Formatting".
/
/ SAS VERSION:      6.12 (UNIX)
/
/ CREATED BY:       John Henry King
/ DATE:             OCT1997
/
/ INPUT PARAMETERS: NEWVAR=   Names the variable created by the concatination operation.
/
/                   STACK=    List the variable names and optionally the SAS format to
/                             use in the concatination operation.  If a variable name
/                             is followed by a SAS format, a word with a dot(.) in it,
/                             the macro uses that format to PUT the values of the
/                             preceeding variable.  If the variable name is NOT followed
/                             by a SAS format then the value is use unformated.  If a
/                             numeric variable is not formated then SAS will perform
/                             a numeric to character conversion.
/
/                   SPLIT=*   Names the split character to include in the new variable
/                             for explicit splitting.
/
/                   SLASH=/   Names the character to place between the values of the
/                             individual variables.
/
/
/ OUTPUT CREATED:   A SAS variable.
/
/ MACROS CALLED:    None
/
/ EXAMPLE CALL:     %stackvar(newvar = new,
/                             stack  = var1 var2 date9. var3 date9.)
/
/                   This example call would produce the following 3 lines of code:
/
/                   LENGTH NEW $200.;
/
/                   NEW = TRIM(LEFT(VAR1)) ||"/*"|| TRIM(LEFT(PUT(VAR2,DATE9.)))
/                      ||"/*"|| TRIM(LEFT(PUT(VAR3,DATE9.))) ;
/
/                   IF LENGTH(NEW)=200 THEN
/                      PUT "NOTE: Length of new equals 200 the values may be truncated.";
/
/========================================================================================
/ CHANGE LOG:
/
/    MODIFIED BY: Jonathan Fry
/    DATE:        10DEC1998
/    MODID:       JMF001
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 1.1.
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
/=======================================================================================*/

%macro stackvar( newvar = _NEWVAR_,
                 stack  = ,
                 split  = *,
                 slash  = /
                );

/*-------------------------------------------------------------------------/
/ JMF001                                                                   /
/ Display Macro Name and Version Number in LOG                             /
/-------------------------------------------------------------------------*/

   %put ------------------------------------------------------;
   %put NOTE: Macro called: STACKVAR.SAS   Version Number: 1.1;
   %put ------------------------------------------------------;

   %local i j w nw;

   %let j  = 0;
   %let i  = 1;

   %let w  = %scan(&stack,&i,%str( ));
   %let nw = %scan(&stack,&i+1,%str( ));

   %do %while(%bquote(&w)^=);

/*-------------------------------------------------------------------------/
/ If current word is a name with no dot assume a sas name and process      /
/-------------------------------------------------------------------------*/

      %if %index(&w,.)=0 %then %do;
         %let j = %eval(&j +1);
         %local v&j;

/*-------------------------------------------------------------------------/
/ If the next word is a format (has a dot) them process variable name      /
/ with format                                                              /
/-------------------------------------------------------------------------*/

         %if %index(&nw,.)>0 %then %do;
            %let v&j = trim(left(put(&w,&nw)));
            %end;

/*-------------------------------------------------------------------------/
/ Otherwise process variable name without format                           /
/-------------------------------------------------------------------------*/

         %else %do;
            %let v&j = trim(left(&w));
            %end;

         %end;

      %let i  = %eval(&i + 1);
      %let w  = %scan(&stack,&i,%str( ));
      %let nw = %scan(&stack,&i+1,%str( ));

      %end;

   %if &j > 0 %then %do;

      length &newvar $200;

      &newvar = &&v1

      %do i = 2 %to &j;
         ||"&slash&split"|| &&v&i
         %end;
      ;

      if length(&newvar)=200 then
         put "W A R N I N G: Length of &newvar equals 200 the values may be truncated.";

      %end;

   %mend stackvar;
