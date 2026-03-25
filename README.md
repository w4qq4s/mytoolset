# Waqqas Toolset

A larger, opinionated CLI toolkit for CTF, Hack The Box, lab, and repeatable Linux setup workflows.

This repo is designed to give you a machine that feels like **your** machine quickly:
- a reproducible local toolset
- consistent project scaffolding
- faster notes and artifact management
- small recon and triage helpers
- optional HTB CLI integration without trying to re-implement the whole platform

Installation puts executables into `~/.local/bin` and stores the toolset under `~/.waqqas-toolset`.

## Quick install

```bash
curl -fsSL https://raw.githubusercontent.com/w4qq4s/mytoolset/main/install.sh | bash
```

Then reload your shell:

```bash
source ~/.bashrc 2>/dev/null || true
source ~/.zshrc 2>/dev/null || true
```

Verify:

```bash
wsetup
```

## Safer install

```bash
git clone https://github.com/w4qq4s/mytoolset.git
cd mytoolset
bash install.sh
```

## Philosophy

This repo complements `htb-cli`; it does not try to replace it.

- Use `htb-cli` for platform-aware HTB actions.
- Use Waqqas Toolset for workflow, notes, recon wrappers, archive handling, and local quality-of-life.

## Commands

### Workflow and management
- `wsetup` - show version, install path, repo, dependencies, and current project root
- `wupdate` - update from GitHub and reinstall
- `ctfinit` - create a new project directory with notes, recon, loot, artifacts, and templates
- `boxprep` - shortcut for creating a box-style workspace
- `tmuxbox` - create a tmux session with common windows
- `wnote` - append a timestamped note to the current project
- `wgrep` - search across the current project or your workspace
- `lootindex` - maintain a simple TSV index of creds, hashes, tokens, flags, or other findings

### Recon and triage
- `scanwrap` - opinionated `nmap` wrapper with saved output
- `portpeek` - summarize ports from `nmap -oN`
- `webprobe` - quick HTTP and page fingerprinting
- `dnspeek` - print common DNS records
- `httphead` - fetch response headers and redirects
- `myip` - show local addressing and public IP
- `netcheck` - verify gateway, DNS, basic connectivity, and HTTPS
- `flagscan` - search for common flag patterns
- `extractall` - unpack archives into predictable directories
- `hashid` - quick hash family guesser
- `jwtpeek` - decode JWT header and payload, and show expiry when present

### HTB helper
- `htbsave` - download HTB challenge archives with progress, checksum, and password-aware extraction

## Example usage

### Create a workspace

```bash
ctfinit boardlight --type box --ip 10.10.11.11
cd boardlight
tmuxbox
```

### Save an HTB challenge archive

```bash
htbsave "https://labs.hackthebox.com/api/v4/challenge/download/220?auth_user_id=...&expires=...&signature=..." -o challenge_220.zip
```

Creates:

```text
challenge_220/
├── challenge_220.zip
├── challenge_220.zip.sha256
└── extracted/
```

### Append a note

```bash
wnote "Found password reset endpoint on 8443"
```

### Scan and summarize

```bash
scanwrap 10.10.11.11 --name boardlight --profile quick
portpeek recon/nmap_boardlight_quick.nmap
```

### Quick web check

```bash
webprobe https://example.org
httphead https://example.org
```

## Install layout

- Commands: `~/.local/bin`
- Toolset home: `~/.waqqas-toolset`
- Templates: `~/.waqqas-toolset/templates`
- Library helpers: `~/.waqqas-toolset/lib`

## Installer options

```bash
bash install.sh --help
```

Available flags:
- `--skip-deps` - do not install apt packages
- `--with-htb-cli` - try to install `htb-cli` as `htb`
- `--no-path` - do not modify shell rc files

## Updating

```bash
wupdate
```

## Uninstalling

```bash
bash uninstall.sh
```

## Dependencies

The installer can install these on Debian-based systems:

- `curl`
- `wget`
- `git`
- `jq`
- `tmux`
- `unzip`
- `file`
- `dnsutils`
- `iproute2`
- `openssl`
- `tar`
- `gzip`

Some optional commands can also benefit from:
- `ripgrep`
- `nmap`
- `p7zip-full`
- `unrar`

## Security note

This repo is intended for legitimate labs, training, and CTF workflows. Review scripts before running them on systems you care about. If you do not like `curl | bash`, clone the repo and inspect `install.sh`, `lib/`, and `bin/` first.

## Contributing

PRs are welcome. Start with:
- `CONTRIBUTING.md`
- `docs/COMMANDS.md`
- `docs/DESIGN.md`

## License

MIT

## Author

Built and maintained by **Waqqas**.
