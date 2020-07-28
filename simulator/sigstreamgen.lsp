(osql "

create function drand(Number a, Number b)-> Number 
as if (a=b) then return a else return (a + (rand(a, b)/b)*(b-a));

create function drand(Number a)-> Number 
as if (a=0) then return 0.0 else return ((rand(a)/a)*(a));

create function frandom(Number upper) -> Number
  as drand(upper*1000)/1000.0;

create function frandom(number lower, Number upper) -> Number
  as lower+frandom(upper-lower);

create function randombag(Number lower, Number upper, Number points) 
                        -> Bag of Number
  as for each Integer i where i in iota(1,points)
     return frandom(lower, upper);

create function randomStream(Number lower, Number upper, Number points)
                           -> Stream of Number
  as streamof(randombag(lower, upper, points));

")

