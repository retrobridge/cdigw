.PHONY: build-base release shell

HTTP_PORT = 8333
ELIXIR_VER = 1.10
TAG = cddb_gateway_elixir_$(ELIXIR_VER)
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
		--tag cddb_gateway:$(VERSION) .
