FROM httpd:2.4

ADD https://raw.githubusercontent.com/robin-thoni/docker-utils/develop/setup.sh /tmp/docker-utils-setup.sh
RUN sh /tmp/docker-utils-setup.sh
ENTRYPOINT ["gcf-entrypoint"]
CMD ["run.sh"]

#RUN pkgs-install dependency

COPY ./bin /usr/local/bin/
COPY ./config /etc/salt/base/
