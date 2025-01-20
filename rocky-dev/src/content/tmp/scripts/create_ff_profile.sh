#!/bin/bash
set -e

firefox --headless &
pid=$!
sleep 20
kill ${pid}
