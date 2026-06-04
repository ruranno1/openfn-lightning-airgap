#!/usr/bin/env bash
set -euo pipefail

if [ ! -f sha256sums.txt ]; then
  echo "FAILED: sha256sums.txt not found. Run this script from the extracted bundle directory."
  exit 1
fi

echo "Checking bundle integrity..."
sha256sum -c sha256sums.txt

echo
echo "SUCCESS: Bundle integrity check passed."
