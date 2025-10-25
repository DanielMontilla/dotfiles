#!/usr/bin/env bash

set -e

# Color definitions
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PROFILE_NAME="nix"
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
FLAKE_TARGET="path:$SCRIPT_DIR"

echo -e "${BLUE}▶ Activating profile '${YELLOW}${PROFILE_NAME}${BLUE}' from local flake...${NC}"

echo -e "${BLUE} - Removing old profile...${NC}"
nix profile remove "$PROFILE_NAME" || true

echo -e "${BLUE} - Adding new profile from local changes...${NC}"
nix profile add "$FLAKE_TARGET"

echo -e "${GREEN}Completed.${NC}"

