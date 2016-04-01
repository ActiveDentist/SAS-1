/*
/ Program name:     JOBID2.SAS
/
/ Program version:  2.1
/
/ Program purpose:  Creates jobid information in various titles footnotes
/                   etc. (username, program name etc.).
/
/ SAS version:      6.12 TS020
/
/ Created by:
/ Date:
/
/ Input parameters: ARG     - Area to print jobid info
/                   INFO    - Information to print
/                   DATEFMT - Date format
/                   TIME    - Include time of day
/                   BEFORE  - Text to print before jobid string
/                   AFTER   - Text to print after jobid string
/                   FONT    - Graphics font
/                   HEIGHT  - Font height
/                   COLOUR  - Font colour
/                   PREMOVE - Starting point for relative moves
/                   MOVE    - Location of id string
/
/ Output created:
/
/ Macros called:    %jobid.sas
/
/ Example call:     %jobid2(title);
/
/=========================================================================
/ Change Log:
/
/   MODIFIED BY: Jonathan Fry
/   DATE:        09DEC1998
/   MODID:       JMF001
/   DESCRIPTION: Tested for Y2K compliance.
/                Add %PUT statement for Macro Name and Version Number.
/                Change Version Number to 2.1.
/   ------------------------------------------------------------------
/   MODIFIED BY:
/   DATE:
/   MODID:       XXX002
/   DESCRIPTION:
/   ------------------------------------------------------------------
/   MODIFIED BY:
/   DATE:
/   MODID:       XXX003
/   DESCRIPTION:
/   ------------------------------------------------------------------
/=========================================================================*/

%macro jobid2(arg,
             info=USERID,
          datefmt=DATE9.,
             time=YES,
           before=,
            after=,
             font=SIMPLEX,
           height=0.5,
            color=BLACK,
             move=(0.0 IN, 0.01 IN));

/*-------------------------------------------------------------------------/
/ JMF001                                                                   /
/ Display Macro Name and Version Number in LOG                             /
/-------------------------------------------------------------------------*/

   %put ------------------------------------------------------;
   %put NOTE: Macro called: JOBID2.SAS     Version Number: 2.1;
   %put ------------------------------------------------------;

   %jobid(&arg,info=&info,datefmt=&datefmt,time=&time,before=&before,
          after=&after,font=&font,height=&height,color=&color,move=&move);

%mend jobid2;
