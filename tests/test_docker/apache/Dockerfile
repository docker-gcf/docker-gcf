FROM httpd:2.4

ADD https://raw.githubusercontent.com/robin-thoni/docker-utils/develop/setup.sh /tmp/docker-utils-setup.sh
RUN sh /tmp/docker-utils-setup.sh && rm /tmp/docker-utils-setup.sh
COPY config /etc/gcf/
COPY bin /usr/local/bin/

ENTRYPOINT ["run.sh"]
