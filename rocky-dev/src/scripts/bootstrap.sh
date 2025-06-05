#!/bin/bash -eux

function add_line_to_hosts() {
  grep -q -F "$1" /etc/hosts || echo "$1" >>/etc/hosts
}

function import_ca_cert_into_intellij_idea() {
  idea_config_dir="${1}"
  cert_alias="${2}"
  cert_file="${3}"
  keystore_file="${idea_config_dir}/ssl/cacerts"
  mkdir -p "$(dirname "${keystore_file}")"
  keytool -importcert -noprompt -alias "${cert_alias}" -file "${cert_file}" \
    -keystore "${keystore_file}" -storetype JKS -storepass changeit
  chown user:user -R "${idea_config_dir}"
  chmod u=rwX,g=rX,o=rX -R "${idea_config_dir}"
}

function install_jetbrains_plugin() {
  plugin_dir="${1}"
  plugin_dist_fname="${2}"
  plugin_dist_url=""
  if [[ "${#}" -ge 3 ]]; then
    plugin_dist_url="${3}"
  fi
  plugin_dist="${CACHE_DIR}/${plugin_dist_fname}"
  if [[ ! -f "${plugin_dist}" ]]; then
    if [[ -z "${plugin_dist_url}" ]]; then
      echo "${plugin_dist} file not found and download URL is no specified - cannot install requested JetBrains plugin"
      return 1
    fi
    curl -sLf -o "${plugin_dist}" "${plugin_dist_url}"
  fi
  mkdir -p "${plugin_dir}"
  unzip -q -d "${plugin_dir}" "${plugin_dist}"
}

user_home_dir="/home/${VM_USER}"
opt_bin_dir="/opt"
usr_local_dir="/usr/local"
usr_local_bin_dir="${usr_local_dir}/bin"
usr_local_share_dir="${usr_local_dir}/share"
etc_profile_env_script="/etc/profile.d/localenv.sh"
truetype_fonts_dir="/usr/share/fonts/truetype"
repository_dir="/repository"

provision_certs_dir="${PROVISION_CONTENT_DIR}/tmp/certs"
provision_scripts_dir="${PROVISION_CONTENT_DIR}/tmp/scripts"

java8_home="${opt_bin_dir}/jdk"
java11_home="${opt_bin_dir}/jdk-11"
java17_home="${opt_bin_dir}/jdk-17"
java21_home="${opt_bin_dir}/jdk-21"
export JAVA_HOME="${java17_home}"

export ANT_HOME="${opt_bin_dir}/ant"
ant_version="1.10.14"
ant_contrib_version=1.0b3

maven_version="3.9.8"
export M2_HOME="${opt_bin_dir}/maven"
export MAVEN_OPTS='-Djava.net.preferIPv4Stack=true -Xms512m -Xmx2048m -Daether.syncContext.named.factory=rwlock-redisson -Daether.syncContext.named.time=300'

gradle_version="7.6.4"
gradle_home="${opt_bin_dir}/gradle"

groovy_version="4.0.24"
groovy_home="${opt_bin_dir}/groovy"

golang_version="1.24.4"
golang_home="${opt_bin_dir}/go"

docker_compose_version="2.37.0"
kubectl_version="1.33.1"
minikube_version="1.36.0"
helm_version="3.18.2"
helm_secrets_plugin_version="4.6.5"
age_version="1.2.1"
sops_version="3.10.2"
helmfile_version="1.1.1"
shellcheck_version="0.10.0"
dbeaver_version="25.1.0"
yq_version="4.45.4"
xq_version="1.3.0"
direnv_version="2.36.0"
headlamp_version="0.28.1"

intellij_idea_version="2024.3.5"
goland_version="2024.3.5"
clion_version="2024.3.5"

add_line_to_hosts "# Some entries integrated into Vagrant box"

find "${PROVISION_CONTENT_DIR}" -type f -regextype posix-extended -regex '.*\.(sh|js|cfg)' -exec sed -i -r 's/\r//' {} +
find "${PROVISION_CONTENT_DIR}/home/user" -type f -exec sed -i -r 's/\r//' {} +
chmod a+x "${provision_scripts_dir}/"*.sh

"${provision_scripts_dir}/limits.sh"

export PATH="${PATH}:${gradle_home}/bin:${M2_HOME}/bin:${ANT_HOME}/bin:${JAVA_HOME}/bin:${groovy_home}/bin"

echo "export JAVA_HOME=$(printf "%q" "${JAVA_HOME}")" >"${etc_profile_env_script}"
chown root:root "${etc_profile_env_script}"
chmod 644 "${etc_profile_env_script}"

# shellcheck disable=SC2129
echo "export ANT_HOME=$(printf "%q" "${ANT_HOME}")" >>"${etc_profile_env_script}"
echo "export DOCKER_TLS_VERIFY=" >>"${etc_profile_env_script}"
echo "export M2_HOME=$(printf "%q" "${M2_HOME}")" >>"${etc_profile_env_script}"
echo "export MAVEN_OPTS=$(printf "%q" "${MAVEN_OPTS}")" >>"${etc_profile_env_script}"
echo "export GOPATH=$(printf "%q" "${repository_dir}/go")" >>"${etc_profile_env_script}"
echo "export GOCACHE=$(printf "%q" "${repository_dir}/cache/go-build")" >>"${etc_profile_env_script}"
echo "pathmunge $(printf "%q" "${golang_home}/bin")" >>"${etc_profile_env_script}"
echo "pathmunge $(printf "%q" "${groovy_home}/bin")" >>"${etc_profile_env_script}"
echo "pathmunge $(printf "%q" "${JAVA_HOME}/bin")" >>"${etc_profile_env_script}"
echo "pathmunge $(printf "%q" "${ANT_HOME}/bin")" >>"${etc_profile_env_script}"
echo "pathmunge $(printf "%q" "${M2_HOME}/bin")" >>"${etc_profile_env_script}"
echo "pathmunge $(printf "%q" "${gradle_home}/bin")" >>"${etc_profile_env_script}"
echo "pathmunge $(printf "%q" "${repository_dir}/go/bin") after" >>"${etc_profile_env_script}"

# https://wiki.archlinux.org/title/Uniform_look_for_Qt_and_GTK_applications#Adwaita
echo "export QT_STYLE_OVERRIDE=adwaita-dark" >>"${etc_profile_env_script}"

localectl --no-convert set-x11-keymap us pc105 "" srvrkeys:none

# Force usage of IPv4 only
echo "ip_resolve=4" >>/etc/dnf/dnf.conf

# Install custom trusted CA certificates into system trusted CA certificates.
# It is required prior to any TLS communication, because some of these CAs are used to issue
# TLS certificates, which are used for sniffing of TLS traffic (i.e. some TLS certificate can
# be replaced with another certificate issued / signed by custom CA).
mkdir -p /etc/pki/ca-trust/source/anchors
find "${provision_certs_dir}" -type f -printf "%f\0" \
  | xargs -r --null -I{} cp -f "${provision_certs_dir}/"{} /etc/pki/ca-trust/source/anchors/
/bin/update-ca-trust

dnf install -y \
  ca-certificates \
  curl

# Install tools & applications available as packages
dnf install -y epel-release
dnf config-manager --set-enabled crb
dnf install -y \
  svn \
  p7zip \
  p7zip-plugins \
  git \
  gcc \
  gcc-c++ \
  glibc-devel \
  cmake \
  ninja-build \
  zlib-devel \
  make \
  autoconf \
  automake \
  bzip2 \
  perl \
  xz \
  nmap \
  telnet \
  nss-tools \
  xfsprogs \
  net-tools \
  autoconf \
  tmux \
  flex \
  bison \
  multitail \
  cabextract \
  vim \
  nano \
  mc \
  xsel \
  xdotool \
  httpie \
  moreutils \
  meld \
  sqlite \
  pandoc \
  lynx \
  expect \
  python3 \
  cifs-utils \
  nfs-utils \
  htop \
  jq \
  gnome-tweaks \
  gnome-extensions-app \
  adwaita-qt5 \
  dbus-x11 \
  bash-completion

