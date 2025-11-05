/q tick.q SRC [DST] [-p 5010] [-o h]
system"l tick/",(src:first .z.x,enlist"sym"),".q"  / load table schema

if[not system"p";system "p 5010"]

//maintain table for connections
//cons:([handle:`long$()] user:`$(); connTime:`timestamp$()) 

\l tick/u.q



\d .u

logBuffer:0#value `..trades;


tick:{[sch;logf]
      init[];
	  /check all tables have the first three fields as id,time,sym
	  if[not min(`id`time`sym ~3#key flip value @)each lst:((tables `.) except `cons`latency);
	     '"first three columns are not `id`time`sym"];
	  /apply g to all syms
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
if[not system"t";system "t 2000"]  / FH call upd on TP which immediately publish data downstream no wait, to use batch mode use .z.ts (trigered when count >n or t= x)

.z.ts:{ts .z.D;
    if[l & h:count .u.logBuffer;
	  l enlist (`upd;`trades;.u.logBuffer);  / here table name is hard coded?
	  .u.i:.u.i+h;  /here i total number of rows not messages in the normal case  
	 delete from `.u.logBuffer;]
	}	  
	
/.z.po:{[h] `cons upsert (h;.z.u;.z.P)}
/.z.pc:{[h] delete from `cons where handle=h}

\d .
.u.tick[src;.z.x 1];
