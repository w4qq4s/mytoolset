#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "[*] Checking shell syntax"
find "$ROOT/bin" "$ROOT/lib" -type f -name '*.sh' -print0 | while IFS= read -r -d '' f; do
  bash -n "$f"
done
bash -n "$ROOT/install.sh"
bash -n "$ROOT/uninstall.sh"

echo "[*] Running basic help output"
for cmd in "$ROOT/bin/"*; do
  if [ -x "$cmd" ]; then
    "$cmd" --help >/dev/null 2>&1 || true
  fi
done

echo "[+] Smoke test completed"
