# drift-scan.ps1
# Deterministic PAI drift DETECTION. Runs on a schedule with no LLM and no
# interactive auth. Checks every project note in 10-Projects against its real
# repo, checks the workspace for repos that have NO note, and writes a dated
# report to 00-Inbox, then commits and pushes.
#
# It does NOT rewrite note content. Semantic reconciliation (deciding whether a
# flagged note is actually wrong) is the job of the pai-drift-check skill, run
# on demand against whatever this scan flags.
#
# Rewritten 2026-07-12 after the full sweep. Fixed:
#   - `git commit` had no pathspec, so it committed the ENTIRE index. With
#     Obsidian Git auto-committing every 10 minutes, unrelated staged work was
#     landing on main authored by 'drift-scan'. Now uses `commit --only <path>`.
#   - The git block could not report failure. Native commands do not throw in
#     PowerShell, $LASTEXITCODE was never checked, and stderr went to $null, so a
#     rejected push printed "Committed and pushed." Now every git call is checked.
#   - Dates were compared as ordinal strings. A YAML-quoted last_verified would
#     mark a note stale forever. Now parsed as real dates; unparseable is
#     malformed, not a guess.
#   - Quoted or relative `repo:` values were misclassified as broken.
#   - Repos with no note were invisible. Now reported as `untracked`.
#   - Reports were written with a UTF-8 BOM, which hides the YAML frontmatter
#     from strict parsers.

$ErrorActionPreference = 'Stop'

# Any unhandled terminating error must exit NON-ZERO.
#
# Without this trap, `powershell.exe -File drift-scan.ps1` exits 0 even when the
# script dies partway through: PowerShell only returns a non-zero code when a
# script says so explicitly. So the scan could throw on line 191, print a red
# stack trace nobody reads (it runs unattended, on a schedule), and hand Task
# Scheduler a Last Result of 0. The task history would show an unbroken run of
# successes for a scanner that had not completed once.
#
# The explicit `exit 1` calls further down cover the failures we anticipated. This
# covers the ones we did not, which are the ones that matter. A check that cannot
# fail is not a check.
trap {
  Write-Host "ERROR: drift scan aborted: $($_.Exception.Message)"
  Write-Host "  at $($_.InvocationInfo.ScriptName):$($_.InvocationInfo.ScriptLineNumber)"
  exit 1
}

# Vault is derived from this script's own location, never configured.
$Vault    = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$Projects = Join-Path $Vault '10-Projects'
$Inbox    = Join-Path $Vault '00-Inbox'
$Today    = Get-Date -Format 'yyyy-MM-dd'

# Deterministic working directory. A relative `repo:` value used to resolve
# against the caller's cwd, which differs between a manual run and the scheduled
# run (C:\Windows\System32), classifying the same note differently.
Push-Location $Vault

# ---------- config ----------
$WorkspaceRoot = Split-Path $Vault -Parent
$Branch        = $null
$IdentityName  = 'drift-scan'
$IdentityEmail = $null

# A MISSING config is fine: every key has a fallback, and a user who skipped
# bootstrap should still get working behavior.
#
# A config that EXISTS but does not parse is fatal. Silently falling back to
# defaults means running on values nobody chose, while the file on disk says
# otherwise. The most likely cause is an unescaped Windows path (`C:\tmp` contains
# \t, a tab escape), which is exactly the kind of config that looks correct to a
# human and is garbage to a parser. Refuse to run rather than pretend.
$cfgPath = Join-Path $Vault '50-Meta\pai.config.json'
if (Test-Path -LiteralPath $cfgPath) {
  try {
    $cfg = Get-Content -LiteralPath $cfgPath -Raw | ConvertFrom-Json
  } catch {
    Write-Host "ERROR: $cfgPath exists but is not valid JSON: $($_.Exception.Message)"
    Write-Host "Refusing to run on default values while a config file says otherwise."
    Write-Host "Most likely an unescaped Windows path. Backslashes must be doubled: C:\\\\Repos, not C:\\Repos."
    Pop-Location
    exit 1
  }
  if ($cfg.workspace_root)          { $WorkspaceRoot = $cfg.workspace_root }
  if ($cfg.git_branch)              { $Branch        = $cfg.git_branch }
  if ($cfg.commit_identity.name)    { $IdentityName  = $cfg.commit_identity.name }
  if ($cfg.commit_identity.email)   { $IdentityEmail = $cfg.commit_identity.email }

  # A configured workspace_root that does not resolve is fatal. Left unchecked, the
  # untracked-repo check further down simply skips itself, so a typo silently
  # disables an entire class of detection while every report still says "0
  # untracked" and looks clean. Note that `C:\tmp` in unescaped JSON parses to
  # "C:<TAB>mp", which is legal JSON and an illegal path: exactly this failure.
  if ($cfg.workspace_root) {
    $bad = $false
    try { $bad = -not (Test-Path -LiteralPath $WorkspaceRoot -PathType Container) }
    catch { $bad = $true }
    if ($bad) {
      Write-Host "ERROR: workspace_root in $cfgPath does not resolve to a directory: '$WorkspaceRoot'"
      Write-Host "Untracked-repo detection would silently do nothing. Fix the config."
      Write-Host "If this looks right, check the backslashes: JSON needs them doubled."
      Pop-Location
      exit 1
    }
  }
}
# Never hardcode the branch. Fall back to whatever HEAD actually is.
if (-not $Branch) {
  $Branch = (& git -C $Vault rev-parse --abbrev-ref HEAD 2>$null)
  if ($LASTEXITCODE -ne 0 -or -not $Branch) { $Branch = 'main' }
  $Branch = $Branch.Trim()
}

