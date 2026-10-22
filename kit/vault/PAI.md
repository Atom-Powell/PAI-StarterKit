---
type: index
updated: {{TODAY}}
---

# PAI: Personal AI Infrastructure

Start here. This vault is the durable home for pertinent information across all
projects, and the context substrate Claude reads to stay oriented. It is one
markdown tree that is also an Obsidian vault and a git repo.

> If you are Claude, read `CLAUDE.md` first: it holds the operating rules for
> reading, writing, and drift-checking this vault.

## Map

| Folder | Holds | Enter |
|--------|-------|-------|
| `Home.md` | Your Obsidian dashboard: accuracy, projects, open threads | [[Home]] |
| `00-Inbox` | Unsorted capture and generated **drift reports** | [[00-Inbox]] |
| `10-Projects` | One note per active repo, frontmatter-stamped | [[10-Projects]] |
| `20-Areas` | Ongoing lanes of responsibility (define your own) | [[20-Areas]] |
| `30-Knowledge` | Atomic evergreen notes and references | [[30-Knowledge]] |
| `40-Sessions` | Dated decision logs, cross-cutting only | [[40-Sessions]] |
| `50-Meta` | About-Me, Preferences, Stack, Automation, design | [[50-Meta]] |
| `90-Archive` | Retired notes | |
| `_templates` | Note templates (Templater) | |

## Meta (who and how)

- [[About-Me]]: who you are. Fill this in; Claude reads it.
- [[Preferences]]: how you want work done.
- [[Stack]]: your tools, platforms, environment.
- [[Automation]]: what is scheduled, what is a hook, and what is only a convention
- [[Memory-Bridge]]: how this vault and the `.claude` memory system divide ownership
- [[Skipped-Repos]]: repos deliberately given no note, and why

## Drift status

The weekly `drift-scan.ps1` task writes a dated **Drift Report** into `00-Inbox`.
The newest report is the authoritative statement of this vault's accuracy. Do not
read staleness off a Dataview query: Dataview cannot run git, so it cannot know
whether a repo has moved past its note.

The scanner only **detects**. Run the `pai-drift-check` skill to reconcile
whatever it flags.

## How this stays true

Pertinent information stays here, and drift is caught by an automated,
accuracy-first process rather than left to rot. The scanner is deterministic and
never rewrites a note. Reconciliation, which does rewrite notes, stays
human-in-the-loop. That split is the load-bearing idea of the whole system.
