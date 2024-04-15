FROM greicodex/freeswitch:alpine-latest-build as build
FROM alpine:latest
LABEL MAINTAINER="Javier Munoz <javier@greicodex.com>"
# explicitly set user/group IDs

RUN echo "**** Installing Packages *****" \
    && apk add --no-cache lua sqlite lua-sqlite tiff-tools util-linux s6 \
    openssl rabbitmq-c curl speex speexdsp ffmpeg ldns libogg sqlite pcre \
    zlib libdbi unixodbc ncurses expat gdbm erlang libpq opus lua5.2 python3 \
    libsndfile flac libvorbis libshout mpg123 lame libedit libwebsockets
RUN addgroup freeswitch
RUN adduser -g "<freeswitch>" -S -D -H -G freeswitch freeswitch 
COPY --from=build --chown=freeswitch:freeswitch /usr/local/freeswitch /usr/local/freeswitch
COPY --from=build --chown=freeswitch:freeswitch /usr/src/freeswitch/conf /usr/share/freeswitch/conf
COPY --from=build /usr/lib/libspandsp.* /usr/lib/
COPY --from=build /usr/lib/libsofia-sip-ua.* /usr/lib/
COPY --from=build /usr/lib/libks* /usr/lib/
RUN ln -s /usr/local/freeswitch/bin/freeswitch /usr/bin/freeswitch
RUN ln -s /usr/local/freeswitch/bin/fs_cli /usr/bin/fs_cli
RUN ln -s /usr/local/freeswitch/bin/fs_encode /usr/bin/fs_encode
RUN ln -s /usr/local/freeswitch/bin/fs_ivrd /usr/bin/fs_ivrd
RUN ln -s /usr/local/freeswitch/bin/fs_tts /usr/bin/fs_tts
RUN ln -s /usr/local/freeswitch/bin/tone2wav /usr/bin/tone2wav
RUN echo "**** Linking Config ****" \    
    && mkdir -p /usr/share/freeswitch/conf/original \
    && mv  /usr/local/freeswitch/conf/*  /usr/share/freeswitch/conf/original/ \
    && mkdir -p /usr/share/freeswitch/sounds  \
    && mkdir -p /usr/share/freeswitch/db \
    && mkdir -p /usr/share/freeswitch/web \
    && mkdir -p /var/run/freeswitch \
    && mkdir -p /var/lib/freeswitch \    
    && ln -s /usr/local/freeswitch/conf /config \            
    && ln -s /usr/share/freeswitch/sounds /sounds \
    && ln -s /usr/share/freeswitch/db /data \
    && ln -s /usr/share/freeswitch/web /web \
    && chown -R freeswitch:freeswitch /var/run/freeswitch /var/lib/freeswitch /usr/local/freeswitch/conf /usr/share/freeswitch
    
#   && mv /usr/lib/freeswitch/db /usr/share/freeswitch/conf/data \
#   && ln -s /data /usr/lib/freeswitch/db \
# USER freeswitch
# Volumes
## Freeswitch Configuration
VOLUME ["/config", "/data", "/sounds", "/web"]
## Tmp so we can get core dumps out
VOLUME ["/tmp"]

COPY docker/docker-entrypoint.sh /
## Ports
# Open the container up to the world.
### 8021 fs_cli, 5060 5061 5080 5081 sip and sips, 16384-32768 rtp
EXPOSE 8021/tcp
EXPOSE 5060/tcp 5060/udp 5080/tcp 5080/udp
EXPOSE 5061/tcp 5061/udp 5081/tcp 5081/udp
EXPOSE 7443/tcp
EXPOSE 5070/udp 5070/tcp
EXPOSE 16384-32768/udp

# Limits Configuration
COPY docker/build/freeswitch.limits.conf /etc/security/limits.d/

# Healthcheck to make sure the service is running
SHELL       ["/bin/bash"]
HEALTHCHECK --interval=15s --timeout=5s \
    CMD  fs_cli -x status | grep -q ^UP || exit 1

## Add additional things here

##

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["freeswitch"]