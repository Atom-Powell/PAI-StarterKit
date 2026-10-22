# 05 Make it yours

The starter is deliberately generic. These are the safe places to bend it.

## Teach Claude about you (the highest value change)

Three notes in `50-Meta` describe you. Fill them in before anything else.

- **About-Me**: who you are, what you are accountable for, what "done" means to you,
  what you want challenged.
- **Preferences**: how you like work done. The file lists a few example habits to
  keep, edit or delete: brainstorm before building, treat notes as leads not
  facts, and treat a live test as the finish line rather than a passing test.
- **Stack**: your operating system, editors, languages, services. This stops Claude
  suggesting tools you do not run.

Be specific. "I prefer concise answers" does little. "Lead with the answer, then the
reasoning, and ask before making any change that deletes data" does a lot.

## Edit the rulebook

`CLAUDE.md` in the vault root is the contract for how Claude reads and writes the
vault. It is yours to change. Good edits are small and come from something that
went wrong: if Claude kept filing notes in the wrong folder, add a sentence saying
where they go.

Keep one habit: delete rules you no longer follow. A rule nobody enforces teaches
Claude that the rest of the file is negotiable too.

## Add areas when they become obvious

`20-Areas` ships empty. An area is a lane of ongoing responsibility that holds
several projects, for example "Client work", "Home lab" or "Writing". Create one
only when you notice three or more projects sharing a lane. Use
`_templates/area.md`. An area with one project in it is just that project.

## Tell the scanner what to ignore

Open `50-Meta/Skipped-Repos.md`. Folders in your workspace that you do not want
notes for (scratch space, downloaded copies of other people's code) go under the
heading `## Skipped: not a project`, one per line as `- **FolderName**: reason`. The
scanner reads that exact heading and that bullet format, so keep both. Without this,
every such folder is reported as untracked every week.

## Change when the scan runs

The schedule is set when you run `register-drift-task.ps1`. To change it, open Task
Scheduler, find `PAI-DriftScan`, and edit its trigger. Or delete the task
(`schtasks /Delete /TN PAI-DriftScan /F`), edit the day and time in the script, and
register again.

## Turn on the optional prose lint

Some people dislike the recognisable habits of machine-written text: em dashes,
"it's worth noting", "navigating the complexities". The kit includes a small
Node.js script that reports them whenever Claude writes a markdown or text file.
It reports only; it never blocks an edit.

To use it, `bootstrap.ps1` printed an optional `"PostToolUse"` block. Add it inside
your `"hooks"` object in `~/.claude/settings.json`, next to `"SessionStart"`, and
restart Claude Code. The script itself was already copied to
`~/.claude/hooks/lint-ai-tells.mjs`. You can edit its word list.

If you do not want it, delete the "Prose style" section in the vault's `CLAUDE.md`
too, so the rule and the enforcement agree.

## Where things live, so you can find them

| Thing | Location |
|-------|----------|
| Your vault | where you ran bootstrap, for example `C:\GitRepos\MyVault` |
| The startup hook script | `MyVault\50-Meta\scripts\session-context.ps1` |
| The weekly scanner | `MyVault\50-Meta\scripts\drift-scan.ps1` |
| Scanner settings | `MyVault\50-Meta\pai.config.json` |
| The reconcile skill | `~/.claude/skills/pai-drift-check/SKILL.md` |
| Hook wiring | `~/.claude/settings.json` |
| The scheduled task | Task Scheduler, named `PAI-DriftScan` |

## Before you edit a script

Make a git commit first, so you can undo it. If you change a script, run it by
hand and read the output before trusting it to run unattended. The scripts report
failure loudly on purpose; keep that when you change them.

## Next

[06 Growing into it](06-growing-into-it.md)
