<#
.SYNOPSIS
    DWP Endpoint Temp File Cleanup - PowerShell 5.1, safe and reversible.

.DESCRIPTION
    Cleans up temporary files from configured target paths. Files are never
    permanently deleted in one step - they are moved ("soft deleted") into a
    dated quarantine folder, with every move recorded in a manifest CSV, so a
    rollback can restore them later if something turns out to still be needed.

    Supports a dry run mode, a configurable file-age filter, per-file
    try/catch handling (locked files are logged and skipped, not fatal),
    timestamped logging, and an end-of-run summary.

.PARAMETER TargetPaths
    One or more directories to clean. Defaults to the current user's Temp
    folder and the Windows system Temp folder.

.PARAMETER DaysOld
    Only files with a LastWriteTime older than this many days are targeted.
    Default is 0 (all files currently in the target paths are eligible).

.PARAMETER DryRun
    When set, no files are moved. The script only logs/prints what it would
    delete, and no quarantine folder or manifest is created.

.PARAMETER Rollback
    When set, restores files from a previous run's quarantine folder back to
    their original locations, using that run's manifest CSV.

.PARAMETER ManifestFile
    Optional, used with -Rollback. Full path to the specific manifest CSV to
    restore from. If omitted, the most recently written manifest is used.

.PARAMETER QuarantinePath
    Folder where "deleted" files are moved to. Defaults to a CleanupData
    folder next to this script, kept outside the target temp paths so a
    cleanup run never re-scans its own previously quarantined files.

.PARAMETER LogPath
    Folder where the timestamped log file is written. Defaults to a
    CleanupData\Logs folder next to this script.

.EXAMPLE
    .\Clear-EndpointTempFiles.ps1 -DryRun
    Lists what would be cleaned up without changing anything on disk.

.EXAMPLE
    .\Clear-EndpointTempFiles.ps1 -DaysOld 7
    Moves temp files older than 7 days into quarantine.

.EXAMPLE
    .\Clear-EndpointTempFiles.ps1 -Rollback
    Restores files quarantined by the most recent cleanup run.

.NOTES
    Idempotent by design: a "delete" is really a move out of the target path,
    so re-running the cleanup against the same folder simply finds nothing
    left to act on for files already handled - it does not error or double
    process. Rollback likewise skips entries whose quarantined file is
    already gone or whose original path is already occupied.
#>

#Requires -Version 5.1

[CmdletBinding()]
param(
    [string[]]$TargetPaths = @($env:TEMP, (Join-Path $env:WINDIR "Temp")),
    [int]$DaysOld = 0,
    [switch]$DryRun,
    [switch]$Rollback,
    [string]$ManifestFile,
    [string]$QuarantinePath = (Join-Path $PSScriptRoot "CleanupData\Quarantine"),
    [string]$LogPath = (Join-Path $PSScriptRoot "CleanupData\Logs")
)

# --- Logging setup: one timestamped log file per run, used by Write-Log below ---
$runTimestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$runId = $runTimestamp
if (-not (Test-Path $LogPath)) { New-Item -Path $LogPath -ItemType Directory -Force | Out-Null }
$logFile = Join-Path $LogPath "TempCleanup_$runTimestamp.log"

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

function Test-FileLocked {
    # Attempts an exclusive open to detect files currently in use by another process
    param([string]$Path)
    try {
        $stream = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
        $stream.Close()
        $stream.Dispose()
        return $false
    }
    catch {
        return $true
    }
}

Write-Log "============================================="
Write-Log "DWP Temp File Cleanup - RunId: $runId"
Write-Log "Mode: $(if ($Rollback) { 'ROLLBACK' } elseif ($DryRun) { 'DRY RUN' } else { 'CLEANUP' })"
Write-Log "============================================="

