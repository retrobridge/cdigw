.PHONY: build-base build-test push-release release shell test test-credo test-format

HTTP_PORT = 8880
CDDBP_PORT = 8888
ELIXIR_VER = 1.15
APP = cdigw
DOCKER_ORG = retrobridge
TAG = $(APP)_elixir_$(ELIXIR_VER)
GIT_COMMIT = $(shell git rev-parse --verify --short HEAD)

build-base:
	docker build --build-arg elixir_ver=$(ELIXIR_VER) --target base -t $(TAG) .

shell: build-base
	docker run --rm -it \
		-v $(PWD)/src:/opt/app \
		-p $(HTTP_PORT):80 \
		-p $(CDDBP_PORT):888 \
		$(TAG) bash

test: build-base
	docker run --rm -v $(PWD)/src:/opt/app -e MIX_ENV=test $(TAG) mix do ecto.migrate, test

test-format: build-base
	docker run --rm -v $(PWD)/src:/opt/app $(TAG) mix format --check-formatted

test-credo: build-base
	docker run --rm -v $(PWD)/src:/opt/app $(TAG) mix credo --strict

release:
	@echo Building version $(GIT_COMMIT)
	docker build \
		--build-arg elixir_ver=$(ELIXIR_VER) \
		--build-arg git_commit=$(GIT_COMMIT) \
		--target release \
		--tag $(DOCKER_ORG)/$(APP):$(GIT_COMMIT) .
	docker tag $(DOCKER_ORG)/$(APP):$(GIT_COMMIT) $(DOCKER_ORG)/$(APP):latest

push-release: release
	docker push $(DOCKER_ORG)/$(APP):$(GIT_COMMIT)
	docker push $(DOCKER_ORG)/$(APP):latest
