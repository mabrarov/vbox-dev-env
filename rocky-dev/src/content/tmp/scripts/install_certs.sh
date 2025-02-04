#!/bin/bash -eux
echo "Installing certificates"

certs_dir="${PROVISION_CONTENT_DIR}/tmp/certs"

function import_ca_cert_into_java {
  keytool -import -file "${1}" -noprompt -alias "${2}" -storepass changeit -keystore "${3}"
}

function import_certs_into_java {
  import_ca_cert_into_java "${certs_dir}/ru-root-ca.crt" ru-root-ca "${1}"
}

import_certs_into_java /opt/jdk/jre/lib/security/cacerts
import_certs_into_java /opt/ideaIU/jbr/lib/security/cacerts
import_certs_into_java /opt/jdk-11/lib/security/cacerts
import_certs_into_java /opt/jdk-17/lib/security/cacerts

sudo -H -i -u "${VM_USER}" /opt/scripts/certdb.sh "${certs_dir}/ru-root-ca.crt" ru-root-ca
