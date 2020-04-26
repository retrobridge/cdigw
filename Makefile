.PHONY: build-base push-release release shell

HTTP_PORT = 8880
ELIXIR_VER = 1.10
APP = cdigw
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
	docker run --rm \
		-v $(PWD)/src:/opt/app $(TAG) \
		mix do test, format --check-formatted, credo --strict

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
