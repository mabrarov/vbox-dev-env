#!/bin/bash

set -e

max_proc='1000000'
max_files='4000000'
max_user_namespaces='28633'
inotify_max_user_watches='524288'
inotify_max_user_instances='16384'

create_root_owned_file_if_not_exists() {
  local file_path="${1}"
  if [[ -f "${file_path}" ]]; then
    return 
  fi
  mkdir -p "$(dirname "${file_path}")"
  touch "${file_path}"
  chown root:root "${file_path}"
  chmod u=rw,g=r,o=r "${file_path}"
}

escape_text_for_regex() {
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

escape_text_for_sed() {
  local text="${1}"
  text="${text////\\/}"
  echo "${text}"
}

set_sysctl_conf_option() {
  local file_path="${1}"
  local option_name="${2}"
  local option_value="${3}"
  create_root_owned_file_if_not_exists "${file_path}"
  if grep -m 1 -P \
    "^[[:space:]]*$(escape_text_for_regex "${option_name}")[[:space:]]*=.*$" \
    "${file_path}" >/dev/null; then
    sed -r -i \
      "s/^([[:space:]]*$(escape_text_for_sed "$(escape_text_for_regex "${option_name}")")[[:space:]]*=[[:space:]]*)[^[:space:]]*$/\\1$(escape_text_for_sed "${option_value}")/" \
      "${file_path}"
  else
    echo "${option_name} = ${option_value}" >>"${file_path}"
  fi
}

set_security_limits_conf_option() {
  local file_path="${1}"
  local conf_domain="${2}"
  local conf_type="${3}"
  local conf_item="${4}"
  local conf_value="${5}"
  create_root_owned_file_if_not_exists "${file_path}"
  if grep -m 1 -P \
    "^[[:space:]]*$(escape_text_for_regex "${conf_domain}")[[:space:]]+$(escape_text_for_regex "${conf_type}")[[:space:]]+$(escape_text_for_regex "${conf_item}")[[:space:]]+.*$" \
    "${file_path}" >/dev/null; then
    sed -r -i \
      "s/^([[:space:]]*$(escape_text_for_sed "$(escape_text_for_regex "${conf_domain}")")[[:space:]]+$(escape_text_for_sed "$(escape_text_for_regex "${conf_type}")")[[:space:]]+$(escape_text_for_sed "$(escape_text_for_regex "${conf_item}")")[[:space:]]+).*$/\\1$(escape_text_for_sed "${conf_value}")/" \
      "${file_path}"
  else
    printf '%-11s%-8s%-10s%s' "${conf_domain}" "${conf_type}" "${conf_item}" "${conf_value}" \
      >>"${file_path}"
  fi
}

set_systemd_conf_option() {
  local file_path="${1}"
  local option_name="${2}"
  local option_value="${3}"
  create_root_owned_file_if_not_exists "${file_path}"
  if grep -m 1 -P \
    "^[[:space:]]*$(escape_text_for_regex "${option_name}")[[:space:]]*=.*$" \
    "${file_path}" >/dev/null; then
    sed -r -i \
      "s/^([[:space:]]*$(escape_text_for_sed "$(escape_text_for_regex "${option_name}")")[[:space:]]*=[[:space:]]*)[^[:space:]]*$/\\1$(escape_text_for_sed "${option_value}")/" \
      "${file_path}"
  else
    echo "${option_name}=${option_value}" >>"${file_path}"
  fi
}

sysctl_nproc_conf_file='/etc/sysctl.d/20-nproc.conf'
set_sysctl_conf_option "${sysctl_nproc_conf_file}" 'kernel.threads-max' "${max_proc}"
set_sysctl_conf_option "${sysctl_nproc_conf_file}" 'kernel.pid_max' "${max_proc}"
set_sysctl_conf_option "${sysctl_nproc_conf_file}" 'vm.max_map_count' "$((2*max_proc))"
sysctl_nofile_conf_file='/etc/sysctl.d/21-nofile.conf'
set_sysctl_conf_option "${sysctl_nofile_conf_file}" 'fs.file-max' "${max_files}"
set_sysctl_conf_option "${sysctl_nofile_conf_file}" 'fs.nr_open' "${max_files}"
set_sysctl_conf_option '/etc/sysctl.d/22-filewatch.conf' 'fs.inotify.max_user_watches' "${inotify_max_user_watches}"
set_sysctl_conf_option '/etc/sysctl.d/22-filewatch.conf' 'fs.inotify.max_user_instances' "${inotify_max_user_instances}"
set_sysctl_conf_option '/etc/sysctl.d/23-userns.conf' 'user.max_user_namespaces' "${max_user_namespaces}"
sysctl -p --system

set_security_limits_conf_option '/etc/security/limits.d/20-nproc.conf' '*' 'soft' 'nproc' "${max_proc}"
set_security_limits_conf_option '/etc/security/limits.d/21-nofile.conf' '*' 'soft' 'nofile' "${max_files}"

systemd_default_conf_file='/etc/systemd/system.conf'
set_systemd_conf_option "${systemd_default_conf_file}" 'DefaultLimitNPROC' "${max_proc}"
set_systemd_conf_option "${systemd_default_conf_file}" 'DefaultLimitNOFILE' "${max_files}"
systemd_default_conf_file='/etc/systemd/user.conf'
set_systemd_conf_option "${systemd_default_conf_file}" 'DefaultLimitNOFILE' "${max_files}"
