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
    && apt-get update 
RUN apt-get install -y wget gnupg2 software-properties-common 
RUN wget -qO - https://matrix.org/packages/debian/repo-key.asc | apt-key add - \
    && add-apt-repository https://matrix.org/packages/debian/ \
    && apt-get update 
RUN apt-get install -y --no-install-recommends \ 
        bash \
        nano  \
        matrix-synapse \
        supervisor \
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
