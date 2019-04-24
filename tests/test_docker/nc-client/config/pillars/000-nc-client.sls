gcf:
  supervisor:
    programs:
      nc-client:
        extraConfig:
          command: wait-for-nc-server nc-client
          startsecs: 6
          stopsignal: KILL
