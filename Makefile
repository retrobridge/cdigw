.PHONY: build run

HTTP_PORT = 8333
ELIXIR_VER = 1.10
TAG = cddb_gateway_elixir_$(ELIXIR_VER)

build:
	docker build --build-arg elixir_ver=$(ELIXIR_VER) -t $(TAG) .

shell: build
	docker run --rm -it \
		-v $(PWD)/src:/opt/app \
		-p $(HTTP_PORT):80 \
		$(TAG) bash
