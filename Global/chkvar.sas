/*
/ Program Name:     CHKVAR.SAS
/
/ Program Version:  2.1
/
/ Program purpose:  Check if variables are in a data set.
/
/ SAS Version:      6.12
/
/ Created By:       Carl P. Arneson
/ Date:             26 Mar 1993
/
/ Input Parameters: VAR  - List of variables to be processed.
/                   FLAG - List of corresponding flag variables.
/
/ Output Created:   Flag variables are assigned a value 1 if the corresponding variable
/                   is initialized.
/
/ Macros Called:    None.
/
/ Example Call:     %chkvar(var=name age var1 var3,flag=fname fage fvar1 fvar3);
/
/================================================================================================
/ Change Log
/
/    MODIFIED BY: Jonathan Fry
/    DATE:        09DEC1998
/    MODID:       JMF001
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 2.1.
/    ---------------------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX002
/    DESCRIPTION:
/    ---------------------------------------------------------------------------------
/=================================================================================================*/

%macro chkvar(var=,flag=) ;

  %local vcnt v fcnt f ;
  %let vcnt = 1 ;
  %let v = %upcase(%scan(&var,&vcnt,%str( ))) ;
  %do %while(&v~= ) ;
    %local v&vcnt ;
    %let v&vcnt = &v ;
    %let vcnt = %eval(&vcnt + 1) ;
    %let v = %upcase(%scan(&var,&vcnt,%str( ))) ;
  %end ;
  %let vcnt = %eval(&vcnt - 1) ;

  %let fcnt = 1 ;
  %let f = %upcase(%scan(&flag,&fcnt,%str( ))) ;
  %do %while(&f~= ) ;
    %local f&fcnt ;
    %let f&fcnt = &f ;
    %let fcnt = %eval(&fcnt + 1) ;
    %let f = %upcase(%scan(&flag,&fcnt,%str( ))) ;
  %end ;
  %let fcnt = %eval(&fcnt - 1) ;

  %local mincnt ;
  %if &fcnt ~= &vcnt %then %do ;
    %put WARNING: Number of flags does not equal number of variables. ;
    %if &fcnt<&vcnt %then %let mincnt = &fcnt ;
    %else %let mincnt = &vcnt ;
  %end ;
  %else %let mincnt = &fcnt ;

  %if &mincnt=0 %then %do ;
    %put WARNING:  No VAR= or FLAG= has been specified, macro will end.;
    %goto finish ;
  %end ;

  array _c_v_a_r {*} _character_ _c_d_u_m ;
  array _n_v_a_r {*} _numeric_ _n_d_u_m ;
  drop _c_n_t_ _f_l_a_g _v_n_a_m _n_d_u_m _c_d_u_m ;
  length _v_n_a_m $30 ;
  retain _f_l_a_g 1 &flag 0 ;
  if _f_l_a_g then do ;
    do _c_n_t_ = 1 to (dim(_c_v_a_r)-1) ;
       call vname(_c_v_a_r{_c_n_t_},_v_n_a_m) ;
       select (upcase(_v_n_a_m)) ;
         %do i = 1 %to &mincnt ;
           when (upcase("&&v&i")) &&f&i = 1 ;
         %end ;
         otherwise ;
       end ;
    end ;
    do _c_n_t_ = 1 to (dim(_n_v_a_r)-1) ;
       call vname(_n_v_a_r{_c_n_t_},_v_n_a_m) ;
       select (upcase(_v_n_a_m)) ;
         %do i = 1 %to &mincnt ;
           when (upcase("&&v&i")) &&f&i = 1 ;
         %end ;
         otherwise ;
       end ;
    end ;
    _f_l_a_g = 0 ;
  end ;

  %finish :
%mend chkvar ;
