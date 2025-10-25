#!/usr/bin/env bash

set -e

# Check if profile argument is provided
if [ $# -eq 0 ]; then
    echo "Error: Profile argument is required."
    echo "Usage: $0 <profile>"
    echo "Example: $0 bulblax"
    exit 1
fi

profile="$1"

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "${BASEDIR}"

# Use profile-specific config file
CONFIG="${profile}.conf.yaml"

# Check if config file exists
if [ ! -f "$CONFIG" ]; then
    echo "Error: Config file '$CONFIG' does not exist."
    exit 1
fi

echo "Using profile: $profile"
echo "Using config: $CONFIG"

dotbot -d "${BASEDIR}" -c "${CONFIG}" "${@:2}"
