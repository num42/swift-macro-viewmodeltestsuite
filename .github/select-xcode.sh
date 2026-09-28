#!/bin/sh
set -e

# Package.swift needs Swift tools 6.3, which the runner's default Xcode may not have.
# Use the newest stable Xcode on the runner.
XCODE=$(ls -d /Applications/Xcode_*.app | grep -viE 'beta|_rc' | sort -V | tail -1)

echo "DEVELOPER_DIR=$XCODE/Contents/Developer" >> "$GITHUB_ENV"
DEVELOPER_DIR="$XCODE/Contents/Developer" xcrun swift --version
