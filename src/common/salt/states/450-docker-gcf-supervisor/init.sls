{% set state_name = "docker-gcf-supervisor" %}

{% set supervisor_program_default = {
  "extraConfig": {
    "autostart": true,
    "priority": 500,
    "stdout_logfile": "syslog",
    "stdout_logfile_maxbytes": 0,
    "stderr_logfile": "syslog",
    "stderr_logfile_maxbytes": 0,
    "stopsignal": "INT"
  },
  "wrapper": None
} %}

{{ state_name }}-config-dir:
  file.directory:
    - name: /etc/supervisor/conf.d
    - makedirs: True
    - user: root
    - group: root
    - dir_mode: 755

{{ state_name }}-config:
  file.managed:
    - name: /etc/supervisor/supervisord.conf
    - source: salt://{{ tpldir }}/supervisord.conf
    - template: jinja

{{ state_name }}-pid-file:
  file.absent:
    - name: /var/run/supervisord.pid

{% for name,p in salt['pillar.get']('gcf:supervisor:programs').items() %}
{% set program = salt['slsutil.merge'](supervisor_program_default, p) %}
{{ state_name }}-program-{{ name }}-config:
  file.managed:
    - name: /etc/supervisor/conf.d/{{ name }}.conf
    - source: salt://{{ tpldir }}/supervisor.conf
    - template: jinja
    - context:
        program: {{ program | yaml }}
        program_name: {{ name }}

{% endfor %}
