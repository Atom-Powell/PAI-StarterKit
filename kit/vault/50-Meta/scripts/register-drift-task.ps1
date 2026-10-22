# register-drift-task.ps1
# Registers (or re-registers) the weekly PAI drift-detection scheduled task.
# Run once (either PowerShell edition works):
#   pwsh -f C:/GitRepos/PAI-Vault/50-Meta/scripts/register-drift-task.ps1
#
# Primary path uses the ScheduledTasks cmdlets. Those fail on some PowerShell 7
# installs with a CIM native-layer error, so this falls back to native
# schtasks.exe driven by a task XML. The XML sets StartWhenAvailable=true, which
# gives catch-up-on-next-boot: if the machine was off at the scheduled time, the
# task runs at the next opportunity.

[CmdletBinding()]
param(
  # The scheduled-task name. Parameterized because it is a machine-global
  # namespace: registering from a second vault (a test install, a scratch copy)
  # with the name hardcoded silently REPOINTS the existing task at the new vault.
  # The old vault then stops being scanned and nothing anywhere says so.
  [string] $TaskName = 'PAI-DriftScan',

  # Required to retarget a task that already points at a different vault.
  [switch] $Force
)

$ErrorActionPreference = 'Stop'
$taskName = $TaskName

# Derived from this script's own location, so the registrar works from any clone.
$script = Join-Path $PSScriptRoot 'drift-scan.ps1'

if (-not (Test-Path -LiteralPath $script)) { throw "Scanner not found: $script" }
$script = (Resolve-Path -LiteralPath $script).Path

# Refuse to silently hijack a task that already points at a DIFFERENT vault.
# Without this, standing up a second vault (or testing the kit) quietly stops the
# first one from ever being scanned again, and the only symptom is drift reports
# that stop appearing, which is a thing nobody notices.
$existing = & schtasks.exe /Query /TN $taskName /XML ONE 2>$null
if ($LASTEXITCODE -eq 0 -and $existing) {
  $xmlText = ($existing -join "`n")
  if ($xmlText -notmatch [regex]::Escape($script)) {
    $m = [regex]::Match($xmlText, '-File\s+"([^"]+)"')
    $current = if ($m.Success) { $m.Groups[1].Value } else { '(could not parse)' }
    if (-not $Force) {
      Write-Host ""
      Write-Host "REFUSING TO OVERWRITE." -ForegroundColor Red
      Write-Host "  A scheduled task named '$taskName' already exists and points at a DIFFERENT vault:"
      Write-Host "    existing : $current"
      Write-Host "    this one : $script"
      Write-Host ""
      Write-Host "  Overwriting would stop the other vault being scanned, with no other symptom"
      Write-Host "  than its drift reports quietly ceasing."
      Write-Host ""
      Write-Host "  Either re-run with -Force to retarget it, or give this vault its own task:"
      Write-Host "    -TaskName PAI-DriftScan-<something>"
      exit 1
    }
    Write-Host "WARNING: -Force set. Retargeting '$taskName' from $current to $script." -ForegroundColor Yellow
  }
}

# Next Monday at 09:00 as the trigger's StartBoundary (weekly recurrence handles
# the rest; the exact date only anchors the weekly cadence).
#
# The guard below matters. If today IS Monday the loop never advances, so the
# boundary lands on today at 09:00, which is in the PAST if you register on a
# Monday afternoon. Combined with StartWhenAvailable, Task Scheduler reads that
# as a missed trigger and runs the scan almost immediately, committing and
# pushing to the vault's branch without anyone asking for it.
$d = Get-Date
if ($d.DayOfWeek -eq [DayOfWeek]::Monday -and $d.TimeOfDay -ge [timespan]'09:00:00') {
  $d = $d.AddDays(7)
}
while ($d.DayOfWeek -ne [DayOfWeek]::Monday) { $d = $d.AddDays(1) }
$startBoundary = (Get-Date -Year $d.Year -Month $d.Month -Day $d.Day -Hour 9 -Minute 0 -Second 0).ToString('yyyy-MM-ddTHH:mm:ss')

