#!/bin/bash
set -e

echo "Starting system setup"

if [[ $EUID -eq 0 ]]; then
  echo "Please do not run as root"
  exit 1
fi

