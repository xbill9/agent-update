---
name: deploy
description: Publish bin/* to the stage bucket and ~/bin, then confirm the bucket copies match the repo.
disable-model-invocation: true
---

Deploy the scripts in this repo. `$ARGUMENTS` may be `--local` (copy to ~/bin only, skip the bucket).

1. `git status --short`. If there are uncommitted changes to `bin/`, say so and ask whether to commit them first. Deploying uncommitted work leaves the bucket ahead of GitHub.
2. `./deploy --dry-run $ARGUMENTS` and show the copies it lists.
3. `./deploy $ARGUMENTS`. It runs `./test` first and stops if that fails. Report the failure and do not work around it.
4. Verify every file, unless `--local` was given:
   ```
   bucket=$(sed -n 's/^BUCKET="\${BUCKET:-\(.*\)}"$/\1/p' deploy)
   for f in bin/*; do gcloud storage cat "$bucket/${f##*/}" | cmp -s - "$f" && echo "ok   ${f##*/}" || echo "DIFF ${f##*/}"; done
   for f in bin/*; do cmp -s "$f" ~/bin/"${f##*/}" && echo "ok   ~/bin/${f##*/}" || echo "DIFF ~/bin/${f##*/}"; done
   ```
5. Report the ok/DIFF lines as printed. Any DIFF means the deploy failed for that file.
