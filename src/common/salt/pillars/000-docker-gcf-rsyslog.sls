gcf:
  supervisor:
    programs:
      rsyslog:
        extraConfig:
          command: rsyslogd -n
          priority: 100
          stdout_logfile: /dev/stdout
          stderr_logfile: /dev/stderr
          stopsignal: TERM
