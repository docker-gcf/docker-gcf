#! /bin/sh

HOME_BASE_URL="https://raw.githubusercontent.com/robin-thoni/docker-utils/develop"

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

  pkgs_install ca-certificates wget curl python3 python3-pip rsync jq || exit 1

  pip3 install -U argparse jinja2 || exit 1

  echo_dbg "Installing pkgs-install..."
  exe="/usr/local/bin/pkgs-install"
  dl_file "${HOME_BASE_URL}/debian/pkgs-install" "${exe}" && chmod +x "${exe}" || exit 1

  echo_dbg "Installing gcf..."
  exe="/usr/local/bin/gcf"
  dl_file "${HOME_BASE_URL}/debian/gcf.py" "${exe}" && chmod +x "${exe}" || exit 1


  echo_dbg "Cleaning apt cache..."
  apt-get clean && rm -rf /var/lib/apt/lists/* || exit 1

}

main
