{% set state_name = "docker-gcf-ssmtp" %}

{{ state_name }}-config:
  file.managed:
    - name: /etc/ssmtp/ssmtp.conf
    - source: salt://{{ tpldir }}/ssmtp.conf
    - template: jinja
