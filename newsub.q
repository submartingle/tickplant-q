
.latency.latency:([]id:`long$();fhTime:"p"$();tpTime:"p"$();rdbTime:"p"$());
.latency.stats:([]id:`long$();recTime:"p"$();latency_FH:`int$();latency_TP:`int$());
.latency.sampleRate:0.1;

.stat.msgCount:0;
.stat.reportinterval:10000000000;  / seconds
.stat.startTime:.stat.lastReport:.z.P;
.stat.throughput:1b;

sub:{[tab;s;TPhandle]
    if[not `h in key `.; 0N!h::hopen `$"::", string TPhandle;]; /use 5010 for TP port
   t:h (`.u.sub;tab;s);
   :value (t 0) set (t 1);}



upd:{[t;x]
    t insert x;
	if[.stat.throughput;
		$[99h=type x;.stat.msgCount+:1;.stat.msgCount+:count x];
		if[.stat.reportinterval < .z.P - .stat.lastReport;
		elapsed:`int$(.z.P - .stat.lastReport) % 1000000000;  // seconds
		throughput:.stat.msgCount % elapsed;
		memUsed:.Q.w[][`used] % 4 xexp 10;
		-1 "Throughput: ",string[throughput]," rows/sec";
		-1 "Memory used: ", string[memUsed]," MB  ";
		.stat.lastReport:.z.P;
		.stat.msgCount:0]]
	}

.latency.upd:{[t;x]
    x:update rdbTime:.z.P from x;
	t insert x;
	if[.latency.sampleRate > rand 1.0;
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
    latency_TR: asc (.latency.stats`latency_FH)-(.latency.stats`latency_TP);
    r3:`p50`p95`p99`maxlat`minlat`avglat!(latency_TR  floor 0.5*num;latency_TR  floor 0.95*num;latency_TR  floor 0.99*num; max latency_TR;min latency_TR;avg latency_TR);
	([]route:`FH_RDB`TP_RDB`FH_TP),'(flip r1,'r2,'r3)}
	

del:{[tab] h (`.u.del;tab;0N!.z.w)}  /if current subscription is subscribing to all tickers `, call del first and then sub with new tickers (for reduced set)


   
sub[`trades;`;5010]


	
