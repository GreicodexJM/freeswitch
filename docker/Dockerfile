FROM greicodex/freeswitch:alpine-test-builder as base_build

FROM alpine:latest
RUN apk --update --no-cache add \
# general
    openssl zlib libdbi unixodbc ncurses expat gdbm bison erlang msgpack-c tiff util-linux diffutils \
# core
    pcre libedit sqlite curl nasm \
# core codecs
    libogg speex speexdsp \
# mod_enum
    ldns \
# mod_python3
    python3 \
# mod_av
    ffmpeg \
# mod_lua
    lua5.2 \
# mod_opus
    opus \
# mod_pgsql
    libpq \
# mod_sndfile
    libsndfile flac libogg libvorbis \
# mod_shout
    libshout mpg123 lame \
# mod_amqp
    rabbitmq-c
RUN mkdir -p /usr/share/docker
ENV SOUND_RATES=8000
ENV SOUND_TYPES=1.0.51
COPY --from=base_build /usr/local/freeswitch /usr/local/freeswitch
COPY ./docker /usr/share/docker
RUN chmod +x /usr/share/docker/*.sh
ENTRYPOINT ["/usr/share/docker/entrypoint.sh"]
CMD ["freeswitch"]