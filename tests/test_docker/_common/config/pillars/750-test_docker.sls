gcf:
  entrypoint:
    env:
      exports:
        NC_SERVER_PORT: {{ stack['nc_server']['port'] | string | yaml }}
        NC_SERVER_HOST: {{ stack['nc_server']['host'] | string | yaml }}
