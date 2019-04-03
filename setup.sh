#! /bin/sh

VERSION_PREFIX=v
VERSION=1.5.0
#VERSION_PREFIX=
#VERSION=develop

ZIP_URL="https://github.com/docker-gcf/docker-gcf/archive/${VERSION_PREFIX}${VERSION}.zip"

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
  local exe_name="${1}"

  if which "${exe_name}" 2>&1 >/dev/null
  then
    return 0
  else
    return 1
  fi
}

dl_file()
{
    local file_url="${1}"
    local file_path="${2}"

    if has_exe wget
    then
        wget "${file_url}" -O "${file_path}" || return 1
    elif has_exe curl
    then
        curl "${file_url}" -o "${file_path}" || return 1
    else
        echo_err "No backend for download"
        return 1
    fi
}

debian_pkgs_update()
{
  apt-get update || return 1
}

debian_pkgs_install()
{
  apt-get install --no-install-recommends -y "${@}" || return 1
}

pkgs_update()
{
  debian_pkgs_update || return 1
}

pkgs_install()
{
  if [ "${PKGS_CACHE_UPDATED}" != "1" ]
  then
    echo_dbg "Updating pkgs cache..."
    pkgs_update || return 1
    PKGS_CACHE_UPDATED=1
  fi

  debian_pkgs_install "${@}" || return 1
}

main()
{
    echo_dbg "Installing basic packages..."
    pkgs_install ca-certificates wget curl unzip || exit 1

    echo_dbg "Downloading docker-gcf archive..."
    dl_file "${ZIP_URL}" "/tmp/docker-gcf.zip" || exit 1
    cd /tmp && unzip docker-gcf.zip || exit 1
    mv "/tmp/docker-gcf-${VERSION}" "/tmp/docker-gcf" || exit 1

    BASE_DIR="/tmp/docker-gcf" exec sh /tmp/docker-gcf/src/setup.sh "${@}"
}

main "${@}"
