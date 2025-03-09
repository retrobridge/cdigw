ARG elixir_ver

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
EXPOSE 888/tcp

RUN mkdir /opt/bin
COPY docker/entrypoint.sh /opt/bin/entrypoint

ENV PATH=${PATH}:/opt/bin


################################################################################
FROM base AS dev

COPY src/mix.* .

RUN mix do deps.get, deps.compile
RUN env MIX_ENV=test mix do deps.compile

ENTRYPOINT ["/opt/bin/entrypoint"]


################################################################################
FROM base AS builder

COPY src /opt/app

ENV MIX_ENV=prod \
    MIX_BUILD_PATH=/opt/mix/build/prod

COPY src/mix.* .
RUN mix deps.get --only $MIX_ENV

COPY src .
RUN mix release

################################################################################
FROM alpine AS release

RUN apk --no-cache add bash openssl libstdc++ libgcc

EXPOSE 80
EXPOSE 888

ENV PS1="\u@\h:\w \$ "

WORKDIR /opt/app

RUN date > .BUILD_DATE
COPY --from=builder /opt/mix/build/prod/rel/cdigw ./

# add static assets
RUN mkdir priv
COPY src/priv/. ./priv/

CMD ["bin/cdigw", "start"]
