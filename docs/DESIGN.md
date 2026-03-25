# Design notes

Waqqas Toolset is intentionally not a clone of `htb-cli`.

## Split of responsibilities

- `htb-cli` is a strong fit for platform and API actions:
  - listing machines and challenges
  - downloads
  - platform metadata
  - auth and token-aware features

- Waqqas Toolset focuses on:
  - local environment setup
  - repeatable project scaffolding
  - notes, grep, and artifact helpers
  - standardized recon wrappers
  - triage helpers for archives, headers, JWTs, hashes, and DNS

## Command naming

- `w*` commands are "Waqqas workflow" commands.
- Other commands are short task names.

## Install model

- Source repo is copied under `~/.waqqas-toolset`
- Executables are installed into `~/.local/bin`
- Commands locate their library from either the repo root or installed path
