docker-utils-gcf-json:
  file.managed:
    - name: /tmp/gcf-model.json
    - source: salt://docker-utils/gcf-model.json
    - template: jinja
