DOCKER_IMAGE_NAME?=local/yugabyte
ENVOY_DOCKER_IMAGE_NAME?=local/envoy-thin
TOOLS_DOCKER_IMAGE_NAME?=local/yugabyte-tools
DOCKER_IMAGE_TAG?=2.13.0.0-b42
ENVOY_DOCKER_IMAGE_TAG?=v1.21.1

TOOLS_BASE_DOCKER_IMAGE_NAME?=yugabytedb/yugabyte
TOOLS_BASE_DOCKER_IMAGE_TAG?=$(DOCKER_IMAGE_TAG)

CURRENT_DIR=$(dir $(realpath $(firstword $(MAKEFILE_LIST))))

MEM_TRACKER_MASTER_MEMORY?=512
MEM_TRACKER_MASTER_RATIO?=0.9
MEM_TRACKER_TSERVER_MEMORY?=2048
MEM_TRACKER_TSERVER_RATIO?=0.9

.PHONY: docker-envoy-image
docker-envoy-image:
	docker build -t $(ENVOY_DOCKER_IMAGE_NAME):$(ENVOY_DOCKER_IMAGE_TAG) -f $(CURRENT_DIR)/.docker/envoy/Dockerfile $(CURRENT_DIR)/.docker/envoy/

.PHONY: docker-image-postgis
docker-image-postgis:
	docker build -t $(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)-postgis -f $(CURRENT_DIR)/.docker/yugabyte-db/Dockerfile.postgis $(CURRENT_DIR)/.docker/yugabyte-db/

.PHONY: docker-image-postgis32
docker-image-postgis32:
	docker build -t $(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)-postgis32 -f $(CURRENT_DIR)/.docker/yugabyte-db/Dockerfile.postgis32 $(CURRENT_DIR)/.docker/yugabyte-db/

.PHONY: docker-image-uid
docker-image-uid:
	docker build -t $(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG) -f $(CURRENT_DIR)/.docker/yugabyte-db/Dockerfile.uid $(CURRENT_DIR)/.docker/yugabyte-db/

.PHONY: docker-image-upstream
docker-image-upstream:
	docker build -t $(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG) -f $(CURRENT_DIR)/.docker/yugabyte-db/Dockerfile.upstream $(CURRENT_DIR)/.docker/yugabyte-db/

.PHONY: docker-image-tools
docker-image-tools:
	docker run --rm \
    	-v $(CURRENT_DIR)/.docker/yugabyte-tools/prepare-tools.sh:/tmp/prepare-tools.sh \
    	-v $(CURRENT_DIR)/.docker/yugabyte-tools/tools:/tools \
    	--entrypoint /tmp/prepare-tools.sh \
    	-ti ${TOOLS_BASE_DOCKER_IMAGE_NAME}:${TOOLS_BASE_DOCKER_IMAGE_TAG} \
	&& docker build --no-cache -t $(TOOLS_DOCKER_IMAGE_NAME):${DOCKER_IMAGE_TAG} $(CURRENT_DIR)/.docker/yugabyte-tools/

.PHONY: mem-tracker-settings-master
mem-tracker-settings-master:
	$(eval $@_BYTES_MEM := $(shell echo - | awk 'BEGIN {printf("%d", $(MEM_TRACKER_MASTER_MEMORY) * 1024 * 1024 * $(MEM_TRACKER_MASTER_RATIO))}'))
	$(eval $@_SOFT_LIMIT := $(shell echo - | awk 'BEGIN {printf("%d", $(MEM_TRACKER_MASTER_RATIO) * 100)}'))
	$(eval $@_WARN_LIMIT := $(shell echo - | awk 'BEGIN {printf("%d", $($@_SOFT_LIMIT) * 1.05)}'))
	@echo YB_RESOURCES_MEM_RESERVATION_MASTER=$(MEM_TRACKER_MASTER_MEMORY)
	@echo YB_MEMORY_LIMIT_HARD_BYTES_MASTER=$($@_BYTES_MEM)
	@echo YB_MEMORY_DEFAULT_LIMIT_TO_RAM_RATIO_MASTER=$(MEM_TRACKER_MASTER_RATIO)
	@echo YB_MEMORY_LIMIT_SOFT_PERCENTAGE_MASTER=$($@_SOFT_LIMIT)
	@echo YB_MEMORY_LIMIT_WARN_THRESHOLD_PERCENTAGE_MASTER=$($@_WARN_LIMIT)

.PHONY: mem-tracker-settings-tserver
mem-tracker-settings-tserver:
	$(eval $@_BYTES_MEM := $(shell echo - | awk 'BEGIN {printf("%d", $(MEM_TRACKER_TSERVER_MEMORY) * 1024 * 1024 * $(MEM_TRACKER_TSERVER_RATIO))}'))
	$(eval $@_SOFT_LIMIT := $(shell echo - | awk 'BEGIN {printf("%d", $(MEM_TRACKER_TSERVER_RATIO) * 100)}'))
	$(eval $@_WARN_LIMIT := $(shell echo - | awk 'BEGIN {printf("%d", $($@_SOFT_LIMIT) * 1.05)}'))
	@echo YB_MEMORY_LIMIT_HARD_BYTES_TSERVER=$($@_BYTES_MEM)
	@echo YB_MEMORY_DEFAULT_LIMIT_TO_RAM_RATIO_TSERVER=$(MEM_TRACKER_TSERVER_RATIO)
	@echo YB_MEMORY_LIMIT_SOFT_PERCENTAGE_TSERVER=$($@_SOFT_LIMIT)
	@echo YB_MEMORY_LIMIT_WARN_THRESHOLD_PERCENTAGE_TSERVER=$($@_WARN_LIMIT)
