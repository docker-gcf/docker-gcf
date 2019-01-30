#! /bin/sh

HOME_BASE_URL="https://raw.githubusercontent.com/robin-thoni/docker-utils/v0.1.0"

PKGS_CACHE_UPDATED=0
DOCKER_UTILS_SHARE_PATH="/usr/local/share/docker-utils"

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
  apt-get install -y "${@}" || return 1
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

  if has_exe wget
  then
    HAS_WGET=1
  else
    HAS_WGET=0
  fi

  if has_exe curl
  then
    HAS_CURL=1
  else
    HAS_CURL=0
  fi

  if [ "${HAS_WGET}" = "0" ] && [ "${HAS_CURL}" = "0" ]
  then
    default_dl="wget"
    echo_dbg "wget and curl are not available. Installing ${default_dl}..."
    pkgs_install "${default_dl}" || exit 1
    unset default_dl
  else
    echo_dbg "Found wget and/or curl."
  fi

  echo_dbg "Installing apt-get-install..."
  apti="/usr/local/bin/apt-get-install"
  dl_file "${HOME_BASE_URL}/debian/apt-get-install" "${apti}" && chmod +x "${apti}" || exit 1


  echo_dbg "Creating common dirs..."
  mkdir -p "${DOCKER_UTILS_SHARE_PATH}" || exit1

  echo_dbg "Installing docker-utils.sh"
  dl_file "${HOME_BASE_URL}/common/docker-utils.sh" "${DOCKER_UTILS_SHARE_PATH}/docker-utils.sh" || exit 1


  echo_dbg "Cleaning apt cache..."
  apt-get clean && rm -rf /var/lib/apt/lists/* || exit 1

}

main
