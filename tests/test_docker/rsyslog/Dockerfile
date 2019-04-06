FROM debian:stretch

ADD https://raw.githubusercontent.com/docker-gcf/docker-gcf/develop/setup.sh /tmp/docker-gcf-setup.sh
RUN sh /tmp/docker-gcf-setup.sh -m rsyslog=develop
ENTRYPOINT ["gcf-entrypoint"]
CMD ["run.sh"]

RUN pkgs-install rsyslog

COPY ./bin /usr/local/bin/
