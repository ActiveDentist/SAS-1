/*
/ Program name: pvlst.sas
/
/ Program version: 2.1
/
/ Program purpose: Takes a list of variables and creates arrays of macro
/                  variables containing the variable names and also the
/                  variable labels.
/
/ SAS version: 6.12 TS020
/
/ Created by:
/ Date:
/
/ Input parameters: list - list of variables
/                   exclude -
/                   data - dataset to use
/                   root - root name for all variables
/                   croot - root name character variables
/                   nroot - root name numeric variables
/
/ Output created:
/
/ Macros called:
/
/ Example call:
/
/                %pvlst(data=test,list=_character_,root=b);
/
/============================================================================
/ Change log:
/
/     MODIFIED BY: Jonathan Fry
/     DATE:        10DEC1998
/     MODID:       JMF001
/     DESCRIPTION: Tested for Y2K compliance.
/                  Add %PUT statement for Macro Name and Version Number.
/                  Change Version Number to 2.1.
/     -------------------------------------------------------------------
/     MODIFIED BY:
/     DATE:
/     MODID:       XXX002
/     DESCRIPTION:
/     -------------------------------------------------------------------
/     MODIFIED BY:
/     DATE:
/     MODID:       XXX003
/     DESCRIPTION:
/     -------------------------------------------------------------------
/============================================================================*/

%macro pvlst(list = ,
          exclude = ,
             data = _LAST_,
             root = _PVL,
            croot = _CRV,
            nroot = _NMV);

   /*
   / JMF001
   / Display Macro Name and Version Number in LOG
   /------------------------------------------------------------*/

   %put ---------------------------------------------------;
   %put NOTE: Macro called: PVLST.SAS   Version Number: 2.1;
   %put ---------------------------------------------------;


   %if &sysver<6.07 %then %do;
      %put NOTE: SYSVER=&sysver;
      %put NOTE: Macro PVLST requires version 6.07;
      %if &sysenv=BACK %then %do;
         %put NOTE: Ending SAS session due to errors;
         ;endsas;
         %end;
      %end;

   %local i;
   %if "&list"="" %then %do;
      %global &croot.0 &croot &nroot.0 &nroot;
      %let &croot.0 = 0;
      %let &nroot.0 = 0;
      data _null_;
         set &data;
         array _ary{*} _numeric_;
         array _bry{*} _character_;
         _xcl_ = upcase("&exclude");
         length _vname_ $8 _root_ $20 _label_ $40;
         _jj_ = 0;
         do _II_ = 1 to dim(_ary);
            call vname(_ary{_ii_},_vname_);
            if indexw(_xcl_,trim(_vname_)) then continue;
            _jj_ + 1;
            _root_ = "__pvn"!!left(put(_jj_,8.));
            call symput(_root_,trim(_vname_));

            call label(_ary{_ii_},_label_);
            _root_ = "__pvnl"!!left(put(_jj_,8.));
            call symput(_root_,trim(_label_));
            end;
         call symput("__pvn0",left(put(_jj_,8.)));
         _jj_ = 0;
         do _II_ = 1 to dim(_bry);
            call vname(_bry{_ii_},_vname_);
            if indexw(_xcl_,trim(_vname_)) then continue;
            _jj_ + 1;
            _root_ = "__pvc"!!left(put(_jj_,8.));
            call symput(_root_,trim(_vname_));

            call label(_bry{_ii_},_label_);
            _root_ = "__pvcl"!!left(put(_jj_,8.));
            call symput(_root_,trim(_label_));
            end;
         call symput("__pvc0",left(put(_jj_,8.)));
         stop;
         run;
      %if &syserr>0 %then %do;
         %put NOTE: SYSERR=&syserr;
         %put NOTE: Data step ERRORS in macro PVLST;
         %if &sysenv=BACK %then %do;
            %put NOTE: Ending SAS session due to errors;
            ;endsas;
            %end;
         %end;
      %let &nroot.0 = &__pvn0;
      %do i = 1 %to &__pvn0;
         %global &nroot&i &nroot.L&i;
         %let    &nroot&i   = &&&__pvn&i;
         %let    &nroot.L&i = &&&__pvnl&i;
         %let    &nroot = &&&nroot &&&__pvn&i;
         %end;
      %put NOTE: Numeric variables: &nroot=&&&nroot;
      %put NOTE: Macro variable array &nroot has &&&nroot.0 elements.;
      %let &croot.0 = &__pvc0;
      %do i = 1 %to &__pvc0;
         %global &croot&i &croot.L&i;
         %let    &croot&i   = &&&__pvc&i;
         %let    &croot.L&i = &&&__pvcl&i;
         %let    &croot = &&&croot &&&__pvc&i;
         %end;
      %put NOTE: Character variables: &croot=&&&croot;
      %put NOTE: Macro variable array &croot has &&&croot.0 elements.;
      %end;
   %else %do;
      %global &root.0 &root;
      %let &root.0 = 0;
      data _null_;
         set &data;
         array _ary{*} &list;
         _xcl_ = upcase("&exclude");
         length _vname_ $8 _root_ $20 _label_ $40;
         _jj_ + 0;
         do _II_ = 1 to dim(_ary);
            call vname(_ary{_ii_},_vname_);
            if indexw(_xcl_,trim(_vname_)) then continue;
            _jj_ + 1;
            _root_ = "__pvt"!!left(put(_jj_,8.));
            call symput(_root_,trim(_vname_));

            call label(_ary{_ii_},_label_);
            _root_ = "__pvtl"!!left(put(_jj_,8.));
            call symput(_root_,trim(_label_));
            end;
         call symput("__pvt0",left(put(_jj_,8.)));
         stop;
         run;
      %if &syserr>0 %then %do;
         %put NOTE: SYSERR=&syserr;
         %put NOTE: Data step ERRORS in macro PVLST;
         %if &sysenv=BACK %then %do;
            %put NOTE: Ending SAS session due to errors;
            ;endsas;
            %end;
         %end;
      %let &root.0 = &__pvt0;
      %do i = 1 %to &__pvt0;
         %global &root&i &root.L&i;
         %let    &root&i   = &&&__pvt&i;
         %let    &root.L&i = &&&__pvtl&i;
         %let    &root = &&&root &&&__pvt&i;
         %end;
      %put NOTE: Expanded varlist: &root=&&&root;
      %put NOTE: Macro variable array &root has &&&root.0 elements.;
      %end;
   %mend pvlst;
