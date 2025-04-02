#!/bin/bash -eux

function make_backup {
  if [[ -f "$1.bak" ]]; then
    cp -p -f "$1.bak" "$1"
  else
    cp -p "$1" "$1.bak"
  fi
}

function make_dir {
  local dir_user="${1}"
  local dir_group="${2}"
  local dir_permissions="${3}"
  local dir_path="${4}"
  if [[ -z "${dir_path}" ]]; then
    return
  fi
  if [[ -d "${dir_path}" ]]; then
    return
  fi
  make_dir "${dir_user}" "${dir_group}" "${dir_permissions}" "$(dirname "${dir_path}")"
  mkdir "${dir_path}"
  chown "${dir_user}:${dir_group}" "${dir_path}"
  chmod "${dir_permissions}" "${dir_path}"
}

function escape_text_for_regex() {
  local text="${1}"
  text="${text//\\/\\\\}"
  text="${text//\*/\\*}"
  text="${text//+/\\+}"
  text="${text//-/\\-}"
  text="${text//./\\.}"
  text="${text//\?/\\?}"
  text="${text//^/\\^}"
  text="${text//$/\\$}"
  text="${text//\(/\\(}"
  text="${text//\)/\\)}"
  text="${text//[/\\[}"
  text="${text//]/\\]}"
  text="${text//\{/\\{}"
  text="${text//\}/\}}"
  echo "${text}"
}

function escape_text_for_sed() {
  local text="${1}"
  text="${text////\\/}"
  echo "${text}"
}

function add_line_to_hosts() {
  grep -q -F "$1" /etc/hosts || echo "$1" >>/etc/hosts
}

golang_private_repository="gitlab.c2g.pw"

user_home_dir="/home/${VAGRANT_BOX_USER}"

# Default name of OS account. Matches with base VM defined in Vagrantfile (refer to config.vm.box)
MY_USER="${VAGRANT_BOX_USER}"
# Default password for OS account. Matches with base VM defined in Vagrantfile (refer to config.vm.box)
MY_PASSWORD="${VAGRANT_BOX_PASSWORD}"
# Default full name of user for OS account and Git
MY_NAME="User"
# Default user email for Git
MY_EMAIL="${VAGRANT_BOX_USER}@localdomain.local"
# Default user time zone
MY_TIMEZONE="Europe/Moscow"
# Load custom OS account name and password, full user name and email, Maven project ID
customization_script_file="${PROVISION_CONTENT_DIR}/user.sh"
if [[ -f "${customization_script_file}" ]]; then
  # shellcheck disable=SC1090
  source "${customization_script_file}"
  rm -f "${customization_script_file}"
fi

# Map hostname to private network address
add_line_to_hosts "${PRIVATE_NETWORK_ADDRESS}    ${HOSTNAME}"

# Copy SSH private keys ("${PROVISION_CONTENT_DIR}"/.ssh/id_rsa*, "${PROVISION_CONTENT_DIR}"/.ssh/id_ed* -> ${user_home_dir}/.ssh/)
ssh_user_config_dir="${user_home_dir}/.ssh"
mkdir -p "${ssh_user_config_dir}"
ssh_customization_dir="${PROVISION_CONTENT_DIR}/.ssh"
find "${ssh_customization_dir}" -name "id_rsa*" -type f -printf "%f\0" \
  | xargs --null -I{} mv -f "${ssh_customization_dir}/"{} "${ssh_user_config_dir}/"
find "${ssh_customization_dir}" -name "id_ed*" -type f -printf "%f\0" \
  | xargs --null -I{} mv -f "${ssh_customization_dir}/"{} "${ssh_user_config_dir}/"
if [[ -f "${ssh_customization_dir}/known_hosts" ]]; then
  mv -f "${ssh_customization_dir}/known_hosts" "${ssh_user_config_dir}/"
fi
if [[ -f "${ssh_customization_dir}/config" ]]; then
  mv -f "${ssh_customization_dir}/config" "${ssh_user_config_dir}/"
fi

# Copy auto-login configuration
login_customization_file="${PROVISION_CONTENT_DIR}/login/.netrc"
if [[ -f "${login_customization_file}" ]]; then
  user_login_file="${user_home_dir}/.netrc"
  cp --no-preserve=all "${login_customization_file}" "${user_login_file}"
  chmod 600 "${user_login_file}"
fi