$registered = $false

# Primary: ScheduledTasks cmdlets (also sets StartWhenAvailable).
try {
  # -Force overwrites an existing task. Do NOT Unregister first: if registration
  # then failed we would be left with no task at all.
  $action    = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$script`""
  $trigger   = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At 9:00AM
  $principal = New-ScheduledTaskPrincipal -UserId ([Security.Principal.WindowsIdentity]::GetCurrent().User.Value) -LogonType Interactive -RunLevel Limited
  $settings  = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopOnIdleEnd -ExecutionTimeLimit (New-TimeSpan -Minutes 15)
  Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force `
    -Description 'Weekly PAI vault drift detection. Writes a report to 00-Inbox and pushes it.' | Out-Null
  $registered = $true
  Write-Host "Registered via ScheduledTasks cmdlets (weekly Mon 09:00, catch-up on next boot)."
} catch {
  $firstLine = ($_.Exception.Message -split "`r?`n")[0]
  Write-Host "Cmdlet path unavailable ($firstLine)."
  Write-Host "Falling back to schtasks.exe with a task XML ..."
}

# Fallback: native schtasks.exe from XML. StartWhenAvailable gives catch-up.
if (-not $registered) {
  # Use the current user's SID rather than DOMAIN\USERNAME. The string form
  # breaks on Azure AD / Microsoft-account machines, where the principal is
  # AzureAD\user. The SID is correct everywhere and needs no XML escaping.
  $user = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value

  # The script path is interpolated into XML below, so escape it. An ampersand
  # anywhere in the path would otherwise produce invalid XML.
  $scriptXml = [System.Security.SecurityElement]::Escape($script)

  $xml = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Description>Weekly PAI vault drift detection. Writes a report to 00-Inbox and pushes it.</Description>
  </RegistrationInfo>
  <Triggers>
    <CalendarTrigger>
      <StartBoundary>$startBoundary</StartBoundary>
      <Enabled>true</Enabled>
      <ScheduleByWeek>
        <DaysOfWeek><Monday /></DaysOfWeek>
        <WeeksInterval>1</WeeksInterval>
      </ScheduleByWeek>
    </CalendarTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <UserId>$user</UserId>
      <LogonType>InteractiveToken</LogonType>
      <RunLevel>LeastPrivilege</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <StartWhenAvailable>true</StartWhenAvailable>
    <ExecutionTimeLimit>PT15M</ExecutionTimeLimit>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <Enabled>true</Enabled>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>powershell.exe</Command>
      <Arguments>-NoProfile -ExecutionPolicy Bypass -File "$scriptXml"</Arguments>
    </Exec>
  </Actions>
</Task>
"@
  $xmlPath = Join-Path $env:TEMP 'pai-drift-task.xml'
  Set-Content -LiteralPath $xmlPath -Value $xml -Encoding Unicode

  # No /Delete first. /Create /F already overwrites, and an unconditional delete
  # meant that a subsequent /Create failure (bad XML, locked TEMP, policy block)
  # left NO task at all, which is strictly worse than the task we started with.
  & schtasks.exe /Create /TN $taskName /XML "$xmlPath" /F | Out-Null
  $code = $LASTEXITCODE
  Remove-Item -LiteralPath $xmlPath -ErrorAction SilentlyContinue
  if ($code -ne 0) { throw "schtasks XML registration failed with exit code $code" }
  Write-Host "Registered via schtasks.exe from XML (weekly Mon 09:00, catch-up on next boot)."
}

# Verify with native schtasks so this works regardless of CIM availability.
Write-Host ""
Write-Host "Verification:"
& schtasks.exe /Query /TN $taskName /FO LIST | Select-String 'TaskName|Next Run Time|Status|Schedule Type|Start Time|Days'
Write-Host ""
Write-Host "Run it now as a test:  schtasks.exe /Run /TN $taskName"
Write-Host "Remove it:             schtasks.exe /Delete /TN $taskName /F"
Write-Host "(From Git Bash, prefix both with MSYS_NO_PATHCONV=1 to stop path mangling.)"
