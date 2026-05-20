#!/bin/bash
set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

# -----------------------------------------------
# Step 1: Ensure Node.js >= 20 is available
# -----------------------------------------------

node_ok() {
  command -v node >/dev/null 2>&1 || return 1
  node -e "process.exit(parseInt(process.versions.node) >= 20 ? 0 : 1)" 2>/dev/null
}

if node_ok; then
  echo "Node.js $(node --version) already available. Skipping NVM setup."
else
  # curl 설치 여부 확인
  if ! command -v curl >/dev/null 2>&1; then
    echo "Error: curl is required to install NVM but was not found."
    echo "Please install curl (e.g. sudo apt install curl) and re-run this script."
    exit 1
  fi

  # NVM 설치
  if [ -d "$HOME/.nvm" ]; then
    echo "NVM already installed. Skipping installation."
  else
    echo "Installing NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.2/install.sh | bash
  fi

  # NVM 로드
  export NVM_DIR="$HOME/.nvm"
  # shellcheck disable=SC1091
  if [ -s "$NVM_DIR/nvm.sh" ]; then
    \. "$NVM_DIR/nvm.sh"
  else
    echo "Error: Failed to load NVM. Please restart your shell and re-run this script."
    exit 1
  fi

  echo "Installing Node.js 20.x..."
  nvm install 20
  nvm use 20
fi

node --version
npm --version

# -----------------------------------------------
# Step 2: Install dependencies
# -----------------------------------------------
cd "$SCRIPT_DIR"

if [ -d "node_modules" ]; then
  echo "Dependencies already installed. Skipping npm install."
else
  echo "Installing dependencies..."
  npm install
fi

# -----------------------------------------------
# Step 3: Verify loctool is installed
# -----------------------------------------------
if [ ! -f "$SCRIPT_DIR/node_modules/.bin/loctool" ]; then
  echo "Error: loctool was not installed correctly."
  echo "Please check your network connection and re-run this script."
  exit 1
fi

# -----------------------------------------------
# Step 4: Install bats (test runner)
# -----------------------------------------------
if command -v bats >/dev/null 2>&1; then
  echo "bats $(bats --version) already available. Skipping installation."
else
  echo "Installing bats..."
  npm install -g bats
  if ! command -v bats >/dev/null 2>&1; then
    echo "Error: bats was not installed correctly."
    echo "Please check your network connection and re-run this script."
    exit 1
  fi
fi

echo "✅ Setup complete!"