dnf config-manager --set-enabled devel
dnf install -y xorg-x11-font-utils
dnf config-manager --set-disabled devel
dnf install -y fontconfig

dnf remove -y Thunar yelp
dnf check-update || true
dnf update -y --exclude=kernel*

mkdir -p "${opt_bin_dir}/scripts"
rsync -a --remove-source-files "${PROVISION_CONTENT_DIR}/opt/scripts/" "${opt_bin_dir}/scripts/"
chown -R root:root "${opt_bin_dir}/scripts"
chmod a+x "${opt_bin_dir}/scripts"/*.sh

# Disabling vulnerable ciphers via crypto policy for OpenSSH to prevent Terrapin SSH attack (CVE-2023-48795)
# Refer to https://access.redhat.com/solutions/7062987
cat <<EOF >'/etc/crypto-policies/policies/modules/CVE-2023-48795.pmod'
cipher@SSH = -CHACHA20-POLY1305
ssh_etm = 0
EOF
update-crypto-policies --set "$(update-crypto-policies --show):CVE-2023-48795"

# Install popular GNOME extensions
# Dash to Dock (https://extensions.gnome.org/extension/307/dash-to-dock/)
"${opt_bin_dir}/scripts/gnome_extension.sh" \
  'dash-to-dock@micxgx.gmail.com' \
  'https://extensions.gnome.org/extension-data/dash-to-dockmicxgx.gmail.com.v84.shell-extension.zip' \
  "${CACHE_DIR}"
# Hide Top Bar (https://extensions.gnome.org/extension/545/hide-top-bar/)
"${opt_bin_dir}/scripts/gnome_extension.sh" \
  'hidetopbar@mathieu.bidon.ca' \
  'https://extensions.gnome.org/extension-data/hidetopbarmathieu.bidon.ca.v114.shell-extension.zip' \
  "${CACHE_DIR}"
# Just Perfection (https://extensions.gnome.org/extension/3843/just-perfection/)
"${opt_bin_dir}/scripts/gnome_extension.sh" \
  'just-perfection-desktop@just-perfection' \
  'https://extensions.gnome.org/extension-data/just-perfection-desktopjust-perfection.v24.shell-extension.zip' \
  "${CACHE_DIR}"

# https://github.com/sshuttle/sshuttle
pip3 install sshuttle

# Grant "${VM_USER}" full access to VirtualBox shared folders
usermod -aG vboxsf "${VM_USER}"

if ! which google-chrome-stable &>/dev/null; then
  echo "=== Installing Google Chrome"
  cat <<EOF >'/etc/yum.repos.d/google-chrome.repo'
[google-chrome]
name=Google Chrome
baseurl=https://dl.google.com/linux/chrome/rpm/stable/x86_64
enabled=0
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub
EOF
  rpm --import 'https://dl.google.com/linux/linux_signing_key.pub'
  dnf install --enablerepo=google-chrome -y google-chrome-stable
fi

# Install ShellCheck
if ! which shellcheck &>/dev/null; then
  shellcheck_dist_filename="shellcheck-v${shellcheck_version}.linux.x86_64.tar.xz"
  shellcheck_dist="${CACHE_DIR}/${shellcheck_dist_filename}"
  if [[ ! -f "${shellcheck_dist}" ]]; then
    curl -sLf -o "${shellcheck_dist}" \
      "https://github.com/koalaman/shellcheck/releases/download/v${shellcheck_version}/shellcheck-v${shellcheck_version}.linux.x86_64.tar.xz"
  fi
  tar -xf "${shellcheck_dist}" --strip-components=1 -C "${usr_local_bin_dir}" "shellcheck-v${shellcheck_version}/shellcheck"
fi

icdiff_bin_file="${usr_local_bin_dir}/icdiff"
if [[ ! -e "${icdiff_bin_file}" ]]; then
  echo "=== Installing icdiff"
  icdiff_ver="$(curl -sLf -H "Accept: application/vnd.github.v3+json" \
    'https://api.github.com/repos/jeffkaufman/icdiff/tags' |
    grep "\"name\"" |
    head -1 |
    sed -r 's/^.+(release-[0-9\.]+).*/\1/')"
  icdiff_cache_file="${CACHE_DIR}/icdiff-${icdiff_ver}"
  if [[ ! -e "${icdiff_cache_file}" ]]; then
    curl -sLf -o "${icdiff_cache_file}" "https://raw.githubusercontent.com/jeffkaufman/icdiff/${icdiff_ver}/icdiff"
  fi
  cp "${icdiff_cache_file}" "${icdiff_bin_file}"
  chown root:root "${icdiff_bin_file}"
  chmod ugo+rx "${icdiff_bin_file}"
fi

# https://www.azul.com/downloads/?version=java-8-lts&os=centos&architecture=x86-64-bit&package=jdk-fx#zulu
if [[ ! -e "${java8_home}" ]]; then
  echo "=== Installing Azul Zulu CE JDK 8"
  folder_name="zulu8.84.0.15-ca-fx-jdk8.0.442-linux_x64"
  fname="${folder_name}.tar.gz"
  jdk_dist="${CACHE_DIR}/${fname}"
  if [[ ! -e "${jdk_dist}" ]]; then
    curl -sLf -o "${jdk_dist}" "https://cdn.azul.com/zulu/bin/${fname}"
  fi
  tar -xzf "${jdk_dist}" -C "${opt_bin_dir}"
  mv "${opt_bin_dir}/${folder_name}" "${java8_home}"
  chown -R root:root "${java8_home}"
  sed -i -r 's/^([^#]+?[ =,])anon,?([ $])/\1\2/' "${java8_home}/jre/lib/security/java.security"
fi

# https://www.azul.com/downloads/?version=java-11-lts&os=centos&architecture=x86-64-bit&package=jdk#zulu
if [[ ! -e "${java11_home}" ]]; then
  echo "=== Installing Azul Zulu CE JDK 11"
  folder_name="zulu11.78.15-ca-jdk11.0.26-linux_x64"
  fname="${folder_name}.tar.gz"
  jdk_dist="${CACHE_DIR}/${fname}"
  if [[ ! -e "${jdk_dist}" ]]; then
    curl -sLf -o "${jdk_dist}" "https://cdn.azul.com/zulu/bin/${fname}"
  fi
  tar -xzf "${jdk_dist}" -C "${opt_bin_dir}"
  mv "${opt_bin_dir}/${folder_name}" "${java11_home}"
  chown -R root:root "${java11_home}"
fi

# https://www.azul.com/downloads/?version=java-17-lts&os=centos&architecture=x86-64-bit&package=jdk#zulu
if [[ ! -e "${java17_home}" ]]; then
  echo "=== Installing Azul Zulu CE JDK 17"
  folder_name="zulu17.56.15-ca-jdk17.0.14-linux_x64"
  fname="${folder_name}.tar.gz"
  jdk_dist="${CACHE_DIR}/${fname}"
  if [[ ! -e "${jdk_dist}" ]]; then
    curl -sLf -o "${jdk_dist}" "https://cdn.azul.com/zulu/bin/${fname}"
  fi
  tar -xzf "${jdk_dist}" -C "${opt_bin_dir}"
  mv "${opt_bin_dir}/${folder_name}" "${java17_home}"
  chown -R root:root "${java17_home}"
fi

# https://www.azul.com/downloads/?version=java-21-lts&os=centos&architecture=x86-64-bit&package=jdk#zulu
if [[ ! -e "${java21_home}" ]]; then
  echo "=== Installing Azul Zulu CE JDK 21"
  folder_name="zulu21.40.17-ca-jdk21.0.6-linux_x64"
  fname="${folder_name}.tar.gz"
  jdk_dist="${CACHE_DIR}/${fname}"
  if [[ ! -e "${jdk_dist}" ]]; then
    curl -sLf -o "${jdk_dist}" "https://cdn.azul.com/zulu/bin/${fname}"
  fi
  tar -xzf "${jdk_dist}" -C "${opt_bin_dir}"
  mv "${opt_bin_dir}/${folder_name}" "${java21_home}"
  chown -R root:root "${java21_home}"
fi

if [[ ! -e "${golang_home}" ]]; then
  echo "=== Installing Go"
  fname="go${golang_version}.linux-amd64.tar.gz"
  golang_dist="${CACHE_DIR}/${fname}"
  if [[ ! -e "${golang_dist}" ]]; then
    curl -sLf -o "${golang_dist}" "https://golang.org/dl/${fname}"
  fi
  tar -xzf "${golang_dist}" -C "${opt_bin_dir}"
  chown -R root:root "${golang_home}"
fi

if [[ ! -e "${groovy_home}" ]]; then
  echo "=== Installing Groovy SDK"
  fname="apache-groovy-sdk-${groovy_version}.zip"
  groovy_dist="${CACHE_DIR}/${fname}"
  if [[ ! -e "${groovy_dist}" ]]; then
    curl -sLf -o "${groovy_dist}" \
      "https://groovy.jfrog.io/artifactory/dist-release-local/groovy-zips/${fname}"
  fi
  unzip -q "${groovy_dist}" -d "${opt_bin_dir}"
  mv "${opt_bin_dir}/groovy-${groovy_version}" "${groovy_home}"
  chown -R root:root "${groovy_home}"
fi

if [[ ! -e "${ANT_HOME}" ]]; then
  echo "=== Installing Ant"
  ant_dist="${CACHE_DIR}/apache-ant-${ant_version}-bin.tar.gz"
  if [[ ! -e "${ant_dist}" ]]; then
    curl -sLf -o "${ant_dist}" \
      "http://mirror.linux-ia64.org/apache//ant/binaries/apache-ant-${ant_version}-bin.tar.gz"
  fi
  tar -xzf "${ant_dist}" -C "${opt_bin_dir}"
  mv "${opt_bin_dir}/apache-ant-${ant_version}" "${ANT_HOME}"
  echo "=== Installing Ant-Contrib Tasks"
  ant_contrib_dist="${CACHE_DIR}/ant-contrib-${ant_contrib_version}-bin.tar.gz"
  if [[ ! -e "${ant_contrib_dist}" ]]; then
    curl -sLf -o "${ant_contrib_dist}" \
      "https://sourceforge.net/projects/ant-contrib/files/ant-contrib/${ant_contrib_version}/ant-contrib-${ant_contrib_version}-bin.tar.gz/download"
  fi
  tmp_dir="$(mktemp -d)"
  tar -xzf "${ant_contrib_dist}" -C "${tmp_dir}"
  mv "${tmp_dir}/ant-contrib/ant-contrib-${ant_contrib_version}.jar" "${ANT_HOME}/lib"/
  rm -rf "${tmp_dir}"
  chown -R root:root "${ANT_HOME}"
fi

if [[ ! -e "${M2_HOME}" ]]; then
  echo "=== Installing Maven"
  maven_dist="${CACHE_DIR}/apache-maven-${maven_version}-bin.tar.gz"
  if [[ ! -e "${maven_dist}" ]]; then
    curl -sLf -o "${maven_dist}" \
      "http://mirror.reverse.net/pub/apache/maven/maven-$(echo "${maven_version}" | sed -r 's/([0-9]+)\..*/\1/')/${maven_version}/binaries/apache-maven-${maven_version}-bin.tar.gz"
  fi
  tar -xzf "${maven_dist}" -C "${opt_bin_dir}"
  mv "${opt_bin_dir}/apache-maven-${maven_version}" "${M2_HOME}"
  chown -R root:root "${M2_HOME}"
fi

maven_bash_completion_script="${user_home_dir}/.bash_completion.bash"
if [[ ! -e "${maven_bash_completion_script}" ]]; then
  echo "=== Installing Maven Bash Completion"
  maven_bash_completion_script_cache="${CACHE_DIR}/$(basename "${maven_bash_completion_script}")"
  if [[ ! -e "${maven_bash_completion_script_cache}" ]]; then
    curl -sLf -o "${maven_bash_completion_script_cache}" \
      'https://raw.githubusercontent.com/juven/maven-bash-completion/master/bash_completion.bash'
  fi
  cp "${maven_bash_completion_script_cache}" "${maven_bash_completion_script}"
  chmod u=rwx,g=rx,o=rx "${maven_bash_completion_script}"
fi

if [[ ! -e "${gradle_home}" ]]; then
  echo "=== Installing Gradle"
  gradle_version_major="$(echo "${gradle_version}" | sed -r 's/([0-9]+)\..*/\1/;t;d')"
  gradle_version_middle="$(echo "${gradle_version}" | sed -r 's/[0-9]+\.([0-9]+).*/\1/;t;d')"
  gradle_version_minor="$(echo "${gradle_version}" | sed -r 's/[0-9]+\.[0-9]+\.([0-9]+)/\1/;t;d')"
  gradle_dist="${CACHE_DIR}/gradle-${gradle_version}-bin.zip"
  if [[ ! -e "${gradle_dist}" ]]; then
    gradle_url="https://downloads.gradle.org/distributions/gradle-${gradle_version_major}.${gradle_version_middle}"
    if [[ "${gradle_version_minor:-0}" -ne 0 ]]; then
      gradle_url="${gradle_url}.${gradle_version_minor}"
    fi
    gradle_url="${gradle_url}-bin.zip"
    curl -sLf -o "${gradle_dist}" "${gradle_url}"
  fi
  unzip -q -d "${opt_bin_dir}" "${gradle_dist}"
  gradle_unpack_dir_name="gradle-${gradle_version_major}.${gradle_version_middle}"
  if [[ "${gradle_version_minor:-0}" -ne 0 ]]; then
    gradle_unpack_dir_name="${gradle_unpack_dir_name}.${gradle_version_minor}"
  fi
  mv "${opt_bin_dir}/${gradle_unpack_dir_name}" "${gradle_home}"
  chown -R root:root "${gradle_home}"
fi

idea_home="${opt_bin_dir}/ideaIU"
if [[ ! -e "${idea_home}" ]]; then
  echo "=== Installing IntelliJ IDEA"
  idea_fname="ideaIU-${intellij_idea_version}.tar.gz"
  idea_dist="${CACHE_DIR}/${idea_fname}"
  if [[ ! -e "${idea_dist}" ]]; then
    curl -sLf -o "${idea_dist}" "https://download.jetbrains.com/idea/${idea_fname}"
  fi
  tar -zxf "${idea_dist}" -C "${opt_bin_dir}"
  mv "$(find "${opt_bin_dir}" -maxdepth 1 -name "idea*" -type d)" "${idea_home}"
  ln -s "${idea_home}/bin/idea" "${usr_local_bin_dir}/idea"
  sed -i -r 's/-Xms.+m/-Xms512m/' "${idea_home}/bin/idea64.vmoptions"
  sed -i -r 's/-Xmx.+m/-Xmx4096m/' "${idea_home}/bin/idea64.vmoptions"
  echo '-Dawt.ime.disabled=true' >> "${idea_home}/bin/idea64.vmoptions"
  # https://www.jetbrains.com/help/idea/directories-used-by-the-ide-to-store-settings-caches-plugins-and-logs.html
  echo "
idea.config.path=\${user.home}/.config/JetBrains/IntelliJIdea
idea.system.path=\${user.home}/.cache/JetBrains/IntelliJIdea
idea.plugins.path=\${user.home}/.local/share/JetBrains/IntelliJIdea
idea.log.path=\${idea.system.path}/log
" >>"${idea_home}/bin/idea.properties"
  chown -R root:root "${idea_home}"

  # Make IntelliJ IDEA trusting certificates issued by custom CA for the case when VPN / AV sniffs traffic
  import_ca_cert_into_intellij_idea "${user_home_dir}/.config/JetBrains/IntelliJIdea" \
    "ru-root-ca" "${provision_certs_dir}/ru-root-ca.crt"
