#!/usr/bin/env bash
# pyvenv_lib.sh — helper library for pyvenv
# Sourced by bin/pyvenv; not meant to be run directly.

# ── colour helpers ────────────────────────────────────────────────────────────
_pv_has_colour() {
    [ -t 1 ] && command -v tput >/dev/null 2>&1 && [ "$(tput colors 2>/dev/null)" -ge 8 ] 2>/dev/null
}

pv_msg()  { echo "[*] $*"; }
pv_ok()   { echo "[+] $*"; }
pv_warn() { echo "[!] $*" >&2; }
pv_err()  { echo "[x] $*" >&2; }
pv_ask()  { printf "[?] %s " "$*"; }

pv_sep() {
    printf '%0.s─' $(seq 1 60)
    echo
}

# ── utility ───────────────────────────────────────────────────────────────────
have() { command -v "$1" >/dev/null 2>&1; }

# ── venv detection ────────────────────────────────────────────────────────────
# Finds all venvs in a directory (looks for pyvenv.cfg up to 2 levels deep).
# Prints one result per line: "<venv_dir>|<python_version>"
pv_find_venvs() {
    local target_dir="$1"
    local found=0

    while IFS= read -r cfg; do
        local venv_dir
        venv_dir="$(dirname "$cfg")"
        local py_ver=""
        if [ -f "$cfg" ]; then
            py_ver="$(grep -i '^version' "$cfg" 2>/dev/null | head -n1 | awk -F'=' '{print $2}' | tr -d ' ' || true)"
        fi
        echo "${venv_dir}|${py_ver:-unknown}"
        found=1
    done < <(find "$target_dir" -maxdepth 2 -name "pyvenv.cfg" 2>/dev/null)

    return 0
}

# ── python version discovery ──────────────────────────────────────────────────
pv_discover_pythons() {
    local versions=()

    # Common explicit versioned binaries
    local candidate
    for major in 3; do
        for minor in 14 13 12 11 10 9 8; do
            candidate="python${major}.${minor}"
            if have "$candidate"; then
                local ver
                ver="$($candidate --version 2>&1 | awk '{print $2}')"
                versions+=("${ver}|${candidate}")
            fi
        done
    done

    # Fallback: plain python3
    if have python3; then
        local ver
        ver="$(python3 --version 2>&1 | awk '{print $2}')"
        # Only add if not already captured
        local already=0
        for v in "${versions[@]:-}"; do
            [[ "$v" == "${ver}|"* ]] && already=1 && break
        done
        [ "$already" -eq 0 ] && versions+=("${ver}|python3")
    fi

    # pyenv managed versions (if pyenv present)
    if have pyenv; then
        while IFS= read -r pyenv_ver; do
            pyenv_ver="$(echo "$pyenv_ver" | tr -d ' *')"
            [[ "$pyenv_ver" == 3.* ]] || continue
            local bin
            bin="$(pyenv root)/versions/${pyenv_ver}/bin/python3"
            [ -x "$bin" ] || bin="$(pyenv root)/versions/${pyenv_ver}/bin/python"
            [ -x "$bin" ] || continue
            local already=0
            for v in "${versions[@]:-}"; do
                [[ "$v" == "${pyenv_ver}|"* ]] && already=1 && break
            done
            [ "$already" -eq 0 ] && versions+=("${pyenv_ver}|${bin}")
        done < <(pyenv versions --bare 2>/dev/null)
    fi

    printf '%s\n' "${versions[@]:-}"
}

