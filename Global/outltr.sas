/*
/ Program Name: OUTLTR.SAS
/
/ Program Version: 3.2
/
/ Program Purpose: Assigns an output suffix letter (e.g., ou&outltr)
/
/ SAS Version: 6.12
/
/ Created By: SR Austin
/ Date: Sep 1994  (upper and lower case alphabetics)
/
/ Input Parameters:
/
/ Output Created:
/
/ Macros Called:
/
/ Example Call:   %outltr
/
/====================================================================================
/ Change Log
/
/    MODIFIED BY: H Weissinger
/    DATE:        30Oct1997
/    MODID:       001
/    DESCRIPTION: Remove extraneous ; from code
/    -------------------------------------------------------------------
/    MODIFIED BY: Jonathan Fry
/    DATE:        10DEC1998
/    MODID:       JMF002
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 3.1.
/    -------------------------------------------------------------------
/    MODIFIED BY: Paul Jarrett
/    DATE:	  31AUG1999
/    MODID:       003
/    DESCRIPTION: Change first "z" to "x" in string "...tuvwzyz..." so
/                 it is now "...tuvwxyz...".                ^
/                                   ^ 
/    -------------------------------------------------------------------
/    MODIFIED BY: 
/    DATE:	  
/    MODID:       XXX004
/    DESCRIPTION: 
/                 
/    -------------------------------------------------------------------
/====================================================================================*/

%macro outltr;

      /*
      / JMF002
      / Display Macro Name and Version Number in LOG
      /------------------------------------------------------------------*/

      %put ----------------------------------------------------;
      %put NOTE: Macro called: OUTLTR.SAS   Version Number: 3.2;
      %put ----------------------------------------------------;


   %global _ITR_N  ;
   %let avail=a b c d e f g h i j k l m n o p q r s t u v w x y z 1 2 3 4 5
              6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z;
   %let _ITR_N=%eval(&_ITR_N + 1);
   %let outltr=%scan(&avail,&_ITR_N);
   &outltr
%mend outltr;