fi

# IntelliJ IDEA plugins
idea_plugin_dir="${user_home_dir}/.local/share/JetBrains/IntelliJIdea"
# AsciiDoc (https://plugins.jetbrains.com/plugin/7391-asciidoc)
install_jetbrains_plugin "${idea_plugin_dir}" "asciidoctor-intellij-plugin-0.43.6.zip" \
  "https://downloads.marketplace.jetbrains.com/files/7391/658997/asciidoctor-intellij-plugin-0.43.6.zip"
# Makefile Language (https://plugins.jetbrains.com/plugin/9333-makefile-language)
install_jetbrains_plugin "${idea_plugin_dir}" "makefile-243.23654.19.zip" \
  "https://downloads.marketplace.jetbrains.com/files/9333/654848/makefile-243.23654.19.zip"
# Go (https://plugins.jetbrains.com/plugin/9568-go)
install_jetbrains_plugin "${idea_plugin_dir}" "go-plugin-243.26053.27.zip" \
  "https://downloads.marketplace.jetbrains.com/files/9568/700127/go-plugin-243.26053.27.zip"
# Go Template (https://plugins.jetbrains.com/plugin/10581-go-template)
install_jetbrains_plugin "${idea_plugin_dir}" "go-template-243.21565.122.zip" \
  "https://downloads.marketplace.jetbrains.com/files/10581/629973/go-template-243.21565.122.zip"
# Batch Scripts Support (https://plugins.jetbrains.com/plugin/265-batch-scripts-support)
install_jetbrains_plugin "${idea_plugin_dir}" "idea-batch-1.0.13.zip" \
  "https://downloads.marketplace.jetbrains.com/files/265/148140/idea-batch-1.0.13.zip"
# PowerShell (https://plugins.jetbrains.com/plugin/10249-powershell)
install_jetbrains_plugin "${idea_plugin_dir}" "PowerShell-2.8.0.zip" \
  "https://downloads.marketplace.jetbrains.com/files/10249/678045/PowerShell-2.9.0.zip"
# Python Community Edition (https://plugins.jetbrains.com/plugin/7322-python-community-edition)
install_jetbrains_plugin "${idea_plugin_dir}" "python-ce-243.24978.46.zip" \
  "https://downloads.marketplace.jetbrains.com/files/7322/680217/python-ce-243.24978.46.zip"
# Python (https://plugins.jetbrains.com/plugin/631-python)
install_jetbrains_plugin "${idea_plugin_dir}" "python-243.26053.27.zip" \
  "https://downloads.marketplace.jetbrains.com/files/631/700118/python-243.26053.27.zip"
# Ruby (https://plugins.jetbrains.com/plugin/1293-ruby)
install_jetbrains_plugin "${idea_plugin_dir}" "ruby-243.26053.27.zip" \
  "https://downloads.marketplace.jetbrains.com/files/1293/700107/ruby-243.26053.27.zip"
# String Tools (https://plugins.jetbrains.com/plugin/10066-string-tools)
install_jetbrains_plugin "${idea_plugin_dir}" "StringToolsPlugin-4.22.zip" \
  "https://downloads.marketplace.jetbrains.com/files/10066/668907/StringToolsPlugin-4.22.zip"
# Terraform and HCL (https://plugins.jetbrains.com/plugin/7808-terraform-and-hcl/versions)
install_jetbrains_plugin "${idea_plugin_dir}" "terraform-243.25659.42.zip" \
  "https://downloads.marketplace.jetbrains.com/files/7808/688185/terraform-243.25659.42.zip"

goland_home="${opt_bin_dir}/goland"
if [[ ! -e "${goland_home}" ]]; then
  echo "=== Installing GoLand"
  goland_fname="goland-${goland_version}.tar.gz"
  goland_dist="${CACHE_DIR}/${goland_fname}"
  if [[ ! -e "${goland_dist}" ]]; then
    curl -sLf -o "${goland_dist}" "https://download.jetbrains.com/go/${goland_fname}"
  fi
  tar -zxf "${goland_dist}" -C "${opt_bin_dir}"
  mv "$(find "${opt_bin_dir}" -maxdepth 1 -name "GoLand*" -type d)" "${goland_home}"
  ln -s "${goland_home}/bin/goland" "${usr_local_bin_dir}/goland"
  sed -i -r 's/-Xms.+m/-Xms512m/' "${goland_home}/bin/goland64.vmoptions"
  sed -i -r 's/-Xmx.+m/-Xmx4096m/' "${goland_home}/bin/goland64.vmoptions"
  echo '-Dawt.ime.disabled=true' >> "${goland_home}/bin/goland64.vmoptions"
  # https://www.jetbrains.com/help/go/directories-used-by-the-ide-to-store-settings-caches-plugins-and-logs.html
  echo "
idea.config.path=\${user.home}/.config/JetBrains/GoLand
idea.system.path=\${user.home}/.cache/JetBrains/GoLand
idea.plugins.path=\${user.home}/.local/share/JetBrains/GoLand
idea.log.path=\${idea.system.path}/log
" >>"${goland_home}/bin/idea.properties"
  chown -R root:root "${goland_home}"

  # Make GoLand trusting certificates issued by custom CA for the case when VPN / AV sniffs traffic
  import_ca_cert_into_intellij_idea "${user_home_dir}/.config/JetBrains/GoLand" \
    "ru-root-ca" "${provision_certs_dir}/ru-root-ca.crt"
fi

# GoLand plugins
goland_plugin_dir="${user_home_dir}/.local/share/JetBrains/GoLand"
# AsciiDoc (https://plugins.jetbrains.com/plugin/7391-asciidoc)
install_jetbrains_plugin "${goland_plugin_dir}" "asciidoctor-intellij-plugin-0.43.6.zip" \
  "https://downloads.marketplace.jetbrains.com/files/7391/658997/asciidoctor-intellij-plugin-0.43.6.zip"
# Batch Scripts Support (https://plugins.jetbrains.com/plugin/265-batch-scripts-support)
install_jetbrains_plugin "${goland_plugin_dir}" "idea-batch-1.0.13.zip" \
  "https://downloads.marketplace.jetbrains.com/files/265/148140/idea-batch-1.0.13.zip"
# PowerShell (https://plugins.jetbrains.com/plugin/10249-powershell)
install_jetbrains_plugin "${goland_plugin_dir}" "PowerShell-2.8.0.zip" \
  "https://downloads.marketplace.jetbrains.com/files/10249/678045/PowerShell-2.9.0.zip"
# String Tools (https://plugins.jetbrains.com/plugin/10066-string-tools)
install_jetbrains_plugin "${goland_plugin_dir}" "StringToolsPlugin-4.22.zip" \
  "https://downloads.marketplace.jetbrains.com/files/10066/668907/StringToolsPlugin-4.22.zip"
# Terraform and HCL (https://plugins.jetbrains.com/plugin/7808-terraform-and-hcl/versions)
install_jetbrains_plugin "${goland_plugin_dir}" "terraform-243.25659.42.zip" \
  "https://downloads.marketplace.jetbrains.com/files/7808/688185/terraform-243.25659.42.zip"

clion_home="${opt_bin_dir}/clion"
if [[ ! -e "${clion_home}" ]]; then
  echo "=== Installing CLion"
  clion_fname="CLion-${clion_version}.tar.gz"
  clion_dist="${CACHE_DIR}/${clion_fname}"
  if [[ ! -e "${clion_dist}" ]]; then
    curl -sLf -o "${clion_dist}" "https://download.jetbrains.com/cpp/${clion_fname}"
  fi
  tar -zxf "${clion_dist}" -C "${opt_bin_dir}"
  mv "$(find "${opt_bin_dir}" -maxdepth 1 -name "clion*" -type d)" "${clion_home}"
  ln -s "${clion_home}/bin/clion" "${usr_local_bin_dir}/clion"
  sed -i -r 's/-Xms.+m/-Xms512m/' "${clion_home}/bin/clion64.vmoptions"
  sed -i -r 's/-Xmx.+m/-Xmx4096m/' "${clion_home}/bin/clion64.vmoptions"
  echo '-Dawt.ime.disabled=true' >> "${clion_home}/bin/clion64.vmoptions"
  # https://www.jetbrains.com/help/go/directories-used-by-the-ide-to-store-settings-caches-plugins-and-logs.html
  echo "
