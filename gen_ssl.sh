#!/bin/bash
openssl req -x509 -nodes -newkey rsa:2048 -keyout key.pem -out cert.pem -sha256 -days 365 \
    -subj "/C=VE/ST=Distrito Capital/L=Caracas/O=Greicodex/OU=IT Department/CN=localhost"

export HOST_IP=$(ifconfig | grep en0 -A3 | grep inet | awk '{ print $2 }')
