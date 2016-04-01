/*
/ Program name:     HEXIT.SAS
/
/ Program version:  2.1
/
/ Program purpose:  Use this macro to create macro variables that contain hex
/                   characters 40 through 255. The names have the following form
/                   &root.two digit hex char (ie. hex B1 variable name is XB1).
/
/ SAS version:      6.12 TS020
/
/ Created by:
/ Date:
/
/ Input parameters: ROOT - user defined name
/                   macro name e.g. NAMExx (max 6 chars long)
/                   (xx hex identifier)
/
/ Output created:
/
/ Macros called:    None
/
/ Example call:     %hexit(root=name);
/
/=====================================================================================
/ Change log:
/
/    MODIFIED BY: Jonathan Fry
/    DATE:        09DEC1998
/    MODID:       JMF001
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 2.1.
/    --------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX002
/    DESCRIPTION:
/    --------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX003
/    DESCRIPTION:
/    --------------------------------------------------------------------
/=====================================================================================*/

%macro hexit(root=X);

/*-------------------------------------------------------------------------/
/ JMF001                                                                   /
/ Display Macro Name and Version Number in LOG                             /
/-------------------------------------------------------------------------*/

   %put -----------------------------------------------------;
   %put NOTE: Macro called: HEXIT.SAS      Version Number 2.1;
   %put -----------------------------------------------------;

   %global &root.00 &root.01 &root.02 &root.03
           &root.04 &root.05 &root.06 &root.07
           &root.08 &root.09 &root.0A &root.0B
           &root.0C &root.0D &root.0E &root.0F;
   %global &root.10 &root.11 &root.12 &root.13
           &root.14 &root.15 &root.16 &root.17
           &root.18 &root.19 &root.1A &root.1B
           &root.1C &root.1D &root.1E &root.1F;
   %global &root.20 &root.21 &root.22 &root.23
           &root.24 &root.25 &root.26 &root.27
           &root.28 &root.29 &root.2A &root.2B
           &root.2C &root.2D &root.2E &root.2F;
   %global &root.30 &root.31 &root.32 &root.33
           &root.34 &root.35 &root.36 &root.37
           &root.38 &root.39 &root.3A &root.3B
           &root.3C &root.3D &root.3E &root.3F;
   %global &root.40 &root.41 &root.42 &root.43
           &root.44 &root.45 &root.46 &root.47
           &root.48 &root.49 &root.4A &root.4B
           &root.4C &root.4D &root.4E &root.4F;
   %global &root.50 &root.51 &root.52 &root.53
           &root.54 &root.55 &root.56 &root.57
           &root.58 &root.59 &root.5A &root.5B
           &root.5C &root.5D &root.5E &root.5F;
   %global &root.60 &root.61 &root.62 &root.63
           &root.64 &root.65 &root.66 &root.67
           &root.68 &root.69 &root.6A &root.6B
           &root.6C &root.6D &root.6E &root.6F;
   %global &root.70 &root.71 &root.72 &root.73
           &root.74 &root.75 &root.76 &root.77
           &root.78 &root.79 &root.7A &root.7B
           &root.7C &root.7D &root.7E &root.7F;
   %global &root.80 &root.81 &root.82 &root.83
           &root.84 &root.85 &root.86 &root.87
           &root.88 &root.89 &root.8A &root.8B
           &root.8C &root.8D &root.8E &root.8F;
   %global &root.90 &root.91 &root.92 &root.93
           &root.94 &root.95 &root.96 &root.97
           &root.98 &root.99 &root.9A &root.9B
           &root.9C &root.9D &root.9E &root.9F;
   %global &root.A0 &root.A1 &root.A2 &root.A3
           &root.A4 &root.A5 &root.A6 &root.A7
           &root.A8 &root.A9 &root.AA &root.AB
           &root.AC &root.AD &root.AE &root.AF;
   %global &root.B0 &root.B1 &root.B2 &root.B3
           &root.B4 &root.B5 &root.B6 &root.B7
           &root.B8 &root.B9 &root.BA &root.BB
           &root.BC &root.BD &root.BE &root.BF;
   %global &root.C0 &root.C1 &root.C2 &root.C3
           &root.C4 &root.C5 &root.C6 &root.C7
           &root.C8 &root.C9 &root.CA &root.CB
           &root.CC &root.CD &root.CE &root.CF;
   %global &root.D0 &root.D1 &root.D2 &root.D3
           &root.D4 &root.D5 &root.D6 &root.D7
           &root.D8 &root.D9 &root.DA &root.DB
           &root.DC &root.DD &root.DE &root.DF;
   %global &root.E0 &root.E1 &root.E2 &root.E3
           &root.E4 &root.E5 &root.E6 &root.E7
           &root.E8 &root.E9 &root.EA &root.EB
           &root.EC &root.ED &root.EE &root.EF;
   %global &root.F0 &root.F1 &root.F2 &root.F3
           &root.F4 &root.F5 &root.F6 &root.F7
           &root.F8 &root.F9 &root.FA &root.FB
           &root.FC &root.FD &root.FE &root.FF;
   data _null_;
      do i = 0 to 255;
         call symput("&root"!!put(i,hex2.),collate(i,,1));
         end;
      run;
   %mend hexit;
