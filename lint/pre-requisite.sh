#!/bin/bash
set -e

# Check and install NVM if not installed
if [ -d "$HOME/.nvm" ]; then
  echo "NVM already installed. Skipping installation."
else
  echo "Installing NVM..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.2/install.sh | bash
fi

# Load NVM environment
export NVM_DIR="$HOME/.nvm"
# shellcheck disable=SC1091
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

echo "Installing Node.js 20.x...."
nvm install 20

# Use Node.js 20
nvm use 20

# Check Node.js and npm versions
node --version
npm --version

# Install dependencies if node_modules does not exist
if [ -d "node_modules" ]; then
  echo "Dependencies already installed. Skipping npm install."
else
  echo "Installing dependencies..."
  npm install
fi

# Check if ilib-lint is already linked
if npm ls -g --depth=0 --parseable | grep -q "ilib-lint"; then
  echo "ilib-lint already linked globally. Skipping npm link."
else
  echo "Linking ilib-lint and ilib-lint-webos ..."
  npm link ilib-lint
  npm link ilib-lint-webos
  npm link option-parser
fi

echo "✅ Setup complete!"