#!/bin/bash
set -e

# Installs plugin for Visual Studio Code
vscode_plugin_id="${1}"
user_id="${2:-${USER}}"
max_retries="${3:-0}"
retries=0
while true; do
  exit_code=0
  sudo -H -i -u "${user_id}" \
    sh -c "SSL_CERT_FILE=$(printf "%q" "/etc/ssl/certs/ca-bundle.crt") NODE_OPTIONS=$(printf "%q" "--use-openssl-ca") code --install-extension $(printf "%q" "${vscode_plugin_id}")" \
    && exit_code=0 || exit_code=$?
  if [[ "${exit_code}" -eq 0 ]]; then
    break
  fi
  if [[ "${retries}" -ge "${max_retries}" ]]; then
    exit "${exit_code}"
  fi
  retries=$((retries+1))
  echo "Failed to install Visual Studio Code plugin ${vscode_plugin_id}. Retrying. Retry ${retries} of ${max_retries}"
  sleep 10s
done

find /tmp -maxdepth 1 -regex ".*\/[0-9a-z]+-[0-9a-z]+-[0-9a-z]+-[0-9a-z]+-[0-9a-z]+" -exec rm -f {} +
