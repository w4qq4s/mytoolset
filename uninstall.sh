#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="${HOME}/.waqqas-toolset"
BIN_DIR="${HOME}/.local/bin"

for cmd in   wsetup wupdate ctfinit boxprep tmuxbox wnote wgrep lootindex   scanwrap portpeek webprobe dnspeek httphead myip netcheck flagscan   extractall hashid jwtpeek htbsave; do
  rm -f "$BIN_DIR/$cmd"
done

rm -rf "$INSTALL_DIR"

echo "[+] Uninstalled Waqqas Toolset from $INSTALL_DIR"
echo "[*] ~/.local/bin entries removed for the toolset"
