{% if salt['cmd.has_exec']('rsyslogd') %}
docker-utils-rsyslog-config:
  file.managed:
    - name: /etc/rsyslog.conf
    - source: salt://500-docker-utils-rsyslog/rsyslog.conf
    - template: jinja

docker-utils-rsyslog-pid-file:
  file.absent:
    - name: /var/run/rsyslogd.pid
{% else %}
docker-utils-rsyslog-empty:
  test.nop
{% endif %}
