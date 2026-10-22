---
type: knowledge
last_verified: 2026-10-21
source_paths: []
tags: [knowledge, git]
---

<!--
EXAMPLE ONLY. A filled-in knowledge note. Notice that it states one idea in the
first paragraph and came from a real project first, before being promoted here.
-->

# Never put a live git repository in a synced folder

A git repository inside OneDrive, Dropbox or any similar sync folder will
eventually be corrupted, because two programs are trying to manage the same files.

## Detail

Git keeps many small files inside a hidden `.git` folder and relies on them being
updated together. A sync tool uploads and downloads files one at a time, on its own
schedule, and may restore an older copy of one of them. The result is a repository
with missing objects or a confused index, often discovered days later.

## Why it matters / how to apply

Keep projects in a plain local folder such as `C:\GitRepos`. Use GitHub, not a sync
tool, as the way to copy a project between machines. If a project is already in a
synced folder, move it out and re-clone it.

## Links

- Came from: [[RecipeBox]] (first hit when setting up a second laptop)
- Related: [[Back-Up-With-Push-Not-With-Sync]]
