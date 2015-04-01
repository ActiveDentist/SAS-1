/*
/ Program Name: LINEMUP.SAS
/
/ Program Version: 2.1
/
/ Program purpose: Lines up the decimal place of numbers that are stored as characters
/                  and preserves the number of decimal places that were entered.
/
/ SAS Version: 6.12
/
/ Created By: Hedy Weissinger
/ Date:
/
/ Input Parameters:
/
/           DATA   - is the name of the dataset to be used (the final dataset will also
/                    have this name)
/           VAR    - list of variables that need to be aligned
/           OUTVAR - new variables created by the macro that are the aligned versions of
/                    the VAR list.
/
/ Output Created:
/
/           A set of variables are created which correpsond to the original set of variables
/           but which have been processed by the macro to align decimal points.
/
/ Macros Called: BWWORDS.SAS
/
/ Example Call:
/
/===============================================================================================
/ Change Log:
/
/   MODIFIED BY: Jonathan Fry
/   DATE:        09DEC1998
/   MODID:       JMF001
/   DESCRIPTION: Tested for Y2K compliance.
/                Add %PUT Statement for Macro Name and Version Number.
/                Change Version Number to 2.1.
/   ---------------------------------------------------------------------------
/   MODIFIED BY:
/   DATE:
/   MODID:       XXX002
/   DESCRIPTION:
/   ---------------------------------------------------------------------------
/   MODIFIED BY:
/   DATE:
/   MODID:       XXX003
/   DESCRIPTION:
/   ---------------------------------------------------------------------------
/===============================================================================================*/

%macro linemup(data=,var=,outvar=);

   /*
   / JMF001
   / Display Macro Name and Version Number in LOG
   /--------------------------------------------------------*/

   %put -----------------------------------------------------;
   %put NOTE: Macro called: LINEMUP.SAS   Version Number: 2.1;
   %put -----------------------------------------------------;


   %let _vr0 = %bwwords(&var,root=_vr0);
   data _1_;
      do until(eof);
         set &data end=eof;
         array _v{&_vr0} &var;
         array _i{&_vr0};
         array _iI{&_vr0};
         array _ij{&_vr0};
         array _d{&_vr0};
         do _j = 1 to dim(_v);
            if ^verify(_v{_j},'0123456789. ') then do;
               _i{_j} = max(((index(_v{_j},'.')-1)>0) *
                              index(_v{_j},'.')-1, 0)
                        +((index(_v{_j},'.')=0)*length(_v{_j}));
               _II{_j} = ((index(_v{_j},'.')=0)*length(_v{_j}));
               _ij{_j} = max(((index(_v{_j},'.')-1)>0) *
                              index(_v{_j},'.')-1, 0);
               _d{_j} = max(0,index(left(reverse(_v{_j})),'.')-1);
               end;
            else do;
               _i{_j}=.; _ii{_j}=.; _ij{_j}=.; _d{_j}=.;
               end;
            end;
         output;
         end;
      drop _j;
      run;
   proc summary data=_1_ nway missing;
      var _i1-_i&_vr0 _d1-_d&_vr0;
      output out=_2_(drop=_type_ _freq_)
         max=_mi1-_mi&_vr0 _md1-_md&_vr0;
      run;
   data &data;
      set _2_;
      array _mi{&_vr0};
      array _md{&_vr0};
      do until(eof);
         set _1_ end=eof;
         array _v{&_vr0} &var;
         array _nv{&_vr0} $10 &outvar;
         array _i{&_vr0};
         array _d{&_vr0};
         do _j = 1 to dim(_v);
            if verify(_v{_j},'0123456789. ')=0
               then do;
                  _nv{_j} = putn(input(_v{_j},30.),
                              'F' ,
                             _mi{_j} + _d{_j} + (_d{_j}>0) ,
                             _d{_j});
               end;
            else _nv{_j} = _v{_j};
            end;
         output;
         drop _d1-_d&_vr0 _mi1-_mi&_vr0 _md1-_md&_vr0 _j _i1-_i&_vr0
              _ii1-_ii&_vr0 _ij1-_ij&_vr0 ;
         end;
      run;
   %mend;
