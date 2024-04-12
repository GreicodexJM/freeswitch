FROM alpine:latest
LABEL MAINTAINER="Javier Munoz <javier@greicodex.com>"

RUN apk update && apk add git --no-cache
ENV FREESWITCH_SOURCE_ROOT=/usr/src/freeswitch
ENV LIBKS_SOURCE_ROOT=/usr/src/libs/libks
ENV SOFIASIP_SOURCE_ROOT=/usr/src/libs/sofia-sip 
ENV SPANDSP_SOURCE_ROOT=/usr/src/libs/spandsp
ENV SIGNALWIREC_SOURCE_ROOT=/usr/src/libs/signalwire-c
RUN git clone https://github.com/signalwire/freeswitch --depth 1 --branch=master ${FREESWITCH_SOURCE_ROOT}
RUN git clone https://github.com/signalwire/libks  --depth 1 --branch=master ${LIBKS_SOURCE_ROOT}
RUN git clone https://github.com/freeswitch/sofia-sip  --depth 1 --branch=master ${SOFIASIP_SOURCE_ROOT}
RUN git clone https://github.com/freeswitch/spandsp  --depth 1 --branch=master ${SPANDSP_SOURCE_ROOT}
RUN git clone https://github.com/signalwire/signalwire-c  --depth 1 --branch=master ${SIGNALWIREC_SOURCE_ROOT}
RUN git clone https://github.com/igwtech/mod_whisper.git --depth=1 --branch=main ${FREESWITCH_SOURCE_ROOT}/src/mod/asr_tts/mod_whisper
RUN apk add --no-cache \
# build
    build-base cmake automake autoconf libtool pkgconf linux-headers util-linux-misc \
# general
    openssl-dev zlib-dev libdbi-dev unixodbc-dev ncurses-dev expat-dev gdbm-dev bison erlang-dev msgpack-c-dev tiff-dev util-linux-dev diffutils \
# core
    pcre-dev libedit-dev sqlite-dev curl-dev nasm \
# core codecs
    libogg-dev speex-dev speexdsp-dev \
# mod_enum
    ldns-dev \
# mod_python3
    python3-dev \
# mod_av
    ffmpeg-dev \
# mod_lua
    lua5.2-dev \
# mod_php 
    php82-dev \
# mod_opus
    opus-dev \
# mod_pgsql
    libpq-dev \
# mod_sndfile
    libsndfile-dev flac-dev libogg-dev libvorbis-dev \
# mod_shout
    libshout-dev mpg123-dev lame-dev \
# mod_amqp
    rabbitmq-c-dev \
# clean APT cache
    && apk cache clean

RUN cd ${LIBKS_SOURCE_ROOT} && cmake . -DCMAKE_INSTALL_PREFIX=/usr -DWITH_LIBBACKTRACE=0 && make install
RUN cd ${SOFIASIP_SOURCE_ROOT} && ./bootstrap.sh && ./configure CFLAGS="-g -ggdb" --with-pic --with-glib=no --without-doxygen --disable-stun --prefix=/usr && make -j`nproc --all` && make install
#https://github.com/signalwire/freeswitch/issues/2184
RUN cd ${SPANDSP_SOURCE_ROOT} && ./bootstrap.sh && ./configure CFLAGS="-g -ggdb" --with-pic --prefix=/usr && make -j`nproc --all` && make install
RUN cd ${SIGNALWIREC_SOURCE_ROOT}&& PKG_CONFIG_PATH=/usr/lib/pkgconfig cmake . -DCMAKE_INSTALL_PREFIX=/usr && make install

# Disabled un-needed modules
RUN sed -i 's|applications/mod_signalwire|#applications/mod_signalwire|' ${FREESWITCH_SOURCE_ROOT}/build/modules.conf.in
RUN sed -i 's|applications/mod_sms|#applications/mod_sms|' ${FREESWITCH_SOURCE_ROOT}/build/modules.conf.in
RUN sed -i 's|applications/mod_test|#applications/mod_test|' ${FREESWITCH_SOURCE_ROOT}/build/modules.conf.in
RUN sed -i 's|databases/mod_pgsql|#databases/mod_pgsql|' ${FREESWITCH_SOURCE_ROOT}/build/modules.conf.in
RUN sed -i 's|dialplans/mod_dialplan_asterisk|#dialplans/mod_dialplan_asterisk|' ${FREESWITCH_SOURCE_ROOT}/build/modules.conf.in
RUN sed -i 's|endpoints/mod_skinny|#endpoints/mod_skinny|' ${FREESWITCH_SOURCE_ROOT}/build/modules.conf.in
RUN sed -i 's|endpoints/mod_verto|#endpoints/mod_verto|' ${FREESWITCH_SOURCE_ROOT}/build/modules.conf.in
RUN sed -i 's|event_handlers/mod_cdr_sqlite|#event_handlers/mod_cdr_sqlite|' ${FREESWITCH_SOURCE_ROOT}/build/modules.conf.in
RUN sed -i 's|formats/mod_png|#formats/mod_png|' ${FREESWITCH_SOURCE_ROOT}/build/modules.conf.in
RUN sed -i 's|languages/mod_lua|#languages/mod_lua|' ${FREESWITCH_SOURCE_ROOT}/build/modules.conf.in
# Enable modules
RUN sed -i 's|#event_handlers/mod_amqp|event_handlers/mod_amqp|' ${FREESWITCH_SOURCE_ROOT}/build/modules.conf.in
#RUN sed -i 's|#formats/mod_shout|formats/mod_shout|' ${FREESWITCH_SOURCE_ROOT}/build/modules.conf.in



RUN cd ${FREESWITCH_SOURCE_ROOT} && ./bootstrap.sh -j
RUN cd ${FREESWITCH_SOURCE_ROOT} && ./configure

COPY ./docker/patches/*.diff /usr/src/freeswitch_patches/
RUN cd ${FREESWITCH_SOURCE_ROOT} && patch -p1 < /usr/src/freeswitch_patches/issue_2202.diff 
RUN cd ${FREESWITCH_SOURCE_ROOT} && patch -p1 < /usr/src/freeswitch_patches/issue_2219.diff 
RUN cd ${FREESWITCH_SOURCE_ROOT} && patch -p1 < /usr/src/freeswitch_patches/issue_2158.diff 

RUN cd ${FREESWITCH_SOURCE_ROOT} && make -j`nproc` && make install
RUN apk add --no-cache libwebsockets-dev
RUN sed -i 's|src/mod/asr_tts/mod_tts_commandline/Makefile|src/mod/asr_tts/mod_tts_commandline/Makefile\n\t\tsrc/mod/asr_tts/mod_whisper/Makefile|' ${FREESWITCH_SOURCE_ROOT}/configure.ac
RUN cd ${FREESWITCH_SOURCE_ROOT} && patch -p1 < /usr/src/freeswitch_patches/mod_whisper_config.diff 

RUN echo 'asr_tts/mod_whisper' >> ${FREESWITCH_SOURCE_ROOT}/modules.conf
RUN sed -i 's|<sys/signal.h>|<signal.h>|' /usr/include/libks2/libks/ks_platform.h
RUN cd ${FREESWITCH_SOURCE_ROOT} && autoreconf -f
RUN cd ${FREESWITCH_SOURCE_ROOT} && make -j`nproc` && make install

# Cleanup the image
#RUN apk cache purge

# Uncomment to cleanup even more
#RUN rm -rf /usr/src/*