# ---------- helpers ----------
function Get-Field([string]$text, [string]$key) {
  # Scope to the frontmatter block so a `repo:` mentioned in prose cannot make a
  # note with no frontmatter validate as well-formed.
  $fm = [regex]::Match($text, "(?s)\A\s*---\s*\r?\n(.*?)\r?\n---\s*\r?\n")
  $scope = if ($fm.Success) { $fm.Groups[1].Value } else { '' }
  $m = [regex]::Match($scope, "(?m)^$key\s*:\s*(.+?)\s*$")
  if ($m.Success) { return $m.Groups[1].Value.Trim().Trim('"', "'") }
  return $null
}

function Parse-Date([string]$s) {
  if (-not $s) { return $null }
  $d = [datetime]::MinValue
  $ok = [datetime]::TryParseExact(
    $s, 'yyyy-MM-dd', [Globalization.CultureInfo]::InvariantCulture,
    [Globalization.DateTimeStyles]::None, [ref]$d)
  if ($ok) { return $d }
  return $null
}

$ok = @(); $stale = @(); $broken = @(); $malformed = @()
$repoToNotes = @{}

# ---------- 1. notes -> repos ----------
Get-ChildItem $Projects -Filter *.md | Where-Object { $_.Name -ne '10-Projects.md' } | ForEach-Object {
  $name = $_.Name
  $text = Get-Content -LiteralPath $_.FullName -Raw

  $repo  = Get-Field $text 'repo'
  $lvRaw = Get-Field $text 'last_verified'
  $spRaw = Get-Field $text 'source_paths'

  if (-not $repo -or -not $lvRaw) { $malformed += "$name (missing repo or last_verified)"; return }

  # A relative repo path is ambiguous by construction. Do not guess.
  if (-not [System.IO.Path]::IsPathRooted($repo)) {
    $malformed += "$name (repo is not an absolute path: $repo)"; return
  }

  $lv = Parse-Date $lvRaw
  if (-not $lv) {
    $malformed += "$name (last_verified is not a valid yyyy-MM-dd date: '$lvRaw')"; return
  }

  # Track duplicate repo targets.
  $key = $repo.TrimEnd('\', '/').ToLower()
  if (-not $repoToNotes.ContainsKey($key)) { $repoToNotes[$key] = @() }
  $repoToNotes[$key] += $name

  if (-not (Test-Path -LiteralPath $repo -PathType Container)) {
    $broken += "$name (repo missing: $repo)"; return
  }

  # source_paths: [a, b, c]
  $missing = @()
  if ($spRaw) {
    $inner = $spRaw.Trim('[', ']')
    foreach ($p in ($inner -split ',')) {
      $p = $p.Trim().Trim('"', "'")
      if ($p) { if (-not (Test-Path -LiteralPath (Join-Path $repo $p))) { $missing += $p } }
    }
  }
  if ($missing.Count -gt 0) { $broken += "$name (missing paths: $($missing -join ', '))"; return }

  # git last commit vs last_verified, compared as dates.
  $lc = $null
  if (Test-Path -LiteralPath (Join-Path $repo '.git')) {
    # A repo with zero commits (a brand-new project) makes git exit 128 with text
    # on stderr. Under ErrorActionPreference=Stop in Windows PowerShell 5.1, that
    # stderr text becomes a terminating error and kills the WHOLE scan. Relax it
    # for this one call; an empty repo simply has no commit date to compare.
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try { $raw = (& git -C $repo log -1 --format=%cs 2>$null) } finally { $ErrorActionPreference = $prevEap }
    if ($LASTEXITCODE -eq 0 -and $raw) { $lc = Parse-Date ($raw.Trim()) }
  }
  if ($lc -and ($lc -gt $lv)) {
    $stale += ("$name (repo commit {0} newer than verified {1})" -f $lc.ToString('yyyy-MM-dd'), $lv.ToString('yyyy-MM-dd'))
    return
  }

  $ok += $name
}

# ---------- 2. repos -> notes (the direction that was previously invisible) ----------
$untracked = @()
$duplicates = @()

foreach ($k in $repoToNotes.Keys) {
  if ($repoToNotes[$k].Count -gt 1) {
    $duplicates += ("{0} <- {1}" -f $k, ($repoToNotes[$k] -join ', '))
  }
}

# Repos deliberately not tracked, read from the "Skipped: not a project" section.
$skipped = @()
$skipPath = Join-Path $Vault '50-Meta\Skipped-Repos.md'
if (Test-Path -LiteralPath $skipPath) {
  $sk = Get-Content -LiteralPath $skipPath -Raw
  $sec = [regex]::Match($sk, "(?s)##\s*Skipped:\s*not a project(.*?)(?:\r?\n##\s|\z)")
  if ($sec.Success) {
    foreach ($m in [regex]::Matches($sec.Groups[1].Value, "(?m)^\s*-\s*\*\*(.+?)\*\*")) {
      $skipped += $m.Groups[1].Value.Trim().ToLower()
    }
  }
}

# Repos whose note has been retired to 90-Archive. These are deliberately not in
# 10-Projects, so without this they would be reported as `untracked`, which is
# exactly backwards: they are the most deliberately tracked repos there are.
$archived = @{}
$archiveDir = Join-Path $Vault '90-Archive'
if (Test-Path -LiteralPath $archiveDir -PathType Container) {
  Get-ChildItem $archiveDir -Filter *.md -ErrorAction SilentlyContinue | ForEach-Object {
    $at = Get-Content -LiteralPath $_.FullName -Raw
    $ar = Get-Field $at 'repo'
    if ($ar) { $archived[$ar.TrimEnd('\', '/').ToLower()] = $_.BaseName }
  }
}

if (Test-Path -LiteralPath $WorkspaceRoot -PathType Container) {
  $vaultName = (Split-Path $Vault -Leaf).ToLower()
  Get-ChildItem -LiteralPath $WorkspaceRoot -Directory | ForEach-Object {
    $dirName = $_.Name
    $dirKey  = $_.FullName.TrimEnd('\', '/').ToLower()
    if ($dirName.ToLower() -eq $vaultName) { return }
    if ($skipped -contains $dirName.ToLower()) { return }
    if ($repoToNotes.ContainsKey($dirKey)) { return }
    if ($archived.ContainsKey($dirKey)) { return }
    $untracked += $dirName
  }
}

$checked = $ok.Count + $stale.Count + $broken.Count + $malformed.Count

# ---------- 3. report ----------
function Section($title, $items) {
  if ($items.Count -eq 0) { return "## $title`n`nNone.`n" }
  return "## $title`n`n" + (($items | ForEach-Object { "- $_" }) -join "`n") + "`n"
}

$report = @"
---
type: drift-report
date: $Today
generated_by: drift-scan.ps1 (scheduled, detection only)
checked: $checked
ok: $($ok.Count)
stale: $($stale.Count)
broken: $($broken.Count)
malformed: $($malformed.Count)
untracked: $($untracked.Count)
archived: $($archived.Count)
duplicates: $($duplicates.Count)
---

# Drift Report $Today (scheduled scan)

## Summary

Automated detection scan. $checked project notes checked: $($ok.Count) ok, $($stale.Count) stale, $($broken.Count) broken, $($malformed.Count) malformed. $($untracked.Count) repo(s) in the workspace have no note. Stale and broken items are leads, not proof of error. Run the pai-drift-check skill to read the flagged notes, compare them against their repos, and reconcile. This scan never rewrites note content.

$(Section 'Stale (repo changed since last_verified, review content)' $stale)
$(Section 'Broken (repo or source path missing)' $broken)
$(Section 'Malformed (missing or invalid required frontmatter)' $malformed)
$(Section 'Untracked (repo in the workspace with no project note)' $untracked)
$(Section 'Duplicate targets (more than one note claims the same repo)' $duplicates)
## OK ($($ok.Count))

$(if ($ok.Count -gt 0) { ($ok | ForEach-Object { "- $_" }) -join "`n" } else { 'None.' })
"@

$reportPath = Join-Path $Inbox "drift-report-$Today.md"
# No BOM. Set-Content -Encoding UTF8 under PS 5.1 emits EF BB BF, which hides the
# YAML frontmatter from strict parsers.
[IO.File]::WriteAllText($reportPath, $report, (New-Object Text.UTF8Encoding $false))
Write-Host "Wrote $reportPath (checked=$checked ok=$($ok.Count) stale=$($stale.Count) broken=$($broken.Count) untracked=$($untracked.Count))"

# ---------- 4. commit and push, and SAY SO IF IT FAILS ----------
function Invoke-Git {
  param([string[]]$GitArgs, [switch]$AllowFail)
  # $ErrorActionPreference='Stop' plus `2>&1` makes PowerShell throw on ANY line
  # git writes to stderr, including harmless notices ("LF will be replaced by
  # CRLF"). Exit code is the only reliable success signal for a native command,
  # so drop to Continue while capturing, then judge on $LASTEXITCODE alone.
  $prev = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  try {
    $out  = & git @GitArgs 2>&1
    $code = $LASTEXITCODE
  } finally {
    $ErrorActionPreference = $prev
  }
  if ($code -ne 0 -and -not $AllowFail) {
    throw ("git {0} failed (exit {1}): {2}" -f ($GitArgs -join ' '), $code, ($out -join ' '))
  }
  return [pscustomobject]@{ Code = $code; Output = ($out -join "`n") }
}

$relReport = "00-Inbox/drift-report-$Today.md"
try {
  $identityArgs = @('-C', $Vault, '-c', "user.name=$IdentityName")
  if ($IdentityEmail) { $identityArgs += @('-c', "user.email=$IdentityEmail") }

  # The report is a new file each day, and `commit --only` cannot commit a path
  # git has never seen. So: a SCOPED add (this path and nothing else), then
  # `commit --only` on the same path, which ignores whatever else is staged.
  # Both halves are load-bearing. Dropping the add breaks new reports; dropping
  # --only re-introduces the index-sweeping bug.
  Invoke-Git @('-C', $Vault, 'add', '--', $relReport) | Out-Null

  $msg = "Scheduled drift scan $Today (checked=$checked stale=$($stale.Count) broken=$($broken.Count) untracked=$($untracked.Count))"
  $commit = Invoke-Git ($identityArgs + @('commit', '-q', '--only', '-m', $msg, '--', $relReport)) -AllowFail

  if ($commit.Code -ne 0) {
    if ($commit.Output -match 'nothing to commit|no changes added') {
      # Nothing NEW to commit. That does NOT mean nothing to push.
      #
      # This used to `exit 0` right here, which quietly stranded work: if an
      # earlier run committed the report and its push FAILED, the next run
      # regenerates an identical report, sees nothing to commit, skips the push,
      # and reports success. The commit never reaches the remote, and the scan
      # says "all good" every week from then on. The failure heals itself into a
      # lie, which is worse than staying broken, because a broken thing gets
      # fixed.
      #
      # So: fall through to the push whenever the local branch is ahead of origin.
      Write-Host 'Nothing new to commit (report unchanged since the last run).'

      $ahead = Invoke-Git @('-C', $Vault, 'rev-list', '--count', "origin/$Branch..HEAD") -AllowFail
      if ($ahead.Code -ne 0) {
        # No origin/<branch> ref yet: never pushed. That is something to push.
        Write-Host "No origin/$Branch ref found locally. Attempting push anyway."
      } elseif ([int]$ahead.Output.Trim() -eq 0) {
        Write-Host "Local branch matches origin/$Branch. Nothing to push."
        Pop-Location
        exit 0
      } else {
        Write-Host "Local branch is $($ahead.Output.Trim()) commit(s) ahead of origin/$Branch. Pushing."
      }
    } else {
      throw ("git commit failed (exit {0}): {1}" -f $commit.Code, $commit.Output)
    }
  }

  $push = Invoke-Git @('-C', $Vault, 'push', 'origin', "HEAD:$Branch") -AllowFail
  if ($push.Code -ne 0) {
    # Most likely a non-fast-forward, because Obsidian Git pushes the same branch.
    Write-Host "Push rejected, rebasing onto origin/$Branch and retrying ..."
    Invoke-Git @('-C', $Vault, 'pull', '--rebase', '--autostash', 'origin', $Branch) | Out-Null
    Invoke-Git @('-C', $Vault, 'push', 'origin', "HEAD:$Branch") | Out-Null
  }
  Write-Host "Committed and pushed to origin/$Branch."
} catch {
  # Loud, not silent. This is the whole point of the deterministic design.
  Write-Host "ERROR: drift report was written but NOT synced: $($_.Exception.Message)"
  Pop-Location
  exit 1
}

Pop-Location
exit 0
