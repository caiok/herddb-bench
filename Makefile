SHELL := /bin/bash

# Tells make to run as every variable definition was preceded by a "export"
export

include conf/config.conf
include targets/*

.ONESHELL:

build-herd:
	set -xeu
	cd herddb-bench-docker
	mkdir -p build
	rm -vf build/*.zip
	cp -vf $(HERD_ZIP) build/
	ls build/*.zip | sed -r 's|^.*herddb-services-(.+).zip$$|HERD_VERSION=\1|' > build/herd.version
	cat build/herd.version
	. build/herd.version
	docker build \
	    -t $(DOCKER_HERD_IMAGE):$$HERD_VERSION \
	    -t $(DOCKER_HERD_IMAGE):latest \
	    .

build-slave:
	set -xeu
	cd dind-ssh-docker
	docker build \
		-t $(DOCKER_SLAVE_IMAGE) \
		.

run-herd:
	set -xeu
	mkdir -p $(HERD_TMP_DATA_DIR)/$(CONTAINER_NAME)
	docker run -it -d \
	    --name $(CONTAINER_NAME) \
	    --hostname $(CONTAINER_NAME) \
	    -v $(HERD_TMP_DATA_DIR)/$(CONTAINER_NAME):/data \
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
	    -p $(HERD_PORT):$(HERD_PORT) \
	    $(DOCKER_HERD_IMAGE)

# Expects SSH_HOST=<host> as argument
run-herd-ssh:
	set -xeu
	if [[ "$(SSH_HOST)" == "" ]]; then echo "Need SSH_HOST"; exit 1; fi
	
	ssh -T root@$(SSH_HOST) <<- EOF
		mkdir -p $(HERD_TMP_DATA_DIR)/$(CONTAINER_NAME)
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
			-p $(HERD_PORT):$(HERD_PORT) \
			$(DOCKER_IMAGE)
	EOF 
	
# Expects SLAVE_NAME=<host>
run-herd-slave:	
	$(eval SSH_KEY := $(shell cat ~/.ssh/id_rsa.pub))
	set -xeu
	if [[ "$(SLAVE_NAME)" == "" ]]; then echo "Need SLAVE_NAME"; exit 1; fi
	
	docker rm -f pippo || true
	docker run -it -d \
		--name "$(SLAVE_NAME)" \
		--hostname "$(SLAVE_NAME)" \
		--privileged \
		-v /var/lib/docker:/var/lib/docker-ro:ro \
		-e SSH_KEY="$(SSH_KEY)" \
		$(DOCKER_SLAVE_IMAGE)
	
	sleep 4
	export ip=$$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' $(SLAVE_NAME))
	ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
		root@$${ip} docker info > /dev/null && echo "Test ok"
	
# Expects DEST_DIR=<dir>
export-vars:	
	set -xeu
	if [[ "$(DEST_DIR)" == "" ]]; then echo "Need DEST_DIR"; exit 1; fi
	
	cat <<- EOF > $(DEST_DIR)/parameters.conf
		HERD_BUILD_DIR=$(HERD_BUILD_DIR)
		HERD_ZIP=$(HERD_ZIP)
		HERD_TMP_DATA_DIR=$(HERD_TMP_DATA_DIR)

		DOCKER_HERD_IMAGE=$(DOCKER_HERD_IMAGE)
		DOCKER_SLAVE_IMAGE=$(DOCKER_SLAVE_IMAGE)

		HERD_PORT=$(HERD_PORT)

		YCSB_DIR=$(YCSB_DIR)


		CONTAINER_NAME=$(CONTAINER_NAME)

		REPORT_DIR=$(REPORT_DIR)

		HERD_MODE=$(HERD_MODE)
		HERD_NODE_ID=$(HERD_NODE_ID)
		HERD_SSL=$(HERD_SSL)
		ZK_SERVERS=$(ZK_SERVERS)
		BK_START=$(BK_START)
		BK_PORT=$(BK_PORT)
		BK_ENSAMBLE_SIZE=$(BK_ENSAMBLE_SIZE)
		BK_WRITE_QUORUM_SIZE=$(BK_WRITE_QUORUM_SIZE)
		BK_ACKQUORUM_SIZE=$(BK_ACKQUORUM_SIZE)

		THREADS_NUMBER=$(THREADS_NUMBER)
		RECORD_COUNT=$(RECORD_COUNT)
		OPERATION_COUNT=$(OPERATION_COUNT)
	EOF