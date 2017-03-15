.ONESHELL:

run-standalone:
	set -xeu
	$(eval include conf/standalone.conf)
	make run-herd


herd-shell-standalone:
	set -xeu
	$(eval include conf/standalone.conf)
	docker exec -i $(CONTAINER_NAME) \
	    /bin/bash /opt/herddb/bin/herddb-cli.sh -x jdbc:herddb:server:localhost:$(HERD_PORT) -sc


run-ycsb-standalone:
	set -xeu
	$(eval include conf/standalone.conf)
	
	mkdir -p $(REPORT_DIR)
	cp ycsb/herd.properties $(REPORT_DIR)/
	make export-vars DEST_DIR=$(REPORT_DIR)
	sed -i -e 's|@@TYPE@@|server|g' \
	       -e 's|@@PORT@@|$(HERD_PORT)|g' \
	       -e 's|@@HOST@@|localhost|g' \
	    $(REPORT_DIR)/herd.properties
	
	for workload in $(shell ls ycsb/workloads.torun); do
		
		set +x
		@echo
		@echo "======================================"
		@echo "  Running workload " $${workload}
		@echo "======================================"
		@echo
		set -x
	
		make run-standalone

		sleep 2

		docker exec -i $(CONTAINER_NAME) \
		    /bin/bash /opt/herddb/bin/herddb-cli.sh -x jdbc:herddb:server:localhost:$(HERD_PORT) -q \
			"CREATE TABLE usertable ( YCSB_KEY VARCHAR(191) NOT NULL, FIELD0 STRING, FIELD1 STRING, FIELD2 STRING, FIELD3 STRING, FIELD4 STRING, FIELD5 STRING, FIELD6 STRING, FIELD7 STRING, FIELD8 STRING, FIELD9 STRING, PRIMARY KEY (YCSB_KEY));"

		mkdir -p $(REPORT_DIR)/$${workload}

		$(YCSB_DIR)/bin/ycsb load jdbc -s  \
		-P ycsb/workloads/$${workload} \
		-P $(REPORT_DIR)/herd.properties \
		-cp ycsb/jdbc-binding/herddb-jdbc-*.jar \
		-threads $(THREADS_NUMBER) \
		-p recordcount=$(RECORD_COUNT) \
		> $(REPORT_DIR)/$${workload}/herddb-$${workload}.load.run

		$(YCSB_DIR)/bin/ycsb run jdbc -s \
		-P ycsb/workloads/$${workload} \
		-P $(REPORT_DIR)/herd.properties \
		-cp ycsb/jdbc-binding/herddb-jdbc-*.jar \
		-threads $(THREADS_NUMBER) \
		-p operationcount=$(OPERATION_COUNT) \
		-target $(OPERATION_COUNT) \
		> $(REPORT_DIR)/$${workload}/herddb-$${workload}.run.run

		# Debug
		#break

	done