# Configure Go Modules private repository
etc_profile_env_script="/etc/profile.d/localenv.sh"
echo "export GOPRIVATE=$(printf "%q" "${golang_private_repository}")" >>"${etc_profile_env_script}"

# IntelliJ IDEA offline license key
idea_config_dir="${user_home_dir}/.config/JetBrains/IntelliJIdea"
idea_key_src_file="${PROVISION_CONTENT_DIR}/idea/idea.key"
if [[ -f "${idea_key_src_file}" ]]; then
  mkdir -p "${idea_config_dir}"
  idea_key_dst_file="${idea_config_dir}/idea.key"
  mv -f "${idea_key_src_file}" "${idea_key_dst_file}"
  chmod 600 "${idea_key_dst_file}"
fi

# GoLand offline license key
goland_config_dir="${user_home_dir}/.config/JetBrains/GoLand"
goland_key_src_file="${PROVISION_CONTENT_DIR}/goland/goland.key"
if [[ -f "${goland_key_src_file}" ]]; then
  mkdir -p "${goland_config_dir}"
  goland_key_dst_file="${goland_config_dir}/goland.key"
  mv -f "${goland_key_src_file}" "${goland_key_dst_file}"
  chmod 600 "${goland_key_dst_file}"
fi

# CLion offline license key
clion_config_dir="${user_home_dir}/.config/JetBrains/CLion"
clion_key_src_file="${PROVISION_CONTENT_DIR}/clion/clion.key"
if [[ -f "${clion_key_src_file}" ]]; then
  mkdir -p "${clion_config_dir}"
  clion_key_dst_file="${clion_config_dir}/clion.key"
  mv -f "${clion_key_src_file}" "${clion_key_dst_file}"
  chmod 600 "${clion_key_dst_file}"
fi

docker_customization_dir="${PROVISION_CONTENT_DIR}/.docker"
# Copy Docker authentication data
if [[ -f "${docker_customization_dir}/config.json" ]]; then
  docker_user_config_dir="${user_home_dir}/.docker"
  mkdir -p "${docker_user_config_dir}"
  mv -f "${docker_customization_dir}/config.json" "${docker_user_config_dir}/"
  chmod -R u=rwX,g=,o= "${docker_user_config_dir}"
fi

# Change VSCode editor font and turn on ligatures
vs_code_user_settings_file="${user_home_dir}/.config/Code/User/settings.json"
sed -ri 's/("editor\.fontFamily":).+$/\1 "''Fira Code''",/' "${vs_code_user_settings_file}"
sed -ri 's/("editor\.fontLigatures":).+$/\1 true,/' "${vs_code_user_settings_file}"

# Change system time zone to MSK
if [[ $(grep -c "$(escape_text_for_regex "${MY_TIMEZONE}")" /etc/timezone) -eq 0 ]]; then
  echo "${MY_TIMEZONE}" >/etc/timezone
  ln -fs "/usr/share/zoneinfo/${MY_TIMEZONE}" /etc/localtime
fi

# Configure Git: fill user name and user email
git_user_config_file="${user_home_dir}/.gitconfig"
sed -i -r 's/\{name\}/'"$(escape_text_for_sed "${MY_NAME}")"'/' "${git_user_config_file}"
sed -i -r 's/\{email\}/'"$(escape_text_for_sed "${MY_EMAIL}")"'/' "${git_user_config_file}"
# Go Modules fix for GitLab (in case of repository renaming).
# Use SSH instead of HTTPS to fetch Go Modules.
# Refer to https://github.com/golang/go/issues/37504.
cat <<EOF >>"${git_user_config_file}"
[url "git@${golang_private_repository}:"]
        insteadOf = https://${golang_private_repository}/
EOF

# Change name of OS account
if [[ $(grep -c -E "^$(escape_text_for_regex "${MY_USER}:")" /etc/passwd) -eq 0 ]]; then
  usermod -l "${MY_USER}" "${VAGRANT_BOX_USER}"
  chfn -f "${MY_NAME}" "${MY_USER}"
  provision_user_sed_expr="$(escape_text_for_sed "$(escape_text_for_regex "${VAGRANT_BOX_USER}")")"
  my_user_sed_expr="$(escape_text_for_sed "${MY_USER}")"
  sed -i "s/${provision_user_sed_expr}/${my_user_sed_expr}/g" /etc/subuid
  sed -i "s/${provision_user_sed_expr}/${my_user_sed_expr}/g" /etc/subgid
