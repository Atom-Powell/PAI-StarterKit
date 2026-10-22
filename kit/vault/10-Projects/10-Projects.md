---
type: index
---

# Projects

One note per active repo under `{{WORKSPACE_ROOT}}`. Each note is the durable
record of that project's state, open threads, and decisions.

## Rules

- Name the note after the repo.
- Required frontmatter: `repo`, `status`, `last_verified`, `source_paths`.
- Create new notes from `_templates/project.md`.
- The `pai-drift-check` skill reconciles these against their real repos.

### All projects

Every project note, grouped by status. This is your inventory.

```dataview
TABLE status, last_verified, repo
FROM "10-Projects"
WHERE type = "project"
SORT status ASC, file.name ASC
```

### Active only

```dataview
TABLE last_verified, repo
FROM "10-Projects"
WHERE type = "project" AND status = "active"
SORT file.name ASC
```

### Needs attention

**Do not read staleness off this page.** Dataview cannot run git, so it cannot
know whether a repo has changed since a note's `last_verified` date. Only the
drift scanner can. The authoritative answer is always the newest report in
[[00-Inbox]].

This warning is here because it was a live bug in the reference implementation.
The query on this page used to compare `last_verified` against a 30-day calendar
window and was captioned "Empty is good," so it reported all clear while several
notes were genuinely stale. It measured the wrong thing and could not fail. A
check that cannot fail is not a check.

The query below is kept only as a weak hygiene signal. It measures **how long
since a human last confirmed the note**, which is a different question from
whether the note is wrong.

```dataview
TABLE status, last_verified, repo
FROM "10-Projects"
WHERE type = "project" AND last_verified < date(today) - dur(30 days)
SORT last_verified ASC
```

### Latest drift reports

Newest first. The top one is the current truth about this vault's accuracy.

```dataview
TABLE date, checked, stale, broken, untracked
FROM "00-Inbox"
WHERE type = "drift-report"
SORT date DESC
LIMIT 5
```
