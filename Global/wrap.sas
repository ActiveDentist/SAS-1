/*
/ Program Name:     WRAP.SAS
/
/ Program Version:  2.1
/
/ MDP/Protocol ID:  N/A
/
/ Program Purpose:  Variable &IN is scanned toward the left, beginning at &WLENGTH,
/                   for any of the delimeters contained in &PUNCT.  If a delimiter
/                   is found, the portion of &IN from the start of &IN to the
/                   delimiter is moved to &OUT.  If a delimiter is not found, the
/                   first &WLENGTH characters are moved from &IN to &OUT.
/
/ SAS Version:      6.12
/
/ Created By:       JIM COMER
/ Date:             08JAN91
/
/ Input Parameters: IN      = Input character string.
/                   OUT     = Output character string.
/                   WLENGTH = Wrap length (default 30).
/                   PUNCT   = Valid delimiter list (default .<(+|''!$*:^-/,')).
/
/ Output Created:   OUT     = Output character string
/
/ Macros Called:    None
/
/ Example Call:
/
/==========================================================================================
/ Change Log:
/
/     MODIFIED BY: Mark Foxwell
/     DATE:        08SEP97
/     MODID:       001
/     DESCRIPTION: 1) DO WHILE loop substituted with a DO UNTIL loop as the DO WHILE
/                     loop will drop the value of __i to 0 if a punctuation mark
/                     falls at position 1 (this causes an error in the substr function
/                     later on.).
/                  2) In the penultimate ELSE DO loop, the start position for &in
/                     changed from &wlength to &wlength+1 otherwise the first
/                     character of &in is the same as the last of &out.
/     --------------------------------------------------------------------------------
/     MODIFIED BY: Jonathan Fry
/     DATE:        10DEC1998
/     MODID:       JMF002
/     DESCRIPTION: Tested for Y2K compliance.
/                  Add %PUT statement for Macro Name and Version Number.
/                  Change Version Number to 2.1.
/     --------------------------------------------------------------------------------
/     MODIFIED BY:
/     DATE:
/     MODID:       XXX003
/     DESCRIPTION:
/     --------------------------------------------------------------------------------
/==========================================================================================*/

%MACRO WRAP (IN      = ,                       /* Input character string  */
             OUT     = ,                       /* Output character string */
             WLENGTH = 30,                     /* Wrap length             */
             PUNCT   = ' .<(+|''!$*:^-/,');    /* Valid delimiter list    */

/*--------------------------------------------------------------------/
/ JMF002                                                              /
/ Display Macro Name and Version Number in LOG.                       /
/--------------------------------------------------------------------*/

   %put --------------------------------------------------;
   %put NOTE: Macro called: WRAP.SAS   Version Number: 2.1;
   %put --------------------------------------------------;

/*--------------------------------------------------------------------/
/ Left align input string and check length.                           /
/--------------------------------------------------------------------*/

   &IN=LEFT(&IN);
   __LEN = LENGTH(TRIM(&IN));

/*--------------------------------------------------------------------/
/ If length of string > wrap length, look for punctuation character.  /
/--------------------------------------------------------------------*/

   IF __LEN GT &WLENGTH THEN DO;
      __FOUND = 0;
      DO __I = &WLENGTH TO 1 BY -1  UNTIL(__FOUND=1);
         __I2 = INDEX(&PUNCT,SUBSTR(&IN,__I,1));
         IF __I2 NE 0 THEN __FOUND=1;
      END;

/*--------------------------------------------------------------------/
/ If punctuation character is found, wrap at that position.           /
/--------------------------------------------------------------------*/

      IF __FOUND = 1 THEN DO;
         &OUT = SUBSTR(&IN,1,__I);
         &IN  = SUBSTR(&IN,__I+1);
      END;

/*--------------------------------------------------------------------/
/ If punctuation character is not found, wrap at &wlength.            /
/--------------------------------------------------------------------*/

      ELSE DO;
         &OUT = SUBSTR(&IN,1,&WLENGTH);
         &IN  = SUBSTR(&IN,&WLENGTH+1);
      END;
   END;

/*--------------------------------------------------------------------/
/ If length of input string < wrap length, move to output string.     /
/--------------------------------------------------------------------*/

   ELSE DO;
      &OUT = &IN;
      &IN  = ' ';
   END;

   DROP __LEN __FOUND __I __I2 ;

%MEND;
