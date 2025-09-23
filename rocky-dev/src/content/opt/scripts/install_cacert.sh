#!/bin/bash -eux

cert_file="${1}"
cert_alias="${2}"

function import_ca_cert_into_jks() {
  cert_alias="${1}"
  cert_file="${2}"
  keystore_file="${3}"

  keytool -importcert -noprompt -alias "${cert_alias}" -file "${cert_file}" \
    -keystore "${keystore_file}" -storetype JKS -storepass changeit
}

function import_ca_cert_into_intellij_idea() {
  idea_config_dir="${1}"
  cert_alias="${2}"
  cert_file="${3}"

  keystore_file="${idea_config_dir}/ssl/cacerts"
  mkdir -p "$(dirname "${keystore_file}")"
  import_ca_cert_into_jks "${cert_alias}" "${cert_file}" "${keystore_file}"
  chown user:user -R "${idea_config_dir}"
  chmod u=rwX,g=rX,o=rX -R "${idea_config_dir}"
}

for jks_keystore_file in \
  /opt/jdk/jre/lib/security/cacerts \
  /opt/jdk-11/lib/security/cacerts \
  /opt/jdk-17/lib/security/cacerts \
  /opt/jdk-21/lib/security/cacerts \
  ; do
  import_ca_cert_into_jks "${cert_alias}" "${cert_file}" "${jks_keystore_file}"
done

for idea_config_dir in \
  /home/user/.config/JetBrains/IntelliJIdea \
  /home/user/.config/JetBrains/GoLand \
  /home/user/.config/JetBrains/CLion \
  ; do
  import_ca_cert_into_intellij_idea "${idea_config_dir}" "${cert_alias}" "${cert_file}"
done
