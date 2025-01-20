#!/bin/bash

mkdir -p "${1}/eval"
python "${HOME}/.local/j.py" "${1}/eval/${2}$(sed -r 's/^[A-Z]+-([0-9]+).*$/\1/g' "${3}/build.txt").evaluation.key"
