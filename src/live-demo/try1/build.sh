#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="${ROOT_DIR}/src"
BIN_DIR="${ROOT_DIR}/bin"

mkdir -p "${BIN_DIR}"
rm -f "${BIN_DIR}/"*

fpc -MObjFPC -Sh -S2 -Fi"${SRC_DIR}" -Fu"${SRC_DIR}" -FE"${BIN_DIR}" -o"${BIN_DIR}/Minesweeper" "${SRC_DIR}/MinesweeperApp.pas"
