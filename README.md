Usage:

Dockerfile (replace 'vx.y.z' with actual version):
``` Dockerfile
ADD https://raw.githubusercontent.com/robin-thoni/docker-utils/vx.y.z/setup.sh /tmp/docker-utils-setup.sh
RUN sh /tmp/docker-utils-setup.sh
COPY ./config /etc/salt/base/
COPY ./bin /usr/local/bin/

RUN pkgs-install my-program
# [...]
ENTRYPOINT ["run.sh"]
```

run.sh:
```shell
#! /bin/bash

gcf && \
my_program --foreground --some-arg="$(cat /tmp/gcf-model.json | jq -r .some.value)"
```

See [`tests/test_docker`](./tests/test_docker) for a complete docker example.
