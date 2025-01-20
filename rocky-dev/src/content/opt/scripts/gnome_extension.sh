#!/bin/bash

set -e

if [[ "$#" -lt 2 ]]; then
  echo >&2 "Usage: gnome_extension.sh <gnome-extension-id> <gnome-extension-download-url> [<media-cache-dir>]"
  exit 1
fi

gnome_extension_id="${1}"
gnome_extension_dist_url="${2}"
media_cache_dir=${3}

user_home_dir="${HOME}"
user_name="${USER}"
user_group="${user_name}"
if [[ -n "${VM_USER}" ]]; then
  user_home_dir="/home/${VM_USER}"
  user_name="${VM_USER}"
fi
if [[ -n "${VM_USER_GROUP}" ]]; then
  user_group="${VM_USER_GROUP}"
fi

user_home_local_dir="${user_home_dir}/.local"
user_home_local_share_dir="${user_home_local_dir}/share"
gnome_config_dir="${user_home_local_share_dir}/gnome-shell"
gnome_extensions_user_dir="${gnome_config_dir}/extensions"
gnome_extension_dir="${gnome_extensions_user_dir}/${gnome_extension_id}"

if [[ -e "${gnome_extension_dir}" ]]; then
  echo "${gnome_extension_id} GNOME extension is already installed, skipping installation"
  exit 0
fi

gnome_extension_filename="$(echo "${gnome_extension_dist_url}" | sed -r 's/^https:\/\/.+\/(.+?\.zip)$/\1/;t;d')"
if [[ -n "${media_cache_dir}" ]]; then
  gnome_extension_dist="${media_cache_dir}/${gnome_extension_filename}"
else
  gnome_extension_dist="/tmp/${gnome_extension_filename}"
fi
if ! [[ -f "${gnome_extension_dist}" ]]; then
  echo "Downloading ${gnome_extension_id} GNOME extension from ${gnome_extension_dist_url} into ${gnome_extension_dist} file"
  curl -sLf -o "${gnome_extension_dist}" "${gnome_extension_dist_url}"
fi
echo "Installing ${gnome_extension_id} GNOME extension from ${gnome_extension_dist} file into ${gnome_extension_dir} directory"

if ! [[ -e "${user_home_dir}" ]]; then
  mkdir -p "${user_home_dir}"
  chown -R "${user_name}:${user_group}" "${user_home_dir}"
  chmod -R u=rwX,g=rX,o= "${user_home_dir}"
fi
if ! [[ -e "${user_home_local_dir}" ]]; then
  mkdir -p "${user_home_local_dir}"
  chown -R "${user_name}:${user_group}" "${user_home_local_dir}"
  chmod -R u=rwX,g=,o= "${user_home_local_dir}"
fi
if ! [[ -e "${user_home_local_share_dir}" ]]; then
  mkdir -p "${user_home_local_share_dir}"
  chown -R "${user_name}:${user_group}" "${user_home_local_share_dir}"
  chmod -R u=rwX,g=,o= "${user_home_local_share_dir}"
fi
if ! [[ -e "${gnome_config_dir}" ]]; then
  mkdir -p "${gnome_config_dir}"
  chown -R "${user_name}:${user_group}" "${gnome_config_dir}"
  chmod -R u=rwX,g=,o= "${gnome_config_dir}"
fi
if ! [[ -e "${gnome_extensions_user_dir}" ]]; then
  mkdir -p "${gnome_extensions_user_dir}"
  chown -R "${user_name}:${user_group}" "${gnome_extensions_user_dir}"
  chmod -R u=rwX,g=rwX,o=rX "${gnome_extensions_user_dir}"
fi

mkdir -p "${gnome_extension_dir}"
unzip -q "${gnome_extension_dist}" -d "${gnome_extension_dir}"
chown -R "${user_name}:${user_group}" "${gnome_extension_dir}"
chmod -R u=rwX,g=rwX,o=rX "${gnome_extension_dir}"

if [[ -z "${media_cache_dir}" ]]; then
  rm -f "${gnome_extension_dist}"
fi