idea.config.path=\${user.home}/.config/JetBrains/CLion
idea.system.path=\${user.home}/.cache/JetBrains/CLion
idea.plugins.path=\${user.home}/.local/share/JetBrains/CLion
idea.log.path=\${idea.system.path}/log
" >>"${clion_home}/bin/idea.properties"
  chown -R root:root "${clion_home}"

  # Make CLion trusting certificates issued by custom CA for the case when VPN / AV sniffs traffic
  import_ca_cert_into_intellij_idea "${user_home_dir}/.config/JetBrains/CLion" \
    "ru-root-ca" "${provision_certs_dir}/ru-root-ca.crt"
fi

# CLion plugins
clion_plugin_dir="${user_home_dir}/.local/share/JetBrains/CLion"
# AsciiDoc (https://plugins.jetbrains.com/plugin/7391-asciidoc)
install_jetbrains_plugin "${clion_plugin_dir}" "asciidoctor-intellij-plugin-0.43.6.zip" \
  "https://plugins.jetbrains.com/files/7391/634204/asciidoctor-intellij-plugin-0.43.6.zip"
# Kubernetes (https://plugins.jetbrains.com/plugin/10485-kubernetes)
install_jetbrains_plugin "${clion_plugin_dir}" "clouds-kubernetes-243.24978.79.zip" \
  "https://downloads.marketplace.jetbrains.com/files/10485/684423/clouds-kubernetes-243.24978.79.zip"
# Go Template (https://plugins.jetbrains.com/plugin/10581-go-template)
install_jetbrains_plugin "${clion_plugin_dir}" "go-template-243.21565.122.zip" \
  "https://downloads.marketplace.jetbrains.com/files/10581/629973/go-template-243.21565.122.zip"
# PowerShell (https://plugins.jetbrains.com/plugin/10249-powershell)
install_jetbrains_plugin "${clion_plugin_dir}" "PowerShell-2.8.0.zip" \
  "https://downloads.marketplace.jetbrains.com/files/10249/678045/PowerShell-2.9.0.zip"
# String Tools (https://plugins.jetbrains.com/plugin/10066-string-tools)
install_jetbrains_plugin "${clion_plugin_dir}" "StringToolsPlugin-4.22.zip" \
  "https://downloads.marketplace.jetbrains.com/files/10066/668907/StringToolsPlugin-4.22.zip"

if ! which node &>/dev/null; then
  echo "=== Installing NodeJS"
  cat <<EOF >'/etc/yum.repos.d/nodesource-el9.repo'
[nodesource-nodejs]
name=Node.js Packages for Linux RPM based distros - x86_64
baseurl=https://rpm.nodesource.com/pub_22.x/nodistro/nodejs/x86_64
priority=9
enabled=1
gpgcheck=1
gpgkey=https://rpm.nodesource.com/gpgkey/ns-operations-public.key
module_hotfixes=1
EOF
  rpm --import 'https://rpm.nodesource.com/gpgkey/ns-operations-public.key'
  dnf install --enablerepo=nodesource-nodejs -y nodejs
fi

if ! which code &>/dev/null; then
  echo "=== Installing VSCode"
  cat <<EOF >'/etc/yum.repos.d/vscode.repo'
[vscode]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=0
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
  rpm --import 'https://packages.microsoft.com/keys/microsoft.asc'
  dnf install --enablerepo=vscode -y code
fi

if ! which docker &>/dev/null; then
  echo "=== Installing Docker"
  cat <<EOF >'/etc/yum.repos.d/docker-ce.repo'
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://download.docker.com/linux/rhel/\$releasever/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://download.docker.com/linux/rhel/gpg

EOF
  rpm --import 'https://download.docker.com/linux/rhel/gpg'
  dnf install --enablerepo=docker-ce-stable -y docker-ce docker-ce-cli containerd.io

  docker_config_dir="/etc/docker"
  mkdir -p "${docker_config_dir}"
  cp --no-preserve=all -f "${PROVISION_CONTENT_DIR}/etc/docker/daemon.json" "${docker_config_dir}"/

  if [[ -f "${PROVISION_CONTENT_DIR}/etc/docker/certs.d/docker.local/registry.crt" ]]; then
    docker_cert_dir="${docker_config_dir}/certs.d"
    mkdir -p "${docker_cert_dir}"
    docker_local_cert_dir="${docker_cert_dir}/docker.local:5000"
    mkdir -p "${docker_local_cert_dir}"
    cp --no-preserve=all -f "${PROVISION_CONTENT_DIR}/etc/docker/certs.d/docker.local/registry.crt" "${docker_local_cert_dir}/registry.crt"
  fi

  chown -R root:root "${docker_config_dir}"
  chmod -R u=rwX,g=rX,o=rX "${docker_config_dir}"
  usermod -aG docker "${VM_USER}"

  docker_systemd_service_dir="/etc/systemd/system/docker.service.d"
  mkdir -p "${docker_systemd_service_dir}"
  cp --no-preserve=all -f "${PROVISION_CONTENT_DIR}/etc/systemd/system/docker.service.d/docker.service.conf" "${docker_systemd_service_dir}/override.conf"
  chown -R root:root "${docker_systemd_service_dir}"
  chmod -R u=rwX,g=rX,o=rX "${docker_systemd_service_dir}"
  systemctl daemon-reload
  systemctl enable docker
fi

if ! which docker-compose &>/dev/null; then
  echo "=== Installing Docker-Compose"
  docker_compose_dist="${CACHE_DIR}/docker-compose_${docker_compose_version}"
  if [[ ! -f "${docker_compose_dist}" ]]; then
    curl -sLf -o "${docker_compose_dist}" \
      "https://github.com/docker/compose/releases/download/v${docker_compose_version}/docker-compose-linux-x86_64"
  fi
  docker_compose_file="${usr_local_bin_dir}/docker-compose"
  cp -f "${docker_compose_dist}" "${docker_compose_file}"
  chmod +rx "${docker_compose_file}"
fi

# https://github.com/wagoodman/dive
# A tool for exploring a docker image, layer contents, and discovering ways to shrink the size of your Docker/OCI image.
dive_version="0.12.0"
if ! which dive &>/dev/null; then
  dive_rpm="${CACHE_DIR}/dive_${dive_version}_linux_amd64.rpm"
  if [[ ! -f "${dive_rpm}" ]]; then
    curl -sLf -o "${dive_rpm}" \
      "https://github.com/wagoodman/dive/releases/download/v${dive_version}/dive_${dive_version}_linux_amd64.rpm"
  fi
  dnf install -y --nogpgcheck "${dive_rpm}"
fi

# Install kubectl
if ! which kubectl &>/dev/null; then
  kubectl_filename="kubectl"
  kubectl_dist="${CACHE_DIR}/${kubectl_filename}_${kubectl_version}"
  if [[ ! -f "${kubectl_dist}" ]]; then
    curl -sLf -o "${kubectl_dist}" \
      "https://dl.k8s.io/release/v${kubectl_version}/bin/linux/amd64/kubectl"
  fi
  kubectl_file="${usr_local_bin_dir}/${kubectl_filename}"
  cp -f "${kubectl_dist}" "${kubectl_file}"
  chmod +rx "${kubectl_file}"
fi

