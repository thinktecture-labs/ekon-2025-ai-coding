#!/usr/bin/env bash
set -euo pipefail

if ! command -v fpc >/dev/null 2>&1; then
  echo "[test] Error: fpc not found in PATH" >&2
  exit 1
fi

mkdir -p build
echo "[test] Compiling tests…"
fpc tests/test_all.pas -Fu./src -Fu./src/core -Fu./tests -FEbuild

echo "[test] Running tests…"
exec ./build/test_all --all --format=plain

