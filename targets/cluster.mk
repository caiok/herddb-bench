.ONESHELL:

run-cluster:
	set -xeu
	$(eval include conf/cluster.conf)
	
	docker rm -f $(ZOOKEEPER_CONTAINER) || true
	docker run -it -d \
	    --name "$(ZOOKEEPER_CONTAINER)" \
	    -p $(ZOOKEEPER_PORT):2181 \
	    zookeeper
	
	count=0
	for node in $(shell cat conf/cluster.hosts); do
		
		((count++)) || true
		if [[ $${count} -gt $(HERD_CLUSTER_SIZE) ]]; then
			break
		fi
	
		echo $${node}
		
		make run-herd-ssh \
		    SSH_HOST=$${node} \
		    HERD_HOST=$$(echo $${node} | awk -F'@' '{print $$2}') \
		    ZK_SERVERS=$(shell hostname):$(ZOOKEEPER_PORT)

	done


herd-shell-cluster:
	set -xeu
	$(eval include conf/cluster.conf)
	docker exec -i $(CONTAINER_NAME) \
	    /bin/bash /opt/herddb/bin/herddb-cli.sh -x jdbc:herddb:zookeeper:localhost:$(ZOOKEEPER_PORT) -sc


run-ycsb-cluster:
	set -xeu
	$(eval include conf/cluster.conf)
	
	mkdir -p $(REPORT_DIR)
	cp ycsb/herd.properties $(REPORT_DIR)/
	make export-vars DEST_DIR=$(REPORT_DIR)
	sed -i -e 's|@@TYPE@@|zookeeper|g' \
	       -e 's|@@PORT@@|$(ZOOKEEPER_PORT)|g' \
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
	
		make run-cluster

		sleep 2

		docker exec -i $(CONTAINER_NAME) \
		    /bin/bash /opt/herddb/bin/herddb-cli.sh -x jdbc:herddb:zookeeper:localhost:$(ZOOKEEPER_PORT) -q \
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
		break

	done