# Install Helm
helm_bin_dir="${usr_local_bin_dir}"
if ! which helm &>/dev/null; then
  helm_dist_filename="helm-v${helm_version}-linux-amd64.tar.gz"
  helm_dist="${CACHE_DIR}/${helm_dist_filename}"
  if [[ ! -f "${helm_dist}" ]]; then
    curl -sLf -o "${helm_dist}" "https://get.helm.sh/${helm_dist_filename}"
  fi
  tar -xzf "${helm_dist}" --strip-components=1 -C "${helm_bin_dir}" "linux-amd64/helm"
fi

# helm-secrets plugin
helm_secrets_plugin_dist="${CACHE_DIR}/helm-secrets-v${helm_secrets_plugin_version}.tar.gz"
if [[ ! -f "${helm_secrets_plugin_dist}" ]]; then
  curl -sLf -o "${helm_secrets_plugin_dist}" \
    "https://github.com/jkroepke/helm-secrets/releases/download/v${helm_secrets_plugin_version}/helm-secrets.tar.gz"
fi
helm_bin_file="${helm_bin_dir}/helm"
helm_plugins_dir="$(sudo -H -i -u "${VM_USER}" "${helm_bin_file}" env HELM_PLUGINS)"
mkdir -p "${helm_plugins_dir}"
tar -C "${helm_plugins_dir}" -xzf "${helm_secrets_plugin_dist}"
helm_data_dir="$(sudo -H -i -u "${VM_USER}" "${helm_bin_file}" env HELM_DATA_HOME)"
chown -R "${VM_USER}:${VM_USER_GROUP}" "${helm_data_dir}"
chmod u=rwX,g=rX,o=rX "${helm_data_dir}"

# age
if ! which age &>/dev/null; then
  age_platform="linux-amd64"
  age_dist_filename="age-v${age_version}-${age_platform}.tar.gz"
  age_dist="${CACHE_DIR}/${age_dist_filename}"
  if [[ ! -f "${age_dist}" ]]; then
    curl -sLf -o "${age_dist}" \
      "https://github.com/FiloSottile/age/releases/download/v${age_version}/${age_dist_filename}"
  fi
  tar -xzf "${age_dist}" --strip-components=1 -C "${usr_local_bin_dir}" "age/age*"
fi

# SOPS
if ! which sops &>/dev/null; then
  sops_platform="linux.amd64"
  sops_dist_filename="sops-v${sops_version}.${sops_platform}"
  sops_dist="${CACHE_DIR}/${sops_dist_filename}"
  if [[ ! -f "${sops_dist}" ]]; then
    curl -sLf -o "${sops_dist}" \
      "https://github.com/mozilla/sops/releases/download/v${sops_version}/${sops_dist_filename}"
  fi
  sops_binary="${usr_local_bin_dir}/sops"
  cp -f "${sops_dist}" "${sops_binary}"
  chown root:root "${sops_binary}"
  chmod u=rwx,g=rx,o=rx "${sops_binary}"
fi

# Install Helmfile
if ! which helmfile &>/dev/null; then
  helmfile_dist_filename="helmfile_${helmfile_version}_linux_amd64.tar.gz"
  helmfile_dist="${CACHE_DIR}/${helmfile_dist_filename}"
  if [[ ! -f "${helmfile_dist}" ]]; then
    curl -sLf -o "${helmfile_dist}" "https://github.com/helmfile/helmfile/releases/download/v${helmfile_version}/${helmfile_dist_filename}"
  fi
  tar -xzf "${helmfile_dist}" -C "${usr_local_bin_dir}" helmfile
  chown root:root "${usr_local_bin_dir}/helmfile"
fi

