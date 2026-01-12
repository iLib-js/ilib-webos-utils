!/bin/bash
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

# Check and install Node.js LTS if not installed
if nvm ls --no-colors | grep -q "lts"; then
  echo "Node.js LTS already installed. Skipping installation."
else
  echo "Installing Node.js LTS..."
  nvm install --lts
fi

# Use Node.js LTS
nvm use --lts

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

# Check if ilib-lnt is already linked
if npm ls -g --depth=0 --parseable | grep -q "ilib-lint"; then
  echo "ilib-lnt already linked globally. Skipping npm link."
else
  echo "Linking ilib-lint..."
  npm link ilib-lint
fi

# Run linting
# echo "Running lint..."
#npm run lint -- ilib-lint-webos

echo "✅ Setup complete!"