fi

# Fix permissions for application anchors
find "${user_home_dir}" -name "*.desktop" -type f -exec chmod 755 {} +

# Fix permissions for SSH configuration files
find "${ssh_user_config_dir}" -type f -exec chmod 600 {} +
chmod 700 "${ssh_user_config_dir}"

# Additional Bash aliases
bash_customization_dir="${PROVISION_CONTENT_DIR}/bash"
if [[ -f "${bash_customization_dir}/.bash_aliases" ]]; then
  mkdir -p "${user_home_dir}"
  # Add line break to ensure that new aliases will be appended starting from new line
  bash_aliases_user_config_file="${user_home_dir}/.bash_aliases"
  if [[ -f "${bash_aliases_user_config_file}" ]]; then
    echo -e '\n' >>"${bash_aliases_user_config_file}"
  fi
  cat "${bash_customization_dir}/.bash_aliases" >>"${bash_aliases_user_config_file}"
fi

# Fix permissions of home directory
chown -R "${MY_USER}:${VAGRANT_BOX_USER_GROUP}" "${user_home_dir}"

# Change password of OS account
echo "${MY_USER}:${MY_PASSWORD}" | chpasswd
# Reset GNOME keyrings because of changing of password of OS account
rm -f "${user_home_dir}/.local/share/keyrings/login.keyring"

# Refer to https://gist.github.com/leifg/4713995?permalink_comment_id=1615625#gistcomment-1615625
# for details about the way disk ID is generated and can be determined from respective VMDK file
ws_disk_fstab_id="/dev/disk/by-id/ata-VBOX_HARDDISK_VB1fef54b4-5d082cf0-part1"

ws_disk_mount_path="/ws"
echo "==> Mounting ws.vmdk disk as ${ws_disk_mount_path}"
mkdir -p "${ws_disk_mount_path}"
if ! grep -m 1 -E "$(escape_text_for_regex "${ws_disk_fstab_id}")\\s+$(escape_text_for_regex "${ws_disk_mount_path}")" /etc/fstab >/dev/null; then
  echo "${ws_disk_fstab_id} ${ws_disk_mount_path}                   xfs     defaults        0 0" >>/etc/fstab
fi
mount "${ws_disk_mount_path}"
systemctl daemon-reload
chown "${MY_USER}:${VAGRANT_BOX_USER_GROUP}" "${ws_disk_mount_path}"
chmod 775 "${ws_disk_mount_path}"

# Refer to https://gist.github.com/leifg/4713995?permalink_comment_id=1615625#gistcomment-1615625
# for details about the way disk ID is generated and can be determined from respective VMDK file
repository_disk_id="/dev/disk/by-id/ata-VBOX_HARDDISK_VBa23d58cb-8f3cfb19-part1"

repository_disk_mount_path="/repository"
mkdir -p ${repository_disk_mount_path}
echo "==> Mounting repository.vmdk disk as ${repository_disk_mount_path}"
if ! grep -m 1 -E "$(escape_text_for_regex "${repository_disk_id}")\\s+$(escape_text_for_regex "${repository_disk_mount_path}")" /etc/fstab >/dev/null; then
  echo "${repository_disk_id} ${repository_disk_mount_path}                   xfs     defaults        0 0" >>/etc/fstab
fi
mount "${repository_disk_mount_path}"
systemctl daemon-reload
chown "${MY_USER}:${VAGRANT_BOX_USER_GROUP}" "${repository_disk_mount_path}"
chmod 775 "${repository_disk_mount_path}"
# Create directories for package managers to ensure they work as expected
make_dir "${MY_USER}" "${VAGRANT_BOX_USER_GROUP}" 755 "${repository_disk_mount_path}/maven/repository"
make_dir "${MY_USER}" "${VAGRANT_BOX_USER_GROUP}" 755 "${repository_disk_mount_path}/npm/npm-cache"
make_dir "${MY_USER}" "${VAGRANT_BOX_USER_GROUP}" 755 "${repository_disk_mount_path}/go"
make_dir "${MY_USER}" "${VAGRANT_BOX_USER_GROUP}" 755 "${repository_disk_mount_path}/go/bin"
make_dir "${MY_USER}" "${VAGRANT_BOX_USER_GROUP}" 755 "${repository_disk_mount_path}/cache"
make_dir "${MY_USER}" "${VAGRANT_BOX_USER_GROUP}" 755 "${repository_disk_mount_path}/nuget/packages"

