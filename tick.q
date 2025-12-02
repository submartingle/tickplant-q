system"l tick/",(src:first .z.x,enlist"sym"),".q"  

if[not system"p";system "p 5010"]

\l tick/u.q



\d .u

logBuffer:0#value `..trades;


tick:{[sch;logf]
	  /check all tables have the first three fields as id,time,sym
	  if[not min(`id`time`sym ~3#key flip value @)each lst:((tables `.) except `cons`latency);
	     '"first three columns are not `id`time`sym"];
	  @[;`sym;`g#] each lst;
	  d::.z.D;
	 /create log file path
	  if[count logf;
	   logpath::`$":",logf,"/",sch,10#".";
	   l::ld d];
	   
	  }
	  
ld:{if[not type key L::`$(-10_string logpath),"_", string x;   /x is the date
    .[L;();:;()]];  / create the logfile
    i::j::-11!(-2;L);
    if[1<count i;
	 -2 (string L)," is a corrupt log. Truncate to length ",(string last i)," and restart";
     exit 1];
	 hopen L}



upd:{[t;x]
	  pub[t;x];
	  `.u.logBuffer upsert x;
	 }

	  
ts:{if[x>d;if[d<x-1;system"t 0";'"more than one day?"];eod[]]} 
if[not system"t";system "t 2000"]  
.z.ts:{ts .z.D;
    if[l & h:count .u.logBuffer;
	  l enlist (`upd;`trades;.u.logBuffer);  / table name is hard coded
	  .u.i:.u.i+1;  / i total number of valid chunks   
	 delete from `.u.logBuffer;]
	}	  
	

\d .
.u.tick[src;.z.x 1];
