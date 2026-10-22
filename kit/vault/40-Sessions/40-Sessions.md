---
type: index
---

# Sessions

Dated decision logs, named `YYYY-MM-DD-topic.md`. Create from
`_templates/session.md`.

## What belongs here (narrow on purpose)

Only decisions that are **cross-cutting**: they span several projects, or they
belong to no project at all (the vault itself, tooling, working style).

Anything scoped to a single repo does **not** belong here. It goes in that repo's
note under `## Decisions`, via capture-at-source. That is where you will actually
reread it, and duplicating it here would break one-fact-one-home.

The test: *could this bullet live in exactly one project note?* If yes, put it
there and do not write a session note.

## Why the folder still exists

Capture-at-source has a real gap. A decision that changes how several projects
work, or that is about the system rather than a project, has nowhere to land. It
would otherwise die in the chat that produced it, which is the retention problem
this vault was built to solve. This folder is that gap and nothing wider.

Expect it to stay small. A folder that fills up quickly is a sign the charter has
drifted back to "log everything."
