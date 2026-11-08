# agent-update

Scripts that install or update the coding agents on a Linux machine.

| Script | Updates | How |
|---|---|---|
| `bin/claude-update` | Claude Code CLI | `claude.ai/install.sh` |
| `bin/codex-update` | OpenAI Codex CLI | `chatgpt.com/codex/install.sh`, non-interactive |
| `bin/agy-update` | Antigravity CLI, hub, IDE | `agy update`; hub and IDE from their updater channels, swapped in place (previous copy kept as `<dir>.prev`; IDE tarball sha256-checked) |
| `bin/update-agents` | all of the above | runs each `<agent>-update`, keeps going past a failure, exits non-zero if any failed |

`agy-update` leaves a hub or IDE that is not installed alone and says so;
`--force` installs it, or reinstalls one that is up to date.

Every script takes `--check`, which reports installed versions and changes
nothing, and `--help`, which prints its header: usage, environment, exit
status. Exit status is 0 on success, 1 if an update failed (`update-agents`
lists which), 2 on a bad argument.

```
update-agents --check
update-agents claude codex      # just these two
agy-update --check hub ide
```

## Deploy

`~/bin` is fed from the stage bucket: `update-all` runs `update-update`, which
deletes every `*-update` in `~/bin` and copies them back from the bucket. A
script that exists only in `~/bin` is gone after the next `update-all`, so
deploy writes the bucket first, then `~/bin`.

```
./test                 # bash -n, shellcheck, --help on every script
./deploy --dry-run     # show the copies
./deploy               # bucket + ~/bin
./deploy --local       # ~/bin only
```

The umbrella is named `update-agents` (not `agent-update`) because `update-all`
runs every `*-update` in `~/bin`; an `agent-update` there would update each
agent a second time. For the same reason `update-update` does not fetch it, so
on a new machine copy it with `stbcp update-agents` or `./deploy`.

Overrides: `BUCKET`, `DEST` for `deploy`; `HUB_DIR`, `IDE_DIR` for `agy-update`.
