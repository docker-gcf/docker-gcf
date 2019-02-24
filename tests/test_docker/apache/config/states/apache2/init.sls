apache2-config:
  file.managed:
    - name: /usr/local/apache2/conf/httpd.conf
    - source: salt://apache2/apache2.conf
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
