<#
.SYNOPSIS
    DWP Startup Program Auditor - PowerShell 5.1, safe and reversible.

.DESCRIPTION
    Audits Windows startup programs across the four common startup locations
    (current user Run key, local machine Run key, current user Startup
    folder, all users Startup folder), and can safely disable a named
    startup program on request.

    Disabling never deletes anything outright:
      - Registry Run entries are removed from the Run key (so they stop
        executing) but their name/command is recorded in a structured CSV
        backup file first, so they can be restored later.
      - Startup folder items (shortcuts/executables) are moved into a
        quarantine folder rather than deleted, with the move recorded in
        the same backup file.

    Supports a DryRun switch (list-only / preview-only, no changes), a
    Disable switch to disable a named startup program, and a Rollback
    switch to restore a previously disabled program from the backup file.
    Every entry is processed independently with its own try/catch so one
    inaccessible or problematic entry never stops the rest of the run.

.PARAMETER Disable
    Name of a startup program to disable. Matched by name (case-insensitive)
    across all four startup locations. Requires verification that the name
    exists; if it does not, the script logs this and continues without
    error.

.PARAMETER Rollback
    Name of a previously disabled startup program to restore, using the
    structured backup CSV. If no backup entry exists for the name, the
    script logs this and continues without error.

.PARAMETER DryRun
    When set, no changes are made. On its own it lists all discovered
    startup programs. Combined with -Disable, it previews what would be
    disabled without touching the registry or file system.

.PARAMETER BackupFile
    Path to the structured CSV backup file used to record disabled items
    for later rollback. Defaults to a StartupAuditData folder next to this
    script.

.PARAMETER QuarantinePath
    Folder that disabled Startup-folder items are moved into (instead of
    being deleted). Defaults to a StartupAuditData\Quarantine folder next
    to this script.

.PARAMETER LogPath
    Folder where the timestamped log file for this run is written.
    Defaults to a StartupAuditData\Logs folder next to this script.

.EXAMPLE
    .\StartupProgramAuditor.ps1
    Lists every startup program found in all four locations.

.EXAMPLE
    .\StartupProgramAuditor.ps1 -DryRun
    Same as above, explicitly in read-only/preview mode.

.EXAMPLE
    .\StartupProgramAuditor.ps1 -Disable "OneDriveSetup" -DryRun
    Shows what disabling "OneDriveSetup" would do, without making changes.

.EXAMPLE
    .\StartupProgramAuditor.ps1 -Disable "OneDriveSetup"
    Disables the "OneDriveSetup" startup entry and records a backup entry.

.EXAMPLE
    .\StartupProgramAuditor.ps1 -Rollback "OneDriveSetup"
    Restores the previously disabled "OneDriveSetup" startup entry.

.NOTES
    Idempotent by design: disabling an item that is already disabled (a
    backup entry already exists for it) is detected and skipped rather than
    repeated, so no duplicate backup rows or duplicate actions occur.
    Rolling back an item with no backup entry is likewise a no-op that is
    logged, not an error.

    Modifying HKLM Run entries and the All Users Startup folder typically
    requires local administrator rights. Read-only listing generally does
    not.
#>

#Requires -Version 5.1

[CmdletBinding(DefaultParameterSetName = "List")]
param(
    [Parameter(ParameterSetName = "Disable", Mandatory = $true)]
    [string]$Disable,

    [Parameter(ParameterSetName = "Rollback", Mandatory = $true)]
    [string]$Rollback,

    [switch]$DryRun,

    [string]$BackupFile = (Join-Path $PSScriptRoot "StartupAuditData\StartupBackup.csv"),
    [string]$QuarantinePath = (Join-Path $PSScriptRoot "StartupAuditData\Quarantine"),
    [string]$LogPath = (Join-Path $PSScriptRoot "StartupAuditData\Logs")
)

# --- Logging setup: one timestamped log file per run, used by Write-Log below ---
$runTimestamp = Get-Date -Format "yyyyMMdd_HHmmss"
if (-not (Test-Path $LogPath)) { New-Item -Path $LogPath -ItemType Directory -Force | Out-Null }
$logFile = Join-Path $LogPath "StartupAudit_$runTimestamp.log"

