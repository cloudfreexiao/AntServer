FROM alpine:3.8

RUN  apk update \
  && apk add rsyslog logrotate \
  && rm -rf /var/cache/apk/*

ADD rsyslog.conf /etc/rsyslog.conf
ADD logrotate.conf /etc/logrotate.conf
ADD start.sh start.sh

RUN chmod 644 /etc/logrotate.conf

ENTRYPOINT [ "/bin/sh", "start.sh" ]