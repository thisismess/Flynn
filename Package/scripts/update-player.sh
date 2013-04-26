#!/usr/bin/env bash

set -e

ME="$0"
ME_HOME=$(dirname "$0")
ME_HOME=$(cd "$ME_HOME" && pwd)

SHIP_BASE=$(cd "$ME_HOME/.." && pwd)
PROJECT_BASE=$(cd "$SHIP_BASE/.." && pwd)
PRODUCT_BASE="$SHIP_BASE/products/player"
ARCHIVE_BASE="$PROJECT_BASE/Player"
VERSION_BASE="$SHIP_BASE/releases"

if [ ! -z "$1" ]; then
  VERSION="-$1"; shift
fi

if [ -d "$PRODUCT_BASE" ]; then
  rm -r "$PRODUCT_BASE"
fi

mkdir -p "$PRODUCT_BASE"
cp -r "$ARCHIVE_BASE" "$PRODUCT_BASE"
mv "$PRODUCT_BASE/Player" "$PRODUCT_BASE/flynn"
(cd "$PRODUCT_BASE" && zip -r "$VERSION_BASE/flynn$VERSION.zip" "flynn")

