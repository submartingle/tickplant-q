/q tick/hdb.q sym -p 5012

if[1>count .z.x;show"provide directory of historical database";exit 0];
hdb:.z.x 0
@[{system "l ",x};hdb;{show "error -",x;exit 0}]
