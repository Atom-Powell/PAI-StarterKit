# 07 Working in Obsidian

Obsidian is where you live in this system. Claude works in the terminal; you read,
edit and steer in Obsidian. This page covers what the starter vault configures for
you and how to use it day to day. Do [02 Your first hour](02-first-hour.md) first.

## What Obsidian is doing here

It is only a nice window onto a folder of text files. There is no hidden database.
Close Obsidian and the notes are still ordinary `.md` files that Claude and git read
directly. That is the point: nothing important is locked inside the app.

Obsidian does three jobs for this kit:

1. **Reading and editing** notes with links, search and a graph.
2. **Dashboards**, using the Dataview plugin to turn note metadata into tables.
3. **Backup**, using the Git plugin to commit and push every ten minutes.

## The three plugins

| Plugin | Does | If it is missing |
|--------|------|------------------|
| Git | Commits and pushes your notes | No backup, no sync to GitHub |
| Dataview | Powers the tables on `Home` | `Home` shows raw code instead of tables |
| Templater | Fills in new notes from templates | Templates show `<% ... %>` unfilled |

Install each under **Settings, Community plugins, Browse**. Community plugins are
off by default; the first time, turn them on. The vault ships their settings so they
work straight away.

## Start from Home

Open `Home` (it is bookmarked in the left sidebar). It shows:

- **Is the vault accurate?** The newest drift report. This is the only real answer
  to "can I trust my notes?" See the warning below.
- **Active projects**, **open threads** (every unticked checkbox from every project
  note), the **Inbox** and **recently changed** projects.

> **A dashboard is not a check.** Dataview reads the labels in your notes. It
> cannot look at your project and see that the code has moved on. A table that
> says "confirmed 3 days ago" is telling you what a note claims, not whether it is
> true. Trust the drift report, not the tables.

## Making notes

The templates fill in the title, today's date and the right frontmatter for you.

1. In the left file list, **right-click the folder** the note belongs in and choose
   **New note**. Type the name.
2. Press **Alt+T** (or the command palette, Ctrl+P, then "Templater: Open insert
   template modal") and choose a template.

| Making | In folder | Template | Naming |
|--------|-----------|----------|--------|
| A project | `10-Projects` | `project` | Exactly the project's folder name |
| A lasting lesson | `30-Knowledge` | `knowledge` | A short statement of the idea |
| A cross-project decision | `40-Sessions` | `session` | `2026-10-21 topic` |
| An ongoing lane of work | `20-Areas` | `area` | The lane's name |

For a project note, the template sets `repo:` to your workspace folder plus the note
name. **Check that path** matches the real project folder, and edit `source_paths`.

Press **Ctrl+N** for a quick note when you do not yet know where it goes. New notes
land in `00-Inbox`, which is where unsorted things belong.

## Links are the point

Type `[[` and start typing a note name to link to it. Links are how notes find each
other: the **Backlinks** pane (right sidebar) lists every note that points at the one
you are reading, which is how a lesson in `30-Knowledge` shows you every project that
used it.

- Link a project note to the knowledge notes it relied on.
- Link a knowledge note back to the project where you learned it.
- Link to a missing note on purpose and it shows greyed out. That is a to-do for
  later, not an error.

## Finding things

- **Ctrl+O**: quick switcher. Type part of a note name.
- **Ctrl+Shift+F**: search every note's text.
- **Tags and properties** panes list notes by `type`, `status` and tags.

## The graph

Open it from the left ribbon. The starter colours notes by folder so structure is
visible at a glance:

| Colour | Folder |
|--------|--------|
| Blue | `10-Projects` |
| Purple | `20-Areas` |
| Green | `30-Knowledge` |
| Orange | `40-Sessions` |
| Red | `00-Inbox` |
| Grey | `50-Meta` |

Templates, the archive and drift reports are hidden. A healthy graph is mostly
blue and green with links between them. Red clusters mean filing is overdue. Many
isolated nodes mean you are not linking.

## Properties

The block at the top of a note is shown as a tidy form (Obsidian calls these
properties). Click a value to edit it. Behind the scenes it is the YAML text the
scripts read, so the field names matter: do not rename `repo`, `status`,
`last_verified` or `source_paths`.

## Do and do not

**Do**

- Keep Obsidian open while you work. The Git plugin only runs while it is open.
- Edit notes freely. They are plain files, and git remembers every version.
- Rename and move notes inside Obsidian, not in File Explorer. Obsidian updates
  every link that pointed at them.

**Do not**

- Do not store the vault in OneDrive, Dropbox or another sync folder.
- Do not delete `.obsidian`. It holds your plugin and layout settings.
- Do not put your `repo:` path in quotes or make it relative. The scripts expect a
  full path as written.
- Do not install a plugin that edits notes automatically until you know what it
  does. Claude and the scripts assume the files change only when you or they change
  them.

## What is where in `.obsidian`

You rarely need these, but they are plain JSON and you can read them.

| File | Controls |
|------|----------|
| `app.json` | New notes go to `00-Inbox`; wikilinks; properties shown; deletes go to `.trash` |
| `graph.json` | The graph filter and colours |
| `hotkeys.json` | Alt+T opens the template picker |
| `bookmarks.json` | The sidebar shortcuts |
| `community-plugins.json` | Which plugins should be on |
| `plugins/*/data.json` | Settings for Git and Templater |

Your window layout (`workspace.json`) is deliberately not saved to git, so each
machine keeps its own.

## Next

[Troubleshooting](troubleshooting.md) has an Obsidian section if something here does
not behave.
