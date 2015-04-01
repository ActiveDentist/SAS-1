/*
/ PROGRAM NAME: jkhppcl.sas
/
/ PROGRAM VERSION: 1.0
/
/ PROGRAM PURPOSE: HPPCL printer driver for SAS.
/
/ SAS VERSION: 6.12
/
/ CREATED BY: Jim Comer.
/
/ DATE: 1992 perhaps.
/
/ INPUT PARAMETERS:
/
/   cpi     = characters per inch
/   lpi     = lines per inch
/   margins = margin definition
/   layout  = page orientation LANDSCAPE or PORTRAITE
/   mode    = used to turn off macro variables for testing purposes.
/
/ Jim wrote paper documention for the that may still be available.
/ 
/ OUTPUT CREATED: Global macro variables.
/
/    FORMCHAR HOME BS ULON ULOFF ITALIC UPRIGHT NOBOLD BOLD
/    SUBON SUBOFF SUPON SUPOFF SETUP XLPI
/
/ MACROS CALLED: NONE
/
/ EXAMPLE CALL:
/
/   %jkhppcl(cpi=12,lpi=6,layout=portrait)
/
/==============================================================================
/ CHANGE LOG:
/
/ MODIFIED BY: John Henry King
/ DATE: 1992
/ MODID: 
/ DESCRIPTION: Changed the name and copied to standard macro library for use
/   with standard macros.
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

%MACRO JKHPPCL(PAGEDEF =,
                   CPI =,
                   LPI =,
               MARGINS =,
                LAYOUT =,
                  MODE =);

   %GLOBAL FORMCHAR HOME BS ULON ULOFF ITALIC UPRIGHT NOBOLD BOLD
           SUBON SUBOFF SUPON SUPOFF SETUP XLPI;

   /*
   / establish default values 
   /----------------------------------*/

   %LET NCPI   = 12;
   %LET NLPI   = 6;
   %LET CMAR   = A;
   %LET ORIENT = PORTRAIT;

   /*
   / parse pagedef specification to get lpi, margins and layout 
   /---------------------------------------------------------------*/

   %IF %LENGTH(&PAGEDEF) > 0 %THEN %DO;
      %LET PAGEDEF = %UPCASE(&PAGEDEF);

      %LET CHEK1   = %SUBSTR(&PAGEDEF,1,1);
      %IF       &CHEK1 = X OR &CHEK1 = Y %THEN %LET CMAR = B;
      %ELSE %IF &CHEK1 = Z               %THEN %LET CMAR = C;

      %LET CHEK1 = %SUBSTR(&PAGEDEF,2,1);
      %IF       &CHEK1 = P %THEN %LET ORIENT = PORTRAIT;
      %ELSE %IF &CHEK1 = L %THEN %LET ORIENT = LANDSCAPE;

      %LET TLPI = %SUBSTR(&PAGEDEF,4,2);
      %IF &TLPI = 6 OR &TLPI = 8 OR &TLPI = 9 OR &TLPI = 10
         %THEN %LET NLPI = &TLPI;

      %END;

   %IF %LENGTH(&CPI) > 0 %THEN %DO;
      %IF &CPI = 10 OR &CPI = 12 OR &CPI = 17 %THEN %LET NCPI = &CPI;
      %ELSE %PUT INVALID CPI SPECIFICATION - USING DEFAULT VALUES;
      %END;

   %IF %LENGTH(&LPI) > 0 %THEN %DO;
      %IF &LPI = 6 OR &LPI=8 OR &LPI=9 OR &LPI=10 %THEN %LET NLPI = &LPI;
      %ELSE %PUT INVALID LPI SPECIFICATION - USING DEFAULT VALUES;
      %END;

   %IF %LENGTH(&MARGINS) > 0 %THEN %DO;
      %LET MARGINS = %UPCASE(&MARGINS);
      %IF &MARGINS = A OR &MARGINS = B OR &MARGINS = C OR &MARGINS = D 
         %THEN %LET CMAR = &MARGINS;
      %ELSE %PUT INVALID MARGINS SPECIFICATION - USING DEFAULT VALUES;
      %END;

   %IF %LENGTH(&LAYOUT)  > 0 %THEN %DO;
      %LET LAYOUT = %UPCASE(&LAYOUT);
      %IF &LAYOUT = LANDSCAPE OR &LAYOUT = PORTRAIT 
         %THEN %LET ORIENT = &LAYOUT;
      %ELSE %PUT INVALID LAYOUT SPECIFICATION - USING DEFAULT VALUES;
      %END;

   %LET FORMCHAR='B3C4DAC2BFC3C5B4C0C1D9BACD7CC42F5C1B1A01'x;
   %LET BS      = %STR('1B26'x 'a-1C');
   %LET ULON    = %STR('1B26'x 'dD');
   %LET ULOFF   = %STR('1B26'x 'd@');
   %LET ITALIC  = %STR('1B'x '(s1S' '1B'x ')s1S');
   %LET UPRIGHT = %STR('1B'x '(s0S' '1B'x ')s0S');
   %LET NOBOLD  = %STR('1B'x '(s0B' '1B'x ')s0B');
   %LET BOLD    = %STR('1B'x '(s3B' '1B'x ')s3B');

   %IF       &NLPI =  6 %THEN %LET XLPI = %STR('1B26'x 'l8C');
   %ELSE %IF &NLPI =  8 %THEN %LET XLPI = %STR('1B26'x 'l6C');
   %ELSE %IF &NLPI = 10 %THEN %LET XLPI = %STR('1B26'x 'l5C');  * ACTUALLY 9.6 LPI ;

   %LET SUPON  = %STR('0E1B2A'x 'p' '2D'x '15Y');
   %LET SUBON  = %STR('0E1B2A'x 'p' '2B'x '15Y');
   %LET SUPOFF = %STR('1B2A'x 'p' '2B'x '15Y' '0F'x);
   %LET SUBOFF = %STR('1B2A'x 'p' '2D'x '15Y' '0F'x);

   %IF       &ORIENT = PORTRAIT  %THEN %LET XLAYOUT = %STR('1B26'x 'l0O');
   %ELSE %IF &ORIENT = LANDSCAPE %THEN %LET XLAYOUT = %STR('1B26'x 'l1O');

   %IF       &NCPI = 10 %THEN %LET PITCH = %STR('1B'x '(s10H' '1B'x ')s16.66H');
   %ELSE %IF &NCPI = 12 %THEN %LET PITCH = %STR('1B'x '(s12H' '1B'x ')s16.66H'); 
   %ELSE %IF &NCPI = 17 %THEN %LET PITCH = %STR('1B'x '(s16.66H' '1B'x ')s16.66H');

   /*
   / set margins 
   /---------------------------*/

   %LET LNUM =; 
   %LET RNUM =; 
   %LET TNUM =; 
   %LET BNUM =;

   %if "&ORIENT"="PORTRAIT" %then %do;

      %IF &CMAR = A AND &ORIENT=PORTRAIT %THEN %DO;
         %IF       &NLPI =  6 %THEN %DO; %LET TNUM = 4; %LET BNUM = 55; %END;
         %ELSE %IF &NLPI =  8 %THEN %DO; %LET TNUM = 7; %LET BNUM = 73; %END;
         %ELSE %IF &NLPI = 10 %THEN %DO; %LET TNUM = 7; %LET BNUM = 86; %END;
 
         %IF       &NCPI = 10 %THEN %DO; %LET RNUM =  72; %LET LNUM = 11; %END;
         %ELSE %IF &NCPI = 12 %THEN %DO; %LET RNUM =  86; %LET LNUM = 15; %END;
         %ELSE %IF &NCPI = 17 %THEN %DO; %LET RNUM = 119; %LET LNUM = 22; %END;
         %END;
   
      %else %IF &CMAR = B %THEN %DO;
         %IF       &NLPI =  6 %THEN %DO; %LET TNUM = 1; %LET BNUM =  61; %END;
         %ELSE %IF &NLPI =  8 %THEN %DO; %LET TNUM = 3; %LET BNUM =  80; %END;
         %ELSE %IF &NLPI = 10 %THEN %DO; %LET TNUM = 2; %LET BNUM =  96; %END;
 
         %IF       &NCPI = 10 %THEN %DO; %LET RNUM =  76; %LET LNUM = 5; %END;
         %ELSE %IF &NCPI = 12 %THEN %DO; %LET RNUM =  93; %LET LNUM = 7; %END;
         %ELSE %IF &NCPI = 17 %THEN %DO; %LET RNUM = 128; %LET LNUM = 8; %END;
         %END;
   
      %else %IF &CMAR = C %THEN %DO;
         %IF       &NLPI =  6 %THEN %DO; %LET TNUM = 6; %LET BNUM = 59; %END;
         %ELSE %IF &NLPI =  8 %THEN %DO; %LET TNUM = 9; %LET BNUM = 77; %END;
         %ELSE %IF &NLPI = 10 %THEN %DO; %LET TNUM = 9; %LET BNUM =108; %END;
 
         %IF       &NCPI = 10 %THEN %DO; %LET RNUM =  80; %LET LNUM = 10; %END;
         %ELSE %IF &NCPI = 12 %THEN %DO; %LET RNUM =  96; %LET LNUM = 12; %END;
         %ELSE %IF &NCPI = 17 %THEN %DO; %LET RNUM = 133; %LET LNUM = 18; %END;
         %END;
   
      %else %IF &CMAR = D %THEN %DO;
         %IF       &NLPI =  6 %THEN %DO; %LET TNUM = 1; %LET BNUM =  61; %END;
         %ELSE %IF &NLPI =  8 %THEN %DO; %LET TNUM = 1; %LET BNUM =  88; %END;
         %ELSE %IF &NLPI = 10 %THEN %DO; %LET TNUM = 1; %LET BNUM = 120; %END;
   
         %IF       &NCPI = 10 %THEN %DO; %LET RNUM =  80; %LET LNUM =  0; %END;
         %ELSE %IF &NCPI = 12 %THEN %DO; %LET RNUM =  96; %LET LNUM =  0; %END;
         %ELSE %IF &NCPI = 17 %THEN %DO; %LET RNUM = 133; %LET LNUM =  0; %END;
         %END;
      %end;
 
   %else %if "&orient"="LANDSCAPE" %then %do;
   
      %IF &CMAR = A %THEN %DO;
         %IF       &NLPI =  6 %THEN %DO; %LET TNUM =  8; %LET BNUM = 37; %END;
         %ELSE %IF &NLPI =  8 %THEN %DO; %LET TNUM = 11; %LET BNUM = 50; %END;
         %ELSE %IF &NLPI = 10 %THEN %DO; %LET TNUM = 14; %LET BNUM = 58; %END;
   
         %IF       &NCPI = 10 %THEN %DO; %LET RNUM = 100; %LET LNUM = 10; %END;
         %ELSE %IF &NCPI = 12 %THEN %DO; %LET RNUM = 115; %LET LNUM =  9; %END;
         %ELSE %IF &NCPI = 17 %THEN %DO; %LET RNUM = 167; %LET LNUM = 18; %END;
         %END;
   
      %else %IF &CMAR = B %THEN %DO;
         %IF       &NLPI =  6 %THEN %DO; %LET TNUM = 2; %LET BNUM = 46; %END;
         %ELSE %IF &NLPI =  8 %THEN %DO; %LET TNUM = 5; %LET BNUM = 57; %END;
         %ELSE %IF &NLPI = 10 %THEN %DO; %LET TNUM = 6; %LET BNUM = 71; %END;
   
         %IF       &NCPI = 10 %THEN %DO; %LET RNUM = 103; %LET LNUM = 7; %END;
         %ELSE %IF &NCPI = 12 %THEN %DO; %LET RNUM = 123; %LET LNUM = 5; %END;
         %ELSE %IF &NCPI = 17 %THEN %DO; %LET RNUM = 174; %LET LNUM = 9; %END;
         %END;
   
      %else %IF &CMAR = C %THEN %DO;
         %IF       &NLPI =  6 %THEN %DO; %LET TNUM = 7; %LET BNUM = 42; %END;
         %ELSE %IF &NLPI =  8 %THEN %DO; %LET TNUM = 9; %LET BNUM = 57; %END;
         %ELSE %IF &NLPI = 10 %THEN %DO; %LET TNUM =11; %LET BNUM = 74; %END;
   
         %IF       &NCPI = 10 %THEN %DO; %LET RNUM = 110; %LET LNUM = 12; %END;
         %ELSE %IF &NCPI = 12 %THEN %DO; %LET RNUM = 132; %LET LNUM = 14; %END;
         %ELSE %IF &NCPI = 17 %THEN %DO; %LET RNUM = 183; %LET LNUM = 22; %END;
         %END;
   
      %else %IF &CMAR = D %THEN %DO;
         %IF       &NLPI =  6 %THEN %DO; %LET TNUM = 0; %LET BNUM = 49; %END;
         %ELSE %IF &NLPI =  8 %THEN %DO; %LET TNUM = 0; %LET BNUM = 66; %END;
         %ELSE %IF &NLPI = 10 %THEN %DO; %LET TNUM = 0; %LET BNUM = 85; %END;
   
         %IF       &NCPI = 10 %THEN %DO; %LET RNUM = 110; %LET LNUM = 1; %END;
         %ELSE %IF &NCPI = 12 %THEN %DO; %LET RNUM = 132; %LET LNUM = 1; %END;
         %ELSE %IF &NCPI = 17 %THEN %DO; %LET RNUM = 183; %LET LNUM = 1; %END;
         %END;
      %end;
   

   %LET LMAR =;
   %LET RMAR =;
   %LET TMAR =;
   %LET BMAR =;

   %IF %LENGTH(&LNUM) > 0 %THEN %LET LMAR = %STR('1B26'x "a&LNUM.L");
   %IF %LENGTH(&RNUM) > 0 %THEN %LET RMAR = %STR('1B26'x "a&RNUM.M");
   %IF %LENGTH(&TNUM) > 0 %THEN %LET TMAR = %STR('1B26'x "l&TNUM.E");
   %IF %LENGTH(&BNUM) > 0 %THEN %LET BMAR = %STR('1B26'x "l&BNUM.F");

   %let hrow = 1;
   %let hcol = &lnum;
   %LET HOME    = %STR('1B26'x "a&hrow.R" '1B26'x "a&hcol.C");

   %local martxt;
   %if       &CMAR = A %THEN %let martxt = 1.5  inches binding edge, 1 inch on all others;
   %else %if &CMAR = B %THEN %let martxt = .75 inches binding edge, .5 inches on all others;
   %else %if &CMAR = C %THEN %let martxt = 1.25 inches on top and left sides;
   %else %if &CMAR = D %THEN %let martxt = None;


   %LET SETUP = %STR(
      RETAIN _INIT_ 0;
      IF ^_INIT_ THEN DO;
         _INIT_ = 1;
         PUT +1 &XLAYOUT '1B'x '(10U' '1B'x ')10U'
                      '1B'x '(s0P' '1B'x ')s0P'
             &PITCH
                      '1B'x '(s3T' '1B'x ')s3T'
             &XLPI '1B'x '9'
             &LMAR &RMAR &TMAR &BMAR;

         PUT +5 'This output file contains HPPCL escape sequences';
         put +5 "LAYOUT=&LAYOUT";
         put +5 "CPI=&cpi";
         put +5 "LPI=&lpi";
         put +5 "Margins=&cmar";
         put +5 "&martxt";

         PUT _PAGE_@;
         END;
);


   %PUT;
   %PUT;
   %PUT %str(HPPCL macro variables are now available);
   %PUT;
   %PUT %str(   CPI     = ) &NCPI;
   %PUT %str(   LPI     = ) &NLPI;
   %PUT %str(   Margins = ) &CMAR;
   %IF &CMAR = A %THEN %PUT %STR(   1.5  inches binding edge, 1 inch on all others);
   %IF &CMAR = B %THEN %PUT %STR(    .75 inches binding edge, .5 inches on all others);
   %IF &CMAR = C %THEN %PUT %STR(   1.25 inches on top and left sides);
   %IF &CMAR = D %THEN %PUT %STR(   None);
   %PUT %STR(   Layout  = ) &ORIENT;
   %PUT;
   %PUT;

   %IF %UPCASE(&MODE)=TEST %THEN %DO;
      %LET HOME=;
      %LET BS=;
      %LET ULON=;
      %LET ULOFF=;
      %LET ITALIC=;
      %LET UPRIGHT=;
      %LET NOBOLD=;
      %LET BOLD=;
      %LET SUBON=;
      %LET SUBOFF=;
      %LET SUPON=;
      %LET SUPOFF=;
      %END;
   %MEND JKHPPCL;
