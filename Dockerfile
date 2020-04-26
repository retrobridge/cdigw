ARG elixir_ver=1.10

FROM elixir:${elixir_ver}-alpine AS base

RUN mix do local.hex --force, local.rebar --force

# bash          required for mix test watcher, and a nicer shell
# inotify-tools for test watching
# build-base    building NIFs
# git           pulling dependencies from GitHub that aren't in hex.pm
RUN apk --no-cache add \
      bash \
      inotify-tools \
      build-base \
      git

# read in mix.exs to set the paths for dependencies and build output.
# for local development on non-Linux hosts, this circumvents an I/O bottleneck
# and allows for easily testing against multiple versions of Elixir.
ENV MIX_DEPS_PATH=/opt/mix/deps \
    MIX_BUILD_PATH_ROOT=/opt/mix/build \
    MIX_ENV=dev \
    PS1="\u@\h:\w \$ "

WORKDIR /opt/app
VOLUME /opt/app

EXPOSE 80/tcp

RUN mkdir /opt/bin
COPY docker/entrypoint.sh /opt/bin/entrypoint

ENV PATH=${PATH}:/opt/bin

ENTRYPOINT ["/opt/bin/entrypoint"]


################################################################################
FROM base AS builder

COPY src /opt/app
COPY VERSION /opt/app

ENV MIX_ENV=prod

RUN mix do deps.get --only $MIX_ENV, release


################################################################################
FROM alpine AS release

RUN apk --no-cache add bash openssl

EXPOSE 80
EXPOSE 888

WORKDIR /opt/app

COPY --from=builder /opt/mix/build/rel/cdigw ./

CMD ["bin/cdigw", "start"]
