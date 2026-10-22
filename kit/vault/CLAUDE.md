# Operating rules for Claude in this vault

This file governs how you read from and write to this vault. It is the
Universal File-based Context (UFC) contract. Read `PAI.md` for the map.

## Prose style

No em dashes or en dashes in any prose you write here (an optional lint hook can enforce it).
Use colons, commas, parentheses, or separate sentences instead.

This is a kit default rather than a law. It exists because those characters are
a reliable tell of unedited machine prose. If you do not care about that, delete
this section and unwire `lint-ai-tells.mjs` from your `settings.json`. Do not
leave the rule here while ignoring it: a rule nobody enforces teaches Claude that
the rest of this file is negotiable too.

## Reading (orientation)

1. On entering a task that touches a project, open its note in `10-Projects`
   before acting. That note is the durable record of decisions and state.
2. Treat note contents as **leads, not facts**. Verify against the real repo
   before relaying or acting. If the note and the code disagree, the code wins,
   and you flag the note as drifted.

## Writing (capture)

1. **One fact, one home.** Content lives in the vault. Never copy the full
   content into `.claude` memory too. Memory holds only a one-line pointer plus a
   link back here. See `50-Meta/Memory-Bridge.md`.
2. **Stamp provenance.** Every project or knowledge note carries frontmatter:
   ```yaml
   repo: {{WORKSPACE_ROOT}}\<name>
   status: active | paused | archived
   last_verified: YYYY-MM-DD
   source_paths: [README.md, docs/]
   ```
   When you verify a note against reality, update `last_verified` to today.
3. **Capture-at-source (self-capture).** This is a standing convention, not a
   prompt you wait for. When a session working in a tracked repo makes a
   decision, changes project state, or resolves an open thread, append a terse
   dated bullet under that note's `## Decisions` section before the session ends,
   and update `## Current state` or `## Open threads` if they changed. The
   SessionStart hook injects this instruction plus the note's path into every
   tracked-repo session, so it travels with you outside the vault. Keep entries
   factual and short. New notes come from `_templates`. Skip the capture when a
   session changed nothing worth recording; an empty decision log beats a padded
   one.
4. **Inbox for the unsorted.** If it does not have an obvious home, drop it in
   `00-Inbox` with a date, and file it later.

## Drift control

- The `pai-drift-check` skill (in `~/.claude/skills/pai-drift-check`) is the
  canonical reconciliation routine. Invoke it to check project notes against
  their repos and produce a dated Drift Report in `00-Inbox`.
- Auto-fix only safe, verifiable facts (refresh `last_verified`, correct a moved
  path). Anything requiring judgment goes into the report for a human to confirm.
  Accuracy over automation.

## Folder rules

- `10-Projects`: one note per repo, named after the repo. Frontmatter required.
- `40-Sessions`: dated notes `YYYY-MM-DD-topic.md`, for **cross-cutting decisions
  only**: those spanning several projects, or belonging to none (the vault,
  tooling, working style). If a decision could live in exactly one project note,
  it goes there via capture-at-source and you do **not** write a session note.
  Expect this folder to stay small.
- `30-Knowledge`: atomic, evergreen, one concept per note. Link liberally. It fills
  by **promotion**: a lesson proves reusable in a project note, then moves here,
  leaving a one-line pointer behind. Never seed it by summarizing repos;
  unverified content is worse than an empty folder.
- `90-Archive`: move here instead of deleting when a note retires.
- `_templates`: copy from here; do not edit templates during normal work.
