{% set state_name = "docker-gcf-rsyslog" %}

{{ state_name }}-config:
  file.managed:
    - name: /etc/rsyslog.conf
    - source: salt://{{ tpldir }}/rsyslog.conf
    - template: jinja

{{ state_name }}-pid-file:
  file.absent:
    - name: /var/run/rsyslogd.pid
