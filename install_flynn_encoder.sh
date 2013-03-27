#!/usr/bin/env bash

# exit on error
set -e
# build the Flynn target and install it
xcodebuild -target Flynn -configuration Release DSTROOT=/ install
