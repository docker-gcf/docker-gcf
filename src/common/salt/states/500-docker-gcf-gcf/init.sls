{% set state_name = "docker-gcf" %}

{{ state_name }}-gcf-config-dir:
  file.directory:
    - name: /etc/gcf
    - user: root
    - group: root
    - mod: 755

{{ state_name }}-gcf-model-json:
  file.managed:
    - name: /etc/gcf/gcf-model.json
    - source: salt://{{ tpldir }}/gcf-model.json
    - template: jinja
