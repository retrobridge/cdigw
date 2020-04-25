ARG elixir_ver=1.10

FROM elixir:${elixir_ver}-alpine AS base

RUN mix do local.hex --force, local.rebar --force

RUN apk --no-cache add bash inotify-tools git

# read in mix.exs to set the paths for dependencies and build output.
# for local development on non-Linux hosts, this circumvents an I/O bottleneck
# and allows for easily testing against multiple versions of Elixir.
ENV MIX_DEPS_PATH=/opt/mix/deps
ENV MIX_BUILD_PATH=/opt/mix/build

WORKDIR /opt/app
VOLUME /opt/app

EXPOSE 80/tcp

RUN mkdir /opt/bin
COPY docker/entrypoint.sh /opt/bin/entrypoint

ENV PATH=${PATH}:/opt/bin

ENTRYPOINT ["/opt/bin/entrypoint"]
