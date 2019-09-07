FROM debian:stretch

ADD https://raw.githubusercontent.com/docker-gcf/docker-gcf/develop/setup.sh /tmp/docker-gcf-setup.sh
RUN sh /tmp/docker-gcf-setup.sh
ENTRYPOINT ["gcf-entrypoint"]
CMD ["gcf-cmd"]

COPY ./bin /usr/local/bin/
COPY ./config /etc/salt/base/
