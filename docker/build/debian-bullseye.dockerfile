FROM debian:bullseye
MAINTAINER Javier Munoz <javier@greicodex.com>

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -yq install git

RUN git clone https://github.com/signalwire/freeswitch /usr/src/freeswitch
RUN git clone https://github.com/signalwire/libks /usr/src/libs/libks
RUN git clone https://github.com/freeswitch/sofia-sip /usr/src/libs/sofia-sip 
RUN git clone https://github.com/freeswitch/spandsp /usr/src/libs/spandsp
RUN git clone https://github.com/signalwire/signalwire-c /usr/src/libs/signalwire-c

RUN DEBIAN_FRONTEND=noninteractive apt-get -yq install \
# build
    build-essential cmake automake autoconf 'libtool-bin|libtool' pkg-config \
# general
    libssl-dev zlib1g-dev libdb-dev unixodbc-dev libncurses5-dev libexpat1-dev libgdbm-dev bison erlang-dev libtpl-dev libtiff5-dev uuid-dev \
# core
    libpcre3-dev libedit-dev libsqlite3-dev libcurl4-openssl-dev nasm \
# core codecs
    libogg-dev libspeex-dev libspeexdsp-dev \
# mod_enum
    libldns-dev \
# mod_python3
    python3-dev \
# mod_av
    libavformat-dev libswscale-dev libavresample-dev \
# mod_lua
    liblua5.2-dev \
# mod_opus
    libopus-dev \
# mod_pgsql
    libpq-dev \
# mod_sndfile
    libsndfile1-dev libflac-dev libogg-dev libvorbis-dev \
# mod_shout
    libshout3-dev libmpg123-dev libmp3lame-dev \
# mod_amqp
    librabbitmq-dev \
# clean APT cache
    && rm -rf /var/lib/apt/lists/*

RUN cd /usr/src/libs/libks && cmake . -DCMAKE_INSTALL_PREFIX=/usr -DWITH_LIBBACKTRACE=1 && make install
RUN cd /usr/src/libs/sofia-sip && ./bootstrap.sh && ./configure CFLAGS="-g -ggdb" --with-pic --with-glib=no --without-doxygen --disable-stun --prefix=/usr && make -j`nproc --all` && make install
#https://github.com/signalwire/freeswitch/issues/2184
RUN cd /usr/src/libs/spandsp && git checkout 0d2e6ac && ./bootstrap.sh && ./configure CFLAGS="-g -ggdb" --with-pic --prefix=/usr && make -j`nproc --all` && make install
RUN cd /usr/src/libs/signalwire-c && PKG_CONFIG_PATH=/usr/lib/pkgconfig cmake . -DCMAKE_INSTALL_PREFIX=/usr && make install

# Disabled un-needed modules
RUN sed -i 's|applications/mod_signalwire|#applications/mod_signalwire|' /usr/src/freeswitch/build/modules.conf.in \
    && sed -i 's|applications/mod_sms|#applications/mod_sms|' /usr/src/freeswitch/build/modules.conf.in \
    && sed -i 's|applications/mod_test|#applications/mod_test|' /usr/src/freeswitch/build/modules.conf.in \
    && sed -i 's|databases/mod_pgsql|#databases/mod_pgsql|' /usr/src/freeswitch/build/modules.conf.in \
    && sed -i 's|dialplans/mod_dialplan_asterisk|#dialplans/mod_dialplan_asterisk|' /usr/src/freeswitch/build/modules.conf.in \
    && sed -i 's|endpoints/mod_skinny|#endpoints/mod_skinny' /usr/src/freeswitch/build/modules.conf.in \
    && sed -i 's|endpoints/mod_verto|#endpoints/mod_verto|' /usr/src/freeswitch/build/modules.conf.in \
    && sed -i 's|event_handlers/mod_cdr_sqlite|#event_handlers/mod_cdr_sqlite|' /usr/src/freeswitch/build/modules.conf.in \
    && sed -i 's|formats/mod_png|#formats/mod_png|' /usr/src/freeswitch/build/modules.conf.in \
    && sed -i 's|languages/mod_lua|#languages/mod_lua|' /usr/src/freeswitch/build/modules.conf.in
# Enable modules
RUN sed -i 's|#event_handlers/mod_amqp|event_handlers/mod_amqp|' /usr/src/freeswitch/build/modules.conf.in
#RUN sed -i 's|#formats/mod_shout|formats/mod_shout|' /usr/src/freeswitch/build/modules.conf.in

RUN cd /usr/src/freeswitch && ./bootstrap.sh -j
RUN cd /usr/src/freeswitch && ./configure
RUN cd /usr/src/freeswitch && make -j`nproc` && make install

# Cleanup the image
RUN apt-get clean

# Uncomment to cleanup even more
RUN rm -rf /usr/src/*

