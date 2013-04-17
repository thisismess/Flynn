#!/usr/bin/env bash

set -e

ME="$0"
ME_HOME=$(dirname "$0")
ME_HOME=$(cd "$ME_HOME" && pwd)

SHIP_BASE=$(cd "$ME_HOME/.." && pwd)
PRODUCT_BASE="$SHIP_BASE/product"
ARCHIVE_BASE="$("$ME_HOME/latest_archive.rb" -n Flynn)/Products"

if [ ! -d "$PRODUCT_BASE" ]; then
  mkdir -p "$PRODUCT_BASE"
fi

cp -r "$ARCHIVE_BASE/"* "$PRODUCT_BASE"

