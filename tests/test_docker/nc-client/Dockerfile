FROM debian:stretch

ADD https://raw.githubusercontent.com/docker-gcf/docker-gcf/develop/setup.sh /tmp/docker-gcf-setup.sh
RUN sh /tmp/docker-gcf-setup.sh
ENTRYPOINT ["gcf-entrypoint"]
CMD ["gcf-cmd"]

COPY ./_common/config/ /etc/salt/base/
COPY ./nc-client/bin/ /usr/local/bin/
COPY ./nc-client/config/ /etc/salt/base/
