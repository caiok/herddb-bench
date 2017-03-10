include conf/config.conf
include targets/*

.ONESHELL:
build-herd:
	set -x
	cd herddb-bench-docker
	mkdir -p build
	rm -vf build/*.zip
	cp -vf $(HERD_ZIP) build/
	ls build/*.zip | sed -r 's|^.*herddb-services-(.+).zip$$|HERD_VERSION=\1|' > build/herd.version
	cat build/herd.version
	source build/herd.version
	docker build \
	    -t $(DOCKER_IMAGE):$$HERD_VERSION \
	    -t $(DOCKER_IMAGE):latest \
	    .
