apache2-config:
  file.blockreplace:
    - name: /usr/local/apache2/conf/httpd.conf
    - append_if_not_found: True
    - marker_start: "#-- start managed zone test_docker-apache2 --"
    - marker_end: "#-- end managed zone test_docker-apache2 --"
    - source: salt://750-apache2/apache2.conf
    - template: jinja

{% for vhost in salt['pillar.get']("model:apache2:vhosts") %}
apache2-{{ vhost.name }}-root:
    file.directory:
        - name: /var/www/{{ vhost.name }}
        - makedirs: True

apache2-{{ vhost.name }}-index:
    file.managed:
        - name: /var/www/{{ vhost.name }}/index.html
        - contents: "Default content for {{ vhost.name }}"
{% endfor %}
