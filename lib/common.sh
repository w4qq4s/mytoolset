#!/usr/bin/env bash
# shellcheck shell=bash

WAQQAS_TOOLSET_REPO="https://github.com/w4qq4s/mytoolset"
WAQQAS_TOOLSET_HOME_DEFAULT="${WAQQAS_TOOLSET_HOME:-$HOME/.waqqas-toolset}"
WAQQAS_WORKSPACE_DEFAULT="${WAQQAS_WORKSPACE:-$HOME/CTF}"

waq_msg() {
  echo "[*] $*"
}

waq_ok() {
  echo "[+] $*"
}

waq_warn() {
  echo "[!] $*" >&2
}

waq_die() {
  echo "[!] $*" >&2
  exit 1
}

waq_have() {
  command -v "$1" >/dev/null 2>&1
}

waq_require() {
  waq_have "$1" || waq_die "Missing dependency: $1"
}

waq_repo() {
  printf '%s\n' "$WAQQAS_TOOLSET_REPO"
}

waq_tool_home() {
  printf '%s\n' "${WAQ_HOME:-$WAQQAS_TOOLSET_HOME_DEFAULT}"
}

waq_version() {
  local home
  home="$(waq_tool_home)"
  if [ -f "$home/VERSION" ]; then
    cat "$home/VERSION"
  else
    printf 'unknown\n'
  fi
}

waq_now() {
  date '+%Y-%m-%d %H:%M:%S'
}

waq_slug() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9._-]/_/g'
}

waq_project_root() {
  local dir
  dir="${1:-$PWD}"
  while [ "$dir" != "/" ]; do
    if [ -f "$dir/.waqqas-project" ]; then
      printf '%s\n' "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  return 1
}

waq_project_name() {
  local root
  root="$(waq_project_root "${1:-$PWD}")" || return 1
  basename "$root"
}

waq_project_notes() {
  local root
  root="$(waq_project_root "${1:-$PWD}")" || return 1
  printf '%s\n' "$root/notes/notes.md"
}

waq_workspace() {
  printf '%s\n' "$WAQQAS_WORKSPACE_DEFAULT"
}

waq_escape_sed() {
  printf '%s' "$1" | sed -e 's/[\\/&]/\\&/g'
}

waq_template_render() {
  local template="$1"
  local name="$2"
  local type="$3"
  local target="$4"
  local created="$5"
  local ename etype etarget ecreated
  ename="$(waq_escape_sed "$name")"
  etype="$(waq_escape_sed "$type")"
  etarget="$(waq_escape_sed "$target")"
  ecreated="$(waq_escape_sed "$created")"
  sed \
    -e "s/{{NAME}}/$ename/g" \
    -e "s/{{TYPE}}/$etype/g" \
    -e "s/{{TARGET}}/$etarget/g" \
    -e "s/{{CREATED}}/$ecreated/g" \
    "$template"
}

waq_ensure_dir() {
  mkdir -p "$1"
}

waq_need_project() {
  waq_project_root "${1:-$PWD}" >/dev/null 2>&1 || waq_die "Not inside a Waqqas project. Run ctfinit first."
}

waq_note_append() {
  local message="$1"
  local notes_file
  notes_file="$(waq_project_notes)" || waq_die "Could not find notes.md"
  printf -- "- [%s] %s\n" "$(waq_now)" "$message" >> "$notes_file"
  waq_ok "Added note to $notes_file"
}

waq_nmap_outdir() {
  local root
  if root="$(waq_project_root "${1:-$PWD}" 2>/dev/null)"; then
    printf '%s\n' "$root/recon"
  else
    printf '%s\n' "$PWD"
  fi
}

waq_show_help_hint() {
  local cmd="$1"
  echo "Run '$cmd --help' for usage."
}
