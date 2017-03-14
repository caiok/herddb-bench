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
	
	mkdir -p reports
	
	for workload in $(shell ls ycsb/workloads); do
	    make run-standalone
	    
	    sleep 2
#	    docker exec -it $(CONTAINER_NAME) \
#			/bin/bash /opt/herddb/bin/herddb-cli.sh -x jdbc:herddb:server:localhost:7000 -q 'select * from sysnodes'
	
		docker exec -i $(CONTAINER_NAME) \
		    /bin/bash /opt/herddb/bin/herddb-cli.sh -x jdbc:herddb:server:localhost:7000 -q \
			"CREATE TABLE usertable ( YCSB_KEY VARCHAR(191) NOT NULL, FIELD0 STRING, FIELD1 STRING, FIELD2 STRING, FIELD3 STRING, FIELD4 STRING, FIELD5 STRING, FIELD6 STRING, FIELD7 STRING, FIELD8 STRING, FIELD9 STRING, PRIMARY KEY (YCSB_KEY));"
		
		$(YCSB_DIR)/bin/ycsb load jdbc \
		    -P ycsb/workloads/$${workload} \
		    -P ycsb/jdbc-binding/herd.properties \
		    -cp ycsb/jdbc-binding/herddb-jdbc-*.jar \
		    -threads $(THREADS_NUMBER) \
		    -s -p recordcount=$(OPERATION_COUNT) \
		    > reports/herddb-$${workload}.load.run

		$(YCSB_DIR)/bin/ycsb run jdbc \
		    -P ycsb/workloads/$${workload} \
		    -P ycsb/jdbc-binding/herd.properties \
		    -cp ycsb/jdbc-binding/herddb-jdbc-*.jar \
		    -threads $(THREADS_NUMBER) \
		    -s -p operationcount=$(OPERATION_COUNT) \
		    > reports/herddb-$${workload}.run.run

		# Debug
		break

	done
