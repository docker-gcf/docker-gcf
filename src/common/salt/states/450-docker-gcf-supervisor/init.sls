docker-gcf-supervisor-config-dir:
  file.directory:
    - name: /etc/supervisor/conf.d
    - makedirs: True
    - user: root
    - group: root
    - dir_mode: 755

docker-gcf-supervisor-config:
  file.managed:
    - name: /etc/supervisor/supervisord.conf
    - source: salt://450-docker-gcf-supervisor/supervisord.conf
    - template: jinja

docker-gcf-supervisor-pid:
  file.absent:
    - name: /var/run/supervisord.pid
