/*
/ PROGRAM NAME: jklyot01.sas
/
/ PROGRAM VERSION: 1.0
/
/ PROGRAM PURPOSE: Used by standard macros to set macro variables associated
/   with the page layout.  Not useful outside the context of the standard 
/   macros.
/
/ SAS VERSION: 6.12
/
/ CREATED BY: John Henry King
/ DATE: 1994
/
/ INPUT PARAMETERS: This macro has no parameters.  The macro uses macro
/   variables that are know to be available within the standard macros
/   when the macro is called.
/   
/   LAYOUT
/   DISP
/
/ OUTPUT CREATED: The following global macro variables have their values
/   altered.
/   
/   LS
/   PS
/   FILE_EXT
/   FILE_DSP
/   HPPCL
/   DASHCHR
/
/
/ MACROS CALLED: none
/
/ EXAMPLE CALL: %jklyot01;
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

%macro jklyot01;
   /*
   / Set up the page size based on user input.  
   /-------------------------------------------------------------------*/

   %if "&layout" = "DEFAULT" %then %do;
      %let dashchr  = '-';
      %let file_ext = LIS;
      %let file_dsp = &disp;
      %let hppcl    = 0;
      %let ls       = 132;
      %let ps       = 60;       
      %end;

 
   %else %if %index(&layout,USP) %then %do;

      /*
      / Portrait
      / options for use with US PSPRINT postscript command.
      /-----------------------------------------------------*/

      %let dashchr  = '_';;
      %let file_ext = %substr(&layout,3,3);
      %let file_dsp = &disp;
      %let hppcl    = 0;

      %if       "&layout"="USP09" %then %do;
         %let ls = 80;
         %let ps = 56;
         %end;
      %else %if "&layout"="USP08" %then %do;
         %let ls = 90;
         %let ps = 61;
         %end;
      %else %if "&layout"="USP07" %then %do;
         %let ls = 103;
         %let ps = 77;
         %end;
      %else %if "&layout"="USP06" %then %do;
         %let ls = 121;
         %let ps = 89;
         %end;
      %else %if "&layout"="USP10" %then %do;
         %let ls = 72;
         %let ps = 50;
         %end;
      %end;

   %else %if %index(&layout,USL) %then %do;

      /*
      / Landscape
      / options for use with US PSPRINT postscript command.
      /-----------------------------------------------------*/

      %let dashchr = '_';
      %let file_ext = %substr(&layout,3,3);
      %let file_dsp = &disp;
      %let hppcl    = 0;

      %if       "&layout"="USL09" %then %do;
         %let ls = 120;
         %let ps = 36;
         %end;
      %else %if "&layout"="USL08" %then %do;
         %let ls = 135;
         %let ps = 40;
         %end;
      %else %if "&layout"="USL07" %then %do;
         %let ls = 153;
         %let ps = 50;
         %end;
      %else %if "&layout"="USL06" %then %do;
         %let ls = 179;
         %let ps = 59;
         %end;
      %else %if "&layout"="USL10" %then %do;
         %let ls = 108;
         %let ps = 33;
         %end;
      %end;

   %else %if %index(&layout,UKP) %then %do;

      %let dashchr  = '_';
      %let file_ext = %substr(&layout,3,3);
      %let file_dsp = &disp;
      %let hppcl    = 0;

      %if       "&layout"="UKP09" %then %do;
         %let ls = 81;
         %let ps = 59;
         %end;
      %else %if "&layout"="UKP08" %then %do;
         %let ls = 93;
         %let ps = 67;
         %end;
      %else %if "&layout"="UKP07" %then %do;
         %let ls = 109;
         %let ps = 77;
         %end;
      %else %if "&layout"="UKP06" %then %do;
         %let ls = 124;
         %let ps = 89;
         %end;
      %else %if "&layout"="UKP10" %then %do;
         %let ls = 73;
         %let ps = 53;
         %end;
      %end;

   %else %if %index(&layout,UKL) %then %do;

      %let dashchr = '_';
      %let file_ext = %substr(&layout,3,3);
      %let file_dsp = &disp;
      %let hppcl    = 0;

      %if       "&layout"="UKL09" %then %do;
         %let ls = 119;
         %let ps = 39;
         %end;
      %else %if "&layout"="UKL08" %then %do;
         %let ls = 137;
         %let ps = 45;
         %end;
      %else %if "&layout"="UKL07" %then %do;
         %let ls = 161; 
         %let ps = 52;
         %end;
      %else %if "&layout"="UKL06" %then %do;
         %let ls = 183; 
         %let ps = 59;
         %end;
      %else %if "&layout"="UKL10" %then %do;
         %let ls = 109;
         %let ps = 35;
         %end;
      %end;

   %else %if %index(&layout,PORT) %then %do;
      /* 
      / CPI=10 LPI=06 PS=60 LS=53 
      / CPI=12 LPI=08 PS=71 LS=72 
      / CPI=12 LPI=10 PS=84 LS=72 
      / CPI=17 LPI=08 PS=71 LS=98 
      / CPI=17 LPI=10 PS=85 LS=98 
      /---------------------------------------------*/

      %let dashchr  = 'c4'x;
      %let layout   = PORTRAIT;
      %let file_ext = PCL;

      %if "&disp"="MOD" %then %do;
         %let hppcl    = 0;
         %let file_dsp = MOD;
         %end;
      %else %do;
         %let hppcl    = 1;
         %let file_dsp = MOD;
         %end;

      %if       &cpi=17 %then %let ls=98;
      %else %if &cpi=12 %then %let ls=72;
      %else %if &cpi=10 %then %let ls=60;
      %else %do;
         %let cpi = 17;
         %let  ls = 98;
         %end;
      %if       &lpi=6  %then %let ps=53;
      %else %if &lpi=8  %then %let ps=71;
      %else %if &lpi=10 %then %let ps=85;
      %else %do;
         %let lpi = 10;
         %let ps  = 85;
         %end;
      %end;

   %else %if %index(&layout,LAND) %then %do;
      /* 
      / CPI=12 LPI=10 PS=56 LS=107 
      / CPI=17 LPI=10 PS=56 LS=144
      /-----------------------------------------*/
      
      %let dashchr  = 'C4'x;
      %let layout   = LANDSCAPE;
      %let file_ext = PCL;

      %if "&disp"="MOD" %then %do;
         %let hppcl    = 0;
         %let file_dsp = MOD;
         %end;
      %else %do;
         %let hppcl    = 1;
         %let file_dsp = MOD;
         %end;


      %if       &cpi=17 %then %let ls=144;
      %else %if &cpi=12 %then %let ls=107;
      %else %do;
         %let cpi = 17;
         %let  ls = 144;
         %end;

      %if       &lpi=10 %then %let ps=56;
      %else %do;
         %let lpi = 10;
         %let  ps = 56;
         %end;
      %end;

   %put NOTE: --------------------------------------------------------;
   %put NOTE: JKLYOT01 has assigned the following macro variables.;
   %put NOTE: For LAYOUT=&layout;
   %put NOTE: PS=&ps LS=&ls;
   %put NOTE: DASHCHR=&dashchr;
   %put NOTE: FILE_EXT=&file_ext;
   %put NOTE: HPPCL=&hppcl;
   %put NOTE: --------------------------------------------------------;

   %mend jklyot01;
