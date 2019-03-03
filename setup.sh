#! /bin/sh

VERSION=v1.3.0
#VERSION=develop

HOME_BASE_URL="https://raw.githubusercontent.com/robin-thoni/docker-utils/${VERSION}"
ZIP_URL="https://github.com/robin-thoni/docker-utils/archive/${VERSION}.zip"

PKGS_CACHE_UPDATED=0

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

debian_pkgs_update()
{
  apt-get update || exit 1
}

debian_pkgs_install()
{
  apt-get install --no-install-recommends -y "${@}" || return 1
}

pkgs_update()
{
  debian_pkgs_update
}

pkgs_install()
{
  if [ "${PKGS_CACHE_UPDATED}" != "1" ]
  then
    echo_dbg "Updating pkgs cache..."
    pkgs_update || return 1
    PKGS_CACHE_UPDATED=1
  fi

  debian_pkgs_install "${@}"
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

  echo_dbg "Installing basic packages..."
  pkgs_install ca-certificates wget curl jq unzip || exit 1

  echo_dbg "Installing salt..."
  curl -L https://bootstrap.saltstack.com -o /tmp/bootstrap_salt.sh || exit 1
  BS_SALT_MASTER_ADDRESS=not-a-salt-server sh /tmp/bootstrap_salt.sh || exit 1

  if [ -e /docker-utils/ ]
  then
    echo_dbg "Copying docker-utils folder..."
    cp -r /docker-utils/ "/tmp/docker-utils-${VERSION}"
  else
    echo_dbg "Downloading docker-utils archive..."
    dl_file "${ZIP_URL}" "/tmp/docker-utils.zip" || exit 1
    cd /tmp && unzip docker-utils.zip
  fi

  echo_dbg "Installing docker-utils files..."
  cd "/tmp/docker-utils-*" && \
    cp -r debian/bin/* /usr/local/bin/ && cp -r common/salt/* /etc/salt/ || exit 1

  echo_dbg "Cleaning apt cache and tmp files..."
  apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* || exit 1

}

main
