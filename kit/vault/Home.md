---
type: index
---

# Home

Your dashboard. Open this first in Obsidian. Everything below updates itself, but
read the caveats: a dashboard is a view of your notes, not a check on them.

> [!info] Needs the Dataview plugin
> If you see raw code blocks instead of tables, Dataview is not installed or not
> enabled. Settings, Community plugins, Browse, Dataview, Install, Enable.

## Is the vault accurate? (the one that counts)

The newest drift report is the only honest answer. Dataview cannot run git, so it
cannot know whether a project has moved past its note. Only the weekly scan can.

```dataview
TABLE date, checked, stale, broken, malformed, untracked
FROM "00-Inbox"
WHERE type = "drift-report"
SORT date DESC
LIMIT 1
```

No row here means no scan has run yet. Run `drift-scan.ps1` (see
[[Automation]]) or wait for the Monday task. Open the report, then ask Claude to
run the `pai-drift-check` skill.

## Active projects

```dataview
TABLE status, last_verified AS "Last confirmed", repo
FROM "10-Projects"
WHERE type = "project" AND status = "active"
SORT file.name ASC
```

## Open threads across all projects

Every unticked checkbox from your project notes. Tick it in the project note and it
leaves this list.

```dataview
TASK
FROM "10-Projects"
WHERE !completed
GROUP BY file.link
```

## Unsorted in the Inbox

Things with no home yet. If this list is long, filing is overdue.

```dataview
LIST
FROM "00-Inbox"
WHERE type != "drift-report" AND type != "index"
SORT file.ctime DESC
```

## Recently changed projects

```dataview
TABLE file.mtime AS "Changed"
FROM "10-Projects"
WHERE type = "project"
SORT file.mtime DESC
LIMIT 5
```

## Longest since you last confirmed

A weak hygiene nudge only. It measures how long since a human confirmed the note,
which is not the same as whether the note is wrong.

```dataview
TABLE last_verified AS "Last confirmed", repo
FROM "10-Projects"
WHERE type = "project" AND status = "active"
SORT last_verified ASC
LIMIT 5
```

## Make something new

1. Right-click the target folder in the file list, choose **New note**, and type the
   name. Project notes must be named after the project folder.
2. Press **Alt+T** and pick a template.

| For | Folder | Template |
|-----|--------|----------|
| A project | `10-Projects` | `project` |
| A lasting lesson | `30-Knowledge` | `knowledge` |
| A cross-project decision | `40-Sessions` | `session` (name it `YYYY-MM-DD topic`) |
| An ongoing lane of work | `20-Areas` | `area` |

Unsure where it goes? Press **Ctrl+N** instead. New notes land in `00-Inbox`.

## Go to

[[PAI]] the map, [[About-Me]], [[Preferences]], [[Stack]], [[Automation]],
[[00-Inbox]], [[10-Projects]], [[30-Knowledge]].
