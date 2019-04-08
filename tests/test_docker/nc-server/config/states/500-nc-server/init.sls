{% set state_name = "nc-server" %}

{{ state_name }}-supervisor:
  file.managed:
    - name: /etc/supervisor/conf.d/{{ state_name }}.conf
    - source: salt://500-{{ state_name }}/supervisor.conf
    - template: jinja
