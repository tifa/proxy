FROM traefik:2.10.4

COPY ./assets/logrotate/ /etc/logrotate.d/

RUN chmod +x /etc/logrotate-kill.sh \
    && apk add --no-cache \
        logrotate==3.21.0 \
    && rm -rf /var/cache/apk/*
