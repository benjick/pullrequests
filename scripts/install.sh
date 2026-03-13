#!/bin/bash
set -e

APP_NAME="PullRequests"
BUILD_DIR=".build/release"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

echo "Building..."
bash scripts/build-app.sh

echo "Installing to /Applications..."
cp -r "$APP_BUNDLE" /Applications/
echo "Done! You can launch PullRequests from /Applications."
