export SHELL=bash
# The expression below ensures that an IGNITION_VERSION is defined in the Dockerfile
export IGNITION_VERSION=$$(grep -Po '(?<=IGNITION_VERSION=\")((\d\.){2}\d+)(?=\")' Dockerfile)
# This version check leverages the above and aborts the build if not found
export IGNITION_VERSION_CHECK=if [ -z "${IGNITION_VERSION}" ]; then exit 1; fi
# Extract the IGNITION_RC_VERSION for release candidate, if applicable
IGNITION_RC_VERSION:=$$(grep -Po '(?<=IGNITION_RC_VERSION=\")((\d\.){2}\d+-rc\d)(?=\")' Dockerfile)
# Pull in base options (if called from this directory)
include .env

.build-ubi8-podman:
	@echo "======== BUILDING IGNITION IMAGE LOCALLY (SINGLE ARCHITECTURE) ========"
	$(IGNITION_VERSION_CHECK)
	podman build ${DOCKER_BUILD_OPTS} ${DOCKER_BUILD_ARGS} --format docker --build-arg BUILD_EDITION=STABLE -t ${BASE_IMAGE_NAME}:${IGNITION_VERSION} -f Dockerfile .

.build-ubi8:
	@echo "======== BUILDING IGNITION IMAGE LOCALLY (SINGLE ARCHITECTURE) ========"
	$(IGNITION_VERSION_CHECK)
	docker build ${DOCKER_BUILD_OPTS} ${DOCKER_BUILD_ARGS} --build-arg BUILD_EDITION=STABLE -t ${BASE_IMAGE_NAME}:${IGNITION_VERSION} -f Dockerfile .

.push-registry:
	@echo "======== PUSHING AND TAGGING IMAGES TO REGISTRY ========"
	docker push ${BASE_IMAGE_NAME}:${IGNITION_VERSION}
	docker tag ${BASE_IMAGE_NAME}:${IGNITION_VERSION} ${BASE_IMAGE_NAME}:8.1
	docker push ${BASE_IMAGE_NAME}:8.1
	docker tag ${BASE_IMAGE_NAME}:${IGNITION_VERSION} ${BASE_IMAGE_NAME}:latest
	docker push ${BASE_IMAGE_NAME}:latest
	@if [[ -n "${IGNITION_RC_VERSION}" ]]; then \
		docker push ${BASE_IMAGE_NAME}:${IGNITION_RC_VERSION} \
	fi

### BUILD TARGETS ###
all:
	@echo "Please specify a build target: build, multibuild, build-rc, multibuild-rc, build-nightly, multibuild-nightly"

build-ubi8-podman: .build-ubi8-podman
build-ubi8: .build-ubi8