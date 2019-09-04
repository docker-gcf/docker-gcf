#! /bin/sh

BASE_DIR=${BASE_DIR:="$(dirname "${0}")/.."}
BASE_MODULES=""

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
    res=0
  else
    res=1
  fi

  return "${res}"
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

YUM_pkgs_clean()
{
  yum clean all || return 1
}

DPKG_pkgs_clean()
{
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* || return 1
}

pkgs_clean()
{
  ${_OSTYPE}_pkgs_clean || return 1
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

install_gcf()
{
    echo_dbg "Installing docker-gcf files..."

    mkdir -p "/etc/salt/" && \
    install_folder "${BASE_DIR}/src/salt/" /etc/salt/ && \
    install_gcf_module_folder "${BASE_DIR}" || return 1
}

YUM_install_pkgs()
{

    local deps_setup="ca-certificates wget curl gawk grep unzip"
    local deps_runtime_utils="jq ssmtp moreutils"
    local deps_runtime_main="supervisor rsyslog"
    local deps_wait_for_tcp="nc coreutils"

    pkgs-install epel-release

    pkgs-install ${deps_setup} ${deps_runtime_utils} ${deps_runtime_main} ${deps_wait_for_tcp} || return 1

    touch /etc/default/locale
}

DPKG_install_pkgs()
{

    local deps_setup="ca-certificates wget curl gawk grep unzip"
    local deps_runtime_utils="jq ssmtp moreutils"
    local deps_runtime_main="supervisor rsyslog"
    local deps_wait_for_tcp="netcat-openbsd coreutils"

    pkgs-install ${deps_setup} ${deps_runtime_utils} ${deps_runtime_main} ${deps_wait_for_tcp} || return 1

    touch /etc/default/locale
}

install_pkgs()
{
    echo_dbg "Installing basic packages..."

    ${_OSTYPE}_install_pkgs || return 1
}

install_salt()
{
    echo_dbg "Installing salt..."

    curl -L https://bootstrap.saltstack.com -o /tmp/bootstrap_salt.sh && \
    sh /tmp/bootstrap_salt.sh -X stable 2019.2.0 && \
    rm -f /tmp/bootstrap_salt.sh /tmp/bootstrap-salt.log || return 1
}

install_folder()
{
    local src="${1}"
    local dst="${2}"

    if [ -d "${src}" ]
    then
        echo_dbg "Copying ${src} to ${dst}"
        cp -r "${src}/." "${dst}" || return 1
    else
        echo_dbg "Ignoring ${src}"
    fi
}

install_gcf_module_folder()
{
    local folder_path="${1}"
    echo_dbg "Installing gcf module ${folder_path} from folder..."

    install_folder "${folder_path}/src/common/salt/" /etc/salt/base/ && \
    install_folder "${folder_path}/src/common/bin/" /usr/local/bin/ && \
    install_folder "${folder_path}/src/${_OSTYPE}/bin/" /usr/local/bin/ || return 1
}

install_gcf_module_zip()
{
    local zip_path="${1}"
    local folder_path="/tmp/$(unzip -Z -1 "${zip_path}" | head -n1)"
    local folder_name="$(basename "${folder_path}")"
    echo_dbg "Installing gcf module ${zip_path} from zip..."

    cd "/tmp" && \
    unzip -o "${zip_path}" && \
    install_gcf_module_folder "${folder_path}" || return 1

    rm -rf "/usr/local/src/${folder_name}" && \
    mv "${folder_path}" /usr/local/src/ || return 1
}

install_gcf_modules()
{
    local modules="${1}"
    echo_dbg "Installing gcf modules..."

    for module_full in ${modules}
    do
        if echo "${module_full}" | grep -cE "^file://" 2>&1 >/dev/null
        then
            local path="$(echo "${module_full}" | sed -e "s#file://##")"

            if [ -f "${path}" ]
            then
                install_gcf_module_zip "${path}" || return 1
            elif [ -d "${path}" ]
            then
                install_gcf_module_folder "${path}" || return 1
            else
                return 1
            fi
        else
            local zip_path=""
            local zip_url=""

            if echo "${module_full}" | grep -cE "^https?://" 2>&1 >/dev/null
            then
                zip_path="$(mktemp /tmp/XXXXXX.zip)"
                zip_url="${module_full}"
            else
                local module_name="$(echo "${module_full}" | awk -F '=' '{print $1}')"
                local module_version="$(echo "${module_full}" | awk -F '=' '{print $2}')"
                local module_version_prefix=""

                if echo "${module_version}" | grep -cE "^[0-9]+\.[0-9]+\.[0-9]+$" 2>&1 >/dev/null
                then
                    module_version_prefix="v"
                fi
                zip_path="/tmp/${module_name}.zip"
                zip_url="https://github.com/docker-gcf/module-${module_name}/archive/${module_version_prefix}${module_version}.zip"
            fi
            dl_file "${zip_url}" "${zip_path}" && \
            install_gcf_module_zip "${zip_path}" && \
            rm "${zip_path}" || return 1
        fi


    done
}

main()
{
    local modules=
    local flag_install_gcf=0
    local flag_install_pkgs=0
    local flag_install_salt=0
    local flag_install_modules=0

    _OSTYPE_detect || exit 1

    if ! has_exe "${_OSTYPE}_pkgs_clean"
    then
        echo_dbg "${_OSTYPE} is not supported"
        return 1
    fi

    echo_dbg "Using ${_OSTYPE}"

    while getopts 'm:gpsn' c
    do
        case "${c}" in
            m)
                modules="${modules} ${OPTARG}"
            ;;
            g)
                flag_install_gcf=1
            ;;
            p)
                flag_install_pkgs=1
            ;;
            s)
                flag_install_salt=1
            ;;
            n)
                flag_install_modules=1
            ;;
            *)
                echo_err "Usage error"
                exit 64
            ;;
        esac
    done
    echo_dbg "Working dir: $(pwd)"
    echo_dbg "Base dir: ${BASE_DIR}"

    if [ "${flag_install_gcf}" = "1" ]
    then
        install_gcf || exit 1
    fi

    if [ "${flag_install_pkgs}" = "1" ]
    then
        install_pkgs || exit 1
    fi

    if [ "${flag_install_salt}" = "1" ]
    then
        install_salt || exit 1
    fi

    if [ "${flag_install_modules}" = "1" ]
    then
        install_gcf_modules "${BASE_MODULES}" || exit 1
    fi

    install_gcf_modules "${modules}" || exit 1

    echo_dbg "Cleaning"
    pkgs_clean

}

main "${@}"
