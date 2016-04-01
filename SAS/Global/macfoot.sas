/*
/ Program name: macfoot.sas
/
/ Program version: 2.1
/
/ Program purpose: generates footnotes, adds special char for macpage macro.
/
/ SAS version: 6.12 TS020
/
/ Created by: Randall Austin
/ Date:       7/9/94
/
/ Input parameters: foot1-foot10 - footnotes
/                   target       - 'FF'x macpage trigger
/
/ Output created:
/
/ Macros called:
/
/ Example call:
/
/                   %macfoot(footnote1,footnote2);
/
/================================================================================
/ Change log:
/
/    MODIFIED BY: SRA
/    DATE:        15SEP94
/    MODID:
/    DESCRIPTION: If footnote does not have quotes, puts them in.
/    ------------------------------------------------------------------
/    MODIFIED BY: SRA
/    DATE:        13DEC94
/    MODID:
/    DESCRIPTION: Fixed bug relating to null footnotes.
/    ------------------------------------------------------------------
/    MODIFIED BY: SRA
/    DATE:        13FEB95
/    MODID:
/    DESCRIPTION: Fixed another strange macro.
/    ------------------------------------------------------------------
/    MODIFIED BY: Julian Heritage
/    DATE:        24.02.97
/    MODID:
/    DESCRIPTION: Standard header added
/    ------------------------------------------------------------------
/    MODIFIED BY: Jonathan Fry
/    DATE:        09DEC1998
/    MODID:       JMF001
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 2.1.
/    ------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX002
/    DESCRIPTION:
/    ------------------------------------------------------------------
/=================================================================================*/

%macro macfoot(foot1,foot2,foot3,foot4,foot5,foot6,foot7,foot8,foot9,foot10,
               target='FF'x);

     /*
     / JMF001
     / Display Macro Name and Version Number in LOG
     /---------------------------------------------------------*/

     %put -----------------------------------------------------;
     %put NOTE: Macro called: MACFOOT.SAS   Version Number: 2.1;
     %put -----------------------------------------------------;


%local z __x pad;
%let pad='                                                                ';
%let z=1;
%* Count the nonblank footnotes;
%do __x=1 %to 10;
%if %length(&&foot&__x.)=0 %then %let z=&z;%else %let z=&__x;
%end;
%do q=1 %to %eval(&z-1);
%if %index(&&foot&q,%str(%")) ne 1 and %index(&&foot&q,%str(%')) ne 1
%then %let foot&q="&&foot&q"; %if &&foot&q="" %then %let foot&q=;
footnote&q &&foot&q &pad &pad;
%end;
%if %index(&&foot&z,%str(%")) ne 1 and %index(&&foot&z,%str(%')) ne 1
%then %let foot&z="&&foot&z"; %if &&foot&z="" %then %let foot&z=;
footnote&z &&foot&z. &target. &pad &pad ;
%mend macfoot;
