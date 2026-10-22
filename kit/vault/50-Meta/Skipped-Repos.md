---
type: meta
updated: {{TODAY}}
---

# Skipped Repos

Repos in the workspace that deliberately have **no** project note, and why.

This file is not just documentation. `drift-scan.ps1` parses it at runtime: it
reads the `## Skipped: not a project` section below and suppresses those names
from the `untracked` list in every drift report. Without this file, every scratch
directory and vendored clone in your workspace shows up as drift forever, and a
report that cries wolf every week is a report nobody reads.

**The format is a contract.** The scanner matches the heading text exactly and
reads bullets of the form `- **RepoName**`. Keep both. Prose after the name is
free-form and ignored by the scanner.

## Skipped: not a project

- **ExampleScratchDir**: scratch space, nothing durable. Delete this line and add
  your own.
