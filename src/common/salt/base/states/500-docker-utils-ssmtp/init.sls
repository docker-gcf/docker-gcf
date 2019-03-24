docker-utils-ssmtp-config:
  file.managed:
    - name: /etc/ssmtp/ssmtp.conf
    - source: salt://500-docker-utils-ssmtp/ssmtp.conf
    - template: jinja
