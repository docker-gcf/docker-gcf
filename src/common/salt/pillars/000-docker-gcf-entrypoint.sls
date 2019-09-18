gcf:
  entrypoint:
    debug:
      pillar:
        print: False
      env:
        clear: True
        export: True
      cmd:
        execute: True
    env:
      exports:
        TZ: Europe/London
