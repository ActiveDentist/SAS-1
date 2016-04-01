/*
/ PROGRAM NAME: jkdisc01.sas
/
/ PROGRAM VERSION: 1.0
/
/ PROGRAM PURPOSE: This utility macro is called by SIMSTAT to compute
/ frequency counts for discrete variables.  Do not use this macro outside
/ the context of macro SIMSTAT.
/		     
/ SAS VERSION: 6.12 (UNIX)
/
/ CREATED BY: John Henry King
/ DATE: FEB1997
/
/ INPUT PARAMETERS:
/
/ by=                 List by variables
/
/ uniqueid=           Unique patient identifier
/
/ tmt=                Treatment variable name
/
/ discrete=           List of 1 byte character discrete variables to be 
/                     analyzed.
/
/ dlevels=            List of possible values that the discrete variables may
/                     have.  This is need if one or more of the levels is not
/                     found in the data.
/
/ dexcl=              A single value, for a discrete variable, that should be
/                     excluded by the macro when counting.
/
/ out=                Names the output data set created by the macro.
/
/ print=NO            Print the output data set?
/
/ OUTPUT CREATED: A SAS data set.
/
/ MACROS CALLED:
/
/   jkxwords  parse a list of words
/   jkprefix  add prefix to a list of words
/
/ EXAMPLE CALL:
/
/   %jkdisc01(data=&subset, 
/              out=&_disc2_,
/               by=&by &control,
/              var=_one_,
/         uniqueid=&uniqueid,
/              tmt=&tmt,
/            print=NO,
/         discrete=&discrete,
/          dlevels=&dlevels,
/            dexcl=&dexcl)
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

%macro jkdisc01(data=,
                  by=,
                 var=,
             uniqueid=,
                 tmt=,
            discrete=,
             dlevels=,
               dexcl=,
                 out=,
               print=NO);


   /*
   / Create a unique name for the temporary dataset.
   /-------------------------------------------------*/

   %local temp1; 
   %let temp1 = _1_&sysindex;


   /*
   / Description of LOCAL macro variables.
   /
   / I        = do loop counter
   / J        = holds temporary variables names
   /
   / DATALIST = list of temporary datasets created by PROCs
   /            TRANSPOSE, ANOVA, or FREQ that are need to later
   /            be combined, by MERGEing or SETting.
   /            Includes in= dataset option. This variable is reused
   /            in different sections of the macro.
   /
   / TVARLIST = List of variable names created by PROC TRANPOSE,
   /            in the form _A: _B: etc.
   /
   / DELLIST  = List of temporary datasets created by PROC TRANSPOSE
   /            to use in PROC DELETE.  This list contains the same
   /            names as MRGLIST but without the in= dataset option.
   /
   / DDISCLST = This variable contains a list of discrete variables to
   /            be dropped.  The macros creates variables to count the
   /            missing values of the discrete variables.  These variables
   /            are created by the macro even if there are no missing
   /            values for a particular discrete.  This list provides a way
   /            to DROP this variable from the data. The variables have
   /            names in the form X_A_ X_B_ etc.
   /
   / DDISCn   = need to explain
   /
   / ABC      = The letters of the alphabet.  Used to construct temporary
   /            name for the discrete variables.  The temporary names have
   /            the form X_Ax X_Ay X_Az.
   /            Where X_A is the value of the PREFIX option used in PROC
   /            TRANSPOSE, and z,y,z are the values of the discrete
   /            variable.  This method of naming limits the number of
   /            discrete variables the macro can accept to 36.
   /
   /------------------------------------------------------------------------*/


      %let print = %upcase(&print);

      %local disc0 dlev0;
      %local datalist dellist tvarlist i j abc w levels;

      %let abc = ABCDEFGHIJKLMNOPQRSTUVWXYZ;

      %let datalist = ;
      %let dellist  = ;
      %let tvarlist = ;

     
      %let disc0 = %jkxwords(list=&discrete,root=disc);



      /*
      / Check to see if dlevels is delimited properly
      /------------------------------------------------*/
      %if %length(&dlevels) > 0 %then %do;
         %let dlev0 = 1;

         %if %index("&dlevels",\) = 0 %then %do;
            %let dlev0 = 0;
            %put ER!ROR: MACRO JKDISC01 ER!ROR, You need to delimit DLEVELS= with a backslash \;
            %end;

         %end;

      /*
      / Call PROC TRANSPOSE once for each DISCRETE variable creating a
      / seperate transposed data set for each variable
      /------------------------------------------------------------------*/
      %do i = 1 %to &disc0;
         %let j = %substr(&abc,&i,1);



         /*
         / Scan out the values of DLEVELS and and store them in a macro
         / variable array.  The values of these arrays will be used to
         / create data step array statements below.
         /
         / If the user supplies a DLEVELS list that does not have the same
         / number of elements at the number of variables in DISCRETE the
         / then the macro just uses the LAST value from the list.
         /-------------------------------------------------------------------*/
         %if &dlev0 > 0 %then %do;
            %let w = %scan(&dlevels,&i,%str(\));
            %if "&w" ^= "" %then  %then %let levels = &w;
            %local dlev&i;
            %let dlev&i = %jkprefix(&levels,X_&j);
            %put NOTE: DLEV&i = &&dlev&i;
            %end;

         proc transpose
               data   = &data
               out    = _&j(drop=_name_) 
               prefix = X_&j;
            by &by &uniqueid &tmt;
            id &&disc&i;
            var &var;
            run;

         /*
         / DATALIST will be used in the MERGE statement below
         /-------------------------------------------------------*/
         %let datalist = &datalist _&j;

         /*
         / TVARLIST holds the names of the NEW variables created
         / by PROC TRANSPOSE.
         /--------------------------------------------------------*/
         %let tvarlist = &tvarlist X_&j:;

         /*
         / DELLIST is the list data set names that will be used by
         / PROC DELETE to delete the data set created by transpose
         / after they have been merged.
         /--------------------------------------------------------*/
         %let dellist  = &dellist _&j;
         %end;

      %put NOTE: datalist = &datalist;

      data &temp1;
         merge &datalist;
         by &by &uniqueid &tmt;

         /*
         / For each DISCRETE variable do the following.
         / 1. See of there are any all missing observations.
         /    If so create a variable _A_ and set it to 1.
         /    This variable will be DATA NOT AVAIL counts.
         /
         / 2. Propagate ZERO values for the transposed variables
         /    that are set to missing by PROC TRANSPOSE.  Uses the
         /    MAX library function.
         /
         /----------------------------------------------------------*/


         %do i = 1 %to &disc0;

            %let j = %substr(&abc,&i,1);

            %local ddisc&i;
            %let ddisc&i = x_&j._;

            %if "&dexcl" ^= "" %then %do;
               drop x_&j.&dexcl;
               %end;

            %if (&dlev0 > 0) %then %do;
               array A_&j[*] &&dlev&i;
               %end;

            %else %do;
               array A_&j[*] x_&j:;
               %end;

            /*
            / If all the elements of the an array are missing, then
            / the discrete variable was missing in the input dataset.
            / The macro will create _A_ to count these
            / missing values.
            /
            / Otherwise do over the array and set the missing values
            / to 0.
            /----------------------------------------------------------*/

            %if "&dexcl" ^= "" %then %do;
               if x_&J.&dexcl ^= 1 then do;
                  if nmiss(of A_&j[*])=dim(A_&j)then do;
                     x_&j._ = 1;
                     call symput("DDISC&i",' ');
                     end;
                  else do _i_ = 1 to dim(A_&j);
                     A_&j[_i_] = max(0,A_&j[_i_]);
                     end;
                  end;
               %end;
            %else %do;
               if nmiss(of A_&j[*])=dim(A_&j)then do;
                  x_&j._ = 1;
                  call symput("DDISC&i",' ');
                  end;
               else do _i_ = 1 to dim(A_&j);
                  A_&j[_i_] = max(0,A_&j[_i_]);
                  end;
               %end;

            %end;

         drop _i_;
         run;


      %let ddisclst=;
      %do i = 1 %to &disc0;
         %put NOTE: i=&i DDISC&I=&&ddisc&i;
         %let ddisclst = &ddisclst &&ddisc&i;
         %end;

      %put NOTE: DDISCLST=&ddisclst;

      /*
      / Delete the temporary data sets created by proc transpose
      /------------------------------------------------------------*/
      proc delete data=&dellist;
         run;

      /*
      / Transpose the merged, transposed, data the merge step above.
      / This will string out the data into a form that can easily be
      / processed by proc summary
      /--------------------------------------------------------------*/
      proc transpose
            data   = &temp1(drop=&ddisclst)
            out    = &temp1
            prefix = xxxxxxx;
         by &by &uniqueid &tmt;
         var &tvarlist;
         run;

      /*
      / Call proc summary to get the counts and percents of the 0,1
      / variables created above.
      /--------------------------------------------------------------*/
      proc summary nway missing data=&temp1; 
         by &by;
         class _name_ &tmt;
         var xxxxxxx1;
         output out = &out(drop=_type_ _freq_)
                sum = count
                  n = n
               mean = pct;
         run;


      /*
      / Delete the temporary dataset being use to this point
      /--------------------------------------------------------------*/
      proc delete data=&temp1; 
         run;


      /*
      / Process the proc summary data to
      /
      / 1. Remove the value of the discrete variable from _VNAME_
      /    and assign them to the variable _LEVEL_
      / 2. Create proper values for _VNAME_ from the list of discrete
      /    variables.
      / 3. Create _VTYPE_.
      / 4. Fix up the values of N PCT and COUNT when _LEVEL_ is _
      /--------------------------------------------------------------*/
 
      data &out;

         length _vname_ _level_ _vtype_ $8;
         retain _vtype_ 'DISC';

         set &out;

         _i_      = indexc("&abc",substr(_name_,3,1));
         _vname_  = symget('DISC'||left(put(_i_,2.)));
         _level_  = substr(_name_,4);

         drop _name_ _i_;

         if _level_='_' then do;
            n     = .;
            pct   = .;
            count = max(0,count);
            end;
         run;

   %if "&print"="YES" %then %do;
      title4 "DATA=&out from JKDISC01";
      proc print data=&out;
         run;
      title4;
      %end;

   %mend jkdisc01;
