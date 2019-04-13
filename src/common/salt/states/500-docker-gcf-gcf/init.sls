{% set state_name = "docker-gcf" %}

{{ state_name }}-gcf-model-json:
  file.managed:
    - name: /tmp/gcf-model.json
    - source: salt://{{ tpldir }}/gcf-model.json
    - template: jinja
