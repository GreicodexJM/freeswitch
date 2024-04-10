FROM alpine:latest
MAINTAINER Javier Munoz <javier@greicodex.com>

RUN apk update && apk add git --no-cache

RUN git clone https://github.com/signalwire/freeswitch --depth 1 --branch=master /usr/src/freeswitch
RUN git clone https://github.com/signalwire/libks  --depth 1 --branch=master /usr/src/libs/libks
RUN git clone https://github.com/freeswitch/sofia-sip  --depth 1 --branch=master /usr/src/libs/sofia-sip 
RUN git clone https://github.com/freeswitch/spandsp  --depth 1 --branch=master /usr/src/libs/spandsp
RUN git clone https://github.com/signalwire/signalwire-c  --depth 1 --branch=master /usr/src/libs/signalwire-c

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

RUN cd /usr/src/libs/libks && cmake . -DCMAKE_INSTALL_PREFIX=/usr -DWITH_LIBBACKTRACE=0 && make install
RUN cd /usr/src/libs/sofia-sip && ./bootstrap.sh && ./configure CFLAGS="-g -ggdb" --with-pic --with-glib=no --without-doxygen --disable-stun --prefix=/usr && make -j`nproc --all` && make install
#https://github.com/signalwire/freeswitch/issues/2184
RUN cd /usr/src/libs/spandsp && ./bootstrap.sh && ./configure CFLAGS="-g -ggdb" --with-pic --prefix=/usr && make -j`nproc --all` && make install
RUN cd /usr/src/libs/signalwire-c && PKG_CONFIG_PATH=/usr/lib/pkgconfig cmake . -DCMAKE_INSTALL_PREFIX=/usr && make install

# Disabled un-needed modules
RUN sed -i 's|applications/mod_signalwire|#applications/mod_signalwire|' /usr/src/freeswitch/build/modules.conf.in
RUN sed -i 's|applications/mod_sms|#applications/mod_sms|' /usr/src/freeswitch/build/modules.conf.in
RUN sed -i 's|applications/mod_test|#applications/mod_test|' /usr/src/freeswitch/build/modules.conf.in
RUN sed -i 's|databases/mod_pgsql|#databases/mod_pgsql|' /usr/src/freeswitch/build/modules.conf.in
RUN sed -i 's|dialplans/mod_dialplan_asterisk|#dialplans/mod_dialplan_asterisk|' /usr/src/freeswitch/build/modules.conf.in
RUN sed -i 's|endpoints/mod_skinny|#endpoints/mod_skinny|' /usr/src/freeswitch/build/modules.conf.in
RUN sed -i 's|endpoints/mod_verto|#endpoints/mod_verto|' /usr/src/freeswitch/build/modules.conf.in
RUN sed -i 's|event_handlers/mod_cdr_sqlite|#event_handlers/mod_cdr_sqlite|' /usr/src/freeswitch/build/modules.conf.in
RUN sed -i 's|formats/mod_png|#formats/mod_png|' /usr/src/freeswitch/build/modules.conf.in
RUN sed -i 's|languages/mod_lua|#languages/mod_lua|' /usr/src/freeswitch/build/modules.conf.in
# Enable modules
RUN sed -i 's|#event_handlers/mod_amqp|event_handlers/mod_amqp|' /usr/src/freeswitch/build/modules.conf.in
#RUN sed -i 's|#formats/mod_shout|formats/mod_shout|' /usr/src/freeswitch/build/modules.conf.in

RUN cd /usr/src/freeswitch && ./bootstrap.sh -j
RUN cd /usr/src/freeswitch && ./configure

COPY ./docker/patches/*.diff /usr/src/freeswitch_patches/
RUN cd /usr/src/freeswitch && patch -p1 < /usr/src/freeswitch_patches/issue_2202.diff 
RUN cd /usr/src/freeswitch && patch -p1 < /usr/src/freeswitch_patches/issue_2219.diff 
RUN cd /usr/src/freeswitch && patch -p1 < /usr/src/freeswitch_patches/issue_2158.diff 

RUN cd /usr/src/freeswitch && make -j`nproc` && make install

# Cleanup the image
#RUN apk cache purge

# Uncomment to cleanup even more
#RUN rm -rf /usr/src/*
