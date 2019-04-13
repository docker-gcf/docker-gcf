{% set state_name = "docker-gcf-supervisor" %}

{{ state_name }}-config-dir:
  file.directory:
    - name: /etc/supervisor/conf.d
    - makedirs: True
    - user: root
    - group: root
    - dir_mode: 755

{{ state_name }}-config:
  file.managed:
    - name: /etc/supervisor/supervisord.conf
    - source: salt://{{ tpldir }}/supervisord.conf
    - template: jinja

{{ state_name }}-pid-file:
  file.absent:
    - name: /var/run/supervisord.pid
