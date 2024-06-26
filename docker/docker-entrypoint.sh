#!/bin/sh
set -e

# Source docker-entrypoint.sh:
# https://github.com/docker-library/postgres/blob/master/9.4/docker-entrypoint.sh
# https://github.com/kovalyshyn/docker-freeswitch/blob/vanilla/docker-entrypoint.sh

if [ "$1" = 'freeswitch' ]; then

    if [ ! -f "/etc/freeswitch/freeswitch.xml" ]; then
        mkdir -p /etc/freeswitch
        cp -varf /usr/share/freeswitch/conf/minimal/* /etc/freeswitch/
    fi

    chown -R freeswitch:freeswitch /etc/freeswitch
    chown -R freeswitch:freeswitch /var/run/freeswitch
    chown -R freeswitch:freeswitch /var/lib/freeswitch
    
    if [ -d /docker-entrypoint.d ]; then
        for f in /docker-entrypoint.d/*.sh; do
            [ -f "$f" ] && . "$f"
        done
    fi
    
    exec /usr/bin/freeswitch -u freeswitch -g freeswitch -nonat -nf -c -nonatmap
fi

exec "$@"