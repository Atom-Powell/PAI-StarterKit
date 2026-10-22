# 01 Prerequisites

Install these before you run anything. For each one there is a check command. Open
**PowerShell** (press the Windows key, type `PowerShell`, press Enter) and run it.
If it prints a version number, you have it.

| Tool | Needed for | Check | Get it |
|------|-----------|-------|--------|
| Claude Code | the whole point | `claude --version` | https://claude.com/claude-code |
| Git | versioning and syncing your notes | `git --version` | https://git-scm.com/download/win |
| PowerShell 7 | running the setup script | `pwsh --version` | https://aka.ms/powershell |
| Obsidian | browsing and editing the notes | open the app | https://obsidian.md |
| Node.js | only the optional prose lint | `node --version` | https://nodejs.org |
| A GitHub account | a home for your notes and the weekly scan | log in on github.com | https://github.com |

Windows ships with an older "Windows PowerShell" (version 5.1). The setup script
runs under either one, but PowerShell 7 is the one this guide uses, and the
commands below say `pwsh`. If `pwsh` is not found after installing, close and
reopen the terminal.

## Choose a workspace folder

Pick the folder where your code projects live, or will live. This guide uses
`C:\GitRepos`. If you have no such folder, make one:

```powershell
New-Item -ItemType Directory C:\GitRepos
```

Your vault will sit inside it, next to your projects. The kit uses this folder to
spot projects that have no note yet.

**Do not put it in OneDrive, Dropbox or any synced folder.** Two sync systems
fighting over a git repository corrupts it. `C:\GitRepos` is safe.

## Tell git who you are

Skip this if you have done it before. Run these two lines with your own details:

```powershell
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

If you would rather not publish your email in commits, GitHub gives every account
a private address of the form `<id>+<username>@users.noreply.github.com`. Find it
in GitHub under Settings, Emails.

## Create an empty GitHub repository for your vault

1. On github.com choose New repository.
2. Name it something like `MyVault`.
3. Choose **Private**. Your notes will hold project details you may not want public.
4. Do not add a README or any other file.

Keep the page open. You will need its URL in the next guide.

## Check

You are ready when `claude --version`, `git --version` and `pwsh --version` all
print a version number and you have an empty private GitHub repository waiting.

## Next

[02 Your first hour](02-first-hour.md)
