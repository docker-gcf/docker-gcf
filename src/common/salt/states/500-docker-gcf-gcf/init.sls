{% set state_name = "docker-gcf" %}

{{ state_name }}-gcf-config-dir:
  file.directory:
    - name: /etc/gcf
    - user: root
    - group: root
    - mod: 755

{{ state_name }}-gcf-pillar-json:
  file.managed:
    - name: /etc/gcf/gcf-pillar.json
    - source: salt://{{ tpldir }}/gcf-pillar.json
    - template: jinja
