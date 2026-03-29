#!/usr/bin/env bash
set -euo pipefail

# Rebuild script for reduxjs/react-redux
# Runs from website/ in the existing source tree (no clone).
# Installs deps, runs pre-build steps, builds the Docusaurus site.

# --- Node version ---
# Docusaurus 3.6.3 + Yarn 4.4.1 (Berry) requires Node 20+
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [ -f "$NVM_DIR/nvm.sh" ]; then
    . "$NVM_DIR/nvm.sh"
    nvm install 20
    nvm use 20
fi
echo "[INFO] Node: $(node --version)"

# --- Package manager: Yarn 4.4.1 (Berry) via corepack ---
corepack enable
corepack prepare yarn@4.4.1 --activate

CURRENT_DIR="$(pwd)"

# --- Install root workspace deps ---
# react-redux is a monorepo: root package.json has workspaces, website/ is a workspace.
# The staging repo preserves the full tree, so ../package.json should be present.
if [ -f "../package.json" ] && node -e "const p=require('../package.json'); process.exit(p.workspaces ? 0 : 1)" 2>/dev/null; then
    echo "[INFO] Monorepo root found at .., installing from root..."
    cd ..
    yarn install --immutable
    cd "$CURRENT_DIR"
else
    echo "[INFO] No monorepo root found, cloning source for root-level setup..."
    TEMP_DIR="/tmp/react-redux-root-$$"
    git clone --depth 1 --branch master https://github.com/reduxjs/react-redux "$TEMP_DIR"
    cd "$TEMP_DIR"
    corepack prepare yarn@4.4.1 --activate
    yarn install --immutable
    rm -rf "$TEMP_DIR"
    cd "$CURRENT_DIR"
fi

# --- Install website dependencies ---
yarn install --immutable

# --- Build Docusaurus site ---
yarn build

echo "[DONE] Build complete."
