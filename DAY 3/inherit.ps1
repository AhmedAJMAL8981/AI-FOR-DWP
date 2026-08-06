<#
.SYNOPSIS
    Endpoint health snapshot: computer info, disk space, top processes, recent
    system errors, and stale local user profiles.

.DESCRIPTION
    Purpose : Quick read-only diagnostic report used during endpoint triage.
              Collects and prints computer details, free disk space on C:,
              the top 5 memory-consuming processes, recent System event log
              errors, and a count of local user profiles unused for 90+ days.
    Author  : IT Support Team
    Run     : Open PowerShell and execute:
                  .\inherit.ps1
              Some queries (event log, user profiles) may require running
              PowerShell as Administrator to return complete results.
    Notes   : Read-only script - makes no changes to the system.
#>

# Get computer name, domain, and total physical memory
$computerSystem = Get-CimInstance Win32_ComputerSystem

# Get free space (in bytes) on the C: drive
$freeDiskSpaceBytes = Get-PSDrive C | Select-Object -ExpandProperty Free

# Get the 5 processes currently using the most memory (working set)
$topProcesses = Get-Process | Sort-Object WS -Descending | Select-Object -First 5

# Get the 10 most recent System log entries, then keep only Error-level (2) events
$systemErrorEvents = Get-WinEvent -LogName System -MaxEvents 10 | Where-Object {$_.Level -eq 2}

# Get local user profiles, excluding special/system accounts, not used in the last 90 days
$staleUserProfiles = Get-CimInstance Win32_UserProfile | Where-Object {
     -not $_.Special -and $_.LastUseTime -lt (Get-Date).AddDays(-90)}

# Print computer name and total physical memory (bytes)
Write-Host $computerSystem.Name $computerSystem.TotalPhysicalMemory

# Print free disk space converted to GB, rounded to 2 decimal places
Write-Host ([math]::Round($freeDiskSpaceBytes/1GB,2)) 'GB free'

# Print name and memory usage for each of the top 5 processes
$topProcesses | ForEach-Object { Write-Host $_.Name $_.WS }

# Print timestamp and message for each recent system error event
$systemErrorEvents | ForEach-Object { Write-Host $_.TimeCreated $_.Message }

# Print the count of stale user profiles, if any were found
if ($staleUserProfiles.Count -gt 0) { Write-Host 'Stale profiles:' $staleUserProfiles.Count }