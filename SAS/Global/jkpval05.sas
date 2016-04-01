/*
/ PROGRAM NAME: jkpval05.sas
/
/ PROGRAM VERSION: 1.0
/
/ PROGRAM PURPOSE: Macro used internally by standard macros to do various
/   statistical analysis using PROC FREQ.
/
/ SAS VERSION: 6.12
/
/ CREATED BY: John Henry King
/
/ DATE: FEB1997
/
/ INPUT PARAMETERS:
/
/ DATA=               Names the input data set.
/
/ OUT=                Names the output data set created by the macro.
/
/ BY=                 List of by variables
/
/ UNIQUEID=           UNIQUEID
/
/ ID=                 Names the variable that defines the pair groups when a
/                     pairwise analysis is requested.
/
/ CONTROL=            Names the stratification variable.
/
/ SCORES=             Specifies SCORES option for PROC FREQ.
/
/ TMT=                Treatment variable name.
/
/ RESPONSE=           Names the response variable that will form the COLUMNS of
/                     the frequency table.
/
/ WEIGHT=             Names the variable that contains the frequency counts
/                     needed to form the table. Used in WEIGHT statement in
/                     PROC FREQ.
/
/ DISCRETE=           List of 1 byte character discrete variables to be
/                     analyzed.
/
/ P_VALUE=            Specifices the type of p-value requested by the user.
/
/ VARTYPE=            Identifies the type of response variable. Discrete vs
/                     continious.
/
/ PAIRWISE=0          Boolean for pairwise analysis. 0=not 1=pairwise.
/
/ PRINT=NO            Print the output data set?
/
/ TMTDIFF=            Specifies the which value of TMT is the differences for a
/                     paired t-test. Used only when P_VALUE=PAIRED.
/
/ OUTPUT CREATED:
/ MACROS CALLED:
/ EXAMPLE CALL:
/==============================================================================
/ CHANGE LOG:
/
/ MODIFIED BY: John Henry King
/ DATE: 27FEB1997
/ MODID: JHK001
/ DESCRIPTION: Added option to allow PROC FREQ statement options  
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

%macro jkpval05(data=,
                 out=,
                  by=,
                  id=,
            uniqueid=,
             control=,
                 tmt=,
             tmtdiff=,
            response=,
              weight=,
              scores=TABLE,
             p_value=,
             vartype=,
            pairwise=0,
               print=NO,
            freqopts=NOPRINT); /* JHK001 */

      %local temp1 temp2;
      %let temp1 = _1_&sysindex;
      %let temp2 = _2_&sysindex;

      %let p_value = %upcase(&p_value);
      %let vartype = %upcase(&vartype);
      %let control = %upcase(&control);
      %let print   = %upcase(&print);

      %if "&print"="YES" | "&print"="1"
         %then %let print = 1;
         %else %let print = 0;

      /*
      / Set up PROC FREQ table statement options and output statement
      / options.  If the controlling variable is specified then the
      / pvalue will be CMH
      /------------------------------------------------------------------*/

      %local outopt probvr tblopt ptype l_var u_var onlypvar;


      %if "&vartype"="DISCRETE" %then %do;
         %if "&p_value"="CMH" | "&p_value"="CMHGA" %then %do;
            %let ptype    = CMHGA;
            %let tblopt   = CMH SCORES=&scores;
            %let outopt   = CMHGA;
            %let probvr   = P_CMHGA;
            %let onlypvar = 1;
            %end;
         %else %if "&p_value"="CMHRMS" %then %do;
            %let ptype    = CMHRMS;
            %let tblopt   = CMH2 SCORES=&scores;
            %let outopt   = CMHRMS;
            %let probvr   = P_CMHRMS;
            %let onlypvar = 1;
            %end;
         %else %if "&p_value"="CMHCOR" %then %do;
            %let ptype    = CMHCOR;
            %let tblopt   = CMH1 SCORES=&scores;
            %let outopt   = CMHCOR;
            %let probvr   = P_CMHCOR;
            %let onlypvar = 1;
            %end;
         %else %if "&p_value"="LGOR" %then %do;
            %let ptype    = LGOR;
            %let tblopt   = CMH;
            %let outopt   = LGOR;
            %let probvr   = _LGOR_;
            %let u_var    = U_LGOR;
            %let l_var    = L_LGOR;
            %let onlypvar = 0;
            %end;
         %else %if "&p_value"="CHISQ" %then %do;
            %let ptype    = CHISQ;
            %let tblopt   = CHISQ;
            %let outopt   = PCHI;
            %let probvr   = P_PCHI;
            %let onlypvar = 1;
            %end;
         %else %if "&p_value"="EXACT" %then %do;
            %let ptype    = EXACT;
            %let tblopt   = EXACT;
            %let outopt   = EXACT;
            %let probvr   = _EXACT_;
            %let onlypvar = 1;
            %if &sysver >= 6.10 %then %do;
               %let probvr = P_EXACT2;
               %end;
            %end;


         proc sort data=&data;
            by &by &id;
            run;

         /*
         %if 0 %then %do;
            title4 "DATA=DATA(&data) used by PROC FREQ";
            proc print data=&data;
               run;
            %end;
         */

         proc freq
               &freqopts   /* JHK001 */
               data = &data;
            by &by &id;
            tables &control * &tmt * &response / &tblopt;
            weight &weight;
            output out=&out &outopt;
            run;


         %if &print %then %do;
            title4 "DATA=OUT(&out)";
            proc print data=&out;
               run;
            %end;


         /*
         / Create _PTYPE_ and PROB from output dataset produced
         / by PROC FREQ.
         /----------------------------------------------------------------*/

         data &out;
            set &out;
            length _ptype_ _scores_ $8 prob 8;
            retain _ptype_ "&ptype" _scores_ "&scores";
            prob = &probvr;
            keep &by &id _ptype_ _scores_ prob &u_var &l_var;
            run;

         /*
         / Transpose again to get the paired Pvalues into one observation,
         / only if the pairwise options was used.
         /-----------------------------------------------------------------*/

         %if &pairwise %then %do;
            %if &onlypvar %then %do;
               proc transpose
                     prefix = P
                     data   = &out
                     out    = &out
                        (
                         drop   = _name_ _label_
                         rename = (P0_0 = PROB)
                        )
                     ;
                  by &by _ptype_ _scores_;
                  id &id;
                  var prob;
                  run;
               %end;

            %else %do;

               %local trn1 trn2 trn3;
               %let trn1 = TRN1_&sysindex;
               %let trn2 = TRN2_&sysindex;
               %let trn3 = TRN3_&sysindex;

               proc transpose
                     prefix = P
                     data   = &out
                     out    = trn1(drop=_name_ _label_)
                     ;
                  by &by _ptype_ _scores_;
                  id &id;
                  var prob;
                  run;

               proc transpose
                     prefix = L
                     data = &out
                     out  = trn2(drop=_name_ _label_)
                     ;
                  by &by _ptype_ _scores_;
                  id &id;
                  var &l_var;
                  run;

               proc transpose
                     prefix = U
                     data = &out
                     out  = trn3(drop=_name_ _label_)
                     ;
                  by &by _ptype_ _scores_;
                  id &id;
                  var &u_var;
                  run;


               data &out;
                  merge
                     trn1 trn2 trn3;
                  by &by _ptype_ _scores_;
                  run;

               /*
               title4 'DATA=MERGED TRN1 TRN2 TRN3';
               proc contents data=&out;
                  run;
               proc print data=&out;
                  run;
               */

               %end;
            %end;
         %end;

      %else %if "&vartype"="CONTINUE" %then %do;
         %if "&p_value" = "PAIRED" %then %do;

            %let ptype  = PAIRED;

            proc sort
                  data=&data(keep=&by &id &uniqueid &tmt &continue &control)
                  out =&temp1;
               by &by &id &uniqueid &tmt;
               run;
            proc transpose data=&temp1 out=&temp1 prefix=xxxxxx;
               by &by &id &uniqueid &control &tmt;
               var &continue;
               run;

            proc summary data=&temp1(where=(&tmt=&tmtdiff)) nway missing;
               class &by _name_ &id;
               var xxxxxx1;
               output out=&out(drop=_type_ _freq_)
                      prt=prob;
               run;

            data &out;
               set &out(rename=(_name_=_vname_));
               length _ptype_ _scores_ $8;
               retain _ptype_ "&ptype" _scores_ ' ';
               keep &by &id _vname_ _ptype_ _scores_ prob;
               run;

            proc delete data=&temp1;
               run;

            %end;

         %else %do;
            %let ptype  = VANELT;
            %let tblopt = CMH2 SCORES=MODRIDIT ;
            %let outopt = CMHRMS;
            %let probvr = P_CMHRMS;

            proc sort
                  data=&data(keep=&by &id &uniqueid &tmt &continue &control)
                  out =&temp1;
               by &by &id &uniqueid &control &tmt;
               run;
            proc transpose data=&temp1 out=&temp1 prefix=xxxxxx;
               by &by &id &uniqueid &control &tmt;
               var &continue;
               run;
            proc sort data=&temp1;
               by &by _name_ &id;
               run;

            proc freq &freqopts data=&temp1; /* JHK001 */
               by &by _name_ &id;
               tables &control * &tmt * xxxxxx1 / &tblopt;
               output out=&out &outopt;
               run;

            data &out;
               set &out(rename=(_name_=_vname_));
               length _ptype_ _scores_ $8 prob 8;
               retain _ptype_ "&ptype" _scores_ 'MODRIDIT';
               prob = &probvr;
               keep &by &id _vname_ _ptype_ _scores_ prob;
               run;

            %if &pairwise %then %do;
               proc transpose
                     prefix = P
                     data   = &out
                     out    = &out
                        (
                         drop   = _name_
                         rename = (p0_0=prob)
                        )
                     ;
                  by &by _vname_ _ptype_ _scores_;
                  id &id;
                  var prob;
                  run;
               %end;

            proc delete data=&temp1;
               run;
            %end;
         %end;

   %mend jkpval05;
