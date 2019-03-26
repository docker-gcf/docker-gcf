{% if salt['cmd.has_exec']('rsyslogd') %}
docker-gcf-rsyslog-config:
  file.managed:
    - name: /etc/rsyslog.conf
    - source: salt://500-docker-gcf-rsyslog/rsyslog.conf
    - template: jinja

docker-gcf-rsyslog-pid-file:
  file.absent:
    - name: /var/run/rsyslogd.pid
{% else %}
docker-gcf-rsyslog-empty:
  test.nop
{% endif %}