# Resolve interpreter binary for a given version string like "3.11" or "3.11.2"
pv_resolve_interpreter() {
    local want="$1"

    # Try exact match first: python3.11, python3.11.2 etc.
    local candidates=("python${want}" "python3.${want##3.}" "python3")

    for c in "${candidates[@]}"; do
        if have "$c"; then
            local ver
            ver="$($c --version 2>&1 | awk '{print $2}')"
            # Check the version starts with what was requested
            if [[ "$ver" == "${want}"* ]] || [[ "$ver" == "3.${want##3.}"* ]]; then
                echo "$c"
                return 0
            fi
        fi
    done

    # Try pyenv shims
    if have pyenv; then
        local bin
        bin="$(pyenv root)/versions/${want}/bin/python3"
        [ -x "$bin" ] && echo "$bin" && return 0
        bin="$(pyenv root)/versions/${want}/bin/python"
        [ -x "$bin" ] && echo "$bin" && return 0
    fi

    # Last resort: just check if pythonX.Y exists
    if have "python${want}"; then
        echo "python${want}"
        return 0
    fi

    return 1
}

# ── interactive python picker ─────────────────────────────────────────────────
pv_pick_python() {
    local preset_version="$1"   # empty if not specified by flag

    if [ -n "$preset_version" ]; then
        local interp
        if interp="$(pv_resolve_interpreter "$preset_version")"; then
            echo "$interp"
            return 0
        else
            pv_err "Python $preset_version not found on this system."
            return 1
        fi
    fi

    pv_sep
    pv_msg "Discovering available Python interpreters..."
    local versions_raw
    mapfile -t versions_raw < <(pv_discover_pythons)

    if [ "${#versions_raw[@]}" -eq 0 ]; then
        pv_warn "No Python 3 interpreters found in PATH."
        pv_ask "Enter interpreter path or version manually:"
        read -r manual
        if have "$manual"; then
            echo "$manual"
            return 0
        fi
        pv_err "Cannot find interpreter: $manual"
        return 1
    fi

    echo ""
    local i=1
    for entry in "${versions_raw[@]}"; do
        local ver bin
        ver="${entry%%|*}"
        bin="${entry##*|}"
        printf "    [%d] Python %-12s  (%s)\n" "$i" "$ver" "$bin"
        (( i++ ))
    done
    printf "    [m] Enter manually\n"
    echo ""

    local choice
    while true; do
        pv_ask "Select Python version [1-$((i-1)) / m]:"
        read -r choice
        if [[ "$choice" == "m" || "$choice" == "M" ]]; then
            pv_ask "Enter interpreter (e.g. python3.11 or /usr/bin/python3.12):"
            read -r manual
            if have "$manual"; then
                echo "$manual"
                return 0
            fi
            pv_err "Not found: $manual"
            continue
        fi
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -lt "$i" ]; then
            local selected="${versions_raw[$((choice-1))]}"
            echo "${selected##*|}"
            return 0
        fi
        pv_warn "Invalid selection, try again."
    done
}

# ── venv creation ─────────────────────────────────────────────────────────────
pv_create_venv() {
    local interpreter="$1"
    local venv_path="$2"

    pv_sep
    pv_msg "Creating venv at: $venv_path"
    pv_msg "Using interpreter: $interpreter ($($interpreter --version 2>&1))"

    if ! "$interpreter" -m venv "$venv_path"; then
        pv_err "venv creation failed."
        return 1
    fi

    # Upgrade pip silently
    pv_msg "Upgrading pip..."
    "$venv_path/bin/python" -m pip install --upgrade pip --quiet

    pv_ok "Venv created successfully."
}

# ── requirements install ──────────────────────────────────────────────────────
pv_install_requirements() {
    local venv_path="$1"
    local req_file="$2"

    pv_sep
    pv_msg "Installing requirements from: $req_file"

    if ! "$venv_path/bin/pip" install -r "$req_file"; then
        pv_err "Requirements install failed."
        return 1
    fi

    pv_ok "Requirements installed."
}

# ── activation hint ───────────────────────────────────────────────────────────
pv_print_activate() {
    local venv_path="$1"
    pv_sep
    pv_ok "Done. To activate your venv, run:"
    echo ""
    echo "    source ${venv_path}/bin/activate"
    echo ""
}