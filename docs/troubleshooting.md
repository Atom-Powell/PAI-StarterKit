# Troubleshooting

Find the symptom, read the cause, apply the fix. Each entry has a way to confirm it
worked. The general habit: when a script prints something that looks fine, still
check the result. Several failures here print success while doing nothing.

## Claude does not seem to know about my vault

Check these in order.

1. **Did you restart Claude Code after editing `settings.json`?** Hook changes only
   apply to new sessions. Close it and start again.
2. **Did you start Claude inside the project folder?** The hook matches the folder
   you started in. Starting in your home folder gets you nothing.
3. **Does the note's `repo:` line exactly match the project path?** It must be the
   full path, for example `C:\GitRepos\MyApp`, not a relative path or a path with a
   typo.
4. **Is `settings.json` valid JSON?** Run:
   ```powershell
   Get-Content $HOME\.claude\settings.json -Raw | ConvertFrom-Json | Out-Null; "valid"
   ```
   A stray comma means Claude Code ignores the whole file.
5. **Does the hook work on its own?** Run it by hand, giving it a folder the way
   Claude Code does:
   ```powershell
   '{"cwd":"C:\\GitRepos\\MyApp","hook_event_name":"SessionStart"}' | powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\GitRepos\MyVault\50-Meta\scripts\session-context.ps1
   ```
   Replace both paths with yours. You should see JSON containing `additionalContext`
   and the text of your note. Nothing at all means no note matched. A one-line
   notice means the script hit an error and is telling you what.

## bootstrap says "already exists"

You have run it before for that path. It refuses to overwrite a vault on purpose.
Choose a different `-VaultPath`, or move the old folder aside.

## bootstrap says "REFUSING TO OVERWRITE THE EXISTING pai-drift-check SKILL"

You already have a vault, and its skill points at it. There is only one skill slot
per machine. Overwriting would repoint your existing vault's check at the new one.
If you really mean to replace the old vault, re-run with `-Force`. If you are only
testing, re-run with `-ClaudeHome C:\some\scratch\folder` to install into an
isolated place.

## I see "Unsubstituted tokens remain"

A `{{LIKE_THIS}}` placeholder survived. The script lists the file and line. Replace
it by hand with the value it should have, and tell the maintainers if it happens on
a clean run.

## The scan says "drift report was written but NOT synced"

The report was created locally but could not be pushed. Almost always the vault has
no remote yet, or you are not signed in to GitHub. Check:

```powershell
git -C C:\GitRepos\MyVault remote -v
git -C C:\GitRepos\MyVault push
```

If `remote -v` prints nothing, do Step 4 of [02 Your first hour](02-first-hour.md).
The scan exits with an error on purpose here. A scan that cannot sync should say so.

## Task Scheduler shows Last Result 267011, or a Last Run Time in 1999

The task is registered but has never run. Registration is not execution. Start it:

```powershell
schtasks /Run /TN PAI-DriftScan
```

Wait twenty seconds and query again. `Last Result` should be `0`. If it is any other
number, run the scanner directly to see its error message:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\GitRepos\MyVault\50-Meta\scripts\drift-scan.ps1
```

## "running scripts is disabled on this system"

PowerShell's execution policy is blocking a script. The kit's own commands already
pass `-ExecutionPolicy Bypass` for the hook and scan. For `bootstrap.ps1` run it as
`pwsh -File ...` as shown, or allow your own scripts for your account:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

## Obsidian's Git plugin shows errors, or notes are not reaching GitHub

- Obsidian must be **open** for the plugin to run.
- Confirm the remote exists and a manual `git push` works (see above).
- Check the plugin is enabled under Settings, Community plugins.
- If a merge conflict is reported, open the vault folder in a terminal, run
  `git status`, and resolve the files it names. This is rare with a single user.

## Obsidian: Home shows code instead of tables

Dataview is not installed or not enabled. Settings, Community plugins, Browse,
Dataview, Install, then Enable. If tables are present but empty, that section has
nothing to show yet (for example no drift report exists until a scan has run).

## Obsidian: template shows `<% ... %>` unfilled

Templater is not installed or enabled, or you copied the template file by hand
instead of inserting it. Use Alt+T on a note that already has its final name.

## Obsidian: a new project note has the wrong repo path

The path is your workspace folder plus the note's name. If the note name is not
exactly the project folder name, edit the `repo:` line.

## The reports list a project as "untracked" that I don't want a note for

Add it to `50-Meta/Skipped-Repos.md` under `## Skipped: not a project` as
`- **FolderName**: reason`.

## A note is flagged "stale" but is still correct

That is normal. Stale only means the project has commits newer than `last_verified`.
If the note is still true, set `last_verified` to today. That is exactly what the
`pai-drift-check` skill does for you.

## The drift scan crashed on a brand-new project

A project folder with no commits yet used to stop the scan. This kit handles it.
If you see a git error mentioning "does not have any commits yet", you may be on an
old copy. Pull the latest kit and copy `drift-scan.ps1` into your vault's
`50-Meta/scripts/`.

## It still isn't working

Gather this and ask for help, or open an issue on the kit's GitHub page:

- the exact text of the error
- the output of `claude --version`, `git --version`, `pwsh --version`
- which step of [02 Your first hour](02-first-hour.md) failed

Do not paste your `settings.json` or notes publicly without reading them first.
