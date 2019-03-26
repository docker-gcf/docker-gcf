docker-gcf-gcf-json:
  file.managed:
    - name: /tmp/gcf-model.json
    - source: salt://500-docker-gcf-gcf/gcf-model.json
    - template: jinja
