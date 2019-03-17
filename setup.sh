#! /bin/sh

VERSION_PREFIX=v
VERSION=1.4.0
#VERSION_PREFIX=
#VERSION=develop

HOME_BASE_URL="https://raw.githubusercontent.com/robin-thoni/docker-utils/${VERSION_PREFIX}${VERSION}"
ZIP_URL="https://github.com/robin-thoni/docker-utils/archive/${VERSION_PREFIX}${VERSION}.zip"

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
    echo_dbg "Installing basic packages..."
    pkgs_install ca-certificates wget curl jq unzip

    echo_dbg "Downloading docker-utils archive..."
    dl_file "${ZIP_URL}" "/tmp/docker-utils.zip" || exit 1
    cd /tmp && unzip docker-utils.zip || exit 1
    mv "/tmp/docker-utils-${VERSION}" "/tmp/docker-utils" || exit 1

    BASE_DIR="/tmp/docker-utils" exec sh /tmp/docker-utils/src/setup.sh
}

main
