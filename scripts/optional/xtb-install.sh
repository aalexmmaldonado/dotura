#!/usr/bin/env bash

INSTALL_DIR="/usr/bin"
TMP_DIR=$(mktemp -d)
VERSION="6.7.1"
FILE_NAME="xtb-$VERSION-linux-x86_64.tar.xz"

BIN_URL="https://github.com/grimme-lab/xtb/releases/download/v$VERSION/$FILE_NAME"

cd $TMP_DIR

echo "Downloading xtb v$VERSION ..."
wget -q $BIN_URL

echo "Extracting xtb ..."
tar xf $FILE_NAME

echo "Installing xtb to ~/.local/bin"
cp xtb-dist/bin/xtb ~/.local/bin

clean_up() {
  test -d "$tmp_dir" && rm -fr "$tmp_dir"
}

trap clean_up EXIT

