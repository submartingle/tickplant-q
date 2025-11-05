//tickh:table for trade history
//calculate intra day variation and volatility

tickh:([sym:`u#`symbol$()]time:"p"$();open:"f"$();high:"f"$();low:"f"$();close:"f"$();volP:"f"$())
RV:([sym:`u#`symbol$()]time:"p"$();price:"f"$();tv:"f"$())
    
.latency.latency:([]id:`long$();fhTime:"p"$();tpTime:"p"$();rdbTime:"p"$())
.latency.stats:([]id:`long$();recTime:"p"$();latency_FH:`int$();latency_TP:`int$());
.latency.sampleRate:0.1

.stat.msgCount:0
.stat.reportinterval:10000000000  / seconds
.stat.startTime:.stat.lastReport:.z.P
.stat.throughput:0b;

\d .u

x:.z.x,(count .z.x)_(":5010";":5012");

PVol:{[x;y] sqrt (0.25*(r*r:log x%y))%(log 2)} /Parkinson intra-day vol estimator

rep:{ (.[;();:;].) x;
     if[null first y; :()];
	 ori_upd:get `..upd;
	 upd:insert;
	 -11!y; 
	 upd:ori_upd;
	 / or just change directory to .
	`tickh  upsert select time:max time, high:max price, low: min price, open:first price, close:last price by sym from `trades; 
    `RV upsert  select time:min time, price:last price, tv:sum (xexp[;2] 1_deltas log@) price by sym from `trades;
    `trades set 0#`trades;
    }



\d .

upd:{[tab;newtrades]     
	if[.stat.throughput;
		$[99h=type newtrades;.stat.msgCount+:1;.stat.msgCount+:count newtrades];
		if[.stat.reportinterval < .z.P - .stat.lastReport;
		elapsed:`int$(.z.P - .stat.lastReport) % 1000000000;  // seconds
		throughput:.stat.msgCount % elapsed;
		memUsed:.Q.w[][`used] % 4 xexp 10;
		-1 "Throughput: ",string[throughput]," rows/sec";
		-1 "Memory used: ", string[memUsed]," MB ";
		.stat.lastReport:.z.P;
		.stat.msgCount:0]]
	
      newtrades:distinct newtrades;
      tmp: 0!select itime:min newtrades`time, ntime:max newtrades`time, newhigh:max price, newlow: min price, newopen:first price,newclose:last price by sym from newtrades;
        updTable:(select from 0!tickh where sym in tmp`sym) uj tmp;
        ntab: select time:max ntime,open:first newopen^open,high:max(high,newhigh),low:min(low,newlow),close:last newclose, volP:.u.PVol[max(high,newhigh);min(low,newlow)]*sqrt 252 by sym from updTable;
         `tickh upsert ntab; 

        /note RV`time only updated for the first time a ticker is inserted, the initial timestamp is needed for intraday vol calc
        updRV:`time xasc (0!(select from RV where sym in newtrades`sym)) uj newtrades; 
		updRV[`tv]:0^updRV[`tv];
        ntabRV: select time:min time, price:last price, tv:(first tv)+sum (xexp[;2] 1_deltas log@) price by sym from updRV; 
        `RV upsert ntabRV;
		



      }
	  
getTV:{[s;t]; ts:(`second$t-RV[s;`time])%01:00:00;
         :sqrt RV[s;`tv]* 6.5%ts;}
                





.latency.upd:{[t;x]
    x:update rdbTime:.z.P^rdbTime from x;
	t insert x;
	if [.latency.sampleRate > rand 1.0;
		latencyfromFH:`int$((x`rdbTime)-x`fhTime)%1000;
		latencyfromTP:`int$((x`rdbTime)-x`tpTime)%1000;
		`.latency.stats insert ([]id:x`id;recTime:x`rdbTime;latency_FH:latencyfromFH;latency_TP:latencyfromTP);]
 }
 
.latency.report:{[]
    num:count .latency.stats;
	latency_FH: asc .latency.stats`latency_FH;
    r1:`p50`p95`p99`maxlat`minlat`avglat!(latency_FH  floor 0.5*num;latency_FH  floor 0.95*num;latency_FH  floor 0.99*num; max latency_FH;min latency_FH;avg latency_FH);
	latency_TP: asc .latency.stats`latency_TP;
	r2:`p50`p95`p99`maxlat`minlat`avglat!(latency_TP  floor 0.5*num;latency_TP  floor 0.95*num;latency_TP  floor 0.99*num; max latency_TP;min latency_TP;avg latency_TP);
	([]route:`FH_RDB`TP_RDB),'(flip r1,'r2)}


.u.rep .(hopen `$":",.u.x 0)"(.u.sub[`trades;`];`.u `i`L)";
.u.end:{0N!"End of Day ",string x; delete from `tickh;}


