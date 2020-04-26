.PHONY: build-base push-release release shell

HTTP_PORT = 8880
ELIXIR_VER = 1.10
APP = cdigw
TAG = $(APP)_elixir_$(ELIXIR_VER)
VERSION = `cat VERSION`

build-base:
	docker build --build-arg elixir_ver=$(ELIXIR_VER) --target base -t $(TAG) .

shell: build-base
	docker run --rm -it \
		-v $(PWD)/src:/opt/app \
		-p $(HTTP_PORT):80 \
		$(TAG) bash

release:
	@echo Building version $(VERSION)
	docker build --build-arg elixir_ver=$(ELIXIR_VER) \
		--target release \
		--tag mfroach/$(APP):$(VERSION) .
	docker tag mfroach/$(APP):$(VERSION) mfroach/$(APP):latest

push-release: release
	docker push mfroach/$(APP):$(VERSION)
	docker push mfroach/$(APP):latest
