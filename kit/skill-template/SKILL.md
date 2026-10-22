---
name: pai-drift-check
description: Use when reconciling the PAI vault against reality, or when the user asks to check for drift, verify project notes, or refresh the PAI vault. Checks every project note in {{VAULT}}\10-Projects against its real repo and writes a dated Drift Report to 00-Inbox. Accuracy-first and human-in-the-loop.
---

# PAI Drift Check

Reconcile the PAI vault (`{{VAULT}}`) against reality. A note has "drifted" when
it claims something that is no longer true. This skill finds drift, fixes only
what is safe and verifiable, and queues everything else for you.

Guiding rule: findings are leads, not facts. Verify against the real repo before
changing a note or reporting a conclusion. When a note and the code disagree, the
code wins.

## Relationship to `drift-scan.ps1`

The scanner **detects**; this skill **reconciles**. The scanner runs on a
schedule, uses no LLM, and never rewrites a note. This skill reads what the
scanner flagged, judges whether a flag is a real error, and rewrites notes.

That split is deliberate and it is the core idea of the system. Detection is
mechanical, so it is safe to automate. Reconciliation requires judgment and it
mutates your durable record, so it stays human-in-the-loop. Do not blur the two.

## Prose style

The vault forbids em dashes and en dashes in prose. Write the Drift Report
accordingly (colons, commas, parentheses, separate sentences).

## Procedure

Create one todo per numbered step and work them in order.

1. **Enumerate.** List every `*.md` in `{{VAULT}}\10-Projects` except the
   `10-Projects.md` index. These are the notes to check.

2. **Read frontmatter.** For each note, read `repo`, `status`, `last_verified`,
   `source_paths`. If a note is missing required frontmatter, record it under
   "Malformed" in the report and skip its checks.

3. **Verify against reality.** For each note:
   - Confirm `repo` path exists. If it does not, this is a **broken** note
     (repo moved or deleted).
   - If `repo` is a git repo, read the last commit date
     (`git -C <repo> log -1 --format=%cs`). If the last commit is newer than
     `last_verified`, mark the note **stale** (the repo changed since the note was
     last confirmed, so its content may be out of date).
   - Confirm each entry in `source_paths` still exists under `repo`. Any missing
     path makes the note **broken**.
   - Sanity-check `status`: if the repo is gone, the note should be `archived`.

4. **Classify** each note as one of: `ok`, `stale`, `broken`, `malformed`.

5. **Read stale notes.** For every `stale` note, open the note and compare its
   claims (what it is, current state, decisions) against the repo's README and
   recent changes. Decide whether the content is still accurate.
   - If content still matches reality: this is a **safe auto-fix**. Update
     `last_verified` to today. Record it under "Auto-fixed".
   - If content no longer matches: do NOT rewrite it silently. Record the specific
     mismatch and a proposed reconciliation under "Needs review".

6. **Safe auto-fixes only.** You may, without asking:
   - refresh `last_verified` after confirming content still matches (step 5);
   - correct a `source_paths` entry when a file has clearly moved to an obvious
     new location in the same repo.
   Everything else (rewriting state, changing `status`, resolving a content
   mismatch, deleting a note) goes to "Needs review". Accuracy over automation.

7. **Write the report.** Create
   `{{VAULT}}\00-Inbox\drift-report-YYYY-MM-DD.md` using the template below. Use
   today's date (ask the environment or the user for the date; do not guess).

8. **Report back.** Tell the user: how many notes checked, how many ok /
   auto-fixed / need review / broken, and point them at the report. Ask them to
   resolve the "Needs review" items when ready.

## Report template

```markdown
---
type: drift-report
date: <YYYY-MM-DD>
checked: <N>
ok: <N>
auto_fixed: <N>
needs_review: <N>
broken: <N>
---

# Drift Report <YYYY-MM-DD>

## Summary

<one paragraph: overall accuracy state of the vault>

## Auto-fixed (safe, already applied)

- **<note>**: refreshed last_verified to <date> after confirming content matches.

## Needs review (your decision required)

- **<note>**: <what drifted>. Proposed reconciliation: <suggestion>.

## Broken (repo or source path missing)

- **<note>**: <what is missing>. Suggested action: archive / repoint / recreate.

## OK

- <note>, <note>, ...
```

## Optional extension: memory-bridge check

If asked to also check the memory bridge, verify that pointer lines in
`{{CLAUDE_HOME}}\projects\{{WORKSPACE_SLUG}}\memory\` still resolve to existing
vault notes, and flag any memory file that duplicates full content also present
in the vault (violates the one-fact-one-home invariant). Report findings in the
same Drift Report under a "Memory bridge" section.

Note that Claude Code keys memory by the session's working-directory slug, so
this directory only loads in a session started at exactly that path. See
`{{VAULT}}\50-Meta\Memory-Bridge.md`.
