# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Bash scripts that install or update coding agents. `bin/*` is what ships; `deploy` and `test` stay in the repo.

## Where the scripts live

- The stage bucket (`BUCKET` in `deploy`) is the source of truth for `~/bin`. `update-all` runs `update-update`, which deletes every `*-update*` in `~/bin` and re-copies them from the bucket. A change that is only in `~/bin` is lost on the next `update-all`; edit here and deploy.
- `./deploy` writes the shared bucket that every machine pulls from. Ask before running it; `./deploy --dry-run` and `./deploy --local` are safe.
- `update-all` runs every executable `*-update` in `~/bin`. Per-agent scripts are named `<agent>-update`; anything that runs other scripts must not end in `-update` (hence `update-agents`), or `update-all` runs those updates twice.

## Verifying a change

- Run `./test` (bash -n, shellcheck at warning level, `--help` on each script) and the script's `--check`. Never run a script without `--check` to verify it: a real run replaces the installed agent, including the running `claude`. Run a real update only when the user asks.

## Script conventions

- Every `bin/*` script takes `--check` (report installed versions, change nothing) and `-h|--help`, and rejects unknown arguments with exit 2. `set -euo pipefail` except `update-agents`, which must continue past a failing child.
- `--help` prints the header comment with `sed -n '2,Np' "$0"`. When the header gains or loses lines, update `N`.
- A new agent needs: `bin/<agent>-update`, its name in `AGENTS` in `bin/update-agents`, and a row in the README table. `/add-agent` does this.
