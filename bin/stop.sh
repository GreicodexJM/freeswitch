#!/bin/bash
docker kill $( docker ps -q -f 'ancestor=greicodex/freeswitch' )