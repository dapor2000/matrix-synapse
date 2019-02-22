FROM ubuntu:18.04
LABEL maintainer="Frank Wagener  <git@dapor.de>"

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN groupadd -r synapse && useradd -r -g synapse synapse

# Git branch to build from
ARG SYNAPSE_VERSION=v0.99.1.1
ARG SYNAPSE_REST_AUTH=v0.1.2 

# use --build-arg REBUILD=$(date) to invalidate the cache and upgrade all
# packages
ARG REBUILD=1
RUN set -ex \
    && export DEBIAN_FRONTEND=noninteractive \
    && mkdir -p /var/cache/apt/archives \
    && touch /var/cache/apt/archives/lock \
    && apt update \
    && apt remove -y libcurl4 \
    && apt install -y libcurl4 curl \
    && apt-get install -y apt lsb-core curl apt-transport-https \
    && echo "deb https://matrix.org/packages/debian `lsb_release -cs` main" | tee /etc/apt/sources.list.d/matrix-org.list \
    && curl "https://matrix.org/packages/debian/repo-key.asc" |   apt-key add - \ 
    && apt update \
    && apt-get update \
    && apt-get install -y --no-install-recommends \ 
        bash \
        matrix-synapse-py3 \
    && rm -rf /var/lib/apt/* /var/cache/apt/*

RUN mkdir /data \
    && mkdir /uploads \
    && chown synapse:synapse /data \
    && chown synapse:synapse /uploads

VOLUME /data
VOLUME /uploads



# add configs
COPY config/supervisord-matrix.conf config/supervisord-turnserver.conf  /conf/
COPY config/index.html config/logo.png /webclient/
COPY home_server_config.py docker-entrypoint.sh config/supervisord.conf /

EXPOSE 8008 8448 3478
WORKDIR /data

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["start"]
