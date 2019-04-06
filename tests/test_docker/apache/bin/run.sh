#! /bin/sh

cat /tmp/gcf-model.json | jq -r '.model.apache2.vhosts[] | @base64' | while read vhost; do
    vhost_name="$(echo "${vhost}" | base64 -d | jq -r .name)"
    echo "Serving host: ${vhost_name}"
done

httpd-foreground
