# Contributing

Thanks for contributing to Waqqas Toolset.

## Guidelines

- Keep commands small, readable, and dependency-light.
- Prefer user-space installs.
- Use Bash and `set -euo pipefail` for scripts.
- Add `# WAQQAS_TOOLSET` near the top of command scripts.
- Provide `-h` or `--help` output.
- Avoid duplicating functionality that already belongs in `htb-cli`.

## Local checks

Run these before opening a PR:

```bash
bash scripts/smoke-test.sh
```

## Design preferences

- `w*` commands are for toolset management and note-taking.
- Standalone names are for task tools, for example `htbsave`, `dnspeek`, `scanwrap`.
- Commands should work well on Ubuntu, Kali, and WSL.
