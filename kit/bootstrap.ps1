# bootstrap.ps1
# Stands up a new PAI vault from the kit skeleton.
#
#   pwsh -f .\kit\bootstrap.ps1 -VaultPath C:\GitRepos\MyVault -WorkspaceRoot C:\GitRepos
#
# What it does:
#   1. Copies kit/vault/ to -VaultPath and substitutes the config tokens.
#   2. Writes 50-Meta/pai.config.json with your values.
#   3. Generates ~/.claude/skills/pai-drift-check/SKILL.md from the template.
#      (Generated, not copied: Claude Code skills are plain markdown with no
#      variable interpolation, so the vault path has to be baked in.)
#   4. Installs the (optional) prose lint script to ~/.claude/hooks/
#   5. PRINTS the settings.json hook block for you to paste. It does not write it.
#
# On (5): a bootstrap script that silently mutates your global Claude Code
# settings is a black box, and someone who cannot see what was added cannot debug
# it when it misfires. Printing is the teaching moment. Paste it yourself.

[CmdletBinding()]
param(
  # Where the new vault goes. Must not already exist.
  [Parameter(Mandatory)] [string] $VaultPath,

  # The directory your repos live in. The SessionStart hook scopes itself to this,
  # and the drift scanner looks here for repos with no note.
  [Parameter(Mandatory)] [string] $WorkspaceRoot,

  # Branch the drift scanner pushes to. Defaults to whatever HEAD is after init.
  [string] $GitBranch = 'main',

  # Identity the scheduled scan commits under. Keep it distinct from your own so
  # you can tell scanner commits from human ones in the log.
  [string] $CommitName  = 'drift-scan',
  [string] $CommitEmail = '',

  # Root of the Claude Code config directory.
  [string] $ClaudeHome = (Join-Path $env:USERPROFILE '.claude'),

  # Skip the skill and hook install; only build the vault.
  [switch] $VaultOnly,

  # Overwrite a pai-drift-check skill that already points at another vault.
  [switch] $Force
)

$ErrorActionPreference = 'Stop'

$KitRoot  = $PSScriptRoot
$Skeleton = Join-Path $KitRoot 'vault'
$Today    = Get-Date -Format 'yyyy-MM-dd'

if (-not (Test-Path -LiteralPath $Skeleton)) {
  throw "Skeleton not found at $Skeleton. Run this from inside the kit."
}
if (Test-Path -LiteralPath $VaultPath) {
  throw "$VaultPath already exists. Refusing to overwrite an existing vault. Move it aside or pick another path."
}
if (-not (Test-Path -LiteralPath $WorkspaceRoot -PathType Container)) {
  throw "WorkspaceRoot $WorkspaceRoot does not exist."
}

