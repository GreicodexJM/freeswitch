FROM alpine:latest
# explicitly set user/group IDs
#RUN apk add bash git build-base automake autoconf libtool diffutils yasm
#RUN apk add spandsp3-dev sofia-sip-dev libjpeg-turbo-dev sqlite-dev pcre-dev curl-dev \
#    speex-dev speexdsp-dev ldns-dev libks-dev rabbitmq-c-dev tiff-dev ffmpeg-libavformat \
#    ffmpeg-dev lua5.4-dev opus-dev libopusenc-dev opusfile-dev libsndfile-dev
RUN echo "**** Installing Packages *****" \
    && apk add --no-cache lua sqlite lua-sqlite tiff-tools util-linux s6 openssl
#RUN sed -e 's|applications/mod_signalwire|#applications/mod_signalwire|g' -i modules.conf
RUN apk add freeswitch freeswitch-sample-config freeswitch-sounds-en-us-callie-8000 freeswitch-timezones freeswitch-sounds-music-8000    
RUN echo "**** Linking Config ****" \
    && mkdir -p /usr/share/freeswitch/conf/ \
    && mv /etc/freeswitch /usr/share/freeswitch/conf/vanilla \
    && ln -s /config /etc/freeswitch \        
    && mv /usr/share/freeswitch/sounds /usr/share/freeswitch/conf/sounds \
    && ln -s /sounds /usr/share/freeswitch/sounds
RUN apk add rabbitmq-c --no-cache
#   && mv /usr/lib/freeswitch/db /usr/share/freeswitch/conf/data \
#   && ln -s /data /usr/lib/freeswitch/db \
COPY ./mod_amqp.so /usr/lib/freeswitch/mod/mod_amqp.so
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