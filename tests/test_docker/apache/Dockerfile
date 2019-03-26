FROM httpd:2.4

ADD https://raw.githubusercontent.com/docker-gcf/docker-gcf/develop/setup.sh /tmp/docker-gcf-setup.sh
RUN sh /tmp/docker-gcf-setup.sh
ENTRYPOINT ["gcf-entrypoint"]
CMD ["run.sh"]

#RUN pkgs-install dependency

COPY ./bin /usr/local/bin/
COPY ./config /etc/salt/base/
