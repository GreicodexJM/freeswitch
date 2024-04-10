#!/bin/bash
fs_image=$(docker image ls --filter 'reference=greicodex/freeswitch' -q)
if [ -z $fs_image ]; then
    docker build -f docker/Dockerfile . -t greicodex/freeswitch
fi

CONTROL_PORT=8021
SIP_INTERNAL=15060
SIP_INT_TLS=15061
SIP_EXTERNAL=15080
SIP_EXT_TLS=15081
SIP_WSS=7443
docker run --rm -it \
    -v ./config:/etc/freeswitch \
    -v ./sounds:/usr/share/freeswitch/sounds \
    -v ./tmp:/tmp \
    -p $CONTROL_PORT:8021  \
    -p $SIP_INTERNAL:5060  \
    -p $SIP_INT_TLS:5061  \
    -p $SIP_EXTERNAL:5080  \
    -p $SIP_EXT_TLS:5081  \
    -p $SIP_WS:5066  \
    -p $SIP_WSS:7443  \
    -p $VERTO_WS:8081  \
    -p $VERTO_WSS:8082  \
    -p 16384-16394:16384-16394/udp \
     --name FS0 greicodex/freeswitch  
