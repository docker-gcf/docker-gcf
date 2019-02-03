#! /bin/bash

gcf || exit 1

cat /tmp/gcf-model.json | jq -r '.apache2.vhosts[] | @base64' | while read vhost; do
    vhost_name="$(echo "${vhost}" | base64 -d | jq -r .name)"
    mkdir -p /var/www/"${vhost_name}" || exit 1
    echo "Default content for ${vhost_name}" > /var/www/"${vhost_name}"/index.html
done

httpd-foreground