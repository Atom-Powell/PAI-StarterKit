---
type: meta
updated: {{TODAY}}
---

# Stack

Your tools, platforms, and environment. Claude reads this to avoid suggesting
things you do not run.

## Fill this in

Operating system, shells, editors, languages, cloud platforms, anything you use
daily.

## What this vault itself depends on

Do not delete this section. It is the vault's own dependency list.

- **Obsidian**, with three community plugins: `obsidian-git`, `dataview`,
  `templater-obsidian`. Install them from the community store; the kit ships the
  configuration but not the plugin code.
- **Git**, with a remote you can push to.
- **PowerShell**. The scripts are PowerShell and the scheduler is Windows Task
  Scheduler. This vault is Windows-only.
- **Claude Code**, for the SessionStart hook and the `pai-drift-check` skill.

## Obsidian Git is the sync engine

This is the single most load-bearing fact about how the vault stays alive, and it
is the one people miss.

Nothing in this vault syncs itself. **Obsidian Git does**, on a timer. It
auto-commits every 10 minutes, pulls on boot, and pulls before it pushes. That is
why a note Claude edits from a terminal session, with Obsidian merely open in the
background, ends up on your remote without anyone typing `git push`.

Two consequences follow, and both bite if you do not know this:

1. **If Obsidian is not running, the vault does not sync.** It still works, it
   still gets read, it just quietly stops reaching your other machines.
2. **The 10-minute auto-commit sweeps whatever is staged.** This is exactly why
   `drift-scan.ps1` uses `git commit --only <path>` rather than a bare commit. A
   bare commit races the auto-commit and lands unrelated work on your branch under
   the scanner's identity. If you write your own scripts that commit to this
   vault, scope their commits the same way.