# Normalize: no trailing separators, or the derived paths and the slug go wrong.
$WorkspaceRoot = $WorkspaceRoot.TrimEnd('\', '/')

Write-Host ""
Write-Host "PAI vault bootstrap" -ForegroundColor Cyan
Write-Host "  vault      : $VaultPath"
Write-Host "  workspace  : $WorkspaceRoot"
Write-Host "  branch     : $GitBranch"
Write-Host ""

# ---------- 1. copy the skeleton ----------
Copy-Item -LiteralPath $Skeleton -Destination $VaultPath -Recurse
$VaultPath = (Resolve-Path -LiteralPath $VaultPath).Path.TrimEnd('\', '/')
Write-Host "Copied skeleton to $VaultPath"

# Claude Code keys memory by the session's working-directory slug: drive colon and
# every separator become a dash. C:\GitRepos becomes C--GitRepos.
$WorkspaceSlug = ($WorkspaceRoot -replace '[:\\/]', '-')

$tokens = @{
  '{{VAULT}}'           = $VaultPath
  '{{WORKSPACE_ROOT}}'  = $WorkspaceRoot
  '{{WORKSPACE_SLUG}}'  = $WorkspaceSlug
  '{{GIT_BRANCH}}'      = $GitBranch
  '{{COMMIT_EMAIL}}'    = $CommitEmail
  '{{COMMIT_NAME}}'     = $CommitName
  '{{CLAUDE_HOME}}'     = $ClaudeHome
  '{{TODAY}}'           = $Today
}

function Expand-Tokens {
  param([string] $Path, [hashtable] $Map)
  $text = [IO.File]::ReadAllText($Path)
  $orig = $text

  # In a .json file every backslash in a substituted Windows path must be doubled.
  # Skipping this writes "C:\tmp\ws", where \t is a TAB escape, producing a config
  # that will not parse. drift-scan.ps1 then warns once, falls back to defaults,
  # and carries on reporting success, so the vault runs on values nobody chose and
  # nothing ever says so out loud. Found by a clean install; invisible otherwise.
  $isJson = [IO.Path]::GetExtension($Path) -ieq '.json'

  foreach ($k in $Map.Keys) {
    $v = [string]$Map[$k]
    if ($isJson) { $v = $v.Replace('\', '\\') }
    # Literal replace, not regex: a Windows path is full of backslashes.
    $text = $text.Replace($k, $v)
  }
  if ($text -ne $orig) {
    # No BOM. PS 5.1's -Encoding UTF8 emits EF BB BF, which hides YAML frontmatter
    # from strict parsers.
    [IO.File]::WriteAllText($Path, $text, (New-Object Text.UTF8Encoding $false))
    return $true
  }
  return $false
}

$expanded = 0
Get-ChildItem -LiteralPath $VaultPath -Recurse -File -Include *.md, *.json |
  ForEach-Object { if (Expand-Tokens -Path $_.FullName -Map $tokens) { $expanded++ } }
Write-Host "Substituted tokens in $expanded file(s)"

# Fail loudly if any token survived. A leftover {{VAULT}} in a skill description
# is the kind of thing that works fine until the day it silently does not.
# Select-String has no -Recurse; enumerate first, then scan. -CaseSensitive is
# load-bearing: Select-String is case-insensitive by default, and obsidian-git's
# data.json legitimately contains its own {{date}} placeholder, which an
# insensitive match reports as an unsubstituted token of ours every single run.
# A guard that fires on every clean install is a guard people learn to ignore.
$leftover = Get-ChildItem -LiteralPath $VaultPath -Recurse -File -Include *.md, *.json |
  Select-String -Pattern '\{\{[A-Z_]+\}\}' -CaseSensitive
if ($leftover) {
  Write-Warning "Unsubstituted tokens remain:"
  $leftover | ForEach-Object { Write-Warning ("  {0}:{1}" -f $_.Path, $_.LineNumber) }
}

# ---------- 2. git init ----------
Push-Location $VaultPath
try {
  & git init -q -b $GitBranch 2>&1 | Out-Null
  if ($LASTEXITCODE -ne 0) {
    # Older git has no `init -b`. Fall back.
    & git init -q | Out-Null
    & git symbolic-ref HEAD "refs/heads/$GitBranch" | Out-Null
  }
  # Without this, `git add` on a fresh vault emits a screenful of "LF will be
  # replaced by CRLF" warnings. Harmless, but a wall of yellow on first run reads
  # as "the install broke" to anyone doing this for the first time, and a first
  # impression of noise teaches people to ignore this script's output, which is
  # the one habit the whole design cannot afford.
  & git config core.autocrlf false | Out-Null

  & git add -A | Out-Null
  $identity = @()
  $identity += @('-c', "user.name=$CommitName")
  if ($CommitEmail) { $identity += @('-c', "user.email=$CommitEmail") }
  & git @identity commit -q -m 'Initial vault from PAI-StarterKit' 2>&1 | Out-Null
  if ($LASTEXITCODE -ne 0) { Write-Warning "git commit failed. The vault exists but is not committed." }
  else { Write-Host "Initialized git repo on branch '$GitBranch' and committed." }
} finally {
  Pop-Location
}

Write-Host ""
Write-Host "No remote is configured. The drift scanner pushes to 'origin', so add one:" -ForegroundColor Yellow
Write-Host "  git -C `"$VaultPath`" remote add origin <your-remote-url>"
Write-Host "  git -C `"$VaultPath`" push -u origin $GitBranch"

if ($VaultOnly) {
  Write-Host ""
  Write-Host "-VaultOnly set. Skipping skill and hook install." -ForegroundColor Yellow
  exit 0
}

# ---------- 3. generate the skill ----------
$skillDir = Join-Path $ClaudeHome 'skills\pai-drift-check'
$skillSrc = Join-Path $KitRoot 'skill-template\SKILL.md'
$skillOut = Join-Path $skillDir 'SKILL.md'

# The skill is machine-global: one file, keyed by name, holding one baked-in vault
# path. Overwriting it without asking silently repoints an EXISTING vault's
# reconciliation skill at the vault we just created. Anyone testing the kit on a
# machine that already runs a vault would break the real one and be told "Done."
if ((Test-Path -LiteralPath $skillOut) -and -not $Force) {
  $prior = (Select-String -LiteralPath $skillOut -Pattern 'Reconcile the PAI vault \(`([^`]+)`\)' | Select-Object -First 1)
  $priorVault = if ($prior) { $prior.Matches[0].Groups[1].Value } else { '(unknown)' }
  if ($priorVault -ne $VaultPath) {
    Write-Host ""
    Write-Host "REFUSING TO OVERWRITE THE EXISTING pai-drift-check SKILL." -ForegroundColor Red
    Write-Host "  $skillOut already exists and points at a different vault:"
    Write-Host "    existing : $priorVault"
    Write-Host "    this one : $VaultPath"
    Write-Host ""
    Write-Host "  Overwriting would repoint that vault's reconciliation skill at this one."
    Write-Host "  The vault itself is built and fine. To finish wiring, either:"
    Write-Host "    - re-run with -Force to retarget the skill, or"
    Write-Host "    - re-run with -ClaudeHome <path> to install into an isolated config."
    exit 1
  }
}

New-Item -ItemType Directory -Force -Path $skillDir | Out-Null

$skillText = [IO.File]::ReadAllText($skillSrc)
foreach ($k in $tokens.Keys) { $skillText = $skillText.Replace($k, [string]$tokens[$k]) }
[IO.File]::WriteAllText($skillOut, $skillText, (New-Object Text.UTF8Encoding $false))
Write-Host "Generated skill: $skillOut"

# ---------- 4. install the lint hook ----------
$hookDir = Join-Path $ClaudeHome 'hooks'
New-Item -ItemType Directory -Force -Path $hookDir | Out-Null
Copy-Item -LiteralPath (Join-Path $KitRoot 'hooks\lint-ai-tells.mjs') -Destination $hookDir -Force
Write-Host "Installed hook script: $(Join-Path $hookDir 'lint-ai-tells.mjs')"

# ---------- 5. print the settings block ----------
$sessionScript = Join-Path $VaultPath '50-Meta\scripts\session-context.ps1'
$settingsPath  = Join-Path $ClaudeHome 'settings.json'

# The SessionStart command is the ONE place the absolute vault path has to be
# baked into global config. Everything else in the system derives it.
#
# JSON needs each backslash doubled. Use the string .Replace() method, NOT
# -replace: -replace is regex, and .NET regex REPLACEMENT strings treat backslash
# as a literal character, so '\\\\' emits four backslashes rather than the two we
# want. That produced a hook path of C:\\\\tmp\\\\... which parses to a directory
# that does not exist, and the failure is invisible until a session silently
# starts without context.
$sessionScriptJson = $sessionScript.Replace('\', '\\')

$block = @"
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"$sessionScriptJson\"",
            "timeout": 20,
            "statusMessage": "Loading PAI vault context"
          }
        ]
      }
    ]
  }
"@

# OPTIONAL. The prose lint is a style preference, not part of the memory system,
# so it is printed separately and nothing depends on it. Skip it freely.
$lintBlock = @"
    "PostToolUse": [
      {
        "matcher": "^(Write|Edit|MultiEdit)$",
        "hooks": [
          {
            "type": "command",
            "shell": "bash",
            "command": "node \"`$HOME/.claude/hooks/lint-ai-tells.mjs\"",
            "timeout": 15,
            "statusMessage": "Linting prose for AI tells"
          }
        ]
      }
    ],
"@

Write-Host ""
Write-Host ("=" * 78) -ForegroundColor Cyan
Write-Host "MANUAL STEP: paste this into $settingsPath" -ForegroundColor Cyan
Write-Host ("=" * 78) -ForegroundColor Cyan
Write-Host ""
Write-Host "Merge it into the top-level object. If a `"hooks`" key already exists,"
Write-Host "merge the arrays rather than replacing them."
Write-Host ""
Write-Host $block
Write-Host ""
Write-Host ("-" * 78)
Write-Host "Two things about this block:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  1. HOOK CHANGES TAKE EFFECT NEXT SESSION. Editing settings.json does"
Write-Host "     nothing to the session you are in right now. Restart Claude Code."
Write-Host "     (Editing the .ps1 the hook points at DOES take effect immediately,"
Write-Host "     because it is re-read on each call. Only the wiring is sticky.)"
Write-Host ""
Write-Host "  2. SessionStart is pinned to powershell.exe, not pwsh, on purpose."
Write-Host "     PowerShell 5.1's ConvertTo-Json escapes non-ASCII to \uXXXX, which"
Write-Host "     is what stops note bodies with curly quotes from arriving as"
Write-Host "     mojibake. Switching to pwsh needs [Console]::OutputEncoding set."
Write-Host ("-" * 78)
Write-Host ""
Write-Host "OPTIONAL: prose lint (flags em dashes and stock AI phrases in notes Claude writes)." -ForegroundColor Cyan
Write-Host "Skip it if you do not care. To use it, add this INSIDE the same hooks object,"
Write-Host "next to SessionStart (it needs Node.js installed):"
Write-Host ""
Write-Host $lintBlock
Write-Host ""
Write-Host "Then, to schedule the weekly drift scan:"
Write-Host "  pwsh -f `"$(Join-Path $VaultPath '50-Meta\scripts\register-drift-task.ps1')`""
Write-Host ""
Write-Host "Verify it is REAL (registration is not execution):"
Write-Host "  schtasks /Query /TN PAI-DriftScan /FO LIST"
Write-Host "  Confirm 'Last Result' is 0 and 'Last Run Time' is not N/A."
Write-Host ""
Write-Host "Done." -ForegroundColor Green
