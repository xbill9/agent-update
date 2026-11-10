---
title: "Coding Agent Updater: The Tool You Didn't Know You Needed"
published: false
description: "Claude Code, Codex and Antigravity each ship on their own channel and on their own schedule. A small set of Bash scripts brings all of them to the latest release with one command, reports versions without touching anything, and keeps going when one installer fails."
tags: bash, linux, ai, productivity
cover_image: https://raw.githubusercontent.com/xbill9/agent-update/main/articles/coding-agent-updater/devto-cover.d327219c.jpg
---

This article provides a step by step guide to keeping every coding agent on a Linux machine current with one command. A set of Bash scripts updates Claude Code, the OpenAI Codex CLI and the three Antigravity tools, and reports what is installed without changing anything.

https://github.com/xbill9/agent-update

**One command, `update-agents`, updates Claude Code, Codex and Antigravity's CLI, hub and IDE. `--check` reports the installed versions and changes nothing. A failing installer for one agent leaves the others to finish, and the exit status names the one that failed.**

---

#### What is this project trying to Do?

A developer machine in 2026 runs several coding agents. Each one has its own installer, its own update command and its own release cadence. Claude Code and Codex update from a vendor `install.sh`. Antigravity's CLI has `agy update`, while its hub and IDE ship as tarballs that cannot update themselves when installed that way.

The goal: one command that brings all of them to the latest release, one flag that shows where each one stands, and the same behaviour on every machine.

---

#### At This Point You Should Have…

- A Linux machine with `bash`, `curl`, `tar`, `sha256sum` and `python3`
- Any of Claude Code, Codex or Antigravity installed, or none of them
- Optionally `shellcheck`, which `./test` uses to lint the scripts
- A clone: `git clone https://github.com/xbill9/agent-update`

---

#### Step 1 — Install the Scripts

The `Makefile` tests the scripts, then copies them into `~/bin`:

```bash
cd agent-update
make install
```

`make install` runs `./test` first: `bash -n` on every script, `shellcheck` at warning level, and `--help` on each one.

```text
test: ok
```

`make install BINDIR=/usr/local/bin` puts them somewhere else, and `make uninstall` removes them.

---

#### Step 2 — See Where Every Agent Stands

`--check` reports installed versions and changes nothing. It is the first thing to run on a machine:

```bash
update-agents --check
```

```text
==> claude-update
[claude] installed: 2.1.322 (Claude Code)

==> codex-update
[codex] installed: codex-cli 0.166.0

==> agy-update
[agy] installed 1.5.4 (run without --check to update)
[hub] installed 2.29.0, latest 2.31.0
[ide] up to date (2.6.0)
```

For the hub and the IDE, `--check` also reads the release channel, so it shows the version an update would install. On this machine the hub is two minor releases behind and the IDE is current.

🔎 **Tip: `make check` runs the same thing** from the repository, so the versions are one command away before and after a change.

---

#### Step 3 — Update Everything

```bash
update-agents
```

It runs `claude-update`, `codex-update` and `agy-update` in that order. Names pick a subset:

```bash
update-agents claude codex      # just these two
agy-update --check hub ide      # one tool, two of its parts
```

Each per-agent script also runs on its own. A running agent keeps its old binary until it restarts; the new version starts with the next session.

---

#### Step 4 — Claude Code and Codex: The Vendor Installer, Unattended

Both scripts call the vendor's own installer, which installs the agent when it is missing and updates it otherwise:

```bash
curl -fsSL https://claude.ai/install.sh | bash
curl -fsSL https://chatgpt.com/codex/install.sh | CODEX_NON_INTERACTIVE=1 sh
```

`CODEX_NON_INTERACTIVE=1` makes the Codex installer run without prompts, so it works from cron or from another script. `set -o pipefail` makes a failed download fail the update, along with a failed install. Each script prints the version before and after the update.

---

#### Step 5 — Antigravity: Three Tools, Three Channels

`agy-update` handles three targets, each from a different source:

| Target | What | Installed at | Update source |
| :--- | :--- | :--- | :--- |
| `agy` | CLI | `~/.local/bin/agy` | `agy update` |
| `hub` | Antigravity | `~/Antigravity-x64` | hub updater channel, tarball |
| `ide` | Antigravity IDE | `~/Antigravity IDE` | IDE updater API, sha256-checked |

The hub and IDE tarball installs refuse to update themselves with `APPIMAGE env is not defined`, so the script does the whole update:

1. Read the channel for the latest version and the download URL.
2. Read the installed version: `ideVersion` in the IDE's `product.json`, and for the hub, the `version` in the `package.json` packed inside `resources/app.asar`.
3. Compare with `sort -V`; stop if the installed copy is current.
4. Download to a `.part` file and rename it when complete.
5. Verify: the IDE tarball against the `sha256hash` its API publishes, the hub tarball with a full `tar -tzf` listing, since its channel publishes no hash.
6. Extract to a staging directory, then swap it into place.

The swap keeps the previous copy as `<dir>.prev`. When the extraction fails, the installed copy stays untouched; when the final move fails, the previous copy goes back.

🔎 **Tip: a hub or IDE that is not installed is reported and left alone.** `--force` installs it, or reinstalls one that is already current:

```bash
agy-update --force ide
```

---

#### Step 6 — Keep Going Past a Failure

`update-agents` runs without `set -e`. A failing child is recorded and the loop moves on, so a broken Codex installer leaves Claude Code and Antigravity to update. At the end it lists what failed on stderr and exits 1:

```text
update-agents: failed: codex
```

Every script follows the same exit contract: 0 on success, 1 if an update failed, 2 on a bad argument.

```bash
update-agents --bogus
```

```text
unknown argument: --bogus
```

That run exits 2. A typo in a cron line stops at the argument parser before any installer runs.

---

#### Step 7 — The Help Is the Header

Each script's header comment is its documentation, and `--help` prints it: usage, options, environment and exit status.

```bash
update-agents --help
```

```text
update-agents — update every coding agent on this machine.

Runs each <agent>-update script that sits next to this one, in order, and
keeps going when one fails, so a broken installer for one agent does not
block the others.

Usage: update-agents [--check] [agent ...]   (default: all agents)
  --check   report installed versions only; passed through to each script
  agent     claude | codex | agy
```

One `sed` line in each script does it, so the help and the code sit in the same file and change in the same commit.

---

#### Step 8 — Adding Another Agent

A new agent is three changes:

- `bin/<agent>-update`, with `--check`, `--help`, and exit 2 on an unknown argument
- its name in `AGENTS` in `bin/update-agents`
- a row in the README table

The repository ships a Claude Code skill, `/add-agent`, that makes all three, and a hook that runs `shellcheck` on every edit to a script.

🔎 **Tip: the umbrella is named `update-agents`, with the verb first.** A machine that runs every `*-update` script in `~/bin` from a scheduled job would otherwise run each agent's update twice: once through the umbrella and once directly.

---

#### Compare and Contrast

| | By hand | `update-agents` |
| :--- | :--- | :--- |
| Commands per machine | one per tool, each different | 🥇 one |
| See versions without changing anything | run each `--version`, check each channel | 🟢 `--check`, latest included for hub and IDE |
| Hub and IDE tarball installs | download, verify, extract, move by hand | 🟢 automatic, previous copy kept |
| IDE download verified | only if you compare the hash | 🟢 sha256 from the vendor's API |
| One installer fails | the rest wait for you | 🟢 the rest finish; exit 1 names it |
| Unattended | Codex prompts | 🟢 `CODEX_NON_INTERACTIVE=1` |

---

#### So, Which One?

For a machine with more than one coding agent, `update-agents`. Run `update-agents --check` to see where each one stands, then `update-agents` to bring them current. For a single agent, its own script does the same with the same flags.

---

#### Summary

The goal of this project was to keep every coding agent on a Linux machine current with one command. The key to the solution was one script per agent with the same flags and exit codes, and an umbrella that runs them all and keeps going past a failure. The results were:

- 🟢 `update-agents` updates Claude Code, Codex and Antigravity's CLI, hub and IDE.
- 🟢 `--check` reports installed versions, and the latest available for the hub and IDE, without changing anything.
- 🟢 Hub and IDE tarballs are verified and swapped in place, with the previous copy kept as `<dir>.prev`.
- 🟢 A failed installer is listed and the others finish; exit status 1 for a failure, 2 for a bad argument.
- ⚠️ The hub channel publishes no hash, so its tarball is checked for structure only.
- ⚠️ Linux x64 only; macOS and Windows are not covered.

Scope: one Linux x64 machine, scripts at commit `a0f675b`, with Claude Code 2.1.322, codex-cli 0.166.0, agy 1.5.4, hub 2.29.0 and IDE 2.6.0 installed as reported by `--check` on 2026-11-10. The output above comes from `./test`, `--check`, `--help` and a bad-argument run; a full update was not run for this article. Parts of the writing were done with AI assistance (Claude).

The strategy for keeping coding agents current was validated with an incremental step by step approach.

---

#### References

- Repository: https://github.com/xbill9/agent-update
- Claude Code setup: https://docs.anthropic.com/en/docs/claude-code/setup
- OpenAI Codex CLI: https://github.com/openai/codex
- Google Antigravity: https://antigravity.google
