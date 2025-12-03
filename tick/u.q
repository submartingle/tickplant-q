//utility functions for tickerplant


\d .u
init:{w::t!(count t::(tables[] except `latency))#()}   

add:{[tab;s]
    if[`~tab;:"emptytablename"];
     $[not .z.w in raze w[tab;;0];
	    w[tab],:enlist (.z.w;s);
		[i:w[tab;;0]?.z.w; $[`~s; [w[tab] _: i;add[tab;s]];if[not `~w[tab;i;1];.[`.u.w;(tab;i;1);union;s]]]]]; /need to apply to w symbol to persist the change
        /no need to check if any s in the table as tables are dynamically updated and can contain new symbols and client can add subscription before new symbol arrives
	   (tab;$[99=type v:value tab;select from tab where sym in s;@[0#v;`sym;`g#]])
	   }
     

del:{[tab;h]
      w[tab] _: w[tab;;0]?h}
	  
.z.pc:{[h]  del[;h]each key w}


pub:{[tab;x]
       {[tab;x;c] 
	   /c is the subscriber list
	   tb:$[type x;x;flip (cols tab)!x];
	   / if x is general list, add col headers else if dict or tables pass it
	   
	   msglat:distinct x;
	   lat:([]id:msglat`id;fhTime:msglat`time;tpTime:.z.P;rdbTime:0Np);

	   $[`~c 1; neg[c 0] (`upd;tab;tb); if[count d:select from tb where sym in c 1; neg[c 0] (`upd;tab;d)]];
	   neg[c 0] (`.latency.upd;`.latency.latency;lat);
	   }[tab;x;] each w tab	   
	   / send latency
	   
	   
	  }



sub:{[tab;s] 
    if[tab~`;:sub[;s] each t];
    if[not tab in t;'tab];
	add[tab;s]}  //to add: provide users with two options: 1. overwrite the ticker  2. append the ticker
		
