docker-gcf-ssmtp-config:
  file.managed:
    - name: /etc/ssmtp/ssmtp.conf
    - source: salt://500-docker-gcf-ssmtp/ssmtp.conf
    - template: jinja
