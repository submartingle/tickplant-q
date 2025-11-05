/q tick/r.q [host]:port[:usr:pwd] [host]:port[:usr:pwd]  

.stat.msgCount:0;
.stat.reportinterval:10000000000;  / seconds
.stat.startTime:.stat.lastReport:.z.P;
.stat.throughput:0b;

.latency.latency:([]id:`long$();fhTime:"p"$();tpTime:"p"$();rdbTime:"p"$());
.latency.stats:([]id:`long$();recTime:"p"$();latency_FH:`int$();latency_TP:`int$());
.latency.sampleRate:0.1

upd:{[t;x] 
    $[t~`OHLC;.[t;();,;x]; t insert x];
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
	([]route:`FH_RDB`TP_RDB),'(flip r1,'r2)}

\d .u
eod:{:()}  /not doing end of day process for now
x:.z.x,(count .z.x)_(":5010";":5012");
rep:{(.[;();:;].)each x;
     if[null first y; :()];
	 -11!y;
     system "cd ",1_-10_string first reverse y;
    }

\d .

.u.rep .(hopen `$":",.u.x 0)"(.u.sub[`;`];`.u `i`L)"; 

