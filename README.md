Usage:

Dockerfile (replace 'vx.y.z' with actual version):
``` Dockerfile
ADD https://raw.githubusercontent.com/docker-gcf/docker-gcf/vx.y.z/setup.sh /tmp/docker-gcf-setup.sh
RUN sh /tmp/docker-gcf-setup.sh
ENTRYPOINT ["gcf-entrypoint"]
CMD ["supervisord", "-n"]

RUN pkgs-install my-program

COPY ./bin /usr/local/bin/
COPY ./config /etc/salt/base/

```

run.sh:
```shell
#! /bin/bash

my_program --foreground --some-arg="$(cat /tmp/gcf-model.json | jq -r .some.value)"
```

See [`tests/test_docker`](./tests/test_docker) for a complete docker example.