function Write-Log {
    # Writes a single timestamped line to both the console and the run's log file
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR")][string]$Level = "INFO"
    )
    $line = "[{0}] [{1}] {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Level, $Message
    Add-Content -Path $logFile -Value $line
    switch ($Level) {
        "WARN"  { Write-Warning $Message }
        "ERROR" { Write-Host $line -ForegroundColor Red }
        default { Write-Host $line }
    }
}

# --- Startup locations covered by this audit ---
$RegistryLocations = @(
    @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"; Label = "HKCU-Run" }
    @{ Path = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"; Label = "HKLM-Run" }
)
$FolderLocations = @(
    @{ Path = (Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Startup"); Label = "CurrentUser-StartupFolder" }
    @{ Path = (Join-Path $env:ProgramData "Microsoft\Windows\Start Menu\Programs\Startup"); Label = "AllUsers-StartupFolder" }
)

function Get-RegistryStartupItems {
    # Enumerates value entries under a single Run registry key. Skips (does not
    # throw for) a missing key, and skips any individual value that cannot be
    # read, logging both cases and continuing with the rest.
    param([string]$KeyPath, [string]$Location)
    $items = @()
    try {
        if (-not (Test-Path $KeyPath)) {
            Write-Log "Registry path not found, skipping: $KeyPath" "WARN"
            return $items
        }
        $key = Get-Item -Path $KeyPath -ErrorAction Stop
        foreach ($valueName in $key.Property) {
            try {
                $data = (Get-ItemProperty -Path $KeyPath -Name $valueName -ErrorAction Stop).$valueName
                $items += [PSCustomObject]@{
                    Name     = $valueName
                    Command  = $data
                    Location = $Location
                    Type     = "Registry"
                    Path     = $KeyPath
                }
            }
            catch {
                Write-Log "Skipped unreadable registry value '$valueName' in '$KeyPath': $_" "WARN"
            }
        }
    }
    catch {
        Write-Log "Could not access registry path '$KeyPath': $_" "ERROR"
    }
    return $items
}

function Get-FolderStartupItems {
    # Enumerates files in a Startup folder. Skips (does not throw for) a
    # missing folder, and skips any individual file that cannot be read,
    # logging both cases and continuing with the rest.
    param([string]$FolderPath, [string]$Location)
    $items = @()
    try {
        if (-not (Test-Path $FolderPath)) {
            Write-Log "Startup folder not found, skipping: $FolderPath" "WARN"
            return $items
        }
        Get-ChildItem -Path $FolderPath -File -ErrorAction Stop |
            Where-Object { $_.Name -ne "desktop.ini" } |
            ForEach-Object {
                try {
                    $items += [PSCustomObject]@{
                        Name     = $_.BaseName
                        Command  = $_.FullName
                        Location = $Location
                        Type     = "File"
                        Path     = $FolderPath
                    }
                }
                catch {
                    Write-Log "Skipped unreadable startup folder item '$($_.FullName)': $_" "WARN"
                }
            }
    }
    catch {
        Write-Log "Could not access startup folder '$FolderPath': $_" "ERROR"
    }
    return $items
}

function Get-StartupItems {
    # Combines all four startup locations into a single list
    $items = @()
    foreach ($reg in $RegistryLocations) { $items += Get-RegistryStartupItems -KeyPath $reg.Path -Location $reg.Label }
    foreach ($folder in $FolderLocations) { $items += Get-FolderStartupItems -FolderPath $folder.Path -Location $folder.Label }
    return $items
}

# --- Structured backup file helpers (CSV), used for idempotent disable/rollback ---
function Get-BackupEntries {
    if (Test-Path $BackupFile) { return @(Import-Csv -Path $BackupFile) }
    return @()
}

function Test-BackupEntryExists {
    # $Location is optional - omit it to check for a backup entry by name in any location
    param([string]$Name, [string]$Location)
    $entries = Get-BackupEntries | Where-Object { $_.Name -ieq $Name }
    if ($Location) { $entries = $entries | Where-Object { $_.Location -eq $Location } }
    return [bool]$entries
}

function Add-BackupEntry {
    # Appends one structured backup row; creates the file (with headers) on first use
    param(
        [string]$Name, [string]$Type, [string]$Location,
        [string]$KeyPathOrFolder, [string]$ValueNameOrFileName,
        [string]$OriginalData, [string]$QuarantinePath
    )
    if (-not (Test-Path (Split-Path $BackupFile -Parent))) {
        New-Item -Path (Split-Path $BackupFile -Parent) -ItemType Directory -Force | Out-Null
    }
    $row = [PSCustomObject]@{
        Name                 = $Name
        Type                 = $Type
        Location             = $Location
        KeyPathOrFolder      = $KeyPathOrFolder
        ValueNameOrFileName  = $ValueNameOrFileName
        OriginalData         = $OriginalData
        QuarantinePath       = $QuarantinePath
        DisabledDate         = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }
    $row | Export-Csv -Path $BackupFile -NoTypeInformation -Append
}

function Remove-BackupEntry {
    # Rewrites the backup file without the given entry (called after a successful rollback)
    param([string]$Name, [string]$Location)
    $entries = Get-BackupEntries | Where-Object { -not ($_.Name -ieq $Name -and $_.Location -eq $Location) }
    if ($entries) {
        $entries | Export-Csv -Path $BackupFile -NoTypeInformation
    }
    else {
        Remove-Item -Path $BackupFile -Force -ErrorAction SilentlyContinue
    }
}

# --- Run counters used for the end-of-run summary ---
$totalFound = 0
$processedCount = 0
$skippedCount = 0
$errorCount = 0

Write-Log "============================================="
Write-Log "DWP Startup Program Auditor - Mode: $($PSCmdlet.ParameterSetName)$(if ($DryRun) { ' (DryRun)' })"
Write-Log "============================================="

if ($PSCmdlet.ParameterSetName -eq "List") {
    # --- List mode: read-only report of every startup program found ---
    $allItems = Get-StartupItems
    $totalFound = $allItems.Count
    foreach ($item in ($allItems | Sort-Object Location, Name)) {
        Write-Log ("Found: [{0}] {1} -> {2}" -f $item.Location, $item.Name, $item.Command)
    }
    $allItems | Sort-Object Location, Name | Format-Table Name, Command, Location -AutoSize
}
elseif ($PSCmdlet.ParameterSetName -eq "Disable") {
    # --- Disable mode: verify the name exists, then disable each matching entry ---
    $allItems = Get-StartupItems
    $totalFound = $allItems.Count
    $targetItems = $allItems | Where-Object { $_.Name -ieq $Disable }

    if (-not $targetItems) {
        if (Test-BackupEntryExists -Name $Disable) {
            Write-Log "Startup program '$Disable' already has a backup entry (already disabled). No action taken." "WARN"
            $skippedCount++
        }
        else {
            # Requirement: name not found -> log details and continue, do not stop the script
            Write-Log "Startup program '$Disable' was not found in any startup location. No action taken." "WARN"
        }
    }
    else {
        foreach ($item in $targetItems) {
            try {
                if (Test-BackupEntryExists -Name $item.Name -Location $item.Location) {
                    Write-Log "'$($item.Name)' in $($item.Location) is already disabled (backup entry exists). Skipping." "WARN"
                    $skippedCount++
                    continue
                }

                if ($DryRun) {
                    Write-Log "[DRY RUN] Would disable '$($item.Name)' ($($item.Location)): $($item.Command)"
                    continue
                }

                if ($item.Type -eq "Registry") {
                    Remove-ItemProperty -Path $item.Path -Name $item.Name -ErrorAction Stop
                    Add-BackupEntry -Name $item.Name -Type "Registry" -Location $item.Location `
                        -KeyPathOrFolder $item.Path -ValueNameOrFileName $item.Name `
                        -OriginalData $item.Command -QuarantinePath ""
                }
                else {
                    if (-not (Test-Path $QuarantinePath)) { New-Item -Path $QuarantinePath -ItemType Directory -Force | Out-Null }
                    $destination = Join-Path $QuarantinePath ("{0}_{1}{2}" -f $item.Name, $runTimestamp, [System.IO.Path]::GetExtension($item.Command))
                    Move-Item -Path $item.Command -Destination $destination -Force -ErrorAction Stop
                    Add-BackupEntry -Name $item.Name -Type "File" -Location $item.Location `
                        -KeyPathOrFolder $item.Path -ValueNameOrFileName (Split-Path $item.Command -Leaf) `
                        -OriginalData $item.Command -QuarantinePath $destination
                }

                Write-Log "Disabled '$($item.Name)' ($($item.Location))"
                $processedCount++
            }
            catch {
                Write-Log "Error disabling '$($item.Name)' ($($item.Location)): $_" "ERROR"
                $errorCount++
            }
        }
    }
}
elseif ($PSCmdlet.ParameterSetName -eq "Rollback") {
    # --- Rollback mode: restore a previously disabled entry from the backup file ---
    # Registry entries are re-created from the saved OriginalData value; quarantined
    # files are moved back to their saved OriginalData path. The matching backup row
    # is only removed after a successful restore, so a failed attempt can be retried.
    $allItems = Get-StartupItems
    $totalFound = $allItems.Count
    $backupEntries = Get-BackupEntries | Where-Object { $_.Name -ieq $Rollback }

    if (-not $backupEntries) {
        # Requirement: nothing to restore -> log details and continue, do not stop the script
        Write-Log "No backup entry found for '$Rollback'. Nothing to roll back." "WARN"
    }
    else {
        foreach ($entry in $backupEntries) {
            try {
                if ($DryRun) {
                    Write-Log "[DRY RUN] Would restore '$($entry.Name)' ($($entry.Location))"
                    continue
                }

                if ($entry.Type -eq "Registry") {
                    $existing = Get-ItemProperty -Path $entry.KeyPathOrFolder -Name $entry.ValueNameOrFileName -ErrorAction SilentlyContinue
                    if ($existing) {
                        # Idempotent: value already present, nothing to restore
                        Write-Log "Skip restore: value '$($entry.ValueNameOrFileName)' already exists at '$($entry.KeyPathOrFolder)'." "WARN"
                        $skippedCount++
                        continue
                    }
                    if (-not (Test-Path $entry.KeyPathOrFolder)) {
                        New-Item -Path $entry.KeyPathOrFolder -Force | Out-Null
                    }
                    New-ItemProperty -Path $entry.KeyPathOrFolder -Name $entry.ValueNameOrFileName `
                        -PropertyType String -Value $entry.OriginalData -Force -ErrorAction Stop | Out-Null
                    Write-Log "Restored registry value '$($entry.ValueNameOrFileName)' in '$($entry.KeyPathOrFolder)'."
                }
                else {
                    if (-not (Test-Path $entry.QuarantinePath)) {
                        # Idempotent: already restored (or otherwise removed) - nothing to do
                        Write-Log "Skip restore: quarantined file already gone: $($entry.QuarantinePath)" "WARN"
                        $skippedCount++
                        continue
                    }
                    if (Test-Path $entry.OriginalData) {
                        # Idempotent: do not clobber a file that already exists at the original path
                        Write-Log "Skip restore: original path already occupied: $($entry.OriginalData)" "WARN"
                        $skippedCount++
                        continue
                    }
                    if (-not (Test-Path $entry.KeyPathOrFolder)) {
                        New-Item -Path $entry.KeyPathOrFolder -ItemType Directory -Force | Out-Null
                    }
                    Move-Item -Path $entry.QuarantinePath -Destination $entry.OriginalData -Force -ErrorAction Stop
                    Write-Log "Restored startup file to '$($entry.OriginalData)'."
                }

                Remove-BackupEntry -Name $entry.Name -Location $entry.Location
                $processedCount++
            }
            catch {
                Write-Log "Error restoring '$($entry.Name)' ($($entry.Location)): $_" "ERROR"
                $errorCount++
            }
        }
    }
}

# --- End-of-run summary ---
$summary = [PSCustomObject]@{
    Mode           = $PSCmdlet.ParameterSetName
    DryRun         = [bool]$DryRun
    TotalFound     = $totalFound
    Processed      = $processedCount
    Skipped        = $skippedCount
    Errors         = $errorCount
    LogFile        = $logFile
}

Write-Log ("===== Summary: Mode={0} DryRun={1} TotalFound={2} Processed={3} Skipped={4} Errors={5} =====" -f `
        $summary.Mode, $summary.DryRun, $summary.TotalFound, $summary.Processed, $summary.Skipped, $summary.Errors)
Write-Log "Log file location: $logFile"

$summary | Format-List
