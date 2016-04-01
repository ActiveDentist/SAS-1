%macro SIMTRI2(lamda_a=,
               lamda_c=,
               censor=,
               a=,
               c=,
               neg_v=,
               lookat=,
               nostop=999999999,
               data=,
               runs=100) ;

data &data ;


  pc = &pc ;
  pa = &pa ;
  a = &a ;
  c = &c ;
  neg_v = &neg_v ;

  do run = 1 to &runs ;

    vlast = 0 ;
    nlast = 0 ;
    eventsc = 0 ;
    eventsa = 0 ;
    cutshort = 0 ;
    do n = &lookat ;

      _n = n/2 ;
      newn = (n - nlast) / 2 ;

      * Randomly generate the number of events since last check ;
      eventsc = eventsc + ranbin(-1,newn,pc) ;
      eventsa = eventsa + ranbin(-1,newn,pa) ;

      z = (_n*(_n - eventsa) - _n*(_n - eventsc)) / n ;
      v = (_n*_n*(n - eventsc - eventsa)*(eventsc+eventsa)) / n**3 ;

      * Calculate the upper and lower bounds of the triangle ;
      upper_z = a + (c*v) ;
      lower_z = (-1*a) + (3*c*v) ;

      * Calculate the Christmas Tree Correction ;
      aupper_z = upper_z - (.583*sqrt(v-vlast)) ;
      alower_z = lower_z + (.583*sqrt(v-vlast)) ;

      * Figure out if weve crossed a bound ;
      if (z>aupper_z | z<alower_z) & n ~in(&nostop) then do ;
        if z>aupper_z then reject = 1 ;
        else               reject = 0 ;
        if reject=0 & v<=neg_v then reject = -1 ;
        output ;
        goto exitloop ;
      end ;

      nlast = n ;
      vlast = v ;

    end ;

    n = nlast ;
    reject   = 0 ;
    cutshort = 1 ;

    output ;

    exitloop:

  end ;
  keep a c neg_v pa pc run eventsc eventsa z v n reject cutshort ;
  run ;


%mend SIMTRI2 ;

