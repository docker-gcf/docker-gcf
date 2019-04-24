gcf:
  supervisor:
    programs:
      nc-server:
        extraConfig:
          command: nc-server
          startsecs: 5
          stopsignal: KILL
