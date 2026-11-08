---
name: add-agent
description: Add an update script for another coding agent (e.g. gemini, copilot) — creates bin/<agent>-update and wires it into update-agents and the README.
---

Add an updater for the agent named in `$ARGUMENTS`.

1. Find the official install or update method from the agent's own docs, or from an existing `~/bin/<agent>-update` if there is one (read it; the bucket copy may differ, check with `gcloud storage cat`). Do not guess an installer URL. If no source is found, ask.
2. Create `bin/<agent>-update` by copying `bin/codex-update` as the template. Change the header comment, the `log` tag, the `<agent> --version` call and the install command. Keep `--check`, `-h|--help`, exit 2 on unknown args, and the before -> after version line. If the header changes length, fix the `sed -n '2,Np'` range.
3. `chmod +x` it. Add the name to `AGENTS=(...)` in `bin/update-agents` and to the `# agent` line in its header. Add a row to the README table.
4. Verify with `./test` and `bin/<agent>-update --check` only. Do not run a real update unless the user asks.
5. Commit to main and push. Remind the user that it reaches `~/bin` and other machines only after `/deploy`.
