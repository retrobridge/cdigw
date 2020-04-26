.PHONY: build-base build-test push-release release shell test test-credo test-format

HTTP_PORT = 8880
ELIXIR_VER = 1.10
APP = cdigw
TAG = $(APP)_elixir_$(ELIXIR_VER)
TAG_TEST = $(TAG)_test
VERSION = $(shell cat VERSION)
GIT_COMMIT = $(shell git rev-parse --verify HEAD)

build-base:
	docker build --build-arg elixir_ver=$(ELIXIR_VER) --target base -t $(TAG) .

build-test:
	docker build --build-arg elixir_ver=$(ELIXIR_VER) --target test -t $(TAG_TEST) .

shell: build-base
	docker run --rm -it \
		-v $(PWD)/src:/opt/app \
		-p $(HTTP_PORT):80 \
		$(TAG) bash

test: build-test
	docker run --rm -v $(PWD)/src:/opt/app $(TAG_TEST) mix test

test-format: build-test
	docker run --rm -v $(PWD)/src:/opt/app $(TAG_TEST) mix format --check-formatted

test-credo: build-test
	docker run --rm -v $(PWD)/src:/opt/app $(TAG_TEST) mix credo --strict

release:
	@echo Building version $(VERSION)
	docker build \
		--build-arg elixir_ver=$(ELIXIR_VER) \
		--build-arg git_commit=$(GIT_COMMIT) \
		--build-arg app_version=$(VERSION) \
		--target release \
		--tag mfroach/$(APP):$(VERSION) .
	docker tag mfroach/$(APP):$(VERSION) mfroach/$(APP):latest

push-release: release
	docker push mfroach/$(APP):$(VERSION)
	docker push mfroach/$(APP):latest
