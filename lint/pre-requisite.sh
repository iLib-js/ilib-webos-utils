#!/bin/bash
# install_i18n_utils.sh
# Script to install required packages for webOS i18n/l10n tasks

echo "Installing required npm packages for webOS i18n/l10n..."

# Move to project root (modify if necessary)
cd "$(dirname "$0")"

# Initialize npm project if package.json doesn't exist
if [ ! -f package.json ]; then
  echo "Initializing npm project..."
  npm init -y
fi

# Install required packages
npm install ilib-lint ilib-lint-webos option-parser --save-dev

echo "✅ All required packages have been installed successfully."