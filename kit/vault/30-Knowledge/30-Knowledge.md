---
type: index
---

# Knowledge

Atomic, evergreen notes. One concept per note. Link liberally so the graph
becomes navigable. Create from `_templates/knowledge.md`.

This is where durable lessons land after they prove reusable, promoted out of
project notes or `.claude` memory (see [[Memory-Bridge]]).

## How this folder fills

By **promotion**, never by seeding. A lesson earns its way here: it shows up in a
project note, proves reusable somewhere else, and only then moves here with a
one-line pointer left behind.

Do not seed this folder by summarizing your repos. Unverified content is worse
than an empty folder, because it looks like knowledge and reads like knowledge
while being nobody's actual experience. An empty `30-Knowledge` is an honest
statement that you have not learned anything durable yet. A full one that nobody
verified is a lie the vault will keep telling Claude.

```dataview
TABLE last_verified, source_paths
FROM "30-Knowledge"
WHERE type = "knowledge"
SORT file.name ASC
```
