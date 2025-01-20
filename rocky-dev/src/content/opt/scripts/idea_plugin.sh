#!/bin/bash
set -e
# Installs plugin with specified XML ID for IntelliJ IDEA
# Some details about plugins management and XML ID are here:
# https://www.jetbrains.org/intellij/sdk/docs/plugin_repository/api/plugin_download_update.html
touch /tmp/idea_installed_plugins.log
if grep -m 1 "${1}" /tmp/idea_installed_plugins.log >/dev/null; then
  exit 0
fi
build="${2}"
if [[ -z "${build}" ]]; then
  build="$(head -n 1 /opt/ideaIU/build.txt)"
fi
url="https://plugins.jetbrains.com/pluginManager?action=download&id=$1&build=${build}"
fname="$(curl -sIL "${url}" | grep -o -E 'filename="[^"]+"' | sed -r 's/.*filename="([^"]+)".*/\1/')"
ext=${fname##*.}
if [[ "${ext}" == "zip" ]]; then
  curl -jksSL "${url}" -o /tmp/plugin.zip
  unzip -u -q /tmp/plugin.zip -d /home/user/.local/share/JetBrains/IntelliJIdea
  rm -f /tmp/plugin.zip
elif [[ "${ext}" == "jar" ]]; then
  curl -jksSL "${url}" -o "/home/user/.local/share/JetBrains/IntelliJIdea/${fname}"
else
  echo "Unknown filename extension for plugin '$1': '${ext}'"
  exit 1
fi
echo "${1}" >>/tmp/idea_installed_plugins.log
