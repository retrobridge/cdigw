.PHONY: build-base build-test push-release release shell test test-credo test-format

HTTP_PORT = 8880
ELIXIR_VER = 1.10
APP = cdigw
DOCKER_ORG = retrobridge
TAG = $(APP)_elixir_$(ELIXIR_VER)
VERSION = $(shell cat VERSION)
GIT_COMMIT = $(shell git rev-parse --verify HEAD)

build-base:
	docker build --build-arg elixir_ver=$(ELIXIR_VER) --target base -t $(TAG) .

shell: build-base
	docker run --rm -it \
		-v $(PWD)/src:/opt/app \
		-p $(HTTP_PORT):80 \
		$(TAG) bash

test: build-base
	docker run --rm -v $(PWD)/src:/opt/app $(TAG) mix test

test-format: build-base
	docker run --rm -v $(PWD)/src:/opt/app $(TAG) mix format --check-formatted

test-credo: build-base
	docker run --rm -v $(PWD)/src:/opt/app $(TAG) mix credo --strict

release:
	@echo Building version $(VERSION)
	docker build \
		--build-arg elixir_ver=$(ELIXIR_VER) \
		--build-arg git_commit=$(GIT_COMMIT) \
		--build-arg app_version=$(VERSION) \
		--target release \
		--tag $(DOCKER_ORG)/$(APP):$(VERSION) .
	docker tag $(DOCKER_ORG)/$(APP):$(VERSION) $(DOCKER_ORG)/$(APP):latest

push-release: release
	docker push $(DOCKER_ORG)/$(APP):$(VERSION)
	docker push $(DOCKER_ORG)/$(APP):latest
