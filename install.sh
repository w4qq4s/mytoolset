#!/usr/bin/env bash
set -euo pipefail

TOOLSET_NAME="Waqqas Toolset"
INSTALL_DIR="${HOME}/.waqqas-toolset"
BIN_DIR="${HOME}/.local/bin"
WITH_HTB_CLI=0
SKIP_DEPS=0
NO_PATH=0

msg() {
  echo "[*] $*"
}

ok() {
  echo "[+] $*"
}

warn() {
  echo "[!] $*" >&2
}

have() {
  command -v "$1" >/dev/null 2>&1
}

usage() {
  cat <<'EOF'
Usage:
  bash install.sh [options]

Options:
  --skip-deps       Do not install apt packages
  --with-htb-cli    Install htb-cli as 'htb' if possible
  --no-path         Do not modify .bashrc or .zshrc
  -h, --help        Show this help
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --skip-deps) SKIP_DEPS=1 ;;
    --with-htb-cli) WITH_HTB_CLI=1 ;;
    --no-path) NO_PATH=1 ;;
    -h|--help) usage; exit 0 ;;
    *) warn "Unknown option: $1"; usage; exit 1 ;;
  esac
  shift
done

ensure_packages() {
  [ "$SKIP_DEPS" -eq 1 ] && return 0

  if have apt-get; then
    msg "Installing dependencies with apt"
    if have sudo; then
      sudo apt-get update -y
      sudo apt-get install -y curl wget git jq tmux unzip file dnsutils iproute2 openssl tar gzip ca-certificates
      sudo apt-get install -y ripgrep nmap p7zip-full unrar || true
    else
      warn "sudo not found, skipping package installation"
    fi
  else
    warn "apt-get not found. Install dependencies manually."
  fi
}

ensure_path() {
  [ "$NO_PATH" -eq 1 ] && return 0

  mkdir -p "$BIN_DIR"
  if echo "$PATH" | tr ':' '\n' | grep -qx "$BIN_DIR"; then
    return 0
  fi

  local shell_rc
  if [ -n "${ZSH_VERSION:-}" ]; then
    shell_rc="$HOME/.zshrc"
  else
    shell_rc="$HOME/.bashrc"
  fi
  touch "$shell_rc"

  # shellcheck disable=SC2016
  if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$shell_rc"; then
    # shellcheck disable=SC2016
    printf '\n# Waqqas Toolset\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "$shell_rc"
    ok "Updated PATH in $shell_rc"
  fi
}

copy_repo() {
  local src_dir
  src_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  msg "Installing repo into $INSTALL_DIR"
  mkdir -p "$INSTALL_DIR" "$BIN_DIR"
  rm -rf "$INSTALL_DIR"
  mkdir -p "$INSTALL_DIR"

  cp -R "$src_dir"/. "$INSTALL_DIR"/
  rm -rf "$INSTALL_DIR/.git" "$INSTALL_DIR/.github" || true
}

install_bins() {
  msg "Installing commands into $BIN_DIR"
  local f name
  for f in "$INSTALL_DIR/bin/"*; do
    [ -f "$f" ] || continue
    chmod +x "$f"
    name="$(basename "$f")"
    install -m 0755 "$f" "$BIN_DIR/$name"
  done
  chmod +x "$INSTALL_DIR/scripts/"*.sh || true
}

install_htb_cli() {
  [ "$WITH_HTB_CLI" -eq 1 ] || return 0

  if have htb; then
    ok "htb already present, skipping optional install"
    return 0
  fi

  have curl || { warn "curl missing, cannot install htb-cli"; return 0; }
  have tar || { warn "tar missing, cannot install htb-cli"; return 0; }
  have jq || { warn "jq missing, cannot install htb-cli"; return 0; }

  local repo="Shadow21AR/htb-cli"
  local arch api asset tmp
  case "$(uname -m)" in
    x86_64|amd64) arch="amd64" ;;
    aarch64|arm64) arch="arm64" ;;
    *) warn "Unsupported architecture for htb-cli: $(uname -m)"; return 0 ;;
  esac

  api="https://api.github.com/repos/$repo/releases/latest"
  asset="$(curl -fsSL "$api" | jq -r '.assets[]?.browser_download_url' | grep -i 'linux' | grep -i "$arch" | head -n1 || true)"
  if [ -z "$asset" ]; then
    warn "Could not detect a release asset for htb-cli"
    return 0
  fi

  tmp="$(mktemp -d)"
  (
    cd "$tmp"
    curl -fL --progress-bar "$asset" -o htbcli.pkg
    if file htbcli.pkg | grep -qi 'zip'; then
      unzip -q htbcli.pkg
    else
      tar -xf htbcli.pkg 2>/dev/null || true
    fi
    local bin
    bin="$(find . -maxdepth 3 -type f -name 'htb*' -perm -111 | head -n1 || true)"
    if [ -z "$bin" ]; then
      warn "Could not find extracted htb binary"
      exit 0
    fi
    install -m 0755 "$bin" "$BIN_DIR/htb"
  )
  rm -rf "$tmp"
  ok "Installed optional htb-cli as $BIN_DIR/htb"
}

main() {
  msg "$TOOLSET_NAME"
  ensure_packages
  ensure_path
  copy_repo
  install_bins
  install_htb_cli
  ok "Install complete"
  echo "Run: wsetup"
}

main "$@"
