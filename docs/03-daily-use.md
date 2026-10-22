# 03 Daily use

The setup is a one-off. This page is the habit that makes it pay off. It takes a
few minutes a day at most, and most of it is Claude's job.

## The loop

1. **Start Claude Code inside the project folder.** Not in your home folder, not in
   the vault. The hook looks at where you started and picks the matching note.
   Start somewhere else and Claude gets a short list of your projects instead of
   one note.
2. **Work as normal.** You do not have to mention the vault. Claude has the note.
3. **Before you close, check the note.** Claude is told to append a dated line
   under `## Decisions` when it makes or learns a decision, and to update
   `## Current state` and `## Open threads` when they change. Open the note in
   Obsidian and read it. Two minutes of reading is what keeps the vault honest.
4. **Let Obsidian sync.** Leave Obsidian open (it can sit in the tray). The Git
   plugin commits and pushes every ten minutes.

## What goes in a project note

| Section | Put here | Keep it |
|---------|----------|---------|
| What it is | One or two sentences | Stable |
| Current state | Where things stand today | Rewritten when reality changes |
| Open threads | Unfinished work and open questions, as checkboxes | Ticked off or deleted |
| Decisions | Dated bullets: what was decided and why | Appended, never rewritten |

The **why** is the valuable part. "Used SQLite" is worth little. "Used SQLite
because the app runs on one machine and a server would add a failure mode"
stops someone relitigating it in a month.

## Where does a new note go?

Ask in this order and take the first yes.

1. Is it about one project? Put it in that project's note.
2. Is it a lesson that will apply to future projects too? Make a note in
   `30-Knowledge`, one idea per note, from `_templates/knowledge.md`.
3. Did it decide something across several projects, or about how you work? Make a
   dated note in `40-Sessions`.
4. Not sure? Drop it in `00-Inbox` with the date and sort it later.

`30-Knowledge` should fill slowly. A lesson earns its place there by proving useful
twice, first in a project note and then again somewhere else. Do not fill it by
summarizing your projects. Unchecked content there is worse than an empty folder.

## Adding a new project

1. In Obsidian, right-click `10-Projects` and choose New note.
2. Name it exactly after the project folder.
3. Press Alt+T and choose `project`. The template fills in the date and `repo`.
4. Check `repo` and `source_paths`, then write the two sentences under What it is.

That is all. The next session started in that folder gets the note.

## The weekly report

Each Monday a file called `drift-report-<date>.md` appears in `00-Inbox`. Open the
newest one. It lists notes that look **stale** (the project changed since you last
confirmed the note), **broken** (the project folder moved or a listed file is gone),
**malformed** (the frontmatter is wrong) and **untracked** (a project folder with
no note).

Those are leads, not verdicts. To work through them, start Claude Code in the vault
folder and say:

```
Run the pai-drift-check skill.
```

It reads each flagged note, compares it with the real project, fixes only what is
safe (refreshing `last_verified` on notes that are still accurate), and lists
everything that needs your decision. It will not rewrite your notes behind your back.

## Five rules of thumb

1. **A note is a lead, not a fact.** When a note and the code disagree, the code
   is right and the note is out of date.
2. **One fact, one home.** Write each thing in exactly one place and link to it. Two
   copies drift apart, then neither can be trusted.
3. **Short beats complete.** An accurate three-line note beats a stale page.
4. **Date your decisions.** An undated decision cannot be judged later.
5. **Nothing is lost by deleting.** The notes are in git. Anything you remove can be
   brought back.

Your `Home` note in Obsidian shows all of this at a glance; see
[07 Working in Obsidian](07-working-in-obsidian.md).

## Next

[04 How it works](04-how-it-works.md)
