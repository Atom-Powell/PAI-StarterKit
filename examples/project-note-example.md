---
type: project
repo: C:\GitRepos\RecipeBox
status: active
last_verified: 2026-10-21
source_paths: [README.md, src/]
tags: [project, web]
---

<!--
EXAMPLE ONLY. This is what a filled-in project note looks like. The project
RecipeBox is made up. Copy _templates/project.md for your own, not this file.
-->

# RecipeBox

## What it is

A small web app for saving recipes from links and searching them by ingredient.
Built for one household, so it favours simplicity over scale. Python and Flask,
SQLite for storage.

## Current state

2026-10-21. Saving a recipe from a link works for the three sites I use most.
Search by ingredient works. There is no login yet: the app only listens on the home
network. Tests pass (41). Not yet tried on the phone.

## Open threads

- [ ] Decide how to handle sites that block scraping (paste text instead?)
- [ ] Try it on the phone and fix the layout
- [x] Search by ingredient

## Decisions

- **2026-10-12**: SQLite rather than a database server. One household, one machine,
  and a server would add a failure mode for no benefit.
- **2026-10-15**: No login for now. The app only binds to the home network. Revisit
  before it is ever exposed outside it.
- **2026-10-19**: Store the ingredient list as separate rows, not one text field.
  Search by ingredient needs it, and changing it later means rewriting every
  saved recipe.

## Links

- Repo: `C:\GitRepos\RecipeBox`
- Related: [[Home-Network-Notes]]
