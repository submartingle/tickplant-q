//a simple feedhandler
//the mathematical functions are taken from Q Tips by Nick Psaris


ticklist:`AAPL`NOV`NVDA`PFE`GME
vol:0.26 0.35 0.35 0.25 0.66 
r:0.045
S0:201.53 69.91 143.84 24.02 22.98
p:S0

/ horner's method
/ x:coefficients, y:data
horner:{{z+y*x}[y]/[x]}

/ exponentially weighted moving average
/ x:decay rate, y:data
ewma:{first[y](1f-x)\x*y}

/ central region - normal inverse
cnorminv:{
 a:-25.44106049637 41.39119773534 -18.61500062529 2.50662823884;
 b: 3.13082909833 -21.06224101826 23.08336743743
   -8.47351093090 1;
 x*:horner[a;s]%horner[b] s:x*x-:.5;
 x}

/ tail region - normal inverse
tnorminv:{
 a:0.0000003960315187 0.0000002888167364 0.0000321767881768
   0.0003951896511919 0.0038405729373609 0.0276438810333863
   0.1607979714918209 0.9761690190917186 0.3374754822726147;
 x:horner[a] log neg log 1f-x;
 x}

/ beasley-springer-moro normal inverse approximation
norminv:{
 i:x<.5;
 x:?[i;1f-x;x];
 x:?[x<.92;cnorminv x;tnorminv x];
 x:?[i;neg x;x];
 x}
 
\t 15000 
/convert interval to annualized delta t
dt:system"t"
dt:dt%1000*3600*24*252


/(s)igma, (r)ate, (t)ime, z:uniform random
/user multiplies by price
gbm:{[r;t;s;z]exp (t*r-.5*s*s)+z*s*sqrt t};
rng:{x+rand[y-x]};
tickrnd:{y:x*floor y%x};
l:count ticklist;
scaling:500;
seqNum:0;



genTrade:{p::p*'('[gbm[r;dt;;]][vol;norminv l?1f]);
          trade:scaling#([]id:seqNum+til l;time:l#.z.P;sym:ticklist;price:tickrnd[0.01;]@/:p;tsize:l?rng[300;800]);
		  seqNum+:l; trade}


h:hopen `:localhost:5010
.z.ts:{neg[h](`.u.upd; `trades; genTrade[])}


