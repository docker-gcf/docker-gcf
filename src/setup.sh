#! /bin/sh

BASE_DIR=${BASE_DIR:="$(dirname "${0}")"}

echo_dbg()
{
  echo "====" "${@}"
}

echo_err()
{
  echo "====" "${@}" >&2
}

has_exe()
{
  exe_name="${1}"
  if which "${exe_name}" 2>&1 >/dev/null
  then
    res=0
  else
    res=1
  fi

  return "${res}"
}

dl_file()
{
  file_url="${1}"
  file_path="${2}"
  if has_exe wget
  then
    wget "${file_url}" -O "${file_path}"
  elif has_exe curl
  then
    curl "${file_url}" -o "${file_path}"
  else
    echo "No backend for download" >&2
    return 1
  fi
}

main()
{
    if has_exe apt-get
    then
        echo_dbg "apt-get is available, assuming Debian-like distro."
    else
        echo_err "Distro is not supported"
        exit 1
    fi
    echo_dbg "Working dir: $(pwd)"
    echo_dbg "Base dir: ${BASE_DIR}"

    echo_dbg "Installing docker-utils files..."
    mkdir -p "/etc/salt/" && \
    cp -r "${BASE_DIR}"/debian/bin/* /usr/local/bin/ && \
    cp -r "${BASE_DIR}"/common/bin/* /usr/local/bin/ && \
    cp -r "${BASE_DIR}"/common/salt/* /etc/salt/ || exit 1

    echo_dbg "Installing basic packages..."
    pkgs-install ca-certificates wget curl jq unzip ssmtp || exit 1

    echo_dbg "Installing salt..."
    curl -L https://bootstrap.saltstack.com -o /tmp/bootstrap_salt.sh || exit 1
    sh /tmp/bootstrap_salt.sh -X -A '' stable 2019.2.0 || exit 1

    echo_dbg "Cleaning up..."
    rm -rf /tmp/* || exit 1
}

main
