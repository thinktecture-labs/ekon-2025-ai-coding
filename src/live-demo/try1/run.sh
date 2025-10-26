#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${ROOT_DIR}/bin"
APP_PATH="${BIN_DIR}/Minesweeper"

if [[ ! -x "${APP_PATH}" ]]; then
  echo "Executable not found at ${APP_PATH}. Run ./build.sh first." >&2
  exit 1
fi

"${APP_PATH}"
