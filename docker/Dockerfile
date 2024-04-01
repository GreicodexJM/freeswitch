FROM alpine:latest
RUN apk --update --no-cache add \
    sofia-sip \
    freeswitch \ 
    freeswitch-sample-config 
RUN mkdir -p /usr/share/docker
ENV SOUND_RATES=8000
ENV SOUND_TYPES=1.0.51
COPY ./docker /usr/share/docker
RUN chmod +x /usr/share/docker/*.sh
ENTRYPOINT ["/usr/share/docker/entrypoint.sh"]
CMD ["freeswitch"]