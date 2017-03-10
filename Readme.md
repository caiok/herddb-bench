## Herdb tips

Connettersi ad herddb standalone:
```
bin/herddb-cli.sh -x jdbc:herddb:server:localhost:7000 -sc
```

Connettersi ad herdb cluster:
```
bin/herddb-cli.sh -x jdbc:herddb:zookeeper:localhost:2181 -sc
```

Vedere lo stato del sistema:
```
select * from sysnodes
select * from systablespaces
select * from systablespacereplicastate
```
