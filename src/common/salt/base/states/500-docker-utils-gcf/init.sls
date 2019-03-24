docker-utils-gcf-json:
  file.managed:
    - name: /tmp/gcf-model.json
    - source: salt://500-docker-utils-gcf/gcf-model.json
    - template: jinja
