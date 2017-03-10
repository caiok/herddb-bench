	
run-standalone:
	$(eval include conf/standalone.conf)
	mkdir -p $(LOCAL_DIR)
	-docker rm -f herddb
	docker run -it -d \
	    --name $(CONTAINER_NAME) \
	    --hostname $(CONTAINER_NAME) \
	    -v $(LOCAL_DIR):/data \
	    -e PURGE_DATA_AT_START=true \
	    -e HERD_PORT=$(HERD_PORT) \
	    -e HERD_MODE=$(HERD_MODE) \
	    -e HERD_NODE_ID=$(HERD_NODE_ID) \
	    -e HERD_SSL=$(HERD_SSL) \
	    -e ZK_SERVERS=$(ZK_SERVERS) \
	    -e BK_START=$(BK_START) \
	    -e BK_PORT=$(BK_PORT) \
	    -e BK_ENSAMBLE_SIZE=$(BK_ENSAMBLE_SIZE) \
	    -e BK_WRITE_QUORUM_SIZE=$(BK_WRITE_QUORUM_SIZE) \
	    -e BK_ACKQUORUM_SIZE=$(BK_ACKQUORUM_SIZE) \
	    $(DOCKER_IMAGE)

.ONESHELL:
run-ycsb-standalone:
	$(eval include conf/standalone.conf)
	
	set -xe
	for i in $(shell ls ycsb/workloads); do
	    make run-standalone
	    
	    docker exec -it $(CONTAINER_NAME) \
		herddb-cli.sh -x jdbc:herddb:server:$(CONTAINER_NAME):7000 -q "select * from sysnodes"
	
#		herddb-cli.sh -x jdbc:herddb:server:$(CONTAINER_NAME):7000 -sc <<- "EOF"
#		CREATE TABLE usertable (
#			YCSB_KEY VARCHAR(191) NOT NULL,
#			FIELD0 TEXT, FIELD1 TEXT,
#			FIELD2 TEXT, FIELD3 TEXT,
#			FIELD4 TEXT, FIELD5 TEXT,
#			FIELD6 TEXT, FIELD7 TEXT,
#			FIELD8 TEXT, FIELD9 TEXT,
#		       PRIMARY KEY (YCSB_KEY)
#		    );
#		EOF
	done