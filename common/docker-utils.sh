export CONFIG_DIR="/etc/default/config-files"

resolv_host()
{
  hostname="${1}"
  ip=$(getent hosts "${hostname}" | cut -d' ' -f1)
  echo "${ip}"
}

replace_var()
{
  file="${1}"
  var="${2}"
  sed -e "s?${var}?${!var}?g" -i "${file}"
}

replace_vars()
{
  file="${1}"
  for var in $(cat "${CONFIG_DIR}/vars-vars")
  do
    replace_var "${file}" "${var}"
  done
}

replace_files()
{
  cat "${CONFIG_DIR}/vars-files" | while read line
  do
    filesrc="${CONFIG_DIR}/$(echo "${line}" | awk '{print $1}')"
    filedst=$(echo "${line}" | awk '{print $2}')
    if [ -f "${filesrc}" ]
    then
      echo "Expanding file ${filesrc} to ${filedst}"
      cp "${filesrc}" "${filedst}"
      replace_vars "${filedst}"
    else
      echo "File ${filesrc} does not exist. Skipping."
    fi
  done
}
