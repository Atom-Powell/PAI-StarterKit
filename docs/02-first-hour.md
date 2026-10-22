# 02 Your first hour

Follow these in order. After each step there is a **You should see** line. If you
do not, stop and check [Troubleshooting](troubleshooting.md) before carrying on.
Carrying on past a step that did not work is how a setup ends up half working.

Commands below assume the workspace `C:\GitRepos` and a vault called `MyVault`.
Change those to taste, but keep them consistent.

## Step 1. Get the kit

```powershell
cd C:\GitRepos
git clone https://github.com/Atom-Powell/PAI-StarterKit.git
cd PAI-StarterKit
```

**You should see:** a new `PAI-StarterKit` folder, and your prompt now ends in
`PAI-StarterKit`.

## Step 2. Build your vault

```powershell
pwsh -File .\kit\bootstrap.ps1 -VaultPath C:\GitRepos\MyVault -WorkspaceRoot C:\GitRepos
```

This creates `C:\GitRepos\MyVault`, fills it with the starter folders and notes,
starts a git history in it, installs the `pai-drift-check` skill into
`~/.claude/skills/`, and prints some instructions. It does **not** change your
Claude settings. That is deliberate and is your next step.

**You should see:** lines such as `Copied skeleton`, `Substituted tokens in 11
file(s)`, `Initialized git repo on branch 'main' and committed`, and finally
`Done.` in green. You should see no yellow `WARNING` lines.

If it says `already exists`, you have run it before. Pick a new `-VaultPath` or
move the old folder aside. It will not overwrite a vault.

## Step 3. Wire in the startup hook

The script printed a block of JSON that starts with `"hooks": {`. This tells
Claude Code to run your vault's script at the start of every session.

1. Open `C:\Users\<you>\.claude\settings.json` in Notepad. If the file does not
   exist, create it containing just `{ }`.
2. Paste the block inside the outer braces. If the file already has other
   settings, add a comma after the last one first. Example of a finished file:

   ```json
   {
     "hooks": {
       "SessionStart": [ ... the part the script printed ... ]
     }
   }
   ```

3. If your file already had a `"hooks"` section, do not add a second one. Put the
   new `"SessionStart"` entry inside the existing section.
4. Save. Check the JSON is valid by running:

   ```powershell
   Get-Content $HOME\.claude\settings.json -Raw | ConvertFrom-Json | Out-Null; "valid"
   ```

**You should see:** `valid`. An error means a missing or extra comma or brace.

The optional prose lint block is explained in [05 Make it yours](05-make-it-yours.md).
Skip it for now.

## Step 4. Give the vault a home on GitHub

Use the URL of the empty private repository from the prerequisites:

```powershell
git -C C:\GitRepos\MyVault remote add origin https://github.com/<you>/MyVault.git
git -C C:\GitRepos\MyVault push -u origin main
```

**You should see:** git listing objects and ending with
`branch 'main' set up to track 'origin/main'`. Refresh the GitHub page and your
notes are there. If git asks you to sign in, do so.

## Step 5. Open the vault in Obsidian

1. Open Obsidian, choose **Open folder as vault**, and pick `C:\GitRepos\MyVault`.
2. Obsidian will say community plugins are off. Choose to turn them on
   (**Settings, Community plugins, Turn on community plugins**).
3. Under **Browse**, install and enable these three:
   - **Git** (by Vinzent)
   - **Dataview**
   - **Templater**

The kit ships their settings but not their code, so you always get current
versions. The Git plugin is what keeps your notes backed up: it commits every ten
minutes and pushes to GitHub. **If Obsidian is closed, that does not happen.**

The `Home` note is your dashboard and needs Dataview. How to use it is in
[07 Working in Obsidian](07-working-in-obsidian.md).

**You should see:** `Home` and `PAI` in the file list, and the three plugins in the enabled
list. If the Git plugin reports an error, check that Step 4 worked.

## Step 6. Restart Claude Code and prove the hook works

Close any open Claude Code sessions. Hooks are read when a session starts.

Now make a first project note. In Obsidian, right-click the `10-Projects` folder,
choose **New note**, and name it exactly like one of your real project folders (for
example `MyApp`). Press **Alt+T**, and choose `project`. The template fills in the
top section (the "frontmatter" between the `---` lines) for you:

```yaml
---
type: project
repo: C:\GitRepos\MyApp
status: active
last_verified: 2026-10-21
source_paths: [README.md]
tags: [project]
---
```

Check it, because the hook depends on it:

- `repo` must be the real, full path to the project folder.
- `last_verified` must be today's date as `YYYY-MM-DD`.
- `source_paths` lists files that should exist in that project. If you are not
  sure, use `[]`.

Write two sentences under **What it is** and save. Then start Claude Code inside
that project:

```powershell
cd C:\GitRepos\MyApp
claude
```

Ask: `What do you know about this project from the vault?`

**You should see:** Claude describing what you wrote in the note. That is the
whole trick working. If it knows nothing, see "Claude does not seem to know about
my vault" in [Troubleshooting](troubleshooting.md).

## Step 7. Fill in About-Me

Open `50-Meta/About-Me.md` and write a few honest paragraphs about who you are,
how you work and what you want pushed back on. Do the same, more briefly, for
`Preferences.md` and `Stack.md`. These are the notes that make Claude a better
fit for you across every project, and they are the ones you will keep improving.

## Step 8. Schedule the weekly check (optional, recommended)

```powershell
pwsh -File C:\GitRepos\MyVault\50-Meta\scripts\register-drift-task.ps1
```

This creates a Windows Task Scheduler task named `PAI-DriftScan`. Every Monday at
09:00 it checks your notes against your projects and pushes a report to GitHub.
If your computer is off at that time it runs at the next opportunity.

Registering a task is not the same as the task working, so prove it. Run it once
by hand and then look at the result:

```powershell
schtasks /Run /TN PAI-DriftScan
Start-Sleep 20
schtasks /Query /TN PAI-DriftScan /FO LIST /V | Select-String "Last Run Time","Last Result"
```

**You should see:** a `Last Run Time` that is a real recent date, and
`Last Result: 0`. A `Last Result` of `267011` or a date in 1999 means it has never
run. Then look in `00-Inbox` for a file named `drift-report-<today>.md`.

## You are done

You now have a vault, a hook that proves itself, and a weekly check. Next, learn the
habits that make it worth having: [03 Daily use](03-daily-use.md).
