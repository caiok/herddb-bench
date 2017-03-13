.ONESHELL:

run-standalone:
	set -xeu
	$(eval include conf/standalone.conf)
	mkdir -p $(LOCAL_DIR)
	docker rm -f herddb || true
	make run-herd

run-ycsb-standalone:
	set -xeu
	$(eval include conf/standalone.conf)
	
	for workload in $(shell ls ycsb/workloads); do
	    make run-standalone
	    
	    docker exec -it $(CONTAINER_NAME) \
			/bin/bash /opt/herddb/bin/herddb-cli.sh -x jdbc:herddb:server:localhost:7000 -q 'select * from sysnodes'
	
#~ 		herddb-cli.sh -x jdbc:herddb:server:$(CONTAINER_NAME):7000 -sc <<- "EOF"
#~ 			CREATE TABLE usertable (
#~ 				YCSB_KEY VARCHAR(191) NOT NULL,
#~ 				FIELD0 TEXT, FIELD1 TEXT,
#~ 				FIELD2 TEXT, FIELD3 TEXT,
#~ 				FIELD4 TEXT, FIELD5 TEXT,
#~ 				FIELD6 TEXT, FIELD7 TEXT,
#~ 				FIELD8 TEXT, FIELD9 TEXT,
#~ 			       PRIMARY KEY (YCSB_KEY)
#~ 			    );
#~ 			EOF
	done
