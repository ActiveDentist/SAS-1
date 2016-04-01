%macro SIMTRI2(hr_a=,              /* Lambda from exp distn for active      */
               hr_c=,              /* Lambda from exp disnt for control     */
               censor=,            /* Median censoring time                 */
               a=,                 /* Intercept from PEST                   */
               c=,                 /* Slope from PEST                       */
               neg_v=,             /* Max V to show negative diff from PEST */
               lookat=,            /* # Events to trigger looks             */
               nostop=999999999,   /* Looks where trial will not be stopped */
               data=,              /* Output data set             */
               runs=100) ;         /* # of Trial runs */




%do run = 1 %to &runs ;

data trial ;

  censor = &censor ;
  look = 0 ;

  events = 0 ;

  do lookat = &lookat ;
    look + 1 ;
    call symput('LOOKS',compress(put(look,8.))) ;
    do while(events<lookat) ;

      active = ranbin(-1,1,0.5) ;
      if active then time = ranexp(-1)/&hr_a ;
      else           time = ranexp(-1)/&hr_c ;
      time = ceil(time) ;

      if time<=censor then do ;
        _cens_ = 0 ;
        _time_ = time ;
        events + 1 ;
      end ;
      else do ;
        _cens_ = 1 ;
        _time_ = censor ;
      end ;

      output ;

    end ;

  end ;

  run ;

data trial ;
  set %do i = 1 %to &looks ;
        trial(in=in&i where=(look<=&i))
      %end ;
      ;
  %do i = 1 %to &looks ;
    if in&i then look = &i ;
  %end ;
  keep look _cens_ _time_ active ;
  run ;

proc sort data=trial ;
  by look active ;
  run ;

proc summary data=trial ;
  by look active ;
  class _time_ _cens_ ;
  output out=temp ;
  run ;

data temp ;
  set temp(where=(_type_=0 | (_type_=1 & _cens_=0))) ;
  if _type_=0 then varname = 'N' || compress(put(active,1.)) ;
  else             varname = 'E' || compress(put(active,1.)) ;
  run ;

proc transpose data=temp out=temp ;
  by look ;
  var _freq_ ;
  id varname ;
  run ;

data trial ;
  merge trial temp ;
  by look ;
  run ;

proc sort data=trial ;
  by look _time_ _cens_ ;
  run ;

data trial ;
  set trial ;
  by look _time_ _cens_ ;

  retain i oiE oiC riE riC n_time0 n_time1 z_sum v_sum ;

  if first.look then do ;
    i = 0 ;
    riE = n1 ;
    riC = n0 ;
    z_sum = 0 ;
    v_sum = 0 ;
  end ;

  if first._time_ & _cens_ = 0 then do ;
    i + 1 ;
    oiE = 0 ;
    oiC = 0 ;
  end ;

  if _cens_=0 & active then oiE + 1 ;
  else if _cens_=0 & ~active then oiC + 1 ;

  if last._cens_ & _cens_ = 0 then do ;
    ri = riE + riC ;
    oi = oiE + oiC ;
    z_sum = z_sum + (oi*riC / ri) ;
    v_sum = v_sum + (
             oi*(ri - oi)*riE*riC/( (ri - 1) * ri*ri )
                    ) ;

  end ;

  if first._time_ then do ;
    n_time0 = 0 ;
    n_time1 = 0 ;
  end ;

  if active then n_time1 + 1 ;
  else           n_time0 + 1 ;

  if last._time_ then do ;
    riE = riE - n_time1 ;
    riC = riC - n_time0 ;
  end ;

  if last.look then do ;
    Z = e0 - z_sum ;
    V = v_sum ;
    output ;
  end ;

  run ;

data trial ;
  set trial end=eof ;

  hr_c  = &hr_c ;
  hr_a  = &hr_a ;
  a     = &a ;
  c     = &c ;
  neg_V = &neg_v ;
  run   = &run ;

  events = e0 + e1 ;

  retain vlast cutshort 0 ;

  * Calculate the upper and lower bounds of the triangle ;
  upper_z = a + (c*v) ;
  lower_z = (-1*a) + (3*c*v) ;

  * Calculate the Christmas Tree Correction ;
  aupper_z = upper_z - (.583*sqrt(v-vlast)) ;
  alower_z = lower_z + (.583*sqrt(v-vlast)) ;

  * Figure out if weve crossed a bound ;
  if (z>aupper_z | z<alower_z) & (e0+e1) ~in(&nostop) then do ;
    if z>aupper_z then reject = 1 ;
    else               reject = 0 ;
    if reject=0 & v<=neg_v then reject = -1 ;
    output ;
    stop ;
  end ;

  vlast = v ;

  if eof then do ;
    reject   = 0 ;
    cutshort = 1 ;
    output ;
  end ;

  keep a c neg_v hr_c hr_a run e0 e1 events z v reject cutshort ;
  run ;

data &data ;
  set %if &run>1 %then %do ; &data %end ;
      trial ;
  run ;

%end ;

%mend SIMTRI2 ;
