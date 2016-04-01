/*
/ PROGRAM NAME: jkflsz2.sas
/
/ PROGRAM VERSION: 1.0
/
/ PROGRAM PURPOSE: Flows text array elements into a 2 dimensional array. This
/   macro is an extension of JKFLOWX and was written specifically for the
/   standard macros.  It can be used outside the the standard macros but 
/   JKFLOWX is more generally useful.
/
/ SAS VERSION: 6.12
/
/ CREATED BY: John Henry King
/
/ DATE: 1993
/
/ INPUT PARAMETERS:
/
/  in   = names the array to be re-formated.  Use only expliciatly 
/         subscripted arrays.  Give only the array name, as used in the 
/         DIM function.
/
/  out  = names the array created by the macro.  The default is _FL.
/
/  dim1 = Defines dimension one of the output array.
/
/  dim2 = Defines dimension two of the output array.
/
/  size = specifies the length of each OUT array element.  The default
/         is 40.
/
/  sizear = names and array to pass the size of each flowed field. 
/
/  newline = specifies a character imbedded in the input array to force the 
/            start of a new array element.
/
/  delm = specifies the delimiter for the words in the input array.
/
/ OUTPUT CREATED:
/   An array
/
/ MACROS CALLED: none
/
/ EXAMPLE CALL: 
/   Taken from AETAB.
/
/   %jkflsz2(in=_tl,out=_xl,size=&cwid,sizeAR=_tw,dim1=&cols,dim2=5);
/
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
  
%macro jkflsz2(in = ,
              out = _fl,
             size = 40,
           sizeAR = _xx,
             dim1 = 5,
             dim2 = 5,
          newline = '\',
             delm = ' ');

   %local x;
   %let x = JKFLOW;

   retain &x.L &newline;

   &out.0 = 0;
   array &out.0_[&dim1];

   array &out[&dim1,&dim2] $&size;
   
   do &x.I = 1 to dim(&in);
      &out.0_[&x.I] = 0;
      if &in[&x.I] = ' ' then continue; 
      &out.0 = &x.i;
      &out.0_[&x.I] = 1;
      &x.K = 1;
      &x.W = scan(&in[&x.I] , &x.K , &delm);
      do while( &x.W ^= ' ');
         select;
            when( left(&x.W) = &x.L ) do;
               &out.0_[&x.i] + 1;
               end;
            when( length(&x.W) > &sizeAR[&x.I] ) do;
               if &out[&x.I,&out.0_[&x.i]] ^= ' ' then &out.0_[&x.i] + 1;
               &out[&x.I,&out.0_[&x.i]] = substr( &x.W , 1 , &sizeAR[&x.I]-1 ) || '-';
               &out.0_[&x.i] + 1;
               &out[&x.I,&out.0_[&x.i]] = substr( &x.W , &sizeAR[&x.I] );
               end;
            when( length(&x.W) = &sizeAR[&x.I] & &out[&x.I,&out.0_[&x.i]] = ' ' ) do;
               &out[&x.I,&out.0_[&x.i]] = left(&x.W);
               end;
            when((length(&out[&x.I,&out.0_[&x.i]])*(&out[&x.I,&out.0_[&x.i]]^=' ')) 
                  + length(&x.W)+1 <= &sizeAR[&x.I] ) do;
               &out[&x.I,&out.0_[&x.i]] = left(trim(&out[&x.I,&out.0_[&x.i]])||' '||&x.W);
               end;
            otherwise do;
               &out.0_[&x.i] + 1;
               &out[&x.I,&out.0_[&x.i]] = left(&x.W);
               end;
            end;
         &x.K = &x.K + 1;
         &x.W = scan(&in[&x.I] , &x.K , &delm);
         end;
      if &out[&x.I,&out.0_[&x.i]] = ' ' then &out.0_[&x.i] + -1;
      end;
   
  
   drop &x:;
   
   %mend jkflsz2;
