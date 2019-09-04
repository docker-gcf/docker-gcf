#! /bin/sh

#VERSION_PREFIX=v
#VERSION=1.5.0
VERSION_PREFIX=
VERSION=develop

ZIP_URL="https://github.com/docker-gcf/docker-gcf/archive/${VERSION_PREFIX}${VERSION}.zip"

PKGS_CACHE_UPDATED=0

_OSTYPE=""

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

  if type "${exe_name}" 2>&1 >/dev/null
  then
    return 0
  else
    return 1
  fi
}

# From pacapt
# Detect package type from /etc/issue
_found_arch() {
  local _ostype="$1"
  shift
  grep -qis "$*" /etc/issue && _OSTYPE="$_ostype"
}

# Detect package type
_OSTYPE_detect() {
  _found_arch PACMAN "Arch Linux" && return
  _found_arch DPKG   "Debian GNU/Linux" && return
  _found_arch DPKG   "Ubuntu" && return
  _found_arch YUM    "CentOS" && return
  _found_arch YUM    "Red Hat" && return
  _found_arch YUM    "Fedora" && return
  _found_arch ZYPPER "SUSE" && return

  [[ -z "$_OSTYPE" ]] || return

  # See also https://github.com/icy/pacapt/pull/22
  # Please not that $OSTYPE (which is `linux-gnu` on Linux system)
  # is not our $_OSTYPE. The choice is not very good because
  # a typo can just break the logic of the program.
  if [[ "$OSTYPE" != "darwin"* ]]; then
    echo_err "Can't detect OS type from /etc/issue. Running fallback method."
  fi
  [[ -x "/usr/bin/pacman" ]]           && _OSTYPE="PACMAN" && return
  [[ -x "/usr/bin/apt-get" ]]          && _OSTYPE="DPKG" && return
  [[ -x "/usr/bin/yum" ]]              && _OSTYPE="YUM" && return
  [[ -x "/opt/local/bin/port" ]]       && _OSTYPE="MACPORTS" && return
  command -v brew >/dev/null           && _OSTYPE="HOMEBREW" && return
  [[ -x "/usr/bin/emerge" ]]           && _OSTYPE="PORTAGE" && return
  [[ -x "/usr/bin/zypper" ]]           && _OSTYPE="ZYPPER" && return
  if [[ -z "$_OSTYPE" ]]; then
    echo_err "No supported package manager installed on system"
    echo_err "(supported: apt, homebrew, pacman, portage, yum)"
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

YUM_pkgs_update()
{
  yum check-update || return 1
}

YUM_pkgs_install()
{
  yum install -y "${@}" || return 1
}

DPKG_pkgs_update()
{
  apt-get update || return 1
}

DPKG_pkgs_install()
{
  apt-get install --no-install-recommends -y "${@}" || return 1
}

pkgs_update()
{
  ${_OSTYPE}_pkgs_update || return 1
}

pkgs_install()
{
  if [ "${PKGS_CACHE_UPDATED}" != "1" ]
  then
    echo_dbg "Updating pkgs cache..."
    pkgs_update || return 1
    PKGS_CACHE_UPDATED=1
  fi

  ${_OSTYPE}_pkgs_install "${@}" || return 1
}

main()
{
    _OSTYPE_detect || exit 1

    if ! has_exe "${_OSTYPE}_pkgs_install"
    then
        echo_dbg "${_OSTYPE} is not supported"
        return 1
    fi

    echo_dbg "Using ${_OSTYPE}"


    echo_dbg "Installing basic packages..."
    pkgs_install ca-certificates wget curl unzip || exit 1

    echo_dbg "Downloading docker-gcf archive..."
    dl_file "${ZIP_URL}" "/tmp/docker-gcf.zip" || exit 1
    cd /tmp && unzip docker-gcf.zip && rm docker-gcf.zip || exit 1
    rm -rf "/usr/local/src/docker-gcf" && \
    mv "/tmp/docker-gcf-${VERSION}" /usr/local/src/docker-gcf || exit 1

    exec sh /usr/local/src/docker-gcf/src/setup.sh -gpsn "${@}"
}

main "${@}"
