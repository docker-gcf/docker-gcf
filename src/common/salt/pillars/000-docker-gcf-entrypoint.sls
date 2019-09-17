gcf:
  entrypoint:
    debug:
      pillar:
        print: False
      apply:
        print: False
        execute: True
      env:
        clear: True
      cmd:
        execute: True
    env:
      exports: []