# Refer to https://gist.github.com/leifg/4713995?permalink_comment_id=1615625#gistcomment-1615625
# for details about the way disk ID is generated and can be determined from respective VMDK file
containers_disk_id="/dev/disk/by-id/ata-VBOX_HARDDISK_VB74a636ec-ff1f49fd-part1"

containers_disk_mount_path="/containers"
echo "==> Mounting containers.vmdk disk as ${containers_disk_mount_path}"
mkdir -p "${containers_disk_mount_path}"
chown root:root "${containers_disk_mount_path}"
chmod 711 "${containers_disk_mount_path}"
if ! grep -m 1 -E "$(escape_text_for_regex "${containers_disk_id}")\\s+$(escape_text_for_regex "${containers_disk_mount_path}")" /etc/fstab >/dev/null; then
  echo "${containers_disk_id} ${containers_disk_mount_path}                   xfs     defaults        0 0" >>/etc/fstab
fi
mount "${containers_disk_mount_path}"
systemctl daemon-reload
chown root:root "${containers_disk_mount_path}"
chmod 711 "${containers_disk_mount_path}"

echo "==> Preparing storage for Docker images and containers"
docker_storage_dir="${containers_disk_mount_path}/docker"
mkdir -p "${docker_storage_dir}"
chown root:root "${docker_storage_dir}"
chmod 711 "${docker_storage_dir}"

docker_daemon_config="/etc/docker/daemon.json"
if [[ -f "${docker_daemon_config}" ]]; then
  echo "==> Configuring Docker"
  make_backup "${docker_daemon_config}"
  jq ". + {\"data-root\": \"${docker_storage_dir}\"}" <"${docker_daemon_config}".bak >"${docker_daemon_config}"
  chown root:root "${docker_daemon_config}"
  chmod 644 "${docker_daemon_config}"
  systemctl stop docker
  systemctl start docker
fi

echo "export MINIKUBE_HOME=$(printf "%q" "${ws_disk_mount_path}/.minikube")" >>/etc/profile.d/localenv.sh

# Nautilus bookmarks
nautilus_user_bookmark_file="${user_home_dir}/.config/gtk-3.0/bookmarks"
mkdir -p "$(dirname "${nautilus_user_bookmark_file}")"
touch "${nautilus_user_bookmark_file}"
chown "${MY_USER}:${VAGRANT_BOX_USER_GROUP}" "${user_home_dir}/.config"
chown "${MY_USER}:${VAGRANT_BOX_USER_GROUP}" "${user_home_dir}/.config/gtk-3.0"
echo "file://${ws_disk_mount_path}" >>"${nautilus_user_bookmark_file}"
echo "file://${repository_disk_mount_path}" >>"${nautilus_user_bookmark_file}"

# OS account conf
account_conf_dir="/var/lib/AccountsService/users"
user_account_conf_file="${account_conf_dir}/${MY_USER}"
if [[ ! -f "${user_account_conf_file}" ]]; then
  mkdir -p "${account_conf_dir}"
  echo "[User]" >"${user_account_conf_file}"
  chown root:root "${user_account_conf_file}"
  chmod 644 "${user_account_conf_file}"
  echo "Session=gnome" >>"${user_account_conf_file}"
fi

# OS account avatar
account_customization_avatar_file="${PROVISION_CONTENT_DIR}/user.png"
if [[ -f ${account_customization_avatar_file} ]]; then
  account_icons_dir="/var/lib/AccountsService/icons"
  user_account_icon_file="${account_icons_dir}/${MY_USER}"
  mkdir -p "${account_icons_dir}"
  chown root:root "${account_icons_dir}"
  chmod 755 "${account_icons_dir}"
  mv -f "${account_customization_avatar_file}" "${user_account_icon_file}"
  chown root:root "${user_account_icon_file}"
  chmod 644 "${user_account_icon_file}"
  if [[ $(grep -c "Icon=" "${user_account_conf_file}") -eq 0 ]]; then
    echo "Icon=${user_account_icon_file}" >>"${user_account_conf_file}"
  fi
fi

# Remove temporary dirs
rm -rf "${PROVISION_CONTENT_DIR}"

# Clean tmp directory
rm -rf /tmp/*

# Restart VM for cleanup
shutdown -r 0
