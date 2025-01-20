#!/bin/bash -eux

maven_settings_local_repository='/repository'
tmp_maven_repository="$(mktemp -d)"
mkdir -p "$(dirname "${maven_settings_local_repository}")"
ln -s "${tmp_maven_repository}" "${maven_settings_local_repository}"

maven_settings_file="/home/${VM_USER}/.m2/settings.xml"

maven_dependency_plugin_artifact_id='org.apache.maven.plugins:maven-dependency-plugin:3.7.1'

# https://maven.apache.org/resolver/maven-resolver-named-locks-redisson/index.html
maven_redisson_artifact_ids=(
  'org.apache.maven.resolver:maven-resolver-named-locks-redisson:1.9.21:zip:bundle'
)

maven_redisson_tmp_dir="$(mktemp -d)"
maven_redisson_dir="${M2_HOME}/lib/ext/redisson"
for maven_artifact_id in "${maven_redisson_artifact_ids[@]}"; do
  mvn \
    -s "${maven_settings_file}" \
    "${maven_dependency_plugin_artifact_id}:copy" \
    -D "artifact=${maven_artifact_id}" \
    -D "outputDirectory=${maven_redisson_tmp_dir}" \
    -D aether.syncContext.named.factory=rwlock-local
done

mkdir -p "${maven_redisson_dir}"
unzip "${maven_redisson_tmp_dir}/"*.* -d "${maven_redisson_dir}"
rm -rf "${maven_redisson_tmp_dir}"
chmod u=rwX,g=rX,o=rX "${maven_redisson_dir}"
chown -R root:root "${maven_redisson_dir}"

rm -rf "${maven_settings_local_repository}"
rm -rf "${tmp_maven_repository}"
