#!/usr/bin/env bash

set -e

CONFIG="link.conf.yaml"
BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "${BASEDIR}"

dotbot -d "${BASEDIR}" -c "${CONFIG}" "$@"
