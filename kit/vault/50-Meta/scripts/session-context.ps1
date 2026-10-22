# session-context.ps1
# SessionStart hook for the PAI vault. Reads the session's working directory from
# stdin JSON, finds the project note whose `repo:` frontmatter is the closest
# ancestor of that directory, and injects it as session context. If no repo
# matches, injects a compact project index instead.
#
# Output: JSON on stdout of the form Claude Code expects for SessionStart context
# injection: {"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"..."}}
#
# MATCHING. An earlier version of this script matched cwd path SEGMENTS against
# note basenames and kept the deepest match. That injected the WRONG note whenever
# a repo contained a subdirectory named after another tracked repo, and then told
# the model to write its decisions into that wrong note. Silent corruption of the
# durable record is the worst failure this system can have, and two such name
# collisions existed in the reference vault without anyone noticing.
#
# We now match on the `repo:` frontmatter value by longest path prefix, which is
# exact, handles nesting correctly, and cannot match a foreign checkout.
#
# Always exits 0. A hook that errors must never block a session. But it no longer
# fails SILENTLY: on error it emits a one-line notice, because an invisible
# failure is indistinguishable from "no project matched" and the context
# substrate could stop working without anyone noticing.
#
# Pinned to powershell.exe (5.1) by settings.json. Do not switch to pwsh without
# setting [Console]::OutputEncoding: PS 5.1's ConvertTo-Json escapes non-ASCII to
# \uXXXX, which is what keeps note bodies with curly quotes from mojibake here.

$ErrorActionPreference = 'Stop'

# Vault is derived from this script's own location, never configured. It cannot
# go stale and it survives the vault being moved or renamed.
$Vault    = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$Projects = Join-Path $Vault '10-Projects'

function Emit([string]$context) {
  if (-not $context) { exit 0 }
  $obj = @{
    hookSpecificOutput = @{
      hookEventName     = 'SessionStart'
      additionalContext = $context
    }
  }
  ($obj | ConvertTo-Json -Depth 6 -Compress)
  exit 0
}

function Get-WorkspaceRoot([string]$vault) {
  $cfgPath = Join-Path $vault '50-Meta\pai.config.json'
  if (Test-Path -LiteralPath $cfgPath) {
    try {
      $cfg = Get-Content -LiteralPath $cfgPath -Raw | ConvertFrom-Json
      if ($cfg.workspace_root) { return $cfg.workspace_root }
    } catch { }
  }
  # Fallback: the vault's parent. A missing config must degrade, not break.
  return (Split-Path $vault -Parent)
}

# Normalize for comparison: trailing separators removed, lowercased.
function Norm([string]$p) {
  if (-not $p) { return '' }
  return $p.Trim().Trim('"', "'").TrimEnd('\', '/').ToLower()
}

# True when $child is $parent or lives underneath it. Requires a separator at the
# boundary, so C:\GitReposArchive is NOT inside C:\GitRepos.
function Is-Under([string]$child, [string]$parent) {
  if (-not $child -or -not $parent) { return $false }
  if ($child -eq $parent) { return $true }
  return $child.StartsWith($parent + '\')
}

try {
  # 1. Read cwd from stdin JSON.
  $raw = [Console]::In.ReadToEnd()
  $cwd = $null
  if ($raw) {
    try { $cwd = ($raw | ConvertFrom-Json).cwd } catch { $cwd = $null }
  }
  if (-not $cwd) { $cwd = (Get-Location).Path }
  $cwdN = Norm $cwd

  if (-not (Test-Path -LiteralPath $Projects -PathType Container)) {
    Emit "[PAI vault] context hook: 10-Projects not found under $Vault. The vault may have moved. No project context loaded."
  }

  # 2. Build a repo-path to note map from frontmatter, then pick the note whose
  #    repo path is the LONGEST prefix of cwd. Longest wins so that a nested
  #    tracked repo beats its parent, while a subdirectory that merely shares a
  #    name with another repo matches nothing.
  $bestNote = $null
  $bestLen  = -1

  Get-ChildItem $Projects -Filter *.md | Where-Object { $_.Name -ne '10-Projects.md' } | ForEach-Object {
    $text = Get-Content -LiteralPath $_.FullName -Raw
    $m = [regex]::Match($text, "(?m)^repo\s*:\s*(.+?)\s*$")
    if (-not $m.Success) { return }
    $repoN = Norm $m.Groups[1].Value
    if (-not $repoN) { return }
    if ((Is-Under $cwdN $repoN) -and ($repoN.Length -gt $bestLen)) {
      $bestLen  = $repoN.Length
      $bestNote = $_.FullName
    }
  }

  # 3a. Matched a repo: inject that note.
  if ($bestNote) {
    $body = Get-Content -LiteralPath $bestNote -Raw

    # Truncate the BODY, not the assembled context, so the closing fence always
    # survives and the model can always tell where note content ends.
    # Claude Code caps SessionStart context at 10000 chars; leave headroom for
    # the preamble.
    if ($body.Length -gt 7500) {
      $body = $body.Substring(0, 7500) + "`n... [truncated; open the full note in the vault]"
    }

    $context = @"
[PAI vault] You are working in a repo tracked by the PAI vault. Below is its durable project note. Use it as a lead, not gospel: verify against the live repo before acting, and if the note and code disagree, the code wins.

CAPTURE PROTOCOL: if this session makes a decision, changes project state, or resolves an open thread, append a terse dated bullet under the "## Decisions" section of this file before you finish, and update "## Current state" or "## Open threads" if they changed:
  $bestNote
Keep entries factual and short. This is how the vault stays accurate between drift scans; it syncs to git on its own. Do not copy the content into .claude memory (one fact, one home). Full rules: $Vault\CLAUDE.md.

--- BEGIN PROJECT NOTE ($([System.IO.Path]::GetFileName($bestNote))) ---
$body
--- END PROJECT NOTE ---
"@
    Emit $context
  }

  # 3b. No repo match. Only inject the index when inside the workspace; anywhere
  #     else, stay silent rather than pollute an unrelated session.
  $workspace = Norm (Get-WorkspaceRoot $Vault)
  if (-not (Is-Under $cwdN $workspace)) { exit 0 }

  $lines = @()
  Get-ChildItem $Projects -Filter *.md | Where-Object { $_.Name -ne '10-Projects.md' } | Sort-Object BaseName | ForEach-Object {
    $t = Get-Content -LiteralPath $_.FullName -Raw
    $st = [regex]::Match($t, "(?m)^status\s*:\s*(.+?)\s*$")
    $status = if ($st.Success) { $st.Groups[1].Value.Trim() } else { '?' }
    $lines += ("- {0} [{1}]" -f $_.BaseName, $status)
  }
  $index = $lines -join "`n"
  $context = @"
[PAI vault] The PAI vault at $Vault is the durable, cross-project record and Claude context substrate. Entry point: $Vault\PAI.md. Operating rules: $Vault\CLAUDE.md. When work touches one of these repos, open its note in $Projects and keep it current. Projects tracked:
$index
"@
  Emit $context
}
catch {
  # Never block a session, but never fail silently either.
  $msg = ($_.Exception.Message -split "`r?`n")[0]
  try {
    Emit "[PAI vault] context hook failed: $msg. No project context loaded this session. Check $Vault\50-Meta\scripts\session-context.ps1."
  } catch {
    exit 0
  }
}
