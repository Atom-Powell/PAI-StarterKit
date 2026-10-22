# 04 How it works

You do not need this page to use the kit. Read it when you want to understand what
is happening, or before you change something.

## The big picture

```
   your projects              your vault                      Claude Code
   C:\GitRepos\MyApp  <---  10-Projects\MyApp.md  --->  session starts in MyApp
                                  ^   |                  and is handed that note
                                  |   v
   weekly scan  --- compares notes to projects --->  00-Inbox\drift-report-DATE.md
                                                             |
                                          you ask Claude to run pai-drift-check
```

## Part 1: the vault

A folder of markdown files with this layout:

| Folder | Holds |
|--------|-------|
| `00-Inbox` | Things with no home yet, and the weekly reports |
| `10-Projects` | One note per project |
| `20-Areas` | Ongoing lanes of work that are not single projects (empty at first on purpose) |
| `30-Knowledge` | Lessons that apply across projects, one idea per note |
| `40-Sessions` | Dated records of decisions that span projects |
| `50-Meta` | You: About-Me, Preferences, Stack, plus the scripts |
| `90-Archive` | Retired notes. Move rather than delete |
| `_templates` | Blank notes to copy from |

`PAI.md` is the map. `CLAUDE.md` is the rulebook Claude follows when it works inside
the vault. Both are plain text you can edit.

Each project note starts with **frontmatter**, a small block between `---` lines.
Four fields do the real work:

- `repo` is the path of the project folder. The startup hook matches on this.
- `status` is `active`, `paused` or `archived`.
- `last_verified` is the last date you confirmed the note is true.
- `source_paths` lists files that should exist in the project. If one vanishes,
  the note is flagged.

## Part 2: the startup hook

Claude Code can run a small script at the start of each session. This kit's script
is `50-Meta/scripts/session-context.ps1`. It:

1. reads the folder the session started in
2. finds the project note whose `repo` is the closest enclosing match (so a session
   in `C:\GitRepos\MyApp\src` still finds `MyApp.md`)
3. hands that note to Claude, together with an instruction to record decisions

If the folder is inside your workspace but matches no note, Claude gets a short list
of known projects. Outside the workspace the script says nothing at all.

The script never blocks a session. If it breaks, it emits a one-line notice rather
than failing silently, because silence looks identical to "no project matched".

Where it is wired in: `~/.claude/settings.json`, the file you edited in setup.
Changes to that file apply to **new** sessions only.

## Part 3: the weekly check

Two pieces that deliberately do different jobs.

**The scanner** (`drift-scan.ps1`) is a plain script. It is run by Task Scheduler,
uses no AI and needs no login. It checks that each note's project exists, that its
`source_paths` exist, and whether the project has had commits since `last_verified`.
It also finds project folders with no note. It writes a report and pushes it. It
never edits a note.

**The skill** (`pai-drift-check`) is a set of instructions for Claude. You run it
when you choose. It reads what the scanner flagged, judges whether each flag is a
real problem, and fixes what is safe.

### Why they are split

Spotting a possible problem is mechanical, so it is safe to automate. Deciding what
is true, and changing your record of it, takes judgment. If a scheduled job
rewrote your notes, you would eventually have a vault that was confidently wrong
and nobody had checked. So the machine detects and a person reconciles.

## Part 4: Obsidian Git is the sync engine

Nothing else pushes your notes to GitHub. The Obsidian Git plugin commits every ten
minutes and pushes. That is why a note Claude edits from a terminal, with Obsidian
merely open in the background, ends up on GitHub.

Two consequences:

- If Obsidian is not running, notes do not sync. They still work locally.
- The plugin commits whatever has changed. The scanner therefore commits only its
  own report file, so it never sweeps your unrelated edits into a commit.

## What the kit does not do

- It does not read your projects' code or build a summary of them. You and Claude
  write the notes.
- It does not change your Claude settings for you. It prints what to add.
- It does not support Mac or Linux.
- It does not make Claude obey. Notes and rules are context, not guarantees. A
  habit of reading the notes after a session is the safety net.

## Next

[05 Make it yours](05-make-it-yours.md)
