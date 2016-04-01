/*
/ PROGRAM NAME: jhflowx.sas
/
/ PROGRAM VERSION: 1.0
/
/ PROGRAM PURPOSE:
/   Used to flow text.  The macro will flow text into array elements that 
/   are wider or narrower that the original array.
/
/ SAS VERSION: 6.12
/
/ CREATED BY: John Henry King
/
/ DATE: 1992
/
/ INPUT PARAMETERS:
/
/  in   = names the array to be re-formated.  Use only expliciatly 
/         subscripted arrays.  Give only the array name, as used in the 
/         DIM function.
/
/  out  = names the array created by the macro.  The default is _FLOW.
/
/  dim  = define the dimension of the output array.  The default is 20.
/         This value should be large enought to hold all the newly flowed
/         text but small enough to not waste too much space in your data
/         set.
/
/  size = specifies the length of each OUT array element.  The default
/         is 40.
/
/  newline = specifies a character imbedded in the input array to force the 
/            start of a new array element.
/
/  delm = specifies the delimiter for the words in the input array.
/
/ OUTPUT CREATED:
/   An array.
/
/ MACROS CALLED: none
/
/ EXAMPLE CALL:
/
/     array _y[1] $200 _temporary_;
/     _y[1] = put(&level1,&fmtlvl1);
/
/     %jkflowx(in=_y,out=_1lv,dim=10,size=&swid)
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

%macro jkflowX(in = ,
              out = _flow,
             size = 40,
              dim = 20,
          newline = '\',
             delm = ' ');

   %local x;
   %let x = JKFLOX;
   retain &x.L &newline;

   &out.0 = 1;
   array &out[&dim] $&size;
   
   do &x.I = 1 to dim(&in);
      if &in[&x.I] = ' ' then continue;
      &x.K = 1;
      &x.W = scan(&in[&x.I] , &x.K , &delm);
      do while( &x.W ^= ' ');
         select;
            when( left(&x.W) = &x.L) do;
               &out.0 + 1;
               end;
            when( length(&x.W) > &size ) do;
               if &out[&out.0] ^= ' ' then &out.0 + 1;
               &out[&out.0] = substr( &x.W , 1 , &size-1 ) || '-';
               &out.0 + 1;
               &out[&out.0] = substr( &x.W , &size );
               end;
            when( length(&x.W) = &size & &out[&out.0] = ' ' ) do;
               &out[&out.0] = left(&x.W);
               end;
            when((length(&out[&out.0])*(&out[&out.0]^=' ')) + length(&x.W)+1 <= &size ) do;
               &out[&out.0] = left(trim(&out[&out.0])||' '||&x.W);
               end;
            otherwise do;
               &out.0 + 1;
               &out[&out.0] = left(&x.W);
               end;
            end;
         &x.K + 1;
         &x.W = scan(&in[&x.I] , &x.K , &delm);
         end;
      if &out[&out.0] = ' ' then &out.0 + -1;
      end;
   if (&out[1] = ' ') & (&out.0 = 1) then &out.0 = 0;
  
   drop &x:;
   
   %mend jkflowX;
