.PHONY: build-dev build-test push-release release shell test test-credo test-format

HTTP_PORT = 8880
CDDBP_PORT = 8888
APP = cdigw
DOCKER_ORG = retrobridge
TAG = $(APP)
GIT_COMMIT = $(shell git rev-parse --verify --short HEAD)

build-dev:
	docker build --target dev -t $(TAG) .

shell: build-dev
	docker run --rm -it \
		-v $(PWD)/src:/opt/app \
		-p $(HTTP_PORT):80 \
		-p $(CDDBP_PORT):888 \
		$(TAG) bash

test: build-dev
	docker run --rm -v $(PWD)/src:/opt/app -e MIX_ENV=test $(TAG) mix do ecto.migrate, test

test-format: build-dev
	docker run --rm -v $(PWD)/src:/opt/app $(TAG) mix format --check-formatted

test-credo: build-dev
	docker run --rm -v $(PWD)/src:/opt/app $(TAG) mix credo --strict

release:
	@echo Building version $(GIT_COMMIT)
	docker build \
		--label "org.opencontainers.image.created=$(shell date --utc --rfc-3339=seconds)" \
		--label "org.opencontainers.image.revision=$(GIT_COMMIT)" \
		--target release \
		--tag $(DOCKER_ORG)/$(APP):$(GIT_COMMIT) .
	docker tag $(DOCKER_ORG)/$(APP):$(GIT_COMMIT) $(DOCKER_ORG)/$(APP):latest

push-release: release
	docker push $(DOCKER_ORG)/$(APP):$(GIT_COMMIT)
	docker push $(DOCKER_ORG)/$(APP):latest