if ($Rollback) {
    # --- Rollback mode: restore quarantined files using a manifest, then stop ---
    try {
        if (-not (Test-Path $QuarantinePath)) {
            Write-Log "Quarantine path '$QuarantinePath' not found. Nothing to roll back." "WARN"
        }
        else {
            # Use the explicit manifest if given, otherwise the most recently written one
            if ($ManifestFile) {
                $manifestToUse = $ManifestFile
            }
            else {
                $manifestToUse = Get-ChildItem -Path $QuarantinePath -Filter "Manifest_*.csv" -ErrorAction SilentlyContinue |
                    Sort-Object LastWriteTime -Descending |
                    Select-Object -First 1 -ExpandProperty FullName
            }

            if (-not $manifestToUse -or -not (Test-Path $manifestToUse)) {
                Write-Log "No manifest file found to roll back from." "ERROR"
            }
            else {
                Write-Log "Rolling back using manifest: $manifestToUse"
                $entries = Import-Csv -Path $manifestToUse

                $restored = 0
                $skipped = 0
                $failed = 0

                foreach ($entry in $entries) {
                    try {
                        # Idempotent: already restored (or otherwise removed) - nothing to do
                        if (-not (Test-Path $entry.QuarantinePath)) {
                            Write-Log "Skip (quarantined file already gone): $($entry.QuarantinePath)" "WARN"
                            $skipped++
                            continue
                        }
                        # Idempotent: do not clobber a file that already exists at the original path
                        if (Test-Path $entry.OriginalPath) {
                            Write-Log "Skip (original path already occupied): $($entry.OriginalPath)" "WARN"
                            $skipped++
                            continue
                        }

                        $originalDir = Split-Path -Path $entry.OriginalPath -Parent
                        if (-not (Test-Path $originalDir)) {
                            New-Item -Path $originalDir -ItemType Directory -Force | Out-Null
                        }

                        Move-Item -Path $entry.QuarantinePath -Destination $entry.OriginalPath -Force -ErrorAction Stop
                        Write-Log "Restored: $($entry.OriginalPath)"
                        $restored++
                    }
                    catch {
                        Write-Log "Failed to restore '$($entry.OriginalPath)': $_" "ERROR"
                        $failed++
                    }
                }

                Write-Log "===== Rollback summary: Restored=$restored Skipped=$skipped Failed=$failed ====="
            }
        }
    }
    catch {
        Write-Log "Rollback aborted due to unexpected error: $_" "ERROR"
    }
}
else {
    # --- Cleanup mode: quarantine (or, in -DryRun, just report) eligible temp files ---
    $runQuarantineDir = Join-Path $QuarantinePath $runId
    $manifestPath = Join-Path $QuarantinePath "Manifest_$runId.csv"
    if (-not $DryRun -and -not (Test-Path $runQuarantineDir)) {
        New-Item -Path $runQuarantineDir -ItemType Directory -Force | Out-Null
    }

    $cutoffDate = (Get-Date).AddDays(-1 * $DaysOld)
    # Exclude our own quarantine/log folders in case one lives under a target path
    $excludePrefixes = @($QuarantinePath, $LogPath)

    Write-Log "Target paths: $($TargetPaths -join ', ')"
    Write-Log "Cutoff date (only files last written before this are eligible): $cutoffDate"

    $scanned = 0
    $moved = 0
    $lockedSkipped = 0
    $errors = 0
    $bytesFreed = 0
    $manifestRows = @()

    foreach ($path in $TargetPaths) {
        if (-not (Test-Path $path)) {
            Write-Log "Target path not found, skipping: $path" "WARN"
            continue
        }

        Get-ChildItem -Path $path -File -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object {
            $file = $_
            $scanned++

            $isExcluded = $false
            foreach ($prefix in $excludePrefixes) {
                if ($file.FullName.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
                    $isExcluded = $true
                }
            }
            if ($isExcluded) { return }

            # Age filter: skip files newer than the configured cutoff
            if ($file.LastWriteTime -gt $cutoffDate) { return }

            try {
                if (Test-FileLocked -Path $file.FullName) {
                    Write-Log "Locked, skipping: $($file.FullName)" "WARN"
                    $lockedSkipped++
                    return
                }

                if ($DryRun) {
                    Write-Log "[DRY RUN] Would delete: $($file.FullName) ($([math]::Round($file.Length / 1KB, 1)) KB, LastWriteTime: $($file.LastWriteTime))"
                    $moved++
                    $bytesFreed += $file.Length
                    return
                }

                # "Delete" = move to quarantine (with a GUID prefix to avoid name clashes) so it can be rolled back
                $destination = Join-Path $runQuarantineDir ([guid]::NewGuid().ToString() + "_" + $file.Name)
                Move-Item -Path $file.FullName -Destination $destination -Force -ErrorAction Stop

                $manifestRows += [PSCustomObject]@{
                    Timestamp      = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
                    OriginalPath   = $file.FullName
                    QuarantinePath = $destination
                    SizeBytes      = $file.Length
                }

                Write-Log "Deleted (quarantined): $($file.FullName)"
                $moved++
                $bytesFreed += $file.Length
            }
            catch {
                Write-Log "Error processing '$($file.FullName)': $_" "ERROR"
                $errors++
            }
        }
    }

    # Persist the manifest so this specific run can be rolled back later
    if (-not $DryRun -and $manifestRows.Count -gt 0) {
        $manifestRows | Export-Csv -Path $manifestPath -NoTypeInformation
        Write-Log "Manifest written: $manifestPath"
    }

    $summary = [PSCustomObject]@{
        RunId        = $runId
        Mode         = if ($DryRun) { "DRY RUN" } else { "CLEANUP" }
        FilesScanned = $scanned
        FilesDeleted = $moved
        FilesLocked  = $lockedSkipped
        Errors       = $errors
        SpaceFreedMB = [math]::Round($bytesFreed / 1MB, 2)
    }

    Write-Log ("===== Summary: RunId={0} Mode={1} Scanned={2} Deleted={3} LockedSkipped={4} Errors={5} SpaceFreedMB={6} =====" -f `
            $summary.RunId, $summary.Mode, $summary.FilesScanned, $summary.FilesDeleted, $summary.FilesLocked, $summary.Errors, $summary.SpaceFreedMB)

    $summary | Format-List
}

Write-Log "DWP Temp File Cleanup finished (RunId: $runId)"
