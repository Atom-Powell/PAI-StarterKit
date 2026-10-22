---
type: index
---

# Meta

Who you are and how you want work done, plus the vault's own machinery.

## Who and how

These three ship as empty stubs. **Fill them in.** They do more work per line than
anything else in the vault: Claude reads them to know who it is working for. A
vault with a blank `About-Me` is a filing cabinet, not a context substrate.

- [[About-Me]]
- [[Preferences]]
- [[Stack]]

## How the vault runs itself

- [[Automation]]: what is scheduled, what is a hook, what is only a convention
- [[Memory-Bridge]]: how the vault and `.claude` memory divide ownership
- [[Skipped-Repos]]: repos deliberately given no note, and why
- `pai.config.json`: workspace root, git branch, commit identity for the scripts
- `scripts/`: `session-context.ps1` (SessionStart hook), `drift-scan.ps1`
  (scheduled detection), `register-drift-task.ps1` (one-time setup)