if [[ ! -e /usr/share/fonts/opentype/source-code-pro ]]; then
  echo "=== Installing font: Source Code Pro"
  fname=1.050R-it.zip
  font_dist="${CACHE_DIR}/${fname}"
  if [[ ! -e "${font_dist}" ]]; then
    curl -sLf -o "${font_dist}" \
      "https://github.com/adobe-fonts/source-code-pro/archive/2.030R-ro/${fname}"
  fi
  unzip -q "${font_dist}" -d /tmp/source-code-pro
  mkdir -p /usr/share/fonts/opentype/source-code-pro
  cp /tmp/source-code-pro/*/OTF/*.otf /usr/share/fonts/opentype/source-code-pro
  chown -R root:root /usr/share/fonts/opentype/source-code-pro
  chmod 644 /usr/share/fonts/opentype/source-code-pro/*
  rm -Rf /tmp/source-code-pro
  fc-cache -f
fi

if [[ ! -e /usr/share/fonts/opentype/fira-code ]]; then
  echo "=== Installing font: Fira Code"
  fname=FiraCode_3.zip
  font_dist="${CACHE_DIR}/${fname}"
  if [[ ! -e "${font_dist}" ]]; then
    curl -sLf -o "${font_dist}" "https://github.com/tonsky/FiraCode/releases/download/3/${fname}"
  fi
  unzip -q "${font_dist}" -d /tmp/fira-code
  mkdir -p /usr/share/fonts/opentype/fira-code
  cp /tmp/fira-code/otf/*.otf /usr/share/fonts/opentype/fira-code
  chown -R root:root /usr/share/fonts/opentype/fira-code
  chmod 644 /usr/share/fonts/opentype/fira-code/*
  rm -Rf /tmp/fira-code
  fc-cache -f
fi

mkdir -p "${truetype_fonts_dir}"
chown -R root:root "${truetype_fonts_dir}"
chmod -R u=rwX,g=rwX,o=rX "${truetype_fonts_dir}"

consolas_font_dir="${truetype_fonts_dir}/consolas"
if [[ ! -e "${consolas_font_dir}" ]]; then
  echo "=== Installing font: Consolas"
  mkdir -p "${consolas_font_dir}"
  cp --no-preserve=all -r "${PROVISION_CONTENT_DIR}/usr/share/fonts/truetype/consolas"/. "${consolas_font_dir}"
  chown -R root:root "${consolas_font_dir}"
  chmod -R u=rwX,g=rwX,o=rX "${consolas_font_dir}"
  find "${consolas_font_dir}" -type f -exec chmod u=rw,g=rw,o=r {} +
  fc-cache -f
fi

fontawesome_font_dir="${truetype_fonts_dir}/fontawesome"
if [[ ! -e "${fontawesome_font_dir}" ]]; then
  echo "=== Installing font: FontAwesome"
  fname="Font-Awesome-4.7.0.zip"
  font_dist="${CACHE_DIR}/${fname}"
  if [[ ! -e "${font_dist}" ]]; then
    curl -sLf -o "${font_dist}" "https://github.com/FortAwesome/Font-Awesome/archive/v4.7.0.zip"
  fi
  tmp_dir="$(mktemp -d)"
  unzip -q "${font_dist}" -d "${tmp_dir}"
  mkdir -p "${fontawesome_font_dir}"
  cp --no-preserve=all "${tmp_dir}"/*/fonts/*.ttf "${fontawesome_font_dir}"
  rm -rf "${tmp_dir}"
  chown -R root:root "${fontawesome_font_dir}"
  chmod -R u=rwX,g=rwX,o=rX "${fontawesome_font_dir}"
  find "${fontawesome_font_dir}" -type f -exec chmod u=rw,g=rw,o=r {} +
  fc-cache -f
fi

jetbrainsmono_font_dir="${truetype_fonts_dir}/jetbrainsmono"
if [[ ! -e "${jetbrainsmono_font_dir}" ]]; then
  echo "=== Installing font: JetBrainsMono"
  font_url="$(curl -sLf https://www.jetbrains.com/lp/mono/ |
    grep -E "JetBrainsMono-[0-9\.]+\.zip" |
    sed -r 's/^.*(https:\/\/download\.jetbrains\.com\/fonts\/JetBrainsMono-[0-9\.]+\.zip).*/\1/')"
  fname="$(echo "${font_url}" | sed -r 's/^.+\/(JetBrainsMono-[0-9\.]+\.zip).*$/\1/')"
  font_dist="${CACHE_DIR}/${fname}"
  if [[ ! -e "${font_dist}" ]]; then
    curl -sLf -o "${font_dist}" "${font_url}"
  fi
  tmp_dir="$(mktemp -d)"
  unzip -q "${font_dist}" -d "${tmp_dir}"
  mkdir -p "${jetbrainsmono_font_dir}"
  cp --no-preserve=all "${tmp_dir}"/JetBrainsMono-*/ttf/*.ttf "${jetbrainsmono_font_dir}"
  rm -rf "${tmp_dir}"
  chown -R root:root "${jetbrainsmono_font_dir}"
  chmod -R u=rwX,g=rwX,o=rX "${jetbrainsmono_font_dir}"
  find "${jetbrainsmono_font_dir}" -type f -exec chmod u=rw,g=rw,o=r {} +
  fc-cache -f
fi

echo "=== Installing font: Microsoft fonts"
dnf install -y https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcore-fonts-installer-2.6-1.noarch.rpm
fc-cache -f

if [[ ! -e "${opt_bin_dir}/dbeaver" ]]; then
  echo "=== Installing DBeaver"
  dbv_url="$(curl -jsLf "https://github.com/dbeaver/dbeaver/releases/expanded_assets/${dbeaver_version}" |
    grep -F -- "-linux.gtk.x86_64.tar.gz" |
    grep "href" |
    sed -r 's/^.+"([^"]+dbeaver-ce-[0-9\.]+-linux.gtk.x86_64.tar.gz)".+$/https:\/\/github.com\1/')"
  test "x${dbv_url}" != "x"
  dbv_fname="$(echo "${dbv_url}" | sed -r 's/^.+\/([^/]+)$/\1/')"
  dbv_dist="${CACHE_DIR}/${dbv_fname}"
  if [[ ! -e "${dbv_dist}" ]]; then
    curl -sLf -o "${dbv_dist}" "${dbv_url}"
  fi
  tar -zxf "${dbv_dist}" -C "${opt_bin_dir}"
  ln -s "${opt_bin_dir}/dbeaver/dbeaver" "${usr_local_bin_dir}/dbeaver"
  chown -R root:root "${opt_bin_dir}/dbeaver"
fi

rsync -a --remove-source-files "${PROVISION_CONTENT_DIR}/home/user/" "${user_home_dir}/"
chown -R "${VM_USER}:${VM_USER_GROUP}" "${user_home_dir}"
rsync -a --remove-source-files "${PROVISION_CONTENT_DIR}/usr/local/share/applications/" "${usr_local_share_dir}/applications/"

sudo -H -i -u "${VM_USER}" mkdir -p "${user_home_dir}/.pki/nssdb"
sudo -H -i -u "${VM_USER}" modutil -create -force -dbdir "sql:${user_home_dir}/.pki/nssdb"

sudo -H -i -u "${VM_USER}" dbus-launch "${provision_scripts_dir}/create_ff_profile.sh"

chown root:root "${provision_certs_dir}"/*
chmod 644 "${provision_certs_dir}"/*
"${provision_scripts_dir}/install_certs.sh"

"${opt_bin_dir}/scripts/code_plugin.sh" 'johnpapa.Angular2'                           "${VM_USER}" 10
"${opt_bin_dir}/scripts/code_plugin.sh" 'johnpapa.vscode-peacock'                     "${VM_USER}" 10
"${opt_bin_dir}/scripts/code_plugin.sh" 'johnpapa.winteriscoming'                     "${VM_USER}" 10
"${opt_bin_dir}/scripts/code_plugin.sh" 'johnpapa.angular-essentials'                 "${VM_USER}" 10
"${opt_bin_dir}/scripts/code_plugin.sh" 'Mikael.Angular-BeastCode'                    "${VM_USER}" 10
"${opt_bin_dir}/scripts/code_plugin.sh" 'steoates.autoimport'                         "${VM_USER}" 10
"${opt_bin_dir}/scripts/code_plugin.sh" 'eamodio.gitlens'                             "${VM_USER}" 10
"${opt_bin_dir}/scripts/code_plugin.sh" 'ms-mssql.mssql'                              "${VM_USER}" 10
"${opt_bin_dir}/scripts/code_plugin.sh" 'ms-python.python'                            "${VM_USER}" 10
"${opt_bin_dir}/scripts/code_plugin.sh" 'asciidoctor.asciidoctor-vscode'              "${VM_USER}" 10
"${opt_bin_dir}/scripts/code_plugin.sh" 'IBM.output-colorizer'                        "${VM_USER}" 10
"${opt_bin_dir}/scripts/code_plugin.sh" 'humao.rest-client'                           "${VM_USER}" 10
"${opt_bin_dir}/scripts/code_plugin.sh" 'redhat.ansible'                              "${VM_USER}" 10
"${opt_bin_dir}/scripts/code_plugin.sh" 'donjayamanne.git-extension-pack'             "${VM_USER}" 10
"${opt_bin_dir}/scripts/code_plugin.sh" 'vscjava.vscode-maven'                        "${VM_USER}" 10
"${opt_bin_dir}/scripts/code_plugin.sh" 'DotJoshJohnson.xml'                          "${VM_USER}" 10
"${opt_bin_dir}/scripts/code_plugin.sh" 'christian-kohler.path-intellisense'          "${VM_USER}" 10
"${opt_bin_dir}/scripts/code_plugin.sh" 'esbenp.prettier-vscode'                      "${VM_USER}" 10
"${opt_bin_dir}/scripts/code_plugin.sh" 'mrmlnc.vscode-scss'                          "${VM_USER}" 10
"${opt_bin_dir}/scripts/code_plugin.sh" 'jebbs.plantuml'                              "${VM_USER}" 10
"${opt_bin_dir}/scripts/code_plugin.sh" 'Arjun.swagger-viewer'                        "${VM_USER}" 10
"${opt_bin_dir}/scripts/code_plugin.sh" 'chrmarti.regex'                              "${VM_USER}" 10
"${opt_bin_dir}/scripts/code_plugin.sh" 'marcostazi.VS-code-vagrantfile'              "${VM_USER}" 10
"${opt_bin_dir}/scripts/code_plugin.sh" 'bbenoist.vagrant'                            "${VM_USER}" 10
"${opt_bin_dir}/scripts/code_plugin.sh" 'bitwisecook.irule'                           "${VM_USER}" 10
"${opt_bin_dir}/scripts/code_plugin.sh" 'Postman.postman-for-vscode'                  "${VM_USER}" 10
"${opt_bin_dir}/scripts/code_plugin.sh" 'ms-vscode.cpptools-extension-pack'           "${VM_USER}" 10
"${opt_bin_dir}/scripts/code_plugin.sh" 'ms-kubernetes-tools.vscode-kubernetes-tools' "${VM_USER}" 10
"${opt_bin_dir}/scripts/code_plugin.sh" 'ms-azuretools.vscode-docker'                 "${VM_USER}" 10
"${opt_bin_dir}/scripts/code_plugin.sh" 'ms-vscode-remote.remote-containers'          "${VM_USER}" 10
"${opt_bin_dir}/scripts/code_plugin.sh" 'HashiCorp.terraform'                         "${VM_USER}" 10
"${opt_bin_dir}/scripts/code_plugin.sh" 'HashiCorp.HCL'                               "${VM_USER}" 10
"${opt_bin_dir}/scripts/code_plugin.sh" 'golang.Go'                                   "${VM_USER}" 10

chmod 755 "${user_home_dir}/.profile"
chmod 755 "${user_home_dir}/.bash_aliases"
chmod -R og-rwx "${user_home_dir}/.m2"
chmod u-x "${user_home_dir}/.m2"/*
chmod 644 "${user_home_dir}/.local/share/JetBrains/consentOptions"/*
find "${user_home_dir}/.config/JetBrains/IntelliJIdea" -type f -exec chmod a-x {} +
find "${user_home_dir}/.config/JetBrains/GoLand" -type f -exec chmod a-x {} +
find "${user_home_dir}/.config/JetBrains/CLion" -type f -exec chmod a-x {} +

chown -R "${VM_USER}:${VM_USER_GROUP}" "${user_home_dir}"

root_home="/root"
root_npm_config="${root_home}/.npmrc"
if [[ -f "${user_home_dir}/.npmrc" ]]; then
  cp -f "${user_home_dir}/.npmrc" "${root_npm_config}"
  chown root:root "${root_npm_config}"
  chmod u=rwX,g=rX,o=rX "${root_npm_config}"
fi
root_npm_dir="${root_home}/.npm"
if [[ -d "${user_home_dir}/.npm" ]]; then
  mkdir -p "${root_npm_dir}"
  cp -Rf "${user_home_dir}/.npm"/. "${root_npm_dir}"/
  chown -R root:root "${root_npm_dir}"
  chmod -R u=rwX,g=rX,o=rX "${root_npm_dir}"
fi
npm install -g @angular/cli

sudo -H -i -u "${VM_USER}" dbus-launch "${provision_scripts_dir}/user_settings.sh"

# Turn off Wayland for login screen
sed -i -r 's/^([[:space:]]*\[daemon\][[:space:]]*)/\1\nWaylandEnable=false/' /etc/gdm/custom.conf

# Configure Bash aliases
# shellcheck disable=SC2088
if ! grep -m 1 -F '~/.bash_aliases' "${user_home_dir}/.bashrc" >/dev/null; then
  # shellcheck disable=SC2129
  echo "if [[ -f ~/.bash_aliases ]]; then" >>"${user_home_dir}/.bashrc"
  echo "    source ~/.bash_aliases" >>"${user_home_dir}/.bashrc"
  echo "fi" >>"${user_home_dir}/.bashrc"
fi

# Bash completion for Maven
echo "source $(printf %q "${maven_bash_completion_script}")" >>"${user_home_dir}/.bashrc"
# Bash completion for kubectl
echo 'source <(kubectl completion bash)' >>"${user_home_dir}/.bashrc"

# Minikube
if ! which minikube &>/dev/null; then
  minikube_platform="linux-amd64"
  minikube_dist_filename="minikube-v${minikube_version}-${minikube_platform}.tar.gz"
  minikube_dist="${CACHE_DIR}/${minikube_dist_filename}"
  if [[ ! -f "${minikube_dist}" ]]; then
    curl -sLf -o "${minikube_dist}" \
      "https://github.com/kubernetes/minikube/releases/download/v${minikube_version}/minikube-${minikube_platform}.tar.gz"
  fi
  minikube_binary="${usr_local_bin_dir}/minikube"
  tar -xzOf "${minikube_dist}" --strip-components=1 \
    "out/minikube-${minikube_platform}" > "${minikube_binary}"
  chmod a+x "${minikube_binary}"
  chown root:root "${minikube_binary}"
fi

# Install yq tool (https://github.com/mikefarah/yq)
if ! which yq &>/dev/null; then
  yq_filename="yq"
  yq_file="${usr_local_bin_dir}/${yq_filename}"
  yq_platform="linux_amd64"
  yq_dist_filename="yq_${yq_version}_${yq_platform}.tar.gz"
  yq_dist="${CACHE_DIR}/${yq_dist_filename}"
  if [[ ! -f "${yq_dist}" ]]; then
    curl -sLf -o "${yq_dist}" \
      "https://github.com/mikefarah/yq/releases/download/v${yq_version}/${yq_filename}_${yq_platform}.tar.gz"
  fi
  tar -xf "${yq_dist}" -C "$(dirname "${yq_file}")" "./${yq_filename}_${yq_platform}"
  mv "$(dirname "${yq_file}")/${yq_filename}_${yq_platform}" "${yq_file}"
  chmod a+x "${yq_file}"
  chown root:root "${yq_file}"
fi

# Install xq tool (https://github.com/sibprogrammer/xq)
if ! which xq &>/dev/null; then
  xq_filename="xq"
  xq_file="${usr_local_bin_dir}/${xq_filename}"
  xq_platform="linux_amd64"
  xq_dist_filename="xq_${xq_version}_${xq_platform}.tar.gz"
  xq_dist="${CACHE_DIR}/${xq_dist_filename}"
  if [[ ! -f "${xq_dist}" ]]; then
    curl -sLf -o "${xq_dist}" \
      "https://github.com/sibprogrammer/xq/releases/download/v${xq_version}/${xq_filename}_${xq_version}_${xq_platform}.tar.gz"
  fi
  tar -xf "${xq_dist}" -C "$(dirname "${xq_file}")" "${xq_filename}"
  chmod a+x "${xq_file}"
  chown root:root "${xq_file}"
fi

# direnv (https://direnv.net/)
if ! which direnv &>/dev/null; then
  direnv_filename="direnv"
  direnv_file="${usr_local_bin_dir}/${direnv_filename}"
  direnv_platform="linux-amd64"
  direnv_dist_filename="direnv_${direnv_version}_${direnv_platform}"
  direnv_dist="${CACHE_DIR}/${direnv_dist_filename}"
  if [[ ! -f "${direnv_dist}" ]]; then
    curl -sLf -o "${direnv_dist}" \
      "https://github.com/direnv/direnv/releases/download/v${direnv_version}/direnv.${direnv_platform}"
  fi
  cp --no-preserve=all "${direnv_dist}" "${direnv_file}"
  chmod u=rwx,g=rx,o=rx "${direnv_file}"
  chown root:root "${direnv_file}"
  # shellcheck disable=SC2016
  echo 'eval "$(direnv hook bash)"' >>"${user_home_dir}/.bashrc"
fi

# Headlamp (https://headlamp.dev/)
headlamp_home="${opt_bin_dir}/headlamp"
if [[ ! -e "${headlamp_home}" ]]; then
  echo "=== Installing Headlamp"
  headlamp_fname="Headlamp-${headlamp_version}-linux-x64.tar.gz"
  headlamp_dist="${CACHE_DIR}/${headlamp_fname}"
  if [[ ! -f "${headlamp_dist}" ]]; then
    curl -sLf -o "${headlamp_dist}" "https://github.com/headlamp-k8s/headlamp/releases/download/v${headlamp_version}/${headlamp_fname}"
  fi
  tar -zxf "${headlamp_dist}" -C "${opt_bin_dir}"
  mv "$(find "${opt_bin_dir}" -maxdepth 1 -name "Headlamp*" -type d)" "${headlamp_home}"
  cp --no-preserve=all "${PROVISION_CONTENT_DIR}/opt/headlamp/headlamp.svg" "${headlamp_home}"
  chown -R root:root "${opt_bin_dir}/headlamp"
fi

if ! which lens-desktop &>/dev/null; then
  dnf config-manager -y --add-repo https://downloads.k8slens.dev/rpm/lens.repo
  dnf install -y lens
fi

# Change host name to avoid resolution of host name (default is localhost.localdomain) to 127.0.0.1
hostnamectl set-hostname dev.localdomain.local

# Maven Resolver Named Locks using Redisson
# https://maven.apache.org/resolver/maven-resolver-named-locks-redisson/index.html
dnf install -y redis
systemctl enable redis
systemctl start redis
"${provision_scripts_dir}/maven_resolver_named_locks_redisson.sh"

# Clean up

dnf clean all --enablerepo=*
rm -rf /var/cache/dnf

rm -rf "${repository_dir}"
mkdir -p "${repository_dir}/maven/repository"
mkdir -p "${repository_dir}/npm/npm-cache"
mkdir -p "${repository_dir}/go/bin"
mkdir -p "${repository_dir}/cache"
mkdir -p "${repository_dir}/nuget/packages"
chown -R "${VM_USER}:${VM_USER_GROUP}" "${repository_dir}"
chmod u=rwX,g=rX,o=rX -R "${repository_dir}"

# Remove temporary dirs
rm -rf "${PROVISION_CONTENT_DIR}"

exit 0
