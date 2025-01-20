#!/bin/bash
set -e

# Script installs provided certificate to certificate trust store of applications using NSS
# (e.g. Firefox, Thunderbird, Chromium)
# Mozilla uses cert8, Chromium and Chrome use cert9

# Requirement: apt-get install libnss3-tools
# or:          dnf install nss-tools

cert_file="${1}"
cert_name="${2}"

# For cert8 (legacy - DBM)
while IFS= read -r -d '' cert_db; do
  [[ -f "${cert_db}" ]] || continue
  cert_dir="$(dirname "${cert_db}")"
  certutil -A -n "${cert_name}" -t "C,," -i "${cert_file}" -d "dbm:${cert_dir}"
done <   <(find ~/ -name "cert8.db")

# For cert9 (SQL)
while IFS= read -r -d '' cert_db; do
  [[ -f "${cert_db}" ]] || continue
  cert_dir="$(dirname "${cert_db}")";
  certutil -A -n "${cert_name}" -t "C,," -i "${cert_file}" -d "sql:${cert_dir}"
done <   <(find ~/ -name "cert9.db")